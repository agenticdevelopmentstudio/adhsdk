import AppKit
import CoreText
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage

/// The `LineViewerViewController`'s document view: flipped, exactly
/// `displayedRowCount × rowHeight` tall, drawing only the rows that intersect
/// the dirty rect with Core Text, and of a long line only the glyphs under the
/// dirty rect, from a layout cached per row. The gutter is a subview (`gutterView`) pinned to the visible
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
    /// Glyphs of long rows drawn by the last `draw(_:)`; the seam that shows a
    /// long row draws only what the dirty rect crosses.
    private(set) var drawnGlyphCount = 0

    /// A long row's layout, built once and drawn a glyph range at a time.
    private struct CachedLine {
        /// Held so the runs' storage outlives them.
        let line: CTLine
        let runs: [CTRun]
        /// Each run's left edge (runs are in visual order).
        let runMinX: [CGFloat]
        /// The furthest right edge of each run and every run before it, so it
        /// never decreases.
        let runMaxX: [CGFloat]
        let width: CGFloat
        let length: Int
    }

    /// Long rows' layouts by data row; `lineCacheOrder` lists them least
    /// recently drawn first.
    private var lineCache: [Int: CachedLine] = [:]
    private var lineCacheOrder: [Int] = []
    /// How many long rows' layouts are cached.
    var cachedLineCount: Int { lineCache.count }

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
    /// Rows longer than this (UTF-16 units) are laid out once into the cache
    /// and drawn only where the dirty rect crosses them.
    private static let longRowThreshold = 1024
    /// The cache holds at most this many rows, and at most
    /// `lineCacheUnitBudget` UTF-16 units across them (a CTLine costs about
    /// 40 bytes a glyph), always keeping the row just drawn.
    private static let lineCacheCapacity = 8
    private static let lineCacheUnitBudget = 4_000_000
    /// Columns beyond each side of the dirty rect whose glyphs are drawn too,
    /// so glyphs that overhang their advance into the rect still draw.
    private static let overhangColumns: CGFloat = 4

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
        clearLineCache()
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
        clearLineCache()
        updateFrameSize()
        invalidate()
    }

    private func clearLineCache() {
        lineCache = [:]
        lineCacheOrder = []
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
        drawnGlyphCount = 0
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

    /// Draws one row's text and answers the width the row needs. A short row
    /// is laid out whole; a long one comes from the cache, drawing only the
    /// glyphs the horizontal extent of `span` crosses.
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

        let length = (row.text as NSString).length
        let origin = CGPoint(x: textX, y: baseline)
        if length > Self.longRowThreshold {
            return drawLongText(row, index: index, length: length, origin: origin, rect: rect, span: span,
                                context: context)
        }
        let styled = clippedRuns(of: row, length: length)
        let line = CTLineCreateWithAttributedString(attributedText(row.text, runs: styled))
        var extents: [RunExtent] = []
        for (range, run) in styled {
            let start = CTLineGetOffsetForStringIndex(line, range.location, nil)
            let end = CTLineGetOffsetForStringIndex(line, NSMaxRange(range), nil)
            extents.append(RunExtent(run: run, minX: textX + start, maxX: textX + end))
        }
        drawHighlights(extents, rowTone: row.background, rect: rect)
        context.textPosition = origin
        CTLineDraw(line, context)
        drawDecorations(extents, baseline: baseline)
        return textX + CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)) + charWidth
    }

    /// A run and the horizontal extent of its glyphs, in document coordinates.
    private struct RunExtent {
        let run: LineViewerRun
        let minX: CGFloat
        let maxX: CGFloat
    }

    /// `row`'s runs clipped to its text, empty ones dropped.
    private func clippedRuns(of row: LineViewerRow, length: Int) -> [(range: NSRange, run: LineViewerRun)] {
        row.runs.compactMap { run in
            let range = Self.clip(run.range, to: length)
            return range.length > 0 ? (range, run) : nil
        }
    }

    /// A long row: its cached layout, drawn run by run with `CTRunDraw` over
    /// only the glyphs between the edges of `span` (plus a few columns of
    /// overhang), so every glyph sits where the whole line puts it whichever
    /// dirty rects the row is drawn in. Highlights and decorations are
    /// measured from the drawn glyphs.
    private func drawLongText(_ row: LineViewerRow, index: Int, length: Int, origin: CGPoint, rect: NSRect,
                              span: NSRect, context: CGContext) -> CGFloat {
        let cached = cachedLine(for: row, index: index, length: length)
        let margin = Self.overhangColumns * charWidth
        let minX = span.minX - origin.x - margin
        let maxX = span.maxX - origin.x + margin
        var pieces: [(run: CTRun, range: CFRange)] = []
        var glyphs: [(index: Int, minX: CGFloat, maxX: CGFloat)] = []
        // From the first run that reaches minX, while runs start before maxX.
        var runIndex = Self.partition(cached.runs.count) { cached.runMaxX[$0] >= minX }
        while runIndex < cached.runs.count, cached.runMinX[runIndex] <= maxX {
            let run = cached.runs[runIndex]
            runIndex += 1
            let range = Self.glyphRange(of: run, from: minX, to: maxX)
            guard range.length > 0 else { continue }
            pieces.append((run, range))
            var positions = [CGPoint](repeating: .zero, count: range.length)
            var advances = [CGSize](repeating: .zero, count: range.length)
            var indices = [CFIndex](repeating: 0, count: range.length)
            CTRunGetPositions(run, range, &positions)
            CTRunGetAdvances(run, range, &advances)
            CTRunGetStringIndices(run, range, &indices)
            for glyph in 0..<range.length {
                let left = origin.x + positions[glyph].x
                glyphs.append((indices[glyph], left, left + advances[glyph].width))
            }
        }
        drawnGlyphCount += glyphs.count

        var extents: [RunExtent] = []
        if let lowest = glyphs.map(\.index).min(), let highest = glyphs.map(\.index).max() {
            for (range, run) in clippedRuns(of: row, length: length)
            where range.location <= highest && NSMaxRange(range) > lowest {
                let inside = glyphs.filter { NSLocationInRange($0.index, range) }
                guard let left = inside.map(\.minX).min(), let right = inside.map(\.maxX).max() else { continue }
                extents.append(RunExtent(run: run, minX: left, maxX: right))
            }
        }
        drawHighlights(extents, rowTone: row.background, rect: rect)
        for piece in pieces {
            context.textPosition = origin
            CTRunDraw(piece.run, context, piece.range)
        }
        drawDecorations(extents, baseline: origin.y)
        return origin.x + cached.width + charWidth
    }

    /// Data row `index`'s cached layout, building it (and evicting the least
    /// recently drawn rows past the cache's limits) when it is missing or stale.
    private func cachedLine(for row: LineViewerRow, index: Int, length: Int) -> CachedLine {
        lineCacheOrder.removeAll { $0 == index }
        lineCacheOrder.append(index)
        if let cached = lineCache[index], cached.length == length { return cached }

        let styled = clippedRuns(of: row, length: length)
        let line = CTLineCreateWithAttributedString(attributedText(row.text, runs: styled))
        let runs = (CTLineGetGlyphRuns(line) as? [CTRun]) ?? []
        var runMinX: [CGFloat] = []
        var runMaxX: [CGFloat] = []
        var reach = -CGFloat.greatestFiniteMagnitude
        for run in runs {
            let last = max(0, CTRunGetGlyphCount(run) - 1)
            var firstPoint = CGPoint.zero
            var lastPoint = CGPoint.zero
            CTRunGetPositions(run, CFRange(location: 0, length: 1), &firstPoint)
            CTRunGetPositions(run, CFRange(location: last, length: 1), &lastPoint)
            let left = min(firstPoint.x, lastPoint.x)
            reach = max(reach, left + CGFloat(CTRunGetTypographicBounds(run, CFRange(), nil, nil, nil)))
            runMinX.append(left)
            runMaxX.append(reach)
        }
        let cached = CachedLine(line: line, runs: runs, runMinX: runMinX, runMaxX: runMaxX,
                                width: CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)), length: length)
        lineCache[index] = cached
        var units = lineCache.values.reduce(0) { $0 + $1.length }
        while lineCacheOrder.count > 1,
              lineCacheOrder.count > Self.lineCacheCapacity || units > Self.lineCacheUnitBudget {
            units -= lineCache.removeValue(forKey: lineCacheOrder.removeFirst())?.length ?? 0
        }
        return cached
    }

    /// The glyphs of `run` whose origins lie between `minX` and `maxX` (line
    /// coordinates), plus the one before `minX`, whose advance may cross it.
    /// Glyph origins run one way through a run, either way round.
    private static func glyphRange(of run: CTRun, from minX: CGFloat, to maxX: CGFloat) -> CFRange {
        let count = CTRunGetGlyphCount(run)
        guard count > 0 else { return CFRange() }
        func originX(_ glyph: Int) -> CGFloat {
            var point = CGPoint.zero
            CTRunGetPositions(run, CFRange(location: glyph, length: 1), &point)
            return point.x
        }
        let reversed = originX(0) > originX(count - 1)
        // `visual` counts glyphs left to right.
        func visualX(_ visual: Int) -> CGFloat { originX(reversed ? count - 1 - visual : visual) }
        let start = max(0, partition(count) { visualX($0) > minX } - 1)
        let end = partition(count) { visualX($0) > maxX }
        guard end > start else { return CFRange() }
        return CFRange(location: reversed ? count - end : start, length: end - start)
    }

    /// The first index in `0..<count` for which `isAfter` holds, given that it
    /// holds for every index after one where it does; `count` when none.
    private static func partition(_ count: Int, _ isAfter: (Int) -> Bool) -> Int {
        var low = 0
        var high = count
        while low < high {
            let mid = (low + high) / 2
            if isAfter(mid) { high = mid } else { low = mid + 1 }
        }
        return low
    }

    /// Paints each run's highlight role behind its extent, across `rect`'s height.
    private func drawHighlights(_ extents: [RunExtent], rowTone: LineViewerBackground, rect: NSRect) {
        for extent in extents {
            guard let role = extent.run.highlight, let fill = color(for: role, rowTone: rowTone) else { continue }
            fill.setFill()
            NSRect(x: extent.minX, y: rect.minY, width: extent.maxX - extent.minX, height: rect.height).fill()
        }
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

    /// Core Text draws no underline or strikethrough, so those are drawn here,
    /// across each run's extent.
    private func drawDecorations(_ extents: [RunExtent], baseline: CGFloat) {
        for extent in extents {
            let style = extent.run.fontStyle
            guard style.contains(.underline) || style.contains(.strikethrough) else { continue }
            (extent.run.foreground.map { NSColor($0) } ?? palette.primaryTextColor).setFill()
            let width = extent.maxX - extent.minX
            if style.contains(.underline) {
                NSRect(x: extent.minX, y: baseline + 1, width: width, height: 1).fill()
            }
            if style.contains(.strikethrough) {
                NSRect(x: extent.minX, y: baseline - xHeight / 2, width: width, height: 1).fill()
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
