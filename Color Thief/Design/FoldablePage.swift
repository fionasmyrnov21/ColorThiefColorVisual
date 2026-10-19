import SwiftUI

struct FoldablePage<Primary: View, Secondary: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    let primary: Primary
    let secondary: Secondary

    init(@ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Secondary) {
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        GeometryReader { geometry in
            if #available(iOS 27.1, *) {
                let divisions = geometry.reservedRegions(kind: .division).filter(\.isActive)
                if usesPanes(in: geometry.size) || !divisions.isEmpty {
                    ArrangementView {
                        pane { primary }
                    } secondary: {
                        pane { secondary }
                    }
                    .arrangementViewStyle(.split)
                } else {
                    compactContent
                }
            } else if usesPanes(in: geometry.size) {
                HStack(alignment: .top, spacing: 0) {
                    pane { primary }
                    pane { secondary }
                }
            } else {
                compactContent
            }
        }.pageStyle()
    }

    private var compactContent: some View {
        ReservedRegionContent {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    primary
                    secondary
                }
                .padding(24).frame(maxWidth: 780).frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private func pane<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ReservedRegionContent {
            ScrollView {
                VStack(alignment: .leading, spacing: 26, content: content)
                    .padding(24).frame(maxWidth: 780).frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private func usesPanes(in size: CGSize) -> Bool {
        let minimumWidth: CGFloat = typeSize.isAccessibilitySize ? 1000 : 700
        return size.width >= minimumWidth && (sizeClass == .regular || size.width > size.height)
    }
}

struct ReservedRegionContent<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        if #available(iOS 27.1, *) {
            GeometryReader { geometry in
                let regions: [ReservedRegion] = geometry.reservedRegions(kind: .occlusion) + geometry.reservedRegions(kind: .division)
                let obstacles = regions.filter(\.isActive).map { region in
                    CGRect(
                        x: region.frame.minX - region.margins.leading,
                        y: region.frame.minY - region.margins.top,
                        width: region.frame.width + region.margins.leading + region.margins.trailing,
                        height: region.frame.height + region.margins.top + region.margins.bottom
                    )
                }
                let area = FoldGeometry.availableRect(in: CGRect(origin: .zero, size: geometry.size), avoiding: obstacles)
                content
                    .frame(width: area.width, height: area.height)
                    .clipped()
                    .position(x: area.midX, y: area.midY)
            }
        } else {
            content
        }
    }
}
