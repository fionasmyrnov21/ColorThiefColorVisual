import SwiftUI
import Combine
import UIKit

struct GameView: View {
    @ObservedObject var app: AppViewModel
    @ObservedObject var game: GameViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var paused = false
    @State private var confirmRestart = false
    @State private var showObjects = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if game.session?.won == true {
                ResultView(app: app, game: game)
            } else if game.session?.expired == true {
                expiredView
            } else {
                NavigationStack {
                    FoldablePage {
                        gameHeader
                        board
                    } secondary: {
                        inventory
                        controlPanel
                    }
                    .navigationTitle("COLOR THIEF")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { gameToolbar }
                }
            }
        }
        .tint(Palette.ink).preferredColorScheme(.light)
        .onReceive(timer) { _ in
            if UIApplication.shared.applicationState == .active && !paused && !game.showHint { game.tick() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            game.persist()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            if game.session?.won == false && game.session?.expired == false { paused = true }
        }
        .sheet(isPresented: $paused) { pauseSheet }
        .sheet(isPresented: $game.showHint) { hintSheet }
        .confirmationDialog("Start this place again?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Start again", role: .destructive) { game.restart() }
            Button("Keep exploring", role: .cancel) { }
        } message: { Text("Your moves in this puzzle will be cleared.") }
        .onDisappear { game.persist() }
    }

    @ToolbarContentBuilder private var gameToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { game.persist(); app.isPlaying = false } label: { Label("Sanctuary", systemImage: "xmark") }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { game.showHint = true } label: { Label("Hint", systemImage: "lightbulb") }
            Button { paused = true } label: { Label("Pause", systemImage: "pause") }
        }
    }

    private var gameHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Eyebrow(text: "\(game.session?.timed == true ? "TIMED PASSAGE" : "THE JOURNEY") / \(String(format: "%02d", game.level.id))")
                Spacer()
                HStack(spacing: 4) {
                    ForEach(game.level.colors) { color in Circle().fill(color.color).frame(width: 7, height: 7) }
                }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.level.title).font(.system(.title, design: .serif))
                    Text(game.level.subtitle).font(.caption).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 6) {
                    Text(game.session?.timed == true ? clockText(game.remaining) : "\(game.session?.moves ?? 0)")
                        .font(.system(size: 25, weight: .regular, design: .monospaced)).monospacedDigit()
                        .foregroundStyle(game.session?.timed == true && game.remaining < 30 ? Pigment.red.color : Palette.ink)
                    Eyebrow(text: game.session?.timed == true ? "remaining" : "moves / \(game.level.par) goal")
                }
            }
        }
    }

    private var board: some View {
        VStack(spacing: 12) {
            PuzzleBoard(objects: game.session?.objects ?? [], scene: game.level.scene, held: game.session?.held) { id in
                withAnimation(app.reduceEffects || systemReduceMotion ? nil : .easeInOut(duration: 0.22)) { game.tap(id) }
            }
            HStack(spacing: 5) {
                Image(systemName: "hand.tap").font(.system(size: 10))
                Text(game.session?.held == nil ? "Tap a colored object to take its color" : "Tap a colorless object to give it your color").font(.system(size: 10, design: .rounded))
            }.foregroundStyle(Palette.muted)
        }
    }

    private var inventory: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(game.session?.held?.color ?? Palette.soft)
                Image(systemName: game.session?.held?.symbol ?? "hand.raised").font(.system(size: 22, weight: .light))
            }.frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "In your hand")
                Text(game.session?.held.map { "\($0.title) · \($0.property)" } ?? "A little room for possibility")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
            }
            Spacer(minLength: 0)
            if game.session?.held != nil { Image(systemName: "arrow.up.right").foregroundStyle(Palette.muted) }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(game.session?.held?.color ?? Palette.line, lineWidth: 1))
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Eyebrow(text: game.ready ? "A path is open" : "Your next possibility")
                Spacer()
                Text("\(min((game.session?.stage ?? 0) + 1, game.level.stages.count)) / \(game.level.stages.count)")
                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted)
            }
            Text(game.ready ? "Time to step through." : game.currentStage.title)
                .font(.system(.title2, design: .serif))
            Text(game.currentStage.detail).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
            VStack(spacing: 10) {
                ForEach(game.currentStage.requirements, id: \.objectID) { requirement in
                    let object = game.session?.objects.first { $0.id == requirement.objectID }
                    let complete = object?.pigment == requirement.pigment
                    HStack {
                        Image(systemName: requirement.pigment.symbol).foregroundStyle(requirement.pigment.color).frame(width: 22)
                        Text("\(object?.name ?? "Object") · \(requirement.pigment.state)").font(.system(.subheadline, design: .rounded))
                        Spacer()
                        Image(systemName: complete ? "checkmark.circle.fill" : "circle").foregroundStyle(complete ? Palette.ink : Palette.line)
                    }
                    .accessibilityLabel("\(object?.name ?? "Object") needs \(requirement.pigment.title), \(complete ? "ready" : "pending")")
                }
            }
            if game.ready {
                PrimaryButton(title: "Step through the exit", symbol: "door.left.hand.open", color: Palette.lime, foreground: Palette.ink) { game.finish() }
            }
            Text(game.message).font(.system(.caption, design: .rounded)).foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading).padding(14)
                .background(Palette.soft, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("puzzleFeedback")
            HStack(spacing: 12) {
                Button { game.undo() } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward").font(.subheadline).frame(maxWidth: .infinity, minHeight: 46)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line, lineWidth: 1))
                }.disabled(game.session?.history.isEmpty ?? true)
                Button { confirmRestart = true } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise").font(.subheadline).frame(maxWidth: .infinity, minHeight: 46)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line, lineWidth: 1))
                }
            }.buttonStyle(.plain)
            DisclosureGroup(isExpanded: $showObjects) {
                VStack(spacing: 8) {
                    ForEach(game.session?.objects ?? []) { object in
                        Button { game.tap(object.id) } label: {
                            HStack {
                                Image(systemName: object.pigment?.symbol ?? object.kind.symbol).foregroundStyle(object.pigment?.color ?? Palette.muted).frame(width: 24)
                                Text(object.name).font(.subheadline)
                                Spacer()
                                Text(object.pigment?.state ?? "Dormant").font(.caption).foregroundStyle(Palette.muted)
                                Image(systemName: game.session?.held == nil ? "minus.circle" : "plus.circle").font(.caption)
                            }.frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.padding(.top, 10)
            } label: { Label("All objects", systemImage: "square.grid.2x2").font(.subheadline) }.tint(Palette.muted)
        }
    }

    private var pauseSheet: some View {
        NavigationStack {
            ReservedRegionContent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Eyebrow(text: "Take a breath")
                        Text("The world can wait.").font(.system(size: 36, design: .serif))
                        Text("Your colors are right where you left them. The clock rests while you do.").font(.body).foregroundStyle(Palette.muted).lineSpacing(5)
                        PrimaryButton(title: "Keep exploring", symbol: "play") { paused = false }
                        Button { paused = false; game.persist(); app.isPlaying = false } label: { Text("Return to sanctuary").font(.subheadline).frame(maxWidth: .infinity, minHeight: 48) }
                    }.padding(28)
                }
            }.pageStyle().navigationTitle("Paused").navigationBarTitleDisplayMode(.inline)
        }.presentationDetents([.medium, .large]).tint(Palette.ink)
    }

    private var hintSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "lightbulb").font(.system(size: 38, weight: .ultraLight)).padding(20).background(Palette.lime, in: Circle())
                    Eyebrow(text: "A gentle nudge")
                    Text(game.ready ? "The way is open." : game.currentStage.title).font(.system(.largeTitle, design: .serif))
                    Text(game.ready ? "Tap Step through the exit to complete this place." : game.currentStage.detail).font(.body).lineSpacing(5)
                    Surface {
                        VStack(alignment: .leading, spacing: 12) {
                            Eyebrow(text: "Remember")
                            Text("Take a color, then give it away. Your hand holds only one color. Place it on an empty object before collecting another.").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                            Text("Colors are never created or lost. If an object is in the way, borrow its color and find it a temporary home.").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                        }
                    }
                    PrimaryButton(title: "I have an idea", symbol: "arrow.right") { game.showHint = false }
                }.padding(26)
            }.pageStyle().navigationTitle("A new perspective").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { game.showHint = false } } }
        }.presentationDetents([.medium, .large]).tint(Palette.ink)
    }

    private var expiredView: some View {
        NavigationStack {
            FoldablePage {
                VStack(spacing: 25) {
                    Image(systemName: "hourglass").font(.system(size: 57, weight: .ultraLight))
                    Eyebrow(text: "The fleeting passage")
                    Text("A moment slipped by.").font(.system(.largeTitle, design: .serif)).multilineTextAlignment(.center)
                    Text("Every attempt is a new perspective.\nThe colors are ready when you are.").font(.body).foregroundStyle(Palette.muted).multilineTextAlignment(.center).lineSpacing(5)
                }.frame(maxWidth: .infinity)
            } secondary: {
                VStack(spacing: 25) {
                    PrimaryButton(title: "Try a new approach", symbol: "arrow.counterclockwise") { game.restart() }
                    Button("Return to sanctuary") { game.discard(); app.isPlaying = false }.frame(maxWidth: .infinity, minHeight: 48)
                }
            }
        }
    }
}
