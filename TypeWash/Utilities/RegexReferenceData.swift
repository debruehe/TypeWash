import Foundation

struct RegexPattern: Identifiable {
    let id = UUID()
    let pattern: String
    let name: String
    let description: String
    let example: String
}

struct RegexCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let patterns: [RegexPattern]
}

enum RegexReferenceData {

    static let categories: [RegexCategory] = [
        characterClasses,
        quantifiers,
        anchors,
        groupsAndReferences,
        lookaheadAndLookbehind,
        commonPatterns,
        unicodeProperties,
    ]

    // MARK: - 1. Character Classes

    private static let characterClasses = RegexCategory(
        name: "Character Classes",
        icon: "textformat.abc",
        patterns: [
            RegexPattern(
                pattern: ".",
                name: "Any Character",
                description: "Matches any single character except a newline. The most permissive single-character matcher.",
                example: "h.t matches \"hat\", \"hot\", \"h9t\""
            ),
            RegexPattern(
                pattern: "\\d",
                name: "Digit",
                description: "Matches any digit character (0-9). Equivalent to [0-9].",
                example: "\\d{3} matches \"123\" in \"abc123\""
            ),
            RegexPattern(
                pattern: "\\D",
                name: "Non-Digit",
                description: "Matches any character that is not a digit. Equivalent to [^0-9].",
                example: "\\D+ matches \"abc\" in \"abc123\""
            ),
            RegexPattern(
                pattern: "\\w",
                name: "Word Character",
                description: "Matches any word character: letters, digits, and underscore. Equivalent to [a-zA-Z0-9_].",
                example: "\\w+ matches \"hello_42\" in \"hello_42!\""
            ),
            RegexPattern(
                pattern: "\\W",
                name: "Non-Word Character",
                description: "Matches any character that is not a word character. Useful for finding punctuation and spaces.",
                example: "\\W matches the space in \"hello world\""
            ),
            RegexPattern(
                pattern: "\\s",
                name: "Whitespace",
                description: "Matches any whitespace character: spaces, tabs, newlines, and other Unicode whitespace.",
                example: "\\s+ matches runs of spaces and tabs"
            ),
            RegexPattern(
                pattern: "\\S",
                name: "Non-Whitespace",
                description: "Matches any character that is not whitespace. Useful for finding visible content.",
                example: "\\S+ matches each word in a sentence"
            ),
            RegexPattern(
                pattern: "[abc]",
                name: "Character Set",
                description: "Matches any one of the characters listed inside the brackets. Order does not matter.",
                example: "[aeiou] matches any vowel"
            ),
            RegexPattern(
                pattern: "[^abc]",
                name: "Negated Set",
                description: "Matches any character NOT listed inside the brackets. The caret negates the set.",
                example: "[^0-9] matches any non-digit character"
            ),
            RegexPattern(
                pattern: "[a-z]",
                name: "Character Range",
                description: "Matches any character in the specified range. Commonly used for letters or digit subsets.",
                example: "[A-Za-z] matches any ASCII letter"
            ),
        ]
    )

    // MARK: - 2. Quantifiers

    private static let quantifiers = RegexCategory(
        name: "Quantifiers",
        icon: "number",
        patterns: [
            RegexPattern(
                pattern: "*",
                name: "Zero or More",
                description: "Matches the preceding element zero or more times. Greedy by default (matches as much as possible).",
                example: "ab*c matches \"ac\", \"abc\", \"abbc\""
            ),
            RegexPattern(
                pattern: "+",
                name: "One or More",
                description: "Matches the preceding element one or more times. Requires at least one occurrence.",
                example: "\\d+ matches one or more digits"
            ),
            RegexPattern(
                pattern: "?",
                name: "Zero or One",
                description: "Makes the preceding element optional. Matches zero or exactly one occurrence.",
                example: "colou?r matches \"color\" and \"colour\""
            ),
            RegexPattern(
                pattern: "{n}",
                name: "Exactly N",
                description: "Matches the preceding element exactly n times. Replace n with a number.",
                example: "\\d{4} matches a 4-digit year like \"2024\""
            ),
            RegexPattern(
                pattern: "{n,}",
                name: "N or More",
                description: "Matches the preceding element at least n times with no upper limit.",
                example: "\\w{3,} matches words with 3+ characters"
            ),
            RegexPattern(
                pattern: "{n,m}",
                name: "Between N and M",
                description: "Matches the preceding element between n and m times (inclusive). Both bounds are required.",
                example: "\\d{2,4} matches 2 to 4 digits"
            ),
            RegexPattern(
                pattern: "*?",
                name: "Lazy Zero or More",
                description: "Non-greedy version of *. Matches as few characters as possible instead of as many.",
                example: "<.*?> matches individual HTML tags, not the whole string"
            ),
            RegexPattern(
                pattern: "+?",
                name: "Lazy One or More",
                description: "Non-greedy version of +. Matches the minimum number of characters needed.",
                example: "\\w+? matches a single word character at a time"
            ),
            RegexPattern(
                pattern: "??",
                name: "Lazy Zero or One",
                description: "Non-greedy version of ?. Prefers matching zero occurrences over one.",
                example: "colou??r prefers \"color\" over \"colour\""
            ),
        ]
    )

