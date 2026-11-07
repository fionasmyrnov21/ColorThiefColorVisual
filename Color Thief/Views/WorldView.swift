import SwiftUI

struct Polygon: Shape {
    var points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
            for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.x * rect.width, y: point.y * rect.height)) }
            path.closeSubpath()
        }
    }
}

struct Arch: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.width / 2))
            path.addArc(center: CGPoint(x: rect.width / 2, y: rect.width / 2), radius: rect.width / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.closeSubpath()
        }
    }
}

struct WorldGround: View {
    var hero = false
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 400
            let sy = size.height / 360
            context.scaleBy(x: sx, y: sy)
            func polygon(_ points: [CGPoint], _ color: Color) {
                var path = Path()
                path.addLines(points)
                path.closeSubpath()
                context.fill(path, with: .color(color))
            }
            for row in 0..<16 {
                for column in 0..<19 {
                    let x = CGFloat(column) * 24 + (row % 2 == 0 ? 0 : 12)
                    let y = CGFloat(row) * 24
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)), with: .color(Palette.muted.opacity(0.18)))
                }
            }
            context.fill(Path(ellipseIn: CGRect(x: 36, y: 267, width: 338, height: 63)), with: .color(Palette.ink.opacity(0.07)))
            polygon([.init(x: 28, y: 224), .init(x: 199, y: 127), .init(x: 374, y: 222), .init(x: 202, y: 326)], Color(hex: 0xBABAB4))
            polygon([.init(x: 28, y: 208), .init(x: 202, y: 308), .init(x: 202, y: 326), .init(x: 28, y: 224)], Color(hex: 0xC8C8C2))
            polygon([.init(x: 202, y: 308), .init(x: 374, y: 207), .init(x: 374, y: 224), .init(x: 202, y: 326)], Color(hex: 0xA3A39D))
            polygon([.init(x: 28, y: 208), .init(x: 199, y: 110), .init(x: 374, y: 207), .init(x: 202, y: 308)], Color(hex: 0xE4E4DF))
            for n in 1..<7 {
                let p = CGFloat(n) / 7
                var grid = Path()
                grid.move(to: CGPoint(x: 28 + 171 * p, y: 208 - 98 * p))
                grid.addLine(to: CGPoint(x: 202 + 172 * p, y: 308 - 101 * p))
                grid.move(to: CGPoint(x: 28 + 174 * p, y: 208 + 100 * p))
                grid.addLine(to: CGPoint(x: 199 + 175 * p, y: 110 + 97 * p))
                context.stroke(grid, with: .color(Palette.ink.opacity(0.07)), lineWidth: 0.6)
            }
            polygon([.init(x: 133, y: 147), .init(x: 167, y: 128), .init(x: 319, y: 238), .init(x: 285, y: 258)], Color(hex: 0xBFBFB8))
            for n in 0..<5 {
                let x = CGFloat(116 + n * 24)
                let y = CGFloat(232 - n * 13)
                polygon([.init(x: x, y: y), .init(x: x + 19, y: y - 10), .init(x: x + 34, y: y - 2), .init(x: x + 14, y: y + 8)], Color(hex: 0xF7F7F2))
            }
            for (x, y, h) in [(69.0, 177.0, 41.0), (113, 148, 70), (330, 201, 30)] {
                polygon([.init(x: x, y: y), .init(x: x + 15, y: y + 9), .init(x: x + 15, y: y - h), .init(x: x, y: y - h - 9)], Color(hex: 0xCDCDC7))
                polygon([.init(x: x + 15, y: y + 9), .init(x: x + 29, y: y), .init(x: x + 29, y: y - h - 9), .init(x: x + 15, y: y - h)], Color(hex: 0xB2B2AB))
                polygon([.init(x: x, y: y - h - 9), .init(x: x + 14, y: y - h - 17), .init(x: x + 29, y: y - h - 9), .init(x: x + 15, y: y - h)], Color(hex: 0xF4F4EF))
            }
            for (x, y) in [(47.0, 286.0), (338, 295), (350, 113), (43, 89)] {
                polygon([.init(x: x, y: y), .init(x: x + 10, y: y - 5), .init(x: x + 19, y: y), .init(x: x + 9, y: y + 5)], Palette.line)
            }
        }.accessibilityHidden(true)
    }
}

