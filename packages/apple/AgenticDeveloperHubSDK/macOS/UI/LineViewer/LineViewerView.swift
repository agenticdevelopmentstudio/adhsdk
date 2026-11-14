import AppKit
import CoreText
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage

/// The `LineViewerViewController`'s document view: flipped, exactly
/// `displayedRowCount × rowHeight` tall, drawing only the rows that intersect
/// the dirty rect with Core Text, and of a long line only the stretch under the
/// dirty rect. The gutter is a subview (`gutterView`) pinned to the visible
/// left edge. Selection, folding and copy live here because they are all row
/// geometry; the controller forwards to it.
@MainActor
final class LineViewerView: NSView {

    /// The controller that owns this view; the source of the data source and
    /// delegate, and the object the delegate is told about.
    weak var owner: LineViewerViewController?

    var foldsAtHeaders = false {
        didSet {
            guard foldsAtHeaders != oldValue else { return }
            folds = []
            updateFrameSize()
            invalidate()
        }
    }

    /// The pinned gutter; it draws through `drawGutter(in:width:)`.
    let gutterView = LineViewerGutterView(frame: .zero)

    private(set) var selectedRows = IndexSet()
    private(set) var rowHeight: CGFloat = 0

    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    private var font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private var ascent: CGFloat = 0
    private var xHeight: CGFloat = 0
    /// The advance of "0" in the code font: one column of a monospaced line.
    private(set) var charWidth: CGFloat = 0
    /// UTF-16 units laid out by the last `draw(_:)`; the seam that shows long
    /// lines are sliced rather than laid out whole.
    private(set) var laidOutLength = 0

    private var rowCount = 0
    private var gutterColumnCount = 0
    /// Each gutter column's content width in characters, from the data source.
    private var gutterCharacterWidths: [Int] = []
    /// Folded headers and the data rows each hides, sorted by header.
    private var folds: [(header: Int, hidden: Range<Int>)] = []
    private var anchorRow: Int?
    private var isDragSelecting = false
    /// The widest row drawn since the last reload; the document grows to it.
    private var widestRow: CGFloat = 0

