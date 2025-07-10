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
        
        if paintings.count == 1 {
            // Single painting: center it on the wall
            let painting = paintings[0]
            let startX = (wall.width - painting.width) / 2
            let centerY = wall.height / 2
            let origin = CGPoint(x: startX, y: centerY - painting.height / 2)
            
            let mountingPoints: [CGPoint]
            switch painting.mountType {
            case .dRing(let offsetFromTop, let offsetFromEdge):
                let y = origin.y + painting.height - offsetFromTop
                let left = CGPoint(x: origin.x + offsetFromEdge, y: y)
                let right = CGPoint(x: origin.x + painting.width - offsetFromEdge, y: y)
                mountingPoints = [left, right]
            case .wire(let offset):
                let x = origin.x + painting.width / 2
                let y = origin.y + painting.height - offset
                mountingPoints = [CGPoint(x: x, y: y)]
            }
            
            return [PaintingLayout(painting: painting, origin: origin, mountingPoints: mountingPoints)]
        } else {
            // Multiple paintings: distribute evenly across the wall
            let totalPaintingWidth = paintings.reduce(0) { $0 + $1.width }
            let totalSpacing = wall.width - totalPaintingWidth
            let spacingBetweenPaintings = totalSpacing / CGFloat(paintings.count + 1) // +1 for gaps on both sides
            
            var layouts: [PaintingLayout] = []
            var currentX = spacingBetweenPaintings
            
            for painting in paintings {
                let centerY = wall.height / 2
                let origin = CGPoint(x: currentX, y: centerY - painting.height / 2)
                
                let mountingPoints: [CGPoint]
                switch painting.mountType {
                case .dRing(let offsetFromTop, let offsetFromEdge):
                    let y = origin.y + painting.height - offsetFromTop
                    let left = CGPoint(x: origin.x + offsetFromEdge, y: y)
                    let right = CGPoint(x: origin.x + painting.width - offsetFromEdge, y: y)
                    mountingPoints = [left, right]
                case .wire(let offset):
                    let x = origin.x + painting.width / 2
                    let y = origin.y + painting.height - offset
                    mountingPoints = [CGPoint(x: x, y: y)]
                }
                
                layouts.append(PaintingLayout(painting: painting, origin: origin, mountingPoints: mountingPoints))
                currentX += painting.width + spacingBetweenPaintings
            }
            
            return layouts
        }
    }
    
    static func calculateAutoSpacing(wall: Wall, paintings: [Painting]) -> CGFloat {
        guard paintings.count > 1 else { return 200 } // Default for single painting
        
        let totalPaintingWidth = paintings.reduce(0) { $0 + $1.width }
        let availableSpace = wall.width - totalPaintingWidth
        let numberOfGaps = paintings.count + 1 // +1 for gaps on both sides
        
        // Calculate even spacing across the wall
        let calculatedSpacing = availableSpace / CGFloat(numberOfGaps)
        
        // Ensure minimum spacing of 20cm
        let minimumSpacing: CGFloat = 20
        return max(calculatedSpacing, minimumSpacing)
    }
} 