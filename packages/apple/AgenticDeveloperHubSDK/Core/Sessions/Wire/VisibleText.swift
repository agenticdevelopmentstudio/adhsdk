import Foundation

extension Sessions {

    /// Which characters may reach a terminal, a log line or a stored label as-is.
    /// The router's scrubber deletes everything else. (Template names use the
    /// looser `ModelRouterTemplateValidation.isRefusedInName`.)
    public enum VisibleText {
        /// An allowlist, so a code point nobody thought of is refused by default:
        /// a scalar is visible only if its general category is a letter, number,
        /// punctuation, symbol or space separator, and Unicode does not list it as
        /// default-ignorable (rendered as nothing). Controls, format characters,
        /// marks of every kind, line and paragraph separators, unassigned and
        /// private-use code points are not.
        public static func isVisible(_ scalar: Unicode.Scalar) -> Bool {
            let properties = scalar.properties
            guard !properties.isDefaultIgnorableCodePoint else { return false }
            switch properties.generalCategory {
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
                 .decimalNumber, .letterNumber, .otherNumber,
                 .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation,
                 .initialPunctuation, .finalPunctuation, .otherPunctuation,
                 .mathSymbol, .currencySymbol, .modifierSymbol, .otherSymbol,
                 .spaceSeparator:
                return true
            default:
                return false
            }
        }

        /// `text` with every scalar that is not visible deleted.
        public static func visible(_ text: String) -> String {
            var out = String.UnicodeScalarView()
            out.append(contentsOf: text.unicodeScalars.filter(isVisible))
            return String(out)
        }
    }
}
