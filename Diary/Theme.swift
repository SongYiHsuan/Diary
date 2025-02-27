import SwiftUI

struct Theme {
    // **主題顏色**
    static let primaryColor = Color(hex: "#F48FB1") // 主色（柔和粉色）
    static let secondaryColor = Color(hex: "#FFF3E0") // 副色（柔和暖橘）
    static let accentColor = Color(hex: "#FFD54F") // 點綴色（暖黃色）
    
    //  **背景與標題顏色**
    static let backgroundColor = Color(hex: "#FFFFFF") // 背景色
    static let cardBackground = Color(hex: "#FCFAF2") // 卡片背景
    static let textColor = Color(hex: "#333333") // 主要文字顏色
    static let secondaryTextColor = Color(hex: "#777777") // 次要文字顏色
    
    //  **按鈕與錯誤提示**
    static let buttonColor = Color(hex: "#FFAB91") // 按鈕顏色
    static let deleteColor = Color(hex: "#E57373") // 刪除按鈕（紅色）
    static let successColor = Color(hex: "#81C784") // 成功狀態（綠色）

    //  **自定義 hex 轉換**
    static func color(from hex: String) -> Color {
        return Color(hex: hex)
    }
}

//  **擴展 Color 來支援 hex 值**
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // 不含透明度 (RGB)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // 含透明度 (ARGB)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255) // 預設為白色
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