struct SceneGround: View {
    let scene: BoardScene

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 400, y: size.height / 360)
            let pale = Color(hex: 0xE1E1DA)
            let edge = Color(hex: 0xBDBDB5)
            func line(_ points: [CGPoint], width: CGFloat = 2, dashed: Bool = false) {
                var path = Path()
                path.addLines(points)
                context.stroke(path, with: .color(edge), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dashed ? [3, 6] : []))
            }
            func slab(_ rect: CGRect, radius: CGFloat = 12) {
                let shape = Path(roundedRect: rect, cornerRadius: radius)
                context.fill(shape.offsetBy(dx: 0, dy: 7), with: .color(edge.opacity(0.6)))
                context.fill(shape, with: .color(pale))
                context.stroke(shape, with: .color(edge.opacity(0.5)), lineWidth: 1)
            }
            for row in 0..<18 {
                for column in 0..<20 {
                    let dot = CGRect(x: CGFloat(column * 22), y: CGFloat(row * 22), width: 1, height: 1)
                    context.fill(Path(ellipseIn: dot), with: .color(edge.opacity(0.4)))
                }
            }
            switch scene {
            case .courtyard:
                break
            case .causeway:
                var river = Path()
                river.move(to: .init(x: 180, y: -20))
                river.addCurve(to: .init(x: 235, y: 380), control1: .init(x: 290, y: 110), control2: .init(x: 100, y: 220))
                context.stroke(river, with: .color(edge.opacity(0.45)), style: StrokeStyle(lineWidth: 110))
                for offset in [-23.0, 0, 23] {
                    context.stroke(river.offsetBy(dx: offset, dy: 0), with: .color(Palette.paper.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [9, 8]))
                }
                slab(.init(x: 22, y: 38, width: 122, height: 290), radius: 34)
                slab(.init(x: 258, y: 44, width: 120, height: 274), radius: 34)
                line([.init(x: 110, y: 226), .init(x: 266, y: 116)], width: 14, dashed: true)
            case .night:
                for radius in [148.0, 112, 76] {
                    let ring = Path(ellipseIn: .init(x: 200 - radius, y: 170 - radius, width: radius * 2, height: radius * 2))
                    context.stroke(ring, with: .color(edge.opacity(0.45)), lineWidth: 1)
                }
                for (x, y) in [(43.0, 40.0), (338, 35), (91, 93), (309, 112), (206, 225)] {
                    line([.init(x: x - 4, y: y), .init(x: x + 4, y: y)])
                    line([.init(x: x, y: y - 4), .init(x: x, y: y + 4)])
                }
                line([.init(x: 70, y: 193), .init(x: 200, y: 87), .init(x: 330, y: 193)], width: 3, dashed: true)
                slab(.init(x: 78, y: 295, width: 244, height: 28))
            case .terraces:
                for index in 0..<3 {
                    let x = CGFloat(22 + index * 122)
                    let y = CGFloat(214 - index * 67)
                    slab(.init(x: x, y: y, width: 110, height: 104), radius: 5)
                    for step in 0..<4 {
                        let sy = y + 34 + CGFloat(step * 14)
                        line([.init(x: x + 90, y: sy), .init(x: x + 116, y: sy - 14)], width: 4)
                    }
                }
            case .foundry:
                line([.init(x: 100, y: 98), .init(x: 300, y: 98), .init(x: 300, y: 288), .init(x: 100, y: 288), .init(x: 100, y: 98)], width: 15)
                line([.init(x: 100, y: 98), .init(x: 300, y: 288)], width: 3, dashed: true)
                line([.init(x: 300, y: 98), .init(x: 100, y: 288)], width: 3, dashed: true)
                for x in [100.0, 300] {
                    for y in [98.0, 288] {
                        slab(.init(x: x - 43, y: y - 28, width: 86, height: 60), radius: 30)
                    }
                }
                let hub = Path(ellipseIn: .init(x: 178, y: 173, width: 44, height: 44))
                context.fill(hub, with: .color(Palette.paper))
                context.stroke(hub, with: .color(edge), lineWidth: 4)
            case .signals:
                slab(.init(x: 35, y: 68, width: 330, height: 235), radius: 8)
                for x in [68.0, 200, 332] {
                    line([.init(x: x, y: 84), .init(x: x, y: 276)], width: 2)
                }
                for y in [130.0, 180, 230] {
                    line([.init(x: 68, y: y), .init(x: 332, y: y)], width: 1, dashed: true)
                }
                for x in [112.0, 244] {
                    context.stroke(Path(ellipseIn: .init(x: x, y: 159, width: 38, height: 38)), with: .color(edge), lineWidth: 2)
                }
            case .orchard:
                for (x, y, width) in [(30.0, 70.0, 95.0), (275, 70, 95), (58, 177, 124), (218, 177, 124)] {
                    slab(.init(x: x, y: y, width: width, height: 57), radius: 28)
                    for row in 0..<3 {
                        line([.init(x: x + 17, y: y + 14 + Double(row * 12)), .init(x: x + width - 17, y: y + 14 + Double(row * 12))], width: 1)
                    }
                }
                var trail = Path()
                trail.move(to: .init(x: 90, y: 332))
                trail.addCurve(to: .init(x: 310, y: 332), control1: .init(x: -20, y: 128), control2: .init(x: 420, y: 128))
                context.stroke(trail, with: .color(edge), style: StrokeStyle(lineWidth: 3, dash: [2, 7]))
            case .compass:
                for radius in [135.0, 121] {
                    context.stroke(Path(ellipseIn: .init(x: 200 - radius, y: 174 - radius, width: radius * 2, height: radius * 2)), with: .color(edge), lineWidth: 2)
                }
                for tick in 0..<32 {
                    let angle = Double(tick) * .pi / 16
                    let inner = tick % 4 == 0 ? 106.0 : 115
                    line([.init(x: 200 + cos(angle) * inner, y: 174 + sin(angle) * inner), .init(x: 200 + cos(angle) * 121, y: 174 + sin(angle) * 121)], width: 1)
                }
                line([.init(x: 68, y: 174), .init(x: 332, y: 174)], width: 1, dashed: true)
                line([.init(x: 200, y: 42), .init(x: 200, y: 306)], width: 1, dashed: true)
                var center = Path()
                center.addLines([.init(x: 200, y: 151), .init(x: 223, y: 174), .init(x: 200, y: 197), .init(x: 177, y: 174)])
                center.closeSubpath()
                context.fill(center, with: .color(edge))
            }
        }.accessibilityHidden(true)
    }
}

