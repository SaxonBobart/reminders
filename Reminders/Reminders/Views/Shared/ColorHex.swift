import SwiftUI

extension Color {
    /// Creates a Color from a "#RRGGBB" hex string. Falls back to gray on parse failure.
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmed.count == 6,
              let value = UInt32(trimmed, radix: 16)
        else {
            self = .gray
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
