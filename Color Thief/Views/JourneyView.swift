import SwiftUI

struct JourneyView: View {
    @ObservedObject var app: AppViewModel
    var body: some View {
        FoldablePage {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Eight places. Endless possibilities.")
                    Text("The journey").font(.system(.largeTitle, design: .serif))
                    Text("Leave each place a little more alive.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                HStack {
                    Text("\(app.records.count) of 8 restored").font(.system(.caption, design: .monospaced))
                    Spacer()
                    Label("\(app.totalStars) / 24", systemImage: "star.fill").font(.system(.caption, design: .monospaced))
                }
                ProgressView(value: Double(app.records.count), total: 8).tint(Palette.ink)
                chapter(0)
            }
        } secondary: {
            VStack(alignment: .leading, spacing: 26) {
                chapter(1)
                Surface {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkle").font(.title2)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("A thoughtful touch").font(.headline)
                            Text("Finish at or under the move goal for three stars. Every solution still opens the next place.")
                                .font(.subheadline).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }.navigationTitle("Journey").navigationBarTitleDisplayMode(.inline)
    }

    private func chapter(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            SectionHeading(title: index == 0 ? "The quiet quarter" : "The shifting gardens", trailing: "CHAPTER 0\(index + 1)")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                ForEach(Array(LevelLibrary.levels[(index * 4)..<(index * 4 + 4)])) { level in
                    levelCard(level)
                }
            }
        }
    }

    private func previewKind(_ scene: BoardScene) -> ObjectKind {
        switch scene {
        case .courtyard: return .door
        case .causeway: return .bridge
        case .night, .signals: return .lantern
        case .terraces, .orchard: return .vine
        case .foundry: return .lift
        case .compass: return .button
        }
    }

    private func levelCard(_ level: PuzzleLevel) -> some View {
        let locked = level.id > app.unlocked
        let record = app.records[level.id]
        return Button { app.play(level) } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(String(format: "%02d", level.id)).font(.system(size: 12, weight: .medium, design: .monospaced))
                    Spacer()
                    Image(systemName: locked ? "lock" : record == nil ? "arrow.up.right" : "checkmark").font(.system(size: 12))
                }.foregroundStyle(Palette.muted)
                ZStack {
                    Circle().fill(level.colors.last?.color.opacity(locked ? 0.06 : 0.14) ?? Palette.soft).frame(width: 80, height: 80)
                    ObjectGlyph(object: .init(id: "preview", name: "", kind: previewKind(level.scene), pigment: locked ? nil : level.colors.last, x: 0, y: 0))
                }.frame(maxWidth: .infinity).frame(height: 90)
                Text(level.title).font(.system(.subheadline, design: .rounded, weight: .semibold)).frame(minHeight: 38, alignment: .topLeading).multilineTextAlignment(.leading)
                if let record { StarsView(count: record.stars) }
                else { Text(locked ? "UNDISCOVERED" : "\(level.par) MOVE GOAL").font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(0.8).foregroundStyle(Palette.muted) }
            }.padding(17).frame(maxWidth: .infinity, alignment: .leading)
                .background(level.id == app.nextLevel.id && !locked ? Palette.lime.opacity(0.35) : Color.clear, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.line, lineWidth: 1))
                .opacity(locked ? 0.55 : 1)
        }.buttonStyle(.plain).disabled(locked)
            .accessibilityLabel("Level \(level.id), \(level.title), \(locked ? "locked" : record == nil ? "available" : "completed")")
    }
}