struct ObjectGlyph: View {
    let object: PuzzleObject
    var large = false
    var color: Color { object.pigment?.color ?? Color(hex: 0xB9B9B3) }
    var body: some View {
        ZStack {
            if object.pigment == .yellow {
                Circle().fill(color.opacity(0.14)).frame(width: 94, height: 94).blur(radius: 9)
            }
            switch object.kind {
            case .door:
                ZStack(alignment: .bottom) {
                    Arch().fill(Palette.ink.opacity(0.18)).frame(width: 58, height: 86).offset(x: 7, y: 3)
                    Arch().fill(Color(hex: 0xEEEEE9)).frame(width: 62, height: 91)
                    Arch().stroke(Palette.ink.opacity(0.5), lineWidth: 1).frame(width: 62, height: 91)
                    Arch().fill(object.pigment == .red ? color : Palette.ink).frame(width: 42, height: 75)
                    Arch().stroke(color, lineWidth: 3).frame(width: 42, height: 75)
                    Image(systemName: object.pigment == .red ? "arrow.up.right" : "minus")
                        .font(.system(size: 16, weight: .medium)).foregroundStyle(object.pigment == .red ? Palette.ink : Color.white.opacity(0.4)).padding(.bottom, 23)
                }
            case .bridge:
                VStack(spacing: 0) {
                    ForEach(0..<4) { _ in
                        RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 63, height: 9)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Palette.ink.opacity(0.3), lineWidth: 0.7)).padding(.bottom, 2)
                    }
                }.rotationEffect(.degrees(-27)).scaleEffect(x: 1, y: 0.8)
            case .vine:
                VStack(spacing: -3) {
                    Image(systemName: object.pigment == .green ? "tree.fill" : "leaf.fill")
                        .font(.system(size: object.pigment == .green ? 43 : 25, weight: .light)).foregroundStyle(color)
                    Rectangle().fill(Palette.ink.opacity(0.6)).frame(width: 2, height: object.pigment == .green ? 20 : 12)
                    Ellipse().fill(Palette.ink.opacity(0.12)).frame(width: 28, height: 7)
                }
            case .lantern:
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 5).stroke(Palette.ink, lineWidth: 2).frame(width: 12, height: 9)
                    RoundedRectangle(cornerRadius: 5).fill(color).frame(width: 28, height: 32)
                        .overlay(Image(systemName: "sun.max").font(.system(size: 15)).foregroundStyle(Palette.ink.opacity(0.6)))
                    Rectangle().fill(Palette.ink).frame(width: 35, height: 4)
                    Rectangle().fill(Palette.ink).frame(width: 3, height: 20)
                    Ellipse().fill(Palette.ink.opacity(0.2)).frame(width: 26, height: 6)
                }
            case .button, .lift, .reservoir:
                VStack(spacing: -5) {
                    ZStack {
                        Ellipse().fill(color.opacity(0.7)).frame(width: 45, height: 23).offset(y: 7)
                        Ellipse().fill(color).frame(width: 45, height: 23)
                        Image(systemName: object.kind.symbol).font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.7)).scaleEffect(y: 0.75)
                    }
                    Rectangle().fill(Color(hex: 0xCFCFC9)).frame(width: 38, height: object.kind == .lift && object.pigment == .red ? 39 : 21).zIndex(-1)
                    Ellipse().fill(Color(hex: 0xB0B0AA)).frame(width: 38, height: 17).zIndex(-2)
                }
            }
        }
        .frame(width: 84, height: 102)
        .scaleEffect(large ? 1.18 : 0.86)
        .accessibilityHidden(true)
    }
}

