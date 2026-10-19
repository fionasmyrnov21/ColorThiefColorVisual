import SwiftUI
import PhotosUI

struct PlayerProfileView: View {
    @ObservedObject var app: AppViewModel
    @ObservedObject var profile: ProfileViewModel
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        let hasPhoto = profile.image != nil
        FoldablePage {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Your own little corner")
                    Text("Your profile").font(.system(.largeTitle, design: .serif))
                    Text("Give your journey a familiar face.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                Surface {
                    VStack(spacing: 24) {
                        ZStack {
                            ProfilePortrait(profile: profile, size: 160)
                            if profile.isImporting {
                                Circle().fill(Palette.paper.opacity(0.75)).frame(width: 160, height: 160)
                                ProgressView().tint(Palette.ink).accessibilityLabel("Loading photo")
                            }
                        }.padding(.top, 8)
                        Text("Color explorer").font(.system(.title2, design: .serif))
                        PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .current) {
                            Label(hasPhoto ? "Change photo" : "Choose photo", systemImage: "photo.on.rectangle")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .foregroundStyle(Palette.paper).background(Palette.ink, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain).disabled(profile.isImporting)
                        if profile.image != nil {
                            Button(role: .destructive) { profile.removePhoto(); selectedPhoto = nil } label: {
                                Label("Remove photo", systemImage: "trash").font(.subheadline).frame(maxWidth: .infinity, minHeight: 44)
                            }.disabled(profile.isImporting)
                        }
                    }.frame(maxWidth: .infinity)
                }
            }
        } secondary: {
            VStack(alignment: .leading, spacing: 26) {
                SectionHeading(title: "Your journey", trailing: "A LITTLE MORE ALIVE")
                Surface {
                    VStack(spacing: 22) {
                        progress("Stars found", value: "\(app.totalStars) / 24", symbol: "star")
                        Divider()
                        progress("Places restored", value: "\(app.records.count) / 8", symbol: "square.on.square")
                        Divider()
                        progress("Perfect paths", value: "\(app.records.values.filter { $0.stars == 3 }.count)", symbol: "sparkle")
                    }
                }
                Surface {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Make it yours", systemImage: "photo").font(.headline)
                        Text("Choose an image from your photo library. You can replace it or remove it whenever you like.")
                            .font(.subheadline).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                        Text("Your profile photo is saved on this device.").font(.caption).foregroundStyle(Palette.muted)
                    }
                }
            }
        }
        .navigationTitle("Player profile").navigationBarTitleDisplayMode(.inline)
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            await profile.importPhoto(selectedPhoto)
            if !Task.isCancelled { self.selectedPhoto = nil }
        }
        .onDisappear { profile.cancelImport() }
        .alert("Photo could not be updated", isPresented: Binding(get: { profile.errorMessage != nil }, set: { if !$0 { profile.errorMessage = nil } })) {
            Button("OK", role: .cancel) { profile.errorMessage = nil }
        } message: { Text(profile.errorMessage ?? "Please try again.") }
    }

    private func progress(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).frame(width: 24).foregroundStyle(Palette.muted)
            Text(title).font(.subheadline)
            Spacer(minLength: 12)
            Text(value).font(.system(.headline, design: .monospaced)).monospacedDigit()
        }
    }
}

struct ProfilePortrait: View {
    @ObservedObject var profile: ProfileViewModel
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(Palette.soft)
            if let image = profile.image {
                Image(uiImage: image).resizable().scaledToFill().frame(width: size, height: size).clipped()
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().scaledToFit()
                    .foregroundStyle(Palette.muted.opacity(0.55)).padding(size * 0.16)
            }
        }
        .frame(width: size, height: size).clipShape(Circle())
        .overlay(Circle().stroke(Palette.line, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
