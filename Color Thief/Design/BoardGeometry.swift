import CoreGraphics

enum BoardGeometry {
    static func tileSize(in size: CGSize) -> CGSize {
        CGSize(width: max(44, min(84, size.width * 0.22)), height: max(44, min(92, size.height * 0.28)))
    }

    static func position(for object: PuzzleObject, in size: CGSize) -> CGPoint {
        let tile = tileSize(in: size)
        let horizontalMargin = tile.width / 2 + 4
        let verticalMargin = tile.height / 2 + 4
        return CGPoint(
            x: min(max(horizontalMargin, size.width * object.x), max(horizontalMargin, size.width - horizontalMargin)),
            y: min(max(verticalMargin, size.height * object.y - 23), max(verticalMargin, size.height - verticalMargin))
        )
    }

    static func frame(for object: PuzzleObject, in size: CGSize) -> CGRect {
        let tile = tileSize(in: size)
        let center = position(for: object, in: size)
        return CGRect(x: center.x - tile.width / 2, y: center.y - tile.height / 2, width: tile.width, height: tile.height)
    }
}
