import Foundation

enum TypographicPatterns {
    // Hidden character display symbols
    static let pilcrow     = "\u{00B6}"   // ¶ — paragraph mark
    static let middleDot   = "\u{00B7}"   // · — visible space
    static let rightArrow  = "\u{2192}"   // → — tab
    static let softHyphen  = "\u{00AD}"   // ­ — soft hyphen (invisible)
    static let visibleHyphen = "\u{2010}" // ‐ — visible hyphen substitute

    // Typographic characters
    static let emDash      = "\u{2014}"   // —
    static let enDash      = "\u{2013}"   // –
    static let ellipsis    = "\u{2026}"   // …
    static let superTwo    = "\u{00B2}"   // ²
    static let superThree  = "\u{00B3}"   // ³

    // German quotes
    static let deOpenDouble  = "\u{201E}" // „
    static let deCloseDouble = "\u{201C}" // "
    static let deOpenSingle  = "\u{201A}" // ‚
    static let deCloseSingle = "\u{2018}" // '

    // English quotes
    static let enOpenDouble  = "\u{201C}" // "
    static let enCloseDouble = "\u{201D}" // "
    static let enOpenSingle  = "\u{2018}" // '
    static let enCloseSingle = "\u{2019}" // '
}
