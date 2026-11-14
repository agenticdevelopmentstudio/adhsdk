import AppKit
import CoreText
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage

/// The `LineViewerViewController`'s document view: flipped, exactly
/// `displayedRowCount × rowHeight` tall, drawing only the rows that intersect
/// the dirty rect with Core Text. Selection, folding and copy live here because
/// they are all row geometry; the controller forwards to it.
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
            needsDisplay = true
        }
    }

    private(set) var selectedRows = IndexSet()
    private(set) var rowHeight: CGFloat = 0

    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    private var font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private var ascent: CGFloat = 0
    private var xHeight: CGFloat = 0
    private var charWidth: CGFloat = 0

    private var rowCount = 0
    private var gutterColumnCount = 0
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

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
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
        needsDisplay = true
    }

    private func measure() {
        let ctFont = font as CTFont
        ascent = CTFontGetAscent(ctFont)
        xHeight = CTFontGetXHeight(ctFont)
        rowHeight = ceil(ascent + CTFontGetDescent(ctFont) + CTFontGetLeading(ctFont)) + 2 * Self.verticalPadding
        charWidth = ("0" as NSString).size(withAttributes: [.font: font]).width
    }

    private var gutterColumnWidth: CGFloat {
        CGFloat(max(3, String(rowCount).count) + 2) * charWidth
    }

    private var gutterWidth: CGFloat {
        gutterColumnCount > 0 ? CGFloat(gutterColumnCount) * gutterColumnWidth + 1 : 0
    }

    /// Where a text row's text starts.
    var textOriginX: CGFloat { gutterWidth + charWidth }

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
        folds = []
        selectedRows = []
        anchorRow = nil
        widestRow = 0
        updateFrameSize()
        needsDisplay = true
    }

    /// Shows the rows of the fold that hides data row `row`, if any.
    func unfold(containing row: Int) {
        guard let index = folds.firstIndex(where: { $0.hidden.contains(row) }) else { return }
        folds.remove(at: index)
        updateFrameSize()
        needsDisplay = true
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
        needsDisplay = true
    }

    func updateFrameSize() {
        let height = CGFloat(displayedRowCount) * rowHeight
        let width = max(superview?.bounds.width ?? 0, widestRow)
        if frame.size != NSSize(width: width, height: height) {
            setFrameSize(NSSize(width: width, height: height))
        }
    }

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        if let superview {
            NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: superview)
        }
        super.viewWillMove(toSuperview: newSuperview)
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let superview else { return }
        superview.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(superviewFrameDidChange(_:)),
                                               name: NSView.frameDidChangeNotification, object: superview)
        updateFrameSize()
    }

    @objc private func superviewFrameDidChange(_ notification: Notification) {
        updateFrameSize()
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        palette.windowBackgroundColor.setFill()
        dirtyRect.fill()
        let displayed = displayedRowCount
        guard let source = dataSource, displayed > 0, rowHeight > 0 else { return }
        let first = max(0, Int(floor(dirtyRect.minY / rowHeight)))
        let last = min(displayed - 1, Int(ceil(dirtyRect.maxY / rowHeight)) - 1)
        guard first <= last else { return }

        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        var widest = widestRow
        for display in first...last {
            let index = dataRow(forDisplayRow: display)
            let rect = NSRect(x: 0, y: CGFloat(display) * rowHeight, width: bounds.width, height: rowHeight)
            widest = max(widest, drawRow(source.row(at: index), index: index, in: rect, context: context))
        }
        context.restoreGState()

        if widest > widestRow {
            widestRow = widest
            // Not from inside draw: resizing here would re-enter display.
            Task { @MainActor [weak self] in self?.updateFrameSize() }
        }
    }

    /// Draws one row and answers the width its content needs.
    private func drawRow(_ row: LineViewerRow, index: Int, in rect: NSRect, context: CGContext) -> CGFloat {
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
        drawGutter(row, in: rect)

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

        let length = (row.text as NSString).length
        let line = CTLineCreateWithAttributedString(attributedText(row, length: length))
        for run in row.runs {
            let range = Self.clip(run.range, to: length)
            guard range.length > 0 else { continue }
            let start = CTLineGetOffsetForStringIndex(line, range.location, nil)
            let end = CTLineGetOffsetForStringIndex(line, NSMaxRange(range), nil)
            if let role = run.highlight, let fill = color(for: role, rowTone: row.background) {
                fill.setFill()
                NSRect(x: textX + start, y: rect.minY, width: end - start, height: rect.height).fill()
            }
        }
        context.textPosition = CGPoint(x: textX, y: baseline)
        CTLineDraw(line, context)
        drawDecorations(row, line: line, length: length, textX: textX, baseline: baseline)
        return textX + CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)) + charWidth
    }

    private func drawGutter(_ row: LineViewerRow, in rect: NSRect) {
        guard gutterColumnCount > 0 else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: palette.secondaryTextColor]
        for column in 0..<gutterColumnCount {
            guard column < row.gutter.count, let value = row.gutter[column] else { continue }
            let text = NSAttributedString(string: value, attributes: attributes)
            let width = text.size().width
            let right = CGFloat(column + 1) * gutterColumnWidth - charWidth
            text.draw(at: NSPoint(x: right - width, y: rect.minY + Self.verticalPadding))
        }
        palette.dividerColor.setFill()
        NSRect(x: gutterWidth - 1, y: rect.minY, width: 1, height: rect.height).fill()
    }

    /// Core Text draws no underline or strikethrough, so those are drawn here.
    private func drawDecorations(_ row: LineViewerRow, line: CTLine, length: Int, textX: CGFloat, baseline: CGFloat) {
        for run in row.runs where run.fontStyle.contains(.underline) || run.fontStyle.contains(.strikethrough) {
            let range = Self.clip(run.range, to: length)
            guard range.length > 0 else { continue }
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

    private func attributedText(_ row: LineViewerRow, length: Int) -> NSAttributedString {
        let text = NSMutableAttributedString(string: row.text,
                                             attributes: [.font: font, .foregroundColor: palette.primaryTextColor])
        for run in row.runs {
            let range = Self.clip(run.range, to: length)
            guard range.length > 0 else { continue }
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

    /// A click at `point`: a gutter click, a fold toggle on a header, or a
    /// selection change, in that order.
    func handleClick(at point: NSPoint, modifiers: NSEvent.ModifierFlags) {
        isDragSelecting = false
        guard let display = displayRowIndex(at: point), let source = dataSource else { return }
        let row = dataRow(forDisplayRow: display)
        if gutterColumnCount > 0, point.x < gutterWidth {
            let column = min(gutterColumnCount - 1, Int(point.x / gutterColumnWidth))
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
        needsDisplay = true
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
        guard let source = dataSource, displayedRowCount > 0, rowHeight > 0 else { return "" }
        let visible = visibleRect
        let first = max(0, Int(floor(visible.minY / rowHeight)))
        let last = min(displayedRowCount - 1, Int(ceil(visible.maxY / rowHeight)) - 1)
        guard first <= last else { return "" }
        return (first...last).map { source.row(at: dataRow(forDisplayRow: $0)).text }.joined(separator: "\n")
    }
}

extension LineViewerView: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(copy(_:)) { return !selectedRows.isEmpty }
        return true
    }
}