struct PuzzleBoard: View {
    let objects: [PuzzleObject]
    var scene: BoardScene = .courtyard
    var interactive = true
    var held: Pigment?
    var action: (String) -> Void = { _ in }
    var body: some View {
        GeometryReader { geometry in
            let tile = BoardGeometry.tileSize(in: geometry.size)
            ZStack {
                if scene == .courtyard { WorldGround() }
                else { SceneGround(scene: scene) }
                ForEach(objects) { object in
                    Button { action(object.id) } label: {
                        VStack(spacing: -5) {
                            ObjectGlyph(object: object)
                                .scaleEffect(min(1, (tile.height - 22) / 80))
                                .frame(width: tile.width, height: tile.height - 16)
                            if !object.name.isEmpty {
                                Text(object.name).font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(0.5)
                                    .foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7).padding(.horizontal, 5).padding(.vertical, 4)
                                    .background(Palette.paper.opacity(0.93), in: Capsule())
                            }
                        }
                        .frame(width: tile.width, height: tile.height)
                        .background {
                            if held != nil && object.pigment == nil && interactive {
                                Circle().stroke(held?.color.opacity(0.7) ?? Palette.line, style: StrokeStyle(lineWidth: 1, dash: [3, 4])).frame(width: min(70, tile.width - 4), height: min(70, tile.height - 4))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).allowsHitTesting(interactive)
                    .position(BoardGeometry.position(for: object, in: geometry.size))
                    .accessibilityLabel("\(object.name), \(object.pigment?.title ?? "colorless"), \(object.pigment?.state ?? "dormant")")
                    .accessibilityHint(held == nil ? "Collect color" : "Place collected color")
                }
            }
        }
        .aspectRatio(1.08, contentMode: .fit)
        .background(Color(hex: 0xEEEEEA), in: RoundedRectangle(cornerRadius: 24))
    }
}

struct HeroWorld: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            PuzzleBoard(objects: [
                .init(id: "door", name: "Give", kind: .door, pigment: nil, x: 0.70, y: 0.39),
                .init(id: "switch", name: "Take", kind: .button, pigment: .red, x: 0.28, y: 0.64),
                .init(id: "bridge", name: "Anchor", kind: .bridge, pigment: .blue, x: 0.53, y: 0.62),
                .init(id: "plant", name: "", kind: .vine, pigment: nil, x: 0.80, y: 0.78)
            ], interactive: false)
            HStack(spacing: 6) {
                Circle().fill(Palette.ink).frame(width: 5, height: 5)
                Text("A WORLD WAITING FOR YOU").font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1.1)
            }.padding(18)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("An isometric monochrome world with a red switch, a blue bridge and a quiet doorway")
    }
}
