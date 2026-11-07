import SwiftUI

struct RootView: View {
    @StateObject private var app = AppViewModel()
    var body: some View {
        TabView(selection: $app.selectedTab) {
            NavigationStack { HomeView(app: app) }
                .tabItem { Label("Sanctuary", systemImage: "square.grid.2x2") }.tag(0)
            NavigationStack { JourneyView(app: app) }
                .tabItem { Label("Journey", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }.tag(1)
            NavigationStack { ColorLabView() }
                .tabItem { Label("Color lab", systemImage: "circle.lefthalf.filled") }.tag(2)
            NavigationStack { CollectionView(app: app) }
                .tabItem { Label("Collection", systemImage: "square.stack.3d.up") }.tag(3)
        }
        .tint(Palette.ink)
        .preferredColorScheme(.light)
        .environment(\.locale, Locale(identifier: "en_US"))
        .fullScreenCover(isPresented: $app.isPlaying) { GameView(app: app, game: app.game) }
        .sheet(isPresented: $app.showSettings) { SettingsView(app: app) }
        .sheet(isPresented: $app.showProfile) {
            NavigationStack {
                PlayerProfileView(app: app, profile: app.profile)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { app.showProfile = false } } }
            }.tint(Palette.ink)
        }
    }
}

struct HomeView: View {
    @ObservedObject var app: AppViewModel
    @ObservedObject private var game: GameViewModel
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize = 43
    init(app: AppViewModel) { self.app = app; game = app.game }
    var body: some View {
        FoldablePage {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 10) {
                    BrandMark()
                    Text("color thief.").font(.system(size: 24, weight: .semibold, design: .rounded)).tracking(-1)
                    Spacer()
                    Button { app.showProfile = true } label: {
                        ProfilePortrait(profile: app.profile, size: 46)
                    }.buttonStyle(.plain).accessibilityLabel("Player profile")
                    Button { app.showSettings = true } label: {
                        Image(systemName: "slider.horizontal.3").font(.system(size: 18)).frame(width: 46, height: 46)
                            .overlay(Circle().stroke(Palette.line, lineWidth: 1))
                    }.accessibilityLabel("Settings")
                }.padding(.top, 12)
                VStack(alignment: .leading, spacing: 13) {
                    Eyebrow(text: "Take a color. Change the world.")
                    Text("A little color.\nA different world.")
                        .font(.system(size: headlineSize, weight: .regular, design: .serif)).tracking(-1.8).lineSpacing(-3).fixedSize(horizontal: false, vertical: true)
                    Text("Nothing here is permanent.\nExcept the possibilities.")
                        .font(.system(.subheadline, design: .rounded)).foregroundStyle(Palette.muted).lineSpacing(4)
                }
                VStack(spacing: 0) {
                    HeroWorld()
                    HStack {
                        Text("01 — THE QUIET QUARTER").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1)
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(Pigment.allCases) { pigment in Circle().fill(pigment.color).frame(width: 7, height: 7) }
                        }
                    }.padding(.horizontal, 18).padding(.vertical, 15)
                }
                .background(Color(hex: 0xEEF0E5), in: RoundedRectangle(cornerRadius: 24))
            }
        } secondary: {
            VStack(alignment: .leading, spacing: 26) {
                VStack(spacing: 12) {
                    PrimaryButton(title: game.session != nil && game.session?.won == false ? "Continue your journey" : app.records.isEmpty ? "Enter the quiet world" : "Continue your journey") {
                        if game.session != nil && game.session?.won == false { app.resume() } else { app.play(app.nextLevel) }
                    }
                    HStack(spacing: 7) {
                        Image(systemName: "headphones").font(.system(size: 10))
                        Text("No rush. Just you and a little curiosity.").font(.system(size: 11, design: .rounded))
                    }.foregroundStyle(Palette.muted)
                }
                SectionHeading(title: "Your little universe", trailing: "\(app.records.count) / 8 discovered")
                HStack(spacing: 12) {
                    metric("\(app.totalStars)", caption: "STARS FOUND", symbol: "star")
                    metric("\(app.records.count)", caption: "WORLDS RESTORED", symbol: "square.on.square")
                }
                Button { app.play(LevelLibrary.levels[5], timed: true) } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "hourglass").font(.system(size: 27, weight: .light)).frame(width: 52, height: 60)
                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow(text: "A change of pace")
                            Text("The fleeting passage").font(.system(.headline, design: .rounded))
                            Text("One puzzle. Two and a half minutes.").font(.system(.caption, design: .rounded)).foregroundStyle(Palette.muted)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                    }.padding(19).background(Palette.lime, in: RoundedRectangle(cornerRadius: 22))
                }.buttonStyle(.plain)
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(Palette.line)
                    Text("LESS COLOR. MORE POSSIBILITY.").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1.5).fixedSize()
                    Rectangle().frame(height: 1).foregroundStyle(Palette.line)
                }.foregroundStyle(Palette.muted).padding(.vertical, 12)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }

    private func metric(_ value: String, caption: String, symbol: String) -> some View {
        Surface {
            VStack(alignment: .leading, spacing: 14) {
                HStack { Image(systemName: symbol).font(.system(size: 18, weight: .light)); Spacer(); Text(value).font(.system(size: 29, weight: .regular, design: .serif)) }
                Text(caption).font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(0.6).foregroundStyle(Palette.muted)
            }
        }
    }
}

struct BrandMark: View {
    var body: some View {
        HStack(spacing: 3) {
            VStack(spacing: 3) { Rectangle().fill(Palette.ink); Rectangle().fill(Pigment.blue.color) }
            VStack(spacing: 3) { Rectangle().fill(Pigment.red.color); Rectangle().fill(Palette.ink) }
        }.frame(width: 25, height: 25).rotationEffect(.degrees(-8)).accessibilityHidden(true)
    }
}
