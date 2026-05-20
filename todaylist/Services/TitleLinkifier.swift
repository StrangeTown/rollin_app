import Foundation
import SwiftUI

enum TitleLinkifier {
    private static let detector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    static func attributedTitle(
        _ title: String,
        isCompleted: Bool,
        baseColor: Color
    ) -> AttributedString {
        var attributed = AttributedString(title)
        attributed.foregroundColor = baseColor
        if isCompleted {
            attributed.strikethroughStyle = .single
        }

        guard let detector, !title.isEmpty else {
            return attributed
        }

        let nsRange = NSRange(title.startIndex..<title.endIndex, in: title)
        let matches = detector.matches(in: title, options: [], range: nsRange)
        let characters = attributed.characters

        for match in matches {
            guard let url = match.url,
                  let swiftRange = Range(match.range, in: title) else {
                continue
            }
            let lowerOffset = title.distance(from: title.startIndex, to: swiftRange.lowerBound)
            let upperOffset = title.distance(from: title.startIndex, to: swiftRange.upperBound)
            let attrLower = characters.index(characters.startIndex, offsetBy: lowerOffset)
            let attrUpper = characters.index(characters.startIndex, offsetBy: upperOffset)
            attributed[attrLower..<attrUpper].link = url
        }

        return attributed
    }
}
