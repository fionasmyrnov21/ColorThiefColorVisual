import SwiftUI

struct ResultView: View {
    @ObservedObject var app: AppViewModel
    @ObservedObject var game: GameViewModel
    var body: some View {
        NavigationStack {
            FoldablePage {
                VStack(spacing: 26) {
                    HStack { BrandMark(); Spacer(); Eyebrow(text: "A little more alive") }.padding(.top, 16)
                    ZStack {
                        Circle().fill(Palette.lime.opacity(0.5)).frame(width: 164, height: 164)
                        Image(systemName: "sparkle").font(.system(size: 76, weight: .ultraLight))
                        Circle().fill(Pigment.red.color).frame(width: 12, height: 12).offset(x: -92, y: -30)
                        Circle().fill(Pigment.blue.color).frame(width: 9, height: 9).offset(x: 81, y: 58)
                        Circle().fill(Pigment.yellow.color).frame(width: 7, height: 7).offset(x: 73, y: -72)
                    }.padding(.top, 24).accessibilityHidden(true)
                    VStack(spacing: 13) {
                        Eyebrow(text: "\(game.session?.timed == true ? "PASSAGE" : "PLACE \(String(format: "%02d", game.level.id))") RESTORED")
                        Text("You made\na difference.").font(.system(size: 45, design: .serif)).tracking(-1).multilineTextAlignment(.center)
                        Text(game.level.title).font(.system(.subheadline, design: .rounded)).foregroundStyle(Palette.muted)
                    }
                    StarsView(count: game.stars, size: 27).padding(.vertical, 8)
                }.frame(maxWidth: .infinity)
            } secondary: {
                VStack(spacing: 26) {
                    HStack(spacing: 0) {
                        resultMetric("\(game.session?.moves ?? 0)", "MOVES")
                        Divider().frame(height: 42)
                        resultMetric(clockText(game.session?.elapsed ?? 0), "TIME")
                        Divider().frame(height: 42)
                        resultMetric("\(game.level.par)", "MOVE GOAL")
                    }.padding(.vertical, 22).background(Palette.soft, in: RoundedRectangle(cornerRadius: 22))
                    Text(game.stars == 3 ? "A thoughtful path, beautifully found." : "There is always another way to see the world. Return anytime to find a shorter path.")
                        .font(.system(.subheadline, design: .rounded)).foregroundStyle(Palette.muted).multilineTextAlignment(.center).lineSpacing(4)
                    VStack(spacing: 12) {
                        if game.session?.timed == true {
                            PrimaryButton(title: "Explore at your own pace") { app.play(app.nextLevel) }
                        } else if game.level.id < LevelLibrary.levels.count {
                            PrimaryButton(title: "Discover the next place") { app.play(LevelLibrary.levels[game.level.id]) }
                        } else {
                            PrimaryButton(title: "Visit your collection", symbol: "square.stack.3d.up") { app.selectedTab = 3; app.isPlaying = false }
                        }
                        Button { game.restart() } label: { Label("Find another way", systemImage: "arrow.counterclockwise").font(.subheadline).frame(maxWidth: .infinity, minHeight: 45) }
                        Button("Return to sanctuary") { app.isPlaying = false }.font(.subheadline).foregroundStyle(Palette.muted).frame(minHeight: 44)
                    }.padding(.top, 10)
                }.frame(maxWidth: .infinity)
            }.toolbar(.hidden, for: .navigationBar)
        }.tint(Palette.ink)
    }

    private func resultMetric(_ value: String, _ title: String) -> some View {
        VStack(spacing: 10) {
            Text(value).font(.system(size: 26, weight: .regular, design: .monospaced))
            Eyebrow(text: title)
        }.frame(maxWidth: .infinity)
    }
}
