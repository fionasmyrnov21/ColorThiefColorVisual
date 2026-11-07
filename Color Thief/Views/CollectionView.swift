import SwiftUI

struct CollectionView: View {
    @ObservedObject var app: AppViewModel
    var body: some View {
        FoldablePage {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Small changes, collected")
                    Text("Your collection").font(.system(.largeTitle, design: .serif))
                    Text("A record of the worlds you brought to life.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                VStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(Palette.line, lineWidth: 6)
                        Circle().trim(from: 0, to: CGFloat(app.totalStars) / 24).stroke(Palette.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                        VStack(spacing: 7) {
                            Image(systemName: "sparkle").font(.system(size: 27, weight: .light))
                            Text("\(app.totalStars)").font(.system(size: 52, design: .serif))
                            Eyebrow(text: "of 24 stars")
                        }
                    }.frame(width: 194, height: 194).padding(.top, 12)
                    Text(app.totalStars == 24 ? "A world in full color." : app.records.isEmpty ? "Every journey starts with a spark." : "Look how far a little color goes.").font(.system(.title3, design: .serif)).multilineTextAlignment(.center)
                    HStack {
                        stat("\(app.records.count)", "RESTORED")
                        Spacer()
                        stat("\(app.records.values.filter { $0.stars == 3 }.count)", "PERFECT PATHS")
                        Spacer()
                        stat("\(app.records.values.reduce(0) { $0 + $1.moves })", "BEST MOVES")
                    }.padding(22).background(Palette.soft, in: RoundedRectangle(cornerRadius: 20))
                }.frame(maxWidth: .infinity)
            }
        } secondary: {
            VStack(alignment: .leading, spacing: 26) {
                SectionHeading(title: "Little milestones", trailing: "\(milestones.filter { $0.2 }.count) / 4")
                ForEach(Array(milestones.enumerated()), id: \.offset) { _, milestone in
                    HStack(spacing: 18) {
                        Image(systemName: milestone.3).font(.system(size: 24, weight: .light)).frame(width: 50, height: 56)
                            .background(milestone.2 ? Palette.lime : Palette.soft, in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(milestone.0).font(.system(.headline, design: .rounded))
                            Text(milestone.1).font(.caption).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Image(systemName: milestone.2 ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(milestone.2 ? Palette.ink : Palette.muted)
                    }.opacity(milestone.2 ? 1 : 0.55)
                }
                if !app.records.isEmpty {
                    SectionHeading(title: "Restored places", trailing: "PERSONAL BESTS")
                    ForEach(LevelLibrary.levels.filter { app.records[$0.id] != nil }) { level in
                        if let record = app.records[level.id] {
                            Button { app.play(level) } label: {
                                HStack {
                                    Text(String(format: "%02d", level.id)).font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(level.title).font(.subheadline.weight(.semibold))
                                        Text("\(record.moves) moves · \(clockText(record.seconds)) best time").font(.caption).foregroundStyle(Palette.muted)
                                    }.padding(.leading, 8)
                                    Spacer()
                                    StarsView(count: record.stars)
                                }.padding(.vertical, 14).overlay(alignment: .bottom) { Divider() }
                            }.buttonStyle(.plain)
                        }
                    }
                } else {
                    PrimaryButton(title: "Find your first spark") { app.play(LevelLibrary.levels[0]) }
                }
                if let record = app.challengeRecord {
                    Surface {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("The fleeting passage", systemImage: "hourglass").font(.headline)
                            Text("Best route: \(record.moves) moves · \(clockText(record.seconds))").font(.subheadline).foregroundStyle(Palette.muted)
                        }
                    }
                }
            }
        }.navigationTitle("Collection").navigationBarTitleDisplayMode(.inline)
    }

    private var milestones: [(String, String, Bool, String)] {
        [
            ("The first spark", "Restore your first place.", !app.records.isEmpty, "bolt"),
            ("A thoughtful touch", "Find a three-star solution.", app.records.values.contains { $0.stars == 3 }, "hand.draw"),
            ("A brighter quarter", "Restore the first four places.", (1...4).allSatisfy { app.records[$0] != nil }, "sun.max"),
            ("Nothing left behind", "Bring all eight places to life.", app.records.count == 8, "leaf")
        ]
    }

    private func stat(_ value: String, _ title: String) -> some View {
        VStack(spacing: 8) {
            Text(value).font(.system(size: 25, design: .serif))
            Text(title).font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(0.5).foregroundStyle(Palette.muted)
        }
    }
}