    // MARK: - 3. Anchors

    private static let anchors = RegexCategory(
        name: "Anchors",
        icon: "arrow.left.and.right",
        patterns: [
            RegexPattern(
                pattern: "^",
                name: "Start of Line",
                description: "Matches the position at the start of a line. In multiline mode, matches after each newline.",
                example: "^Hello matches lines starting with \"Hello\""
            ),
            RegexPattern(
                pattern: "$",
                name: "End of Line",
                description: "Matches the position at the end of a line. In multiline mode, matches before each newline.",
                example: "\\.$  matches a period at the end of a line"
            ),
            RegexPattern(
                pattern: "\\b",
                name: "Word Boundary",
                description: "Matches the position between a word character and a non-word character. Does not consume characters.",
                example: "\\bcat\\b matches \"cat\" but not \"concatenate\""
            ),
            RegexPattern(
                pattern: "\\B",
                name: "Non-Word Boundary",
                description: "Matches any position that is not a word boundary. Useful for matching inside words.",
                example: "\\Bcat\\B matches \"cat\" in \"concatenate\""
            ),
        ]
    )

    // MARK: - 4. Groups & References

    private static let groupsAndReferences = RegexCategory(
        name: "Groups & References",
        icon: "rectangle.on.rectangle",
        patterns: [
            RegexPattern(
                pattern: "(...)",
                name: "Capturing Group",
                description: "Groups multiple tokens together and captures the matched text. Captured text can be referenced with $1, $2, etc.",
                example: "(\\d{4})-(\\d{2}) captures year and month separately"
            ),
            RegexPattern(
                pattern: "(?:...)",
                name: "Non-Capturing Group",
                description: "Groups tokens without capturing. Useful for applying quantifiers to a group without creating a back-reference.",
                example: "(?:https?://) groups the protocol without capturing it"
            ),
            RegexPattern(
                pattern: "(?<name>...)",
                name: "Named Group",
                description: "A capturing group with a name. Makes complex patterns more readable and references clearer.",
                example: "(?<year>\\d{4})-(?<month>\\d{2}) for named date parts"
            ),
            RegexPattern(
                pattern: "$1",
                name: "Back-Reference (1st)",
                description: "In the replacement string, inserts the text matched by the first capturing group.",
                example: "Find: (\\w+) (\\w+)  Replace: $2 $1 swaps two words"
            ),
            RegexPattern(
                pattern: "$2",
                name: "Back-Reference (2nd)",
                description: "In the replacement string, inserts the text matched by the second capturing group.",
                example: "Find: (\\d+)/(\\d+)  Replace: $2-$1 reformats a date"
            ),
            RegexPattern(
                pattern: "|",
                name: "Alternation (OR)",
                description: "Matches the expression before or after the pipe. Acts like a boolean OR for patterns.",
                example: "cat|dog matches either \"cat\" or \"dog\""
            ),
        ]
    )

    // MARK: - 5. Lookahead & Lookbehind

    private static let lookaheadAndLookbehind = RegexCategory(
        name: "Lookahead & Lookbehind",
        icon: "eye",
        patterns: [
            RegexPattern(
                pattern: "(?=...)",
                name: "Positive Lookahead",
                description: "Asserts that what follows the current position matches the pattern, without consuming characters.",
                example: "\\d+(?= USD) matches digits followed by \" USD\""
            ),
            RegexPattern(
                pattern: "(?!...)",
                name: "Negative Lookahead",
                description: "Asserts that what follows the current position does NOT match the pattern.",
                example: "\\d+(?!\\d) matches the last digit in a sequence"
            ),
            RegexPattern(
                pattern: "(?<=...)",
                name: "Positive Lookbehind",
                description: "Asserts that what precedes the current position matches the pattern, without consuming characters.",
                example: "(?<=\\$)\\d+ matches digits preceded by a dollar sign"
            ),
            RegexPattern(
                pattern: "(?<!...)",
                name: "Negative Lookbehind",
                description: "Asserts that what precedes the current position does NOT match the pattern.",
                example: "(?<!\\d)\\d{3}(?!\\d) matches exactly 3-digit numbers"
            ),
        ]
    )

