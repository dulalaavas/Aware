import SwiftUI
import UIKit

// MARK: - Palette (light/dark pairs)

private extension UIColor {
    convenience init(_ hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        }
    }
}

extension Color {
    static let appBackground = Color(uiColor: .dynamic(light: 0xF6F4EF, dark: 0x141613))
    static let appCard       = Color(uiColor: .dynamic(light: 0xFFFFFF, dark: 0x1F241F))
    static let appInk        = Color(uiColor: .dynamic(light: 0x23281F, dark: 0xE9ECE4))
    static let appMuted      = Color(uiColor: .dynamic(light: 0x646B5B, dark: 0x9FA796))
    static let appAccent     = Color(uiColor: .dynamic(light: 0x3A6351, dark: 0x8FC7A9))
    static let appAccentSoft = Color(uiColor: .dynamic(light: 0xE3EDE4, dark: 0x2A342C))
    static let appFlame      = Color(uiColor: .dynamic(light: 0xC96F43, dark: 0xE59A6F))
}

// MARK: - Card surface

struct CardStyle: ViewModifier {
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = 20) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Avatar

struct AvatarView: View {
    let profile: UserProfile
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data = profile.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.appAccentSoft
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("Profile photo")
    }

    private var initials: String {
        let parts = profile.name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }
}

// MARK: - Helpers

func formattedDuration(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    return String(format: "%d:%02d", total / 60, total % 60)
}
