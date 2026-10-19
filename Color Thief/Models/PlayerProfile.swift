import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

enum ProfileImageError: Error {
    case unreadable, tooLarge
}

enum ProfileImageProcessor {
    nonisolated static func prepare(_ data: Data) throws -> Data {
        guard data.count <= 40 * 1024 * 1024 else { throw ProfileImageError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1024,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary),
              let context = CGContext(data: nil, width: thumbnail.width, height: thumbnail.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw ProfileImageError.unreadable
        }
        let bounds = CGRect(x: 0, y: 0, width: thumbnail.width, height: thumbnail.height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(bounds)
        context.draw(thumbnail, in: bounds)
        let output = NSMutableData()
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ProfileImageError.unreadable
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ProfileImageError.unreadable }
        return output as Data
    }
}

struct ProfileImageStore {
    let directory: String

    init(directory: String? = nil) {
        let base = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? NSHomeDirectory() + "/Library/Application Support"
        self.directory = directory ?? base + "/ColorThief/Profile"
    }

    private var imagePath: String { directory + "/portrait.jpg" }

    func load() -> Data? { try? Data(contentsOf: .init(filePath: imagePath)) }

    func save(_ data: Data) throws {
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try data.write(to: .init(filePath: imagePath), options: .atomic)
    }

    func remove() throws {
        if FileManager.default.fileExists(atPath: imagePath) {
            try FileManager.default.removeItem(atPath: imagePath)
        }
    }
}
