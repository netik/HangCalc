import Foundation
import CoreGraphics

struct PaintingLayout: Identifiable {
    var id: UUID { painting.id }
    let painting: Painting
    let origin: CGPoint // Bottom-left corner of painting on wall
    let mountingPoints: [CGPoint] // Relative to wall origin
}

struct LayoutCalculator {
    static func calculateLayouts(wall: Wall, paintings: [Painting], spacing: CGFloat = 20) -> [PaintingLayout] {
        guard !paintings.isEmpty else { return [] }
        let totalWidth = paintings.reduce(0) { $0 + $1.width } + CGFloat(paintings.count - 1) * spacing
        let startX = (wall.width - totalWidth) / 2
        let centerY = wall.height / 2
        var layouts: [PaintingLayout] = []
        var currentX = startX
        for painting in paintings {
            let origin = CGPoint(x: currentX, y: centerY - painting.height / 2)
            let mountingPoints: [CGPoint]
            switch painting.mountType {
            case .dRing(let offsetFromTop, let offsetFromEdge):
                // D-rings: offset from top and from edge
                let y = origin.y + painting.height - offsetFromTop
                let left = CGPoint(x: origin.x + offsetFromEdge, y: y)
                let right = CGPoint(x: origin.x + painting.width - offsetFromEdge, y: y)
                mountingPoints = [left, right]
            case .wire(let offset):
                // Wire: midpoint, offset from top
                let x = origin.x + painting.width / 2
                let y = origin.y + painting.height - offset
                mountingPoints = [CGPoint(x: x, y: y)]
            }
            layouts.append(PaintingLayout(painting: painting, origin: origin, mountingPoints: mountingPoints))
            currentX += painting.width + spacing
        }
        return layouts
    }
    
    static func calculateAutoSpacing(wall: Wall, paintings: [Painting]) -> CGFloat {
        guard paintings.count > 1 else { return 200 } // Default for single painting
        
        let totalPaintingWidth = paintings.reduce(0) { $0 + $1.width }
        let availableSpace = wall.width - totalPaintingWidth
        let numberOfGaps = paintings.count - 1
        
        // Ensure minimum spacing of 20cm, but distribute evenly if possible
        let minimumSpacing: CGFloat = 20
        let calculatedSpacing = availableSpace / CGFloat(numberOfGaps)
        
        return max(calculatedSpacing, minimumSpacing)
    }
} 