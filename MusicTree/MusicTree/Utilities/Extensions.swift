import Foundation

extension String {
    /// Trim whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strip Discogs proprietary markup and return plain readable text.
    /// Handles: [a=Name], [l=Name], [r=Name], [m=Name], [a12345], [l12345], etc.,
    /// [url=...]text[/url], [b]...[/b], [i]...[/i]
    var strippingDiscogsMarkup: String {
        var text = self

        // [a=Artist Name] / [l=Label Name] / [r=Release Name] / [m=Master] → extract the name
        text = text.replacingOccurrences(
            of: #"\[[alrmg]=([^\]]+)\]"#,
            with: "$1",
            options: .regularExpression
        )

        // [a12345] / [l12345] / [r12345] / [m12345] (numeric ID only, unresolved) → remove
        text = text.replacingOccurrences(
            of: #"\[[alrmg]\d+\]"#,
            with: "",
            options: .regularExpression
        )

        // [url=http://...]visible text[/url] → keep visible text
        text = text.replacingOccurrences(
            of: #"\[url=[^\]]*\]([^\[]*)\[/url\]"#,
            with: "$1",
            options: .regularExpression
        )

        // [b]...[/b], [i]...[/i] → keep inner text
        text = text.replacingOccurrences(
            of: #"\[/?[bi]\]"#,
            with: "",
            options: .regularExpression
        )

        // Clean up leftover punctuation artifacts from removed references
        text = text.replacingOccurrences(
            of: #"(,\s*){2,}"#,
            with: ", ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"\bof\s*,\s*"#,
            with: "of ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #",\s*(and|&)\s*\."#,
            with: ".",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #",\s*\."#,
            with: ".",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"\s{2,}"#,
            with: " ",
            options: .regularExpression
        )

        return text.trimmed
    }
}
