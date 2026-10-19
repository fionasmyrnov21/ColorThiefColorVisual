import SwiftUI

enum Palette {
    static let paper = Color(hex: 0xF5F3ED)
    static let ink = Color(hex: 0x242720)
    static let muted = Color(hex: 0x797C72)
    static let line = Color(hex: 0xDCDDD4)
    static let lime = Color(hex: 0xD6F069)
    static let soft = Color(hex: 0xEAEAE2)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

extension Pigment {
    var color: Color {
        switch self {
        case .red: return Color(hex: 0xF2715E)
        case .blue: return Color(hex: 0x6F9ED5)
        case .yellow: return Color(hex: 0xEFCB54)
        case .green: return Color(hex: 0x8AAE76)
        }
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(Palette.muted)
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol = "arrow.up.right"
    var color = Palette.ink
    var foreground = Palette.paper
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(title).font(.system(.body, design: .rounded, weight: .semibold))
                Spacer(minLength: 8)
                Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(foreground).padding(.horizontal, 22).padding(.vertical, 19)
            .background(color, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
    }
}

struct Surface<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.line, lineWidth: 1))
    }
}

struct StarsView: View {
    let count: Int
    var size: CGFloat = 12
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .foregroundStyle(index < count ? Palette.ink : Palette.line).font(.system(size: size))
            }
        }.accessibilityLabel("\(count) of 3 stars")
    }
}

struct SectionHeading: View {
    let title: String
    let trailing: String
    var body: some View {
        HStack {
            Text(title).font(.system(.title3, design: .rounded, weight: .semibold))
            Spacer()
            Eyebrow(text: trailing)
        }
    }
}

extension View {
    func pageStyle() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.paper).foregroundStyle(Palette.ink)
    }
}

func clockText(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
