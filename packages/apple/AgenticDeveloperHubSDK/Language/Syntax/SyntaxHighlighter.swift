import Foundation
import JavaScriptCore
import os

import AgenticDeveloperHubSDKCore

public enum SyntaxHighlighterError: Error, Equatable {
    /// A bundle exception or rejected promise, with its message.
    case javaScript(String)
    /// A bundle promise still pending when the call that awaited it returned.
    case promiseDidNotSettle(String)
    /// The bundle's output is not the documented shape.
    case malformedOutput(String)
    /// A run colour other than uppercase `#RRGGBB` / `#RRGGBBAA`.
    case unexpectedColor(String)
}

/// Colours text with the bundled TextMate engine (`highlighter.js` over WASM
/// Oniguruma) in one JavaScriptCore context, created on the first call that
/// needs it.
///
/// Bundle promises are awaited by attaching `then` callbacks that resume a
/// checked continuation. JavaScriptCore drains microtasks when the outermost
/// API call returns and the bundle uses nothing but promises, so every promise
/// settles inside the call that awaits it; one still pending afterwards throws
/// rather than waits. No run loop is ever spun. WebAssembly is compiled
/// synchronously in the context for the same reason: an asynchronous compile
/// can finish on a deferred-work timer only a run loop fires.
public actor SyntaxHighlighter {

    /// Text over this many UTF-8 bytes is not highlighted.
    public static let maximumBytes = 1_000_000
    /// Text with a line over this many UTF-16 units is not highlighted.
    public static let maximumLineLength = 10_000

    private let script: String
    private let wasm: Data
    private let registry: GrammarRegistry
    private var context: JSContext?
    private var currentTheme: CodeTheme?
    private var knownScopes: Set<String> = []

    /// - Throws: the read error when `highlighter.js` or `onig.wasm` cannot be read.
    public init(resources: TextMateResources, registry: GrammarRegistry) throws {
        script = try String(contentsOf: resources.highlighterScript, encoding: .utf8)
        wasm = try Data(contentsOf: resources.onigWASM)
        self.registry = registry
    }

    /// One `StyledLine` per line of `text`, lines split on `\r\n`, `\r` and
    /// `\n` as the bundle splits them.
    ///
    /// nil when the text is over the limits or the scope has no grammar.
    public func highlight(_ text: String, scopeName: String, theme: CodeTheme) async throws -> [StyledLine]? {
        guard !Self.exceedsLimits(text), hasGrammar(scopeName) else { return nil }
        let lengths = Self.lineLengths(text)
        let context = try await readyContext()
        if theme != currentTheme {
            _ = try call(context, "setTheme", [theme.themeJSON])
            currentTheme = theme
        }
        let json = try await settle(try call(context, "highlight", [text, scopeName]), in: context, "highlight")
        return try Self.styledLines(json: json, lineLengths: lengths)
    }

    // MARK: - Limits and lines

    static func exceedsLimits(_ text: String) -> Bool {
        text.utf8.count > maximumBytes || lineLengths(text).contains { $0 > maximumLineLength }
    }

    /// Each line's length in UTF-16 units, split on `/\r\n|\r|\n/` exactly as
    /// the bundle splits: `"a\rb"` and `"a\r\nb"` are both `[1, 1]`.
    static func lineLengths(_ text: String) -> [Int] {
        var lengths: [Int] = []
        var current = 0
        var afterCR = false
        for unit in text.utf16 {
            switch unit {
            case 0x0D:
                lengths.append(current)
                current = 0
                afterCR = true
            case 0x0A:
                if !afterCR {
                    lengths.append(current)
                    current = 0
                }
                afterCR = false
            default:
                current += 1
                afterCR = false
            }
        }
        lengths.append(current)
        return lengths
    }

    private func hasGrammar(_ scopeName: String) -> Bool {
        if knownScopes.contains(scopeName) { return true }
        guard registry.grammarText(scopeName: scopeName) != nil else { return false }
        knownScopes.insert(scopeName)
        return true
    }

    // MARK: - Output

    /// The bundle's `{"lines": [[[start, length, color, fontStyle], ...], ...]}`
    /// as styled lines, checked against the Swift side's own line split.
    static func styledLines(json: String, lineLengths: [Int]) throws -> [StyledLine] {
        guard let root = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any],
              let lines = root["lines"] as? [[[Any]]] else {
            throw SyntaxHighlighterError.malformedOutput("not {\"lines\": [[run]]}")
        }
        guard lines.count == lineLengths.count else {
            throw SyntaxHighlighterError.malformedOutput("\(lines.count) lines, expected \(lineLengths.count)")
        }
        var colors: [String: RGBAColor] = [:]
        return try zip(lines, lineLengths).enumerated().map { index, pair in
            let (runs, length) = pair
            return StyledLine(runs: try runs.map { run in
                guard run.count == 4,
                      let start = run[0] as? Int, let count = run[1] as? Int,
                      let hex = run[2] as? String, let style = run[3] as? Int,
                      start >= 0, count > 0, start + count <= length else {
                    throw SyntaxHighlighterError.malformedOutput("line \(index + 1): bad run \(run)")
                }
                let color = try colors[hex] ?? SyntaxRun.color(highlighterHex: hex)
                colors[hex] = color
                return SyntaxRun(
                    range: NSRange(location: start, length: count),
                    foreground: color,
                    fontStyle: SyntaxFontStyle(rawValue: style)
                )
            })
        }
    }

    // MARK: - JavaScript

    private func readyContext() async throws -> JSContext {
        if let context { return context }
        guard let context = JSContext(virtualMachine: JSVirtualMachine()) else {
            throw SyntaxHighlighterError.javaScript("could not create a JavaScript context")
        }
        installHost(in: context)
        try evaluate(context, Self.synchronousWebAssembly)
        try evaluate(context, script)
        guard let buffer = arrayBuffer(wasm, in: context) else {
            throw SyntaxHighlighterError.javaScript("could not create the WASM ArrayBuffer")
        }
        _ = try await settle(try call(context, "create", [buffer]), in: context, "create")
        self.context = context
        return context
    }

    /// `WebAssembly.instantiate` as a synchronous compile and instantiation
    /// returning an already-resolved promise.
    private static let synchronousWebAssembly = """
        WebAssembly.instantiate = (bytes, imports) => {
          const module = new WebAssembly.Module(bytes);
          return Promise.resolve({ module, instance: new WebAssembly.Instance(module, imports) });
        };
        """

    private func installHost(in context: JSContext) {
        let registry = registry
        let grammarText: @convention(block) (String) -> Any = { scopeName in
            registry.grammarText(scopeName: scopeName) ?? NSNull()
        }
        let host = JSValue(newObjectIn: context)
        host?.setObject(grammarText, forKeyedSubscript: "grammarText" as NSString)
        context.setObject(host, forKeyedSubscript: "ADKHost" as NSString)

        let console = JSValue(newObjectIn: context)
        for (name, level) in [("log", OSLogType.info), ("info", .info), ("debug", .debug),
                              ("warn", .error), ("error", .error)] {
            let log: @convention(block) () -> Void = {
                let parts = (JSContext.currentArguments() as? [JSValue] ?? []).map { $0.toString() ?? "" }
                Self.logger.log(level: level, "console.\(name, privacy: .public): \(parts.joined(separator: " "))")
            }
            console?.setObject(log, forKeyedSubscript: name as NSString)
        }
        context.setObject(console, forKeyedSubscript: "console" as NSString)
    }

    private func evaluate(_ context: JSContext, _ source: String) throws {
        context.exception = nil
        context.evaluateScript(source)
        if let exception = context.exception {
            throw SyntaxHighlighterError.javaScript(exception.toString() ?? "exception")
        }
    }

    /// Calls `ADKHighlighter[name]` with `arguments`.
    private func call(_ context: JSContext, _ name: String, _ arguments: [Any]) throws -> JSValue {
        context.exception = nil
        let result = context.objectForKeyedSubscript("ADKHighlighter")?
            .objectForKeyedSubscript(name)?
            .call(withArguments: arguments)
        if let exception = context.exception {
            throw SyntaxHighlighterError.javaScript(exception.toString() ?? "exception")
        }
        guard let result else { throw SyntaxHighlighterError.javaScript("ADKHighlighter.\(name) is missing") }
        return result
    }

    /// Awaits `promise`, answering its value as a string (`""` when it is not one).
    private func settle(_ promise: JSValue, in context: JSContext, _ name: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let once = ResumeOnce(continuation)
            let fulfil: @convention(block) (JSValue) -> Void = { value in
                once.resume(.success(value.isString ? value.toString() ?? "" : ""))
            }
            let reject: @convention(block) (JSValue) -> Void = { error in
                once.resume(.failure(SyntaxHighlighterError.javaScript(error.toString() ?? "rejected")))
            }
            context.exception = nil
            promise.invokeMethod("then", withArguments: [
                JSValue(object: fulfil, in: context) as Any,
                JSValue(object: reject, in: context) as Any
            ])
            if let exception = context.exception {
                once.resume(.failure(SyntaxHighlighterError.javaScript(exception.toString() ?? "exception")))
            }
            once.resume(.failure(SyntaxHighlighterError.promiseDidNotSettle(name)))
        }
    }

    /// An `ArrayBuffer` over a copy of `data`, freed when the buffer is collected.
    private func arrayBuffer(_ data: Data, in context: JSContext) -> JSValue? {
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: max(data.count, 1), alignment: 16)
        data.copyBytes(to: bytes.assumingMemoryBound(to: UInt8.self), count: data.count)
        guard let buffer = JSObjectMakeArrayBufferWithBytesNoCopy(
            context.jsGlobalContextRef, bytes, data.count, { bytes, _ in bytes?.deallocate() }, nil, nil
        ) else {
            bytes.deallocate()
            return nil
        }
        return JSValue(jsValueRef: buffer, in: context)
    }
}

/// Resumes a continuation the first time only; later outcomes are dropped.
private final class ResumeOnce {
    private var continuation: CheckedContinuation<String, Error>?

    init(_ continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    func resume(_ result: Result<String, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

extension SyntaxHighlighter: Loggable {
    public static nonisolated let logger = makeLogger()
}