    // MARK: - 6. Common Patterns

    private static let commonPatterns = RegexCategory(
        name: "Common Patterns",
        icon: "star",
        patterns: [
            RegexPattern(
                pattern: "\\n",
                name: "Newline",
                description: "Matches a line feed character (LF). The standard line break on Unix and macOS systems.",
                example: "\\n\\n matches double line breaks (empty lines)"
            ),
            RegexPattern(
                pattern: "\\t",
                name: "Tab",
                description: "Matches a horizontal tab character. Commonly found in TSV files and indented text.",
                example: "Replace \\t with spaces to convert indentation"
            ),
            RegexPattern(
                pattern: "\\r\\n",
                name: "Windows Line Break",
                description: "Matches a carriage return + line feed pair (CRLF). The standard line ending on Windows systems.",
                example: "Replace \\r\\n with \\n to normalize line endings"
            ),
            RegexPattern(
                pattern: "\\u00AD",
                name: "Soft Hyphen",
                description: "Matches a soft hyphen (invisible hyphenation hint). Often found in text copied from web pages or PDFs.",
                example: "Replace \\u00AD with empty string to remove soft hyphens"
            ),
            RegexPattern(
                pattern: "\\u2014",
                name: "Em Dash",
                description: "Matches an em dash character. Common in typeset text as a long dash for parenthetical statements.",
                example: "Replace \\u2014 with -- for plain-text formatting"
            ),
            RegexPattern(
                pattern: "\\u2013",
                name: "En Dash",
                description: "Matches an en dash character. Typically used for ranges (e.g., pages 10-20) in typeset text.",
                example: "Replace \\u2013 with - for plain-text ranges"
            ),
            RegexPattern(
                pattern: "[\\u201C\\u201D]",
                name: "Smart Double Quotes",
                description: "Matches left and right typographic (curly) double quotation marks.",
                example: "Replace with straight quotes \" for code or plain text"
            ),
            RegexPattern(
                pattern: "[\\u2018\\u2019]",
                name: "Smart Single Quotes",
                description: "Matches left and right typographic (curly) single quotation marks and apostrophes.",
                example: "Replace with straight apostrophe ' for code contexts"
            ),
            RegexPattern(
                pattern: "\\u00A0",
                name: "Non-Breaking Space",
                description: "Matches a non-breaking space. Looks identical to a regular space but prevents line wrapping.",
                example: "Replace \\u00A0 with a regular space to normalize spacing"
            ),
            RegexPattern(
                pattern: " {2,}",
                name: "Multiple Spaces",
                description: "Matches two or more consecutive space characters. Useful for collapsing extra whitespace.",
                example: "Replace with a single space to normalize spacing"
            ),
        ]
    )

    // MARK: - 7. Unicode Properties

    private static let unicodeProperties = RegexCategory(
        name: "Unicode Properties",
        icon: "globe",
        patterns: [
            RegexPattern(
                pattern: "\\p{L}",
                name: "Any Letter",
                description: "Matches any Unicode letter from any script (Latin, Cyrillic, CJK, Arabic, etc.).",
                example: "\\p{L}+ matches words in any language"
            ),
            RegexPattern(
                pattern: "\\p{Lu}",
                name: "Uppercase Letter",
                description: "Matches any Unicode uppercase letter. More comprehensive than [A-Z] as it includes accented characters.",
                example: "\\p{Lu} matches uppercase letters"
            ),
            RegexPattern(
                pattern: "\\p{Ll}",
                name: "Lowercase Letter",
                description: "Matches any Unicode lowercase letter. Covers all scripts that have case distinctions.",
                example: "\\p{Ll}+ matches lowercase words in any language"
            ),
            RegexPattern(
                pattern: "\\p{N}",
                name: "Any Number",
                description: "Matches any Unicode numeric character, including digits from non-Latin scripts.",
                example: "\\p{N}+ matches numbers in any numeral system"
            ),
            RegexPattern(
                pattern: "\\p{P}",
                name: "Punctuation",
                description: "Matches any Unicode punctuation character, covering all scripts and typographic styles.",
                example: "\\p{P} matches periods, commas, dashes, brackets, etc."
            ),
            RegexPattern(
                pattern: "\\p{S}",
                name: "Symbol",
                description: "Matches any Unicode symbol: math operators, currency signs, box-drawing, emoji modifiers, and more.",
                example: "\\p{S} matches $, +, =, ^, and similar symbols"
            ),
            RegexPattern(
                pattern: "\\p{Z}",
                name: "Separator",
                description: "Matches any Unicode separator, including spaces, line separators, and paragraph separators.",
                example: "\\p{Z}+ matches all types of whitespace and separators"
            ),
        ]
    )
}
