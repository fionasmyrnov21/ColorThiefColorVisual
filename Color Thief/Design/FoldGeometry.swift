import CoreGraphics

enum FoldGeometry {
    static func availableRect(in bounds: CGRect, avoiding obstacles: [CGRect]) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else { return .zero }
        var candidates = [bounds]
        for obstacle in obstacles where !obstacle.isNull && !obstacle.isEmpty {
            candidates = candidates.flatMap { candidate -> [CGRect] in
                let intersection = candidate.intersection(obstacle)
                guard !intersection.isNull, !intersection.isEmpty else { return [candidate] }
                return [
                    CGRect(x: candidate.minX, y: candidate.minY, width: intersection.minX - candidate.minX, height: candidate.height),
                    CGRect(x: intersection.maxX, y: candidate.minY, width: candidate.maxX - intersection.maxX, height: candidate.height),
                    CGRect(x: candidate.minX, y: candidate.minY, width: candidate.width, height: intersection.minY - candidate.minY),
                    CGRect(x: candidate.minX, y: intersection.maxY, width: candidate.width, height: candidate.maxY - intersection.maxY)
                ].filter { $0.width > 0 && $0.height > 0 }
            }
        }
        return candidates.max { first, second in
            let firstArea = first.width * first.height
            let secondArea = second.width * second.height
            if firstArea != secondArea { return firstArea < secondArea }
            let firstDistance = abs(first.midX - bounds.midX) + abs(first.midY - bounds.midY)
            let secondDistance = abs(second.midX - bounds.midX) + abs(second.midY - bounds.midY)
            if firstDistance != secondDistance { return firstDistance > secondDistance }
            if first.minX != second.minX { return first.minX > second.minX }
            return first.minY > second.minY
        } ?? .zero
    }
}
