import Foundation

extension String {
    /// Trim whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strip Discogs proprietary markup and return plain readable text.
    /// Handles: [a=Name], [l=Name], [r=Name], [a12345], [l12345], [r12345],
    /// [url=...]text[/url], [b]...[/b], [i]...[/i]
    var strippingDiscogsMarkup: String {
        var text = self

        // [a=Artist Name] / [l=Label Name] / [r=Release Name] → extract the name
        text = text.replacingOccurrences(
            of: #"\[[alr]=([^\]]+)\]"#,
            with: "$1",
            options: .regularExpression
        )

        // [a12345] / [l12345] / [r12345] (numeric ID only) → remove entirely
        text = text.replacingOccurrences(
            of: #"\[[alr]\d+\]"#,
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

        return text.trimmed
    }
}
