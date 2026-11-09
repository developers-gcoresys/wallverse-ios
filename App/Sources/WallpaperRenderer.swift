import UIKit
import WallVerseCore

enum WallpaperRenderer {
    static let fullSize = CGSize(width: 1080, height: 2400)
    static let previewSize = CGSize(width: 270, height: 600)

    /// Renders a wallpaper at the requested size. The full export is 1080×2400,
    /// matching the Android renderer; the preview uses the same layout scaled down.
    static func image(for verse: WallpaperVerse, style: WallpaperStyle, size: CGSize, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let ratio = size.width / fullSize.width
            UIColor(hex: style.backgroundHex).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let textFont = serifFont(ofSize: 66 * ratio)
            let referenceFont = UIFont.systemFont(ofSize: 38 * ratio, weight: .medium)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.minimumLineHeight = 96 * ratio
            paragraph.maximumLineHeight = 96 * ratio

            let text = verse.text as NSString
            let maxWidth = 860 * ratio
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor(hex: style.foregroundHex),
                .paragraphStyle: paragraph
            ]
            let referenceAttributes: [NSAttributedString.Key: Any] = [
                .font: referenceFont,
                .foregroundColor: UIColor(hex: style.foregroundHex).withAlphaComponent(0.7),
                .paragraphStyle: paragraph
            ]

            let textRect = text.boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: textAttributes,
                context: nil
            )
            let referenceRect = ("— \(verse.reference)" as NSString).boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: referenceAttributes,
                context: nil
            )

            let gap = 60 * ratio
            let totalHeight = textRect.height + gap + referenceRect.height
            let originY = max(0, (size.height - totalHeight) / 2)
            let originX = (size.width - maxWidth) / 2

            text.draw(
                with: CGRect(x: originX, y: originY, width: maxWidth, height: textRect.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: textAttributes,
                context: nil
            )
            ("— \(verse.reference)" as NSString).draw(
                with: CGRect(x: originX, y: originY + textRect.height + gap, width: maxWidth, height: referenceRect.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: referenceAttributes,
                context: nil
            )
        }
    }

    static func preview(for verse: WallpaperVerse, style: WallpaperStyle) -> UIImage {
        image(for: verse, style: style, size: previewSize, scale: 2)
    }

    static func export(for verse: WallpaperVerse, style: WallpaperStyle) -> UIImage {
        image(for: verse, style: style, size: fullSize, scale: 1)
    }

    private static func serifFont(ofSize size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: .regular)
        guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

enum HexColor {
    static func uiColor(_ hex: String) -> UIColor {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        return UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        self.init(cgColor: HexColor.uiColor(hex).cgColor)
    }
}
