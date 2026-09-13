import SwiftUI

/// 主题与通用样式（暗黑 + 科技 + 全息）
enum Theme {
    static let bgTop = Color(hex: "#0A0612")
    static let bgBottom = Color(hex: "#0E1430")
    static let accent = Color(hex: "#8A5CFF")
    static let accentCyan = Color(hex: "#3FA7FF")
    static let textPrimary = Color(hex: "#F2F0FF")
    static let textSecondary = Color(hex: "#9A93C4")

    static func rarityColor(_ rarity: Rarity) -> Color {
        Color(hex: rarity.accentHex)
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

extension View {
    /// 全息边框卡牌背景
    func holographicBackground() -> some View {
        LinearGradient(
            colors: [Color(hex: "#1A1140"), Color(hex: "#0E1430")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    func backgroundGradient() -> some View {
        LinearGradient(
            colors: [Theme.bgTop, Theme.bgBottom],
            startPoint: .top, endPoint: .bottom
        )
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
