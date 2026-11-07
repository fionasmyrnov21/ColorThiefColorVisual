import SwiftUI

struct SettingsView: View {
    @ObservedObject var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    NavigationLink {
                        PlayerProfileView(app: app, profile: app.profile)
                    } label: {
                        HStack(spacing: 14) {
                            ProfilePortrait(profile: app.profile)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Player profile").font(.headline)
                                Text("Add a photo to your journey").font(.caption).foregroundStyle(Palette.muted)
                            }
                        }.padding(.vertical, 4)
                    }
                }
                Section("Make yourself at home") {
                    Toggle(isOn: $app.haptics) { Label("Gentle haptics", systemImage: "hand.tap") }
                    Toggle(isOn: $app.reduceEffects) { Label("Reduce motion effects", systemImage: "circle.dotted") }
                }
                Section {
                    Text("A quiet puzzle about giving something up to make something possible. Four colors, one small world, and more than one way forward.")
                        .font(.system(.body, design: .rounded)).foregroundStyle(Palette.muted).padding(.vertical, 8)
                    LabeledContent("Progress", value: "Saved on this device")
                } header: { Text("Color Thief") }
                Section {
                    Button(role: .destructive) { confirmReset = true } label: { Label("Reset journey", systemImage: "arrow.counterclockwise") }
                } footer: { Text("Clears all stars, best routes, the timed record, and your current puzzle.") }
            }
            .scrollContentBackground(.hidden).background(Palette.paper)
            .navigationTitle("A little adjustment").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Begin again?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset all progress", role: .destructive) { app.reset() }
                Button("Keep my journey", role: .cancel) { }
            } message: { Text("Your saved journey and current puzzle will be cleared. This cannot be undone.") }
        }.tint(Palette.ink).preferredColorScheme(.light)
    }
}
