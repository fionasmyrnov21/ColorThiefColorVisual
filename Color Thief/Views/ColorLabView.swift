import SwiftUI

struct ColorLabView: View {
    @State private var selected = Pigment.red
    @State private var sourceHasColor = true
    @State private var destinationHasColor = false
    @State private var holding = false
    private var demoMessage: String {
        if destinationHasColor { return "A new possibility. The color moved; it was never duplicated." }
        if holding { return "Now tap the object on the right to give it your color." }
        return "Tap the source on the left to collect its color."
    }
    var body: some View {
        FoldablePage {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "A field guide to possibility")
                    Text("The color lab").font(.system(.largeTitle, design: .serif))
                    Text("Four colors. Four ways to change everything.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(Pigment.allCases) { pigment in
                        Button {
                            selected = pigment
                            resetDemo()
                        } label: {
                            VStack(spacing: 11) {
                                Image(systemName: pigment.symbol).font(.system(size: 21)).frame(height: 30)
                                Text(pigment.title).font(.system(size: 11, weight: .semibold, design: .rounded))
                            }.foregroundStyle(Palette.ink).frame(maxWidth: .infinity).padding(.vertical, 19)
                                .background(selected == pigment ? pigment.color : pigment.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected == pigment ? Palette.ink.opacity(0.3) : .clear, lineWidth: 1))
                        }.buttonStyle(.plain).accessibilityAddTraits(selected == pigment ? .isSelected : [])
                    }
                }
                Surface {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(selected.property + ".").font(.system(size: 38, design: .serif))
                            Spacer()
                            Text("0\((Pigment.allCases.firstIndex(of: selected) ?? 0) + 1)").font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
                        }
                        Text(selected.explanation).font(.system(.body, design: .rounded)).foregroundStyle(Palette.muted).lineSpacing(5)
                        Divider()
                        Eyebrow(text: "Try a little change")
                        HStack(spacing: 12) {
                            demoObject(isSource: true)
                            VStack(spacing: 8) {
                                Image(systemName: holding ? selected.symbol : "arrow.right").font(.system(size: 20)).foregroundStyle(holding ? selected.color : Palette.muted)
                                Text(holding ? "HELD" : "TRANSFER").font(.system(size: 8, weight: .bold, design: .monospaced))
                            }
                            demoObject(isSource: false)
                        }.frame(maxWidth: .infinity).padding(.vertical, 10)
                        Text(demoMessage).font(.subheadline).foregroundStyle(Palette.muted).frame(minHeight: 44, alignment: .top)
                        Button { resetDemo() } label: { Label("Try again", systemImage: "arrow.counterclockwise").font(.subheadline).frame(minHeight: 44) }.tint(Palette.ink)
                    }
                }
            }
        } secondary: {
            VStack(alignment: .leading, spacing: 26) {
                SectionHeading(title: "The art of letting go", trailing: "HOW TO PLAY")
                VStack(spacing: 0) {
                    rule("01", "Take", "Tap a colored object. Its color moves into your hand, and its property disappears.")
                    rule("02", "Give", "Tap a colorless object. It gains the color and its special property.")
                    rule("03", "Rethink", "Carry one color at a time. To open one path, you may have to close another.")
                }
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: "hand.raised").font(.title2)
                    Text("You can always undo a move. In the journey, there is no time limit. Explore at your own pace.").font(.subheadline).lineSpacing(4)
                }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(Palette.lime.opacity(0.5), in: RoundedRectangle(cornerRadius: 22))
            }
        }.navigationTitle("Color lab").navigationBarTitleDisplayMode(.inline)
    }

    private func demoObject(isSource: Bool) -> some View {
        let colored = isSource ? sourceHasColor : destinationHasColor
        return Button {
            if holding && !colored {
                if isSource { sourceHasColor = true } else { destinationHasColor = true }
                holding = false
            } else if !holding && colored {
                if isSource { sourceHasColor = false } else { destinationHasColor = false }
                holding = true
            }
        } label: {
            VStack(spacing: 4) {
                ObjectGlyph(object: .init(id: "demo", name: "", kind: isSource ? .reservoir : selected == .green ? .vine : selected == .yellow ? .lantern : selected == .blue ? .bridge : .door, pigment: colored ? selected : nil, x: 0, y: 0))
                Text(isSource ? "SOURCE" : "\(colored ? selected.state.uppercased() : "DORMANT")").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(Palette.muted)
            }.frame(maxWidth: .infinity).padding(.vertical, 5).background(Palette.soft.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain).accessibilityLabel("\(isSource ? "Source" : "Target"), \(colored ? selected.title : "colorless")")
    }

    private func rule(_ number: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Text(number).font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted).padding(.top, 4)
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.system(.headline, design: .rounded))
                Text(text).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(3)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 19).overlay(alignment: .bottom) { Divider() }
    }

    private func resetDemo() { sourceHasColor = true; destinationHasColor = false; holding = false }
}
