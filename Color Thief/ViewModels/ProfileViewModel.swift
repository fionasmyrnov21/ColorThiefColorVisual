import Foundation
import Combine
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isImporting = false
    @Published var errorMessage: String?
    private let store: ProfileImageStore
    private var importID = UUID()

    init(store: ProfileImageStore? = nil) {
        let imageStore = store ?? ProfileImageStore()
        self.store = imageStore
        image = imageStore.load().flatMap { UIImage(data: $0) }
    }

    func importPhoto(_ item: PhotosPickerItem) async {
        let request = UUID()
        importID = request
        isImporting = true
        errorMessage = nil
        defer { if importID == request { isImporting = false } }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { throw ProfileImageError.unreadable }
            try Task.checkCancellation()
            let prepared = try await Task.detached(priority: .userInitiated) {
                try ProfileImageProcessor.prepare(data)
            }.value
            try Task.checkCancellation()
            guard importID == request else { return }
            guard let photo = UIImage(data: prepared) else { throw ProfileImageError.unreadable }
            try store.save(prepared)
            image = photo
        } catch is CancellationError {
        } catch {
            guard importID == request else { return }
            if let failure = error as? ProfileImageError {
                switch failure {
                case .tooLarge: errorMessage = "This image is too large. Choose a photo smaller than 40 MB."
                case .unreadable: errorMessage = "This image could not be opened. Please choose another photo."
                }
            } else {
                errorMessage = "Your photo could not be loaded or saved. Please try again."
            }
        }
    }

    func removePhoto() {
        cancelImport()
        do {
            try store.remove()
            image = nil
        } catch {
            errorMessage = "Your photo could not be removed. Please try again."
        }
    }

    func cancelImport() {
        importID = UUID()
        isImporting = false
    }
}