    private static let verticalPadding: CGFloat = 2
    private static let emphasisAlpha: CGFloat = 0.40
    private static let diffAlpha: CGFloat = 0.18
    private static let hatchSpacing: CGFloat = 6
    /// Lines longer than this (UTF-16 units) are laid out only where the dirty
    /// rect crosses them, treating each unit as one monospaced column.
    private static let sliceThreshold = 1024
    /// Columns laid out beyond each side of the dirty rect, so glyphs cut by
    /// its edges still draw whole.
    private static let slicePadding = 8

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        gutterView.host = self
        addSubview(gutterView)
        measure()
        observeTheme { view, palette in view.apply(palette) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    private var dataSource: LineViewerDataSource? { owner?.dataSource }

    // MARK: - Theme and metrics

    private func apply(_ palette: SemanticPalette) {
        self.palette = palette
        font = palette.font(.code)
        measure()
        updateFrameSize()
        invalidate()
    }

    private func measure() {
        let ctFont = font as CTFont
        ascent = CTFontGetAscent(ctFont)
        xHeight = CTFontGetXHeight(ctFont)
        rowHeight = ceil(ascent + CTFontGetDescent(ctFont) + CTFontGetLeading(ctFont)) + 2 * Self.verticalPadding
        charWidth = ("0" as NSString).size(withAttributes: [.font: font]).width
    }

    /// Gutter column `column`'s rect in `gutterView` coordinates, one row tall
    /// at y 0: its content width plus one character of padding on each side.
    func gutterColumnFrame(_ column: Int) -> NSRect {
        var minX: CGFloat = 0
        for earlier in 0..<column { minX += columnWidth(earlier) }
        return NSRect(x: minX, y: 0, width: columnWidth(column), height: rowHeight)
    }

    private func columnWidth(_ column: Int) -> CGFloat {
        let characters = column < gutterCharacterWidths.count ? gutterCharacterWidths[column] : 3
        return CGFloat(characters + 2) * charWidth
    }

    /// The gutter's width, its divider included; zero with no gutter columns.
    private var gutterWidth: CGFloat {
        guard gutterColumnCount > 0 else { return 0 }
        return (0..<gutterColumnCount).reduce(0) { $0 + columnWidth($1) } + 1
    }

    /// Where a text row's text starts, in document coordinates.
    var textOriginX: CGFloat { gutterWidth + charWidth }

    /// Marks the rows and the gutter for redrawing.
    private func invalidate() {
        needsDisplay = true
        gutterView.needsDisplay = true
    }

    // MARK: - Rows and folds

    var displayedRowCount: Int {
        rowCount - folds.reduce(0) { $0 + $1.hidden.count }
    }

    func dataRow(forDisplayRow display: Int) -> Int {
        var row = display
        for fold in folds {
            guard fold.hidden.lowerBound <= row else { break }
            row += fold.hidden.count
        }
        return row
    }

    /// The display row of data row `row`, or nil when a fold hides it.
    func displayRow(forDataRow row: Int) -> Int? {
        var display = row
        for fold in folds {
            if fold.hidden.contains(row) { return nil }
            if fold.hidden.upperBound <= row { display -= fold.hidden.count }
        }
        return display
    }

    func reload() {
        rowCount = dataSource?.rowCount ?? 0
        gutterColumnCount = dataSource?.gutterColumnCount ?? 0
        gutterCharacterWidths = (0..<gutterColumnCount).map { max(1, dataSource?.gutterColumnWidth($0) ?? 3) }
        folds = []
        selectedRows = []
        anchorRow = nil
        widestRow = 0
        updateFrameSize()
        invalidate()
    }

    /// Shows the rows of the fold that hides data row `row`, if any.
    func unfold(containing row: Int) {
        guard let index = folds.firstIndex(where: { $0.hidden.contains(row) }) else { return }
        folds.remove(at: index)
        updateFrameSize()
        invalidate()
    }

    private func toggleFold(header: Int) {
        if let index = folds.firstIndex(where: { $0.header == header }) {
            folds.remove(at: index)
        } else if let source = dataSource {
            var end = header + 1
            while end < rowCount, source.row(at: end).kind != .header { end += 1 }
            let hidden = (header + 1)..<end
            folds.append((header, hidden))
            folds.sort { $0.header < $1.header }
            var remaining = selectedRows
            remaining.remove(integersIn: hidden)
            setSelection(remaining)
        }
        updateFrameSize()
        invalidate()
    }

    func updateFrameSize() {
        let height = CGFloat(displayedRowCount) * rowHeight
        let width = max(superview?.bounds.width ?? 0, widestRow)
        if frame.size != NSSize(width: width, height: height) {
            setFrameSize(NSSize(width: width, height: height))
        }
        pinGutter()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        pinGutter()
    }

    /// Keeps the gutter at the clip view's left edge, full height.
    private func pinGutter() {
        let width = gutterWidth
        gutterView.isHidden = width == 0
        let left = max(0, (superview as? NSClipView)?.bounds.minX ?? 0)
        let pinned = NSRect(x: left, y: 0, width: width, height: bounds.height)
        if gutterView.frame != pinned { gutterView.frame = pinned }
    }

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        if let superview {
            NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: superview)
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: superview)
        }
        super.viewWillMove(toSuperview: newSuperview)
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let superview else { return }
        superview.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(superviewFrameDidChange(_:)),
                                               name: NSView.frameDidChangeNotification, object: superview)
        superview.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(superviewBoundsDidChange(_:)),
                                               name: NSView.boundsDidChangeNotification, object: superview)
        updateFrameSize()
    }

    @objc private func superviewFrameDidChange(_ notification: Notification) {
        updateFrameSize()
    }

    @objc private func superviewBoundsDidChange(_ notification: Notification) {
        pinGutter()
    }

    // MARK: - Drawing

    /// The display rows that intersect the vertical span of `rect`.
    private func displayRows(in rect: NSRect) -> ClosedRange<Int>? {
        let displayed = displayedRowCount
        guard displayed > 0, rowHeight > 0 else { return nil }
        let first = max(0, Int(floor(rect.minY / rowHeight)))
        let last = min(displayed - 1, Int(ceil(rect.maxY / rowHeight)) - 1)
        return first <= last ? first...last : nil
    }

    override func draw(_ dirtyRect: NSRect) {
        laidOutLength = 0
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        palette.windowBackgroundColor.setFill()
        dirtyRect.fill()
        guard let source = dataSource, let rows = displayRows(in: dirtyRect) else { return }

        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        var widest = widestRow
        for display in rows {
            let index = dataRow(forDisplayRow: display)
            let rect = NSRect(x: 0, y: CGFloat(display) * rowHeight, width: bounds.width, height: rowHeight)
            let row = source.row(at: index)
            drawBackground(row, index: index, in: rect, context: context)
            widest = max(widest, drawText(row, index: index, in: rect, span: dirtyRect, context: context))
        }
        context.restoreGState()

        if widest > widestRow {
            widestRow = widest
            // Not from inside draw: resizing here would re-enter display.
            Task { @MainActor [weak self] in self?.updateFrameSize() }
        }
    }

    /// A row's background role and its selection overlay, across `rect`.
    private func drawBackground(_ row: LineViewerRow, index: Int, in rect: NSRect, context: CGContext) {
        if row.background == .filler {
            drawHatching(in: rect, context: context)
        } else if let fill = color(for: row.background, rowTone: row.background) {
            fill.setFill()
            rect.fill()
        }
        if selectedRows.contains(index) {
            palette.selectionColor.setFill()
            rect.fill()
        }
    }

    /// Draws one row's text, laying out only the stretch of a long line that
    /// the horizontal extent of `span` crosses, and answers the width the row
    /// needs.
    private func drawText(_ row: LineViewerRow, index: Int, in rect: NSRect, span: NSRect,
                          context: CGContext) -> CGFloat {
        var textX = textOriginX
        let baseline = rect.minY + Self.verticalPadding + ascent
        if foldsAtHeaders, row.kind == .header {
            let folded = folds.contains { $0.header == index }
            let chevron = NSAttributedString(string: folded ? "\u{25B8}" : "\u{25BE}",
                                             attributes: [.font: font, .foregroundColor: palette.secondaryTextColor])
            context.textPosition = CGPoint(x: textX, y: baseline)
            CTLineDraw(CTLineCreateWithAttributedString(chevron), context)
            textX += 2 * charWidth
        }

        let text = row.text as NSString
        let length = text.length
        let slice = visibleSlice(of: text, length: length, textX: textX, span: span)
        laidOutLength += slice.length
        let sliceX = textX + CGFloat(slice.location) * charWidth
        let runs = row.runs.compactMap { run -> (range: NSRange, run: LineViewerRun)? in
            let local = Self.localRange(run.range, length: length, slice: slice)
            return local.length > 0 ? (local, run) : nil
        }
        let line = CTLineCreateWithAttributedString(attributedText(text.substring(with: slice), runs: runs))
        for (range, run) in runs {
            let start = CTLineGetOffsetForStringIndex(line, range.location, nil)
            let end = CTLineGetOffsetForStringIndex(line, NSMaxRange(range), nil)
            if let role = run.highlight, let fill = color(for: role, rowTone: row.background) {
                fill.setFill()
                NSRect(x: sliceX + start, y: rect.minY, width: end - start, height: rect.height).fill()
            }
        }
        context.textPosition = CGPoint(x: sliceX, y: baseline)
        CTLineDraw(line, context)
        drawDecorations(runs, line: line, textX: sliceX, baseline: baseline)
        if slice.length < length {
            return textX + CGFloat(length) * charWidth + charWidth
        }
        return textX + CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)) + charWidth
    }

    /// The whole line when it is short; otherwise the UTF-16 range under the
    /// horizontal extent of `span` (each unit one monospaced column), padded
    /// and widened so it neither starts nor ends inside a composed character
    /// sequence or surrogate pair.
    private func visibleSlice(of text: NSString, length: Int, textX: CGFloat, span: NSRect) -> NSRange {
        guard length > Self.sliceThreshold, charWidth > 0 else { return NSRange(location: 0, length: length) }
        let first = Int(floor((span.minX - textX) / charWidth)) - Self.slicePadding
        let last = Int(ceil((span.maxX - textX) / charWidth)) + Self.slicePadding
        let lower = min(max(0, first), length)
        let upper = min(max(lower, last), length)
        guard upper > lower else { return NSRange(location: lower, length: 0) }
        return text.rangeOfComposedCharacterSequences(for: NSRange(location: lower, length: upper - lower))
    }

    /// `range` clipped to the line, then to `slice`, relative to the slice.
    private static func localRange(_ range: NSRange, length: Int, slice: NSRange) -> NSRange {
        let clipped = clip(range, to: length)
        let start = max(clipped.location, slice.location)
        let end = min(NSMaxRange(clipped), NSMaxRange(slice))
        return end > start ? NSRange(location: start - slice.location, length: end - start) : NSRange()
    }

    /// Draws the gutter's rows in `gutterView` coordinates (y is the document's):
    /// each row's background and selection, each column's value right-aligned
    /// in its column (left-aligned when wider) and clipped to it, and the divider.
    func drawGutter(in dirtyRect: NSRect, width: CGFloat) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        palette.windowBackgroundColor.setFill()
        dirtyRect.fill()
        guard gutterColumnCount > 0 else { return }
        if let source = dataSource, let rows = displayRows(in: dirtyRect) {
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: palette.secondaryTextColor]
            for display in rows {
                let index = dataRow(forDisplayRow: display)
                let row = source.row(at: index)
                let top = CGFloat(display) * rowHeight
                drawBackground(row, index: index, in: NSRect(x: 0, y: top, width: width, height: rowHeight),
                               context: context)
                for column in 0..<min(gutterColumnCount, row.gutter.count) {
                    guard let value = row.gutter[column] else { continue }
                    let content = gutterColumnFrame(column).offsetBy(dx: 0, dy: top).insetBy(dx: charWidth, dy: 0)
                    let text = NSAttributedString(string: value, attributes: attributes)
                    let valueWidth = text.size().width
                    let originX = valueWidth <= content.width ? content.maxX - valueWidth : content.minX
                    context.saveGState()
                    context.clip(to: content)
                    text.draw(at: NSPoint(x: originX, y: top + Self.verticalPadding))
                    context.restoreGState()
                }
            }
        }
        palette.dividerColor.setFill()
        NSRect(x: gutterWidth - 1, y: dirtyRect.minY, width: 1, height: dirtyRect.height).fill()
    }

    /// Core Text draws no underline or strikethrough, so those are drawn here.
    /// `runs` carry ranges relative to `line`.
    private func drawDecorations(_ runs: [(range: NSRange, run: LineViewerRun)], line: CTLine, textX: CGFloat,
                                 baseline: CGFloat) {
        for (range, run) in runs where run.fontStyle.contains(.underline) || run.fontStyle.contains(.strikethrough) {
            let start = CTLineGetOffsetForStringIndex(line, range.location, nil)
            let end = CTLineGetOffsetForStringIndex(line, NSMaxRange(range), nil)
            (run.foreground.map { NSColor($0) } ?? palette.primaryTextColor).setFill()
            if run.fontStyle.contains(.underline) {
                NSRect(x: textX + start, y: baseline + 1, width: end - start, height: 1).fill()
            }
            if run.fontStyle.contains(.strikethrough) {
                NSRect(x: textX + start, y: baseline - xHeight / 2, width: end - start, height: 1).fill()
            }
        }
    }

    /// `string` styled by `runs`, whose ranges are relative to it.
    private func attributedText(_ string: String, runs: [(range: NSRange, run: LineViewerRun)]) -> NSAttributedString {
        let text = NSMutableAttributedString(string: string,
                                             attributes: [.font: font, .foregroundColor: palette.primaryTextColor])
        for (range, run) in runs {
            if let foreground = run.foreground {
                text.addAttribute(.foregroundColor, value: NSColor(foreground), range: range)
            }
            var traits: CTFontSymbolicTraits = []
            if run.fontStyle.contains(.bold) { traits.insert(.traitBold) }
            if run.fontStyle.contains(.italic) { traits.insert(.traitItalic) }
            if !traits.isEmpty,
               let styled = CTFontCreateCopyWithSymbolicTraits(font as CTFont, 0, nil, traits, traits) {
                text.addAttribute(.font, value: styled as NSFont, range: range)
            }
        }
        return text
    }

    private func drawHatching(in rect: NSRect, context: CGContext) {
        context.saveGState()
        context.clip(to: rect)
        context.setStrokeColor(palette.surfaceColor.cgColor)
        context.setLineWidth(1)
        var offset = rect.minX - rect.height
        while offset < rect.maxX {
            context.move(to: CGPoint(x: offset, y: rect.maxY))
            context.addLine(to: CGPoint(x: offset + rect.height, y: rect.minY))
            offset += Self.hatchSpacing
        }
        context.strokePath()
        context.restoreGState()
    }

    /// The fill for a background role; `emphasis` takes the row's tone.
    private func color(for role: LineViewerBackground, rowTone: LineViewerBackground) -> NSColor? {
        switch role {
        case .none: return nil
        case .added: return palette.successColor.withAlphaComponent(Self.diffAlpha)
        case .removed: return palette.dangerColor.withAlphaComponent(Self.diffAlpha)
        case .header, .filler: return palette.surfaceColor
        case .emphasis:
            let tone: NSColor
            switch rowTone {
            case .added: tone = palette.successColor
            case .removed: tone = palette.dangerColor
            default: tone = palette.accentColor
            }
            return tone.withAlphaComponent(Self.emphasisAlpha)
        }
    }

    private static func clip(_ range: NSRange, to length: Int) -> NSRange {
        let start = min(max(0, range.location), length)
        let end = min(max(start, range.location + range.length), length)
        return NSRange(location: start, length: end - start)
    }

    // MARK: - Mouse and selection

    private func displayRowIndex(at point: NSPoint) -> Int? {
        guard rowHeight > 0, point.y >= 0 else { return nil }
        let display = Int(point.y / rowHeight)
        return display < displayedRowCount ? display : nil
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        handleClick(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragSelecting, let anchor = anchorRow, displayedRowCount > 0 else { return }
        let point = convert(event.locationInWindow, from: nil)
        let display = min(max(0, Int(point.y / rowHeight)), displayedRowCount - 1)
        let row = dataRow(forDisplayRow: display)
        setSelection(rows(from: anchor, to: row))
        autoscroll(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        isDragSelecting = false
    }

    /// A click at `point` (document coordinates): a gutter click, a fold toggle
    /// on a header, or a selection change, in that order.
    func handleClick(at point: NSPoint, modifiers: NSEvent.ModifierFlags) {
        isDragSelecting = false
        guard let display = displayRowIndex(at: point), let source = dataSource else { return }
        let row = dataRow(forDisplayRow: display)
        let gutterX = point.x - gutterView.frame.minX
        if gutterColumnCount > 0, gutterX >= 0, gutterX < gutterWidth {
            let column = (0..<gutterColumnCount).first { gutterX < gutterColumnFrame($0).maxX } ?? gutterColumnCount - 1
            owner?.notifyGutterClick(column: column, row: row)
            return
        }
        if foldsAtHeaders, source.row(at: row).kind == .header {
            toggleFold(header: row)
            return
        }
        isDragSelecting = true
        if modifiers.contains(.shift), let anchor = anchorRow {
            setSelection(rows(from: anchor, to: row))
        } else if modifiers.contains(.command) {
            var toggled = selectedRows
            if toggled.contains(row) { toggled.remove(row) } else { toggled.insert(row) }
            anchorRow = row
            setSelection(toggled)
        } else {
            anchorRow = row
            setSelection(IndexSet(integer: row))
        }
    }

    /// The visible data rows between two data rows, inclusive, skipping folded ones.
    private func rows(from anchor: Int, to row: Int) -> IndexSet {
        var result = IndexSet(integersIn: min(anchor, row)...max(anchor, row))
        for fold in folds { result.remove(integersIn: fold.hidden) }
        return result
    }

    private func setSelection(_ rows: IndexSet) {
        guard rows != selectedRows else { return }
        selectedRows = rows
        invalidate()
        owner?.notifySelection(rows)
    }

    // MARK: - Copy

    @objc func copy(_ sender: Any?) {
        copySelection(to: .general)
    }

    /// Puts the selected rows' text, in row order and joined by `\n`, on `pasteboard`.
    func copySelection(to pasteboard: NSPasteboard) {
        guard !selectedRows.isEmpty, let source = dataSource else { return }
        let text = selectedRows.map { source.row(at: $0).text }.joined(separator: "\n")
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - Accessibility

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .textArea }

    override func accessibilityValue() -> Any? {
        guard let source = dataSource, let rows = displayRows(in: visibleRect) else { return "" }
        return rows.map { source.row(at: dataRow(forDisplayRow: $0)).text }.joined(separator: "\n")
    }
}

extension LineViewerView: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(copy(_:)) { return !selectedRows.isEmpty }
        return true
    }
}
