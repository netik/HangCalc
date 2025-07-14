import SwiftUI

// Helper view for CAD-style measurement arrow with label
struct MeasurementArrow: View {
    let start: CGPoint
    let end: CGPoint
    let label: String
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // Complete arrow with heads drawn as part of the path
            ArrowPath(start: start, end: end)
                .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 2, dash: [6]))
            
            // Label
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.cardBackground.opacity(0.9))
                .cornerRadius(4)
                .position(midpoint(start, end).offsetBy(dx: 0, dy: -12, flippedY: true))
        }
    }
    
    // Helper to compute midpoint
    func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

// Separate path for the arrow to reduce complexity
struct ArrowPath: Shape {
    let start: CGPoint
    let end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let arrowLength: CGFloat = 8
        let arrowAngle: CGFloat = 0.5 // radians, about 30 degrees
        
        // Calculate the direction vector
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        let unitX = dx / length
        let unitY = dy / length
        
        // Draw the main line
        path.move(to: start)
        path.addLine(to: end)
        
        // Draw arrow head at start (pointing toward the line)
        let startArrowTip = CGPoint(
            x: start.x + arrowLength * unitX,
            y: start.y + arrowLength * unitY
        )
        let startLeftWing = CGPoint(
            x: startArrowTip.x - arrowLength * cos(arrowAngle) * unitX + arrowLength * sin(arrowAngle) * unitY,
            y: startArrowTip.y - arrowLength * cos(arrowAngle) * unitY - arrowLength * sin(arrowAngle) * unitX
        )
        let startRightWing = CGPoint(
            x: startArrowTip.x - arrowLength * cos(arrowAngle) * unitX - arrowLength * sin(arrowAngle) * unitY,
            y: startArrowTip.y - arrowLength * cos(arrowAngle) * unitY + arrowLength * sin(arrowAngle) * unitX
        )
        
        path.move(to: startArrowTip)
        path.addLine(to: startLeftWing)
        path.move(to: startArrowTip)
        path.addLine(to: startRightWing)
        
        // Draw arrow head at end (pointing away from the line)
        let endArrowTip = CGPoint(
            x: end.x - arrowLength * unitX,
            y: end.y - arrowLength * unitY
        )
        let endLeftWing = CGPoint(
            x: endArrowTip.x + arrowLength * cos(arrowAngle) * unitX + arrowLength * sin(arrowAngle) * unitY,
            y: endArrowTip.y + arrowLength * cos(arrowAngle) * unitY - arrowLength * sin(arrowAngle) * unitX
        )
        let endRightWing = CGPoint(
            x: endArrowTip.x + arrowLength * cos(arrowAngle) * unitX - arrowLength * sin(arrowAngle) * unitY,
            y: endArrowTip.y + arrowLength * cos(arrowAngle) * unitY + arrowLength * sin(arrowAngle) * unitX
        )
        
        path.move(to: endArrowTip)
        path.addLine(to: endLeftWing)
        path.move(to: endArrowTip)
        path.addLine(to: endRightWing)
        
        return path
    }
}



// Helper for offset with flipped y
extension CGPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat, flippedY: Bool = false) -> CGPoint {
        if flippedY {
            return CGPoint(x: x + dx, y: y - dy)
        } else {
            return CGPoint(x: x + dx, y: y + dy)
        }
    }
}

// New wrapper view for zoom and scroll
struct WallScrollView: View {
    let wall: Wall
    let layouts: [PaintingLayout]
    @ObservedObject var viewModel: HangCalcViewModel
    @State private var scale: CGFloat = 1.0 // Default scale (1 px/cm)
    @GestureState private var gestureScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            // Visualization area background
            VStack(spacing: 8) {
                // Table of painting info
                if !layouts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header row
                            HStack(spacing: 0) {
                                Text("Name")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 80, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                
                                Text("Type")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 60, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                
                                Text("Offsets")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                
                                Text("Hanger(s)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 100, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                            }
                            .background(Color(.systemGray5))
                            
                            // Data rows
                            ForEach(layouts) { layout in
                                HStack(spacing: 0) {
                                    Text(layout.painting.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 80, alignment: .leading)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                    
                                    switch layout.painting.mountType {
                                    case .wire(let offset):
                                        Text("Wire")
                                            .font(.caption)
                                            .frame(width: 60, alignment: .leading)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                        
                                        Text("Top: \(viewModel.formatForDisplay(offset)) \(viewModel.selectedUnit.shortName)")
                                            .font(.caption)
                                            .frame(width: 120, alignment: .leading)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                        
                                        if layout.mountingPoints.count == 1 {
                                            let hanger = layout.mountingPoints[0]
                                            Text("(\(viewModel.formatCoordinate(hanger.x)), \(viewModel.formatCoordinate(hanger.y)))")
                                                .font(.caption2)
                                                .frame(width: 100, alignment: .leading)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                        } else {
                                            Text("-")
                                                .font(.caption)
                                                .frame(width: 100, alignment: .leading)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                        }
                                        
                                    case .dRing(let offsetTop, let offsetEdge):
                                        Text("D-Ring")
                                            .font(.caption)
                                            .frame(width: 60, alignment: .leading)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                        
                                        Text("T:\(viewModel.formatForDisplay(offsetTop)), E:\(viewModel.formatForDisplay(offsetEdge))")
                                            .font(.caption)
                                            .frame(width: 120, alignment: .leading)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                        
                                        if layout.mountingPoints.count == 2 {
                                            let left = layout.mountingPoints[0]
                                            let right = layout.mountingPoints[1]
                                            let dist = hypot(right.x - left.x, right.y - left.y)
                                            Text("Δ=\(viewModel.formatForDisplay(dist)) \(viewModel.selectedUnit.shortName)")
                                                .font(.caption2)
                                                .frame(width: 100, alignment: .leading)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                        } else {
                                            Text("-")
                                                .font(.caption)
                                                .frame(width: 100, alignment: .leading)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .background(Color(.systemGray6))
                                
                                // Add separator between rows
                                if layout.id != layouts.last?.id {
                                    Divider()
                                        .background(Color(.systemGray4))
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
                HStack(spacing: 16) {
                    Button(action: { scale *= 1.2 }) {
                        Image(systemName: "plus.magnifyingglass")
                            .foregroundColor(AppColors.primary)
                            .font(.title3)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: { scale /= 1.2 }) {
                        Image(systemName: "minus.magnifyingglass")
                            .foregroundColor(AppColors.primary)
                            .font(.title3)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Text(String(format: "Scale: %.1f px/%@", scale * gestureScale, viewModel.selectedUnit.shortName))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.secondary.opacity(0.3))
                        .cornerRadius(6)
                }
                .padding(.bottom, 4)
                GeometryReader { geo in
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        WallView(wall: wall, layouts: layouts, scale: scale * gestureScale, viewModel: viewModel)
                            .contentShape(Rectangle())
                            .gesture(
                                MagnificationGesture()
                                    .updating($gestureScale) { value, state, _ in
                                        state = value
                                    }
                                    .onEnded { value in
                                        scale *= value
                                    }
                            )
                            .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            .background(Color(UIColor.systemGray5))
            .cornerRadius(16)
        }
    }
}

struct WallView: View {
    let wall: Wall
    let layouts: [PaintingLayout]
    let scale: CGFloat
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        GeometryReader { geo in
            let wallRect = CGRect(x: 0, y: 0, width: wall.width * scale, height: wall.height * scale)
            
            // Calculate centering offset
            let centerX = (geo.size.width - wallRect.width) / 2
            let centerY = (geo.size.height - wallRect.height) / 2
            
            ZStack(alignment: .topLeading) {
                // Wall
                Rectangle()
                    .stroke(AppColors.primary, lineWidth: 3)
                    .background(Rectangle().fill(AppColors.background))
                    .frame(width: wallRect.width, height: wallRect.height)
                // Paintings
                if (layouts.count > 0) {
                    ForEach(layouts) { layout in
                        let rect = CGRect(x: layout.origin.x * scale, y: (wall.height - layout.origin.y - layout.painting.height) * scale, width: layout.painting.width * scale, height: layout.painting.height * scale)
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(AppColors.accent.opacity(0.2))
                                .frame(width: rect.width, height: rect.height)
                                .overlay(
                                    Rectangle().stroke(AppColors.accent, lineWidth: 2)
                                )
                            Text(layout.painting.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(6)
                                .background(AppColors.cardBackground.opacity(0.9))
                                .cornerRadius(6)
                                .frame(width: rect.width, height: rect.height, alignment: .center)
                                .multilineTextAlignment(.center)
                            // Mounting points (flip y so 0 is top of painting)
                            ForEach(Array(layout.mountingPoints.enumerated()), id: \.0) { idx, point in
                                Circle()
                                    .fill(AppColors.success)
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.cardBackground, lineWidth: 2)
                                    )
                                    .position(x: (point.x - layout.origin.x) * scale, y: (layout.painting.height - (point.y - layout.origin.y)) * scale)
                            }
                        }
                        .offset(x: rect.minX, y: rect.minY)
                    }
                    // Measurement arrows between paintings
                    ForEach(0..<(layouts.count - 1), id: \.self) { i in
                        let left = layouts[i]
                        let right = layouts[i + 1]
                        let leftEdge = CGPoint(x: (left.origin.x + left.painting.width) * scale, y: (wall.height - (left.origin.y + left.painting.height / 2)) * scale)
                        let rightEdge = CGPoint(x: right.origin.x * scale, y: (wall.height - (right.origin.y + right.painting.height / 2)) * scale)
                        let distanceCm = (right.origin.x - (left.origin.x + left.painting.width))
                        MeasurementArrow(
                            start: leftEdge,
                            end: rightEdge,
                            label: "\(viewModel.formatForDisplay(distanceCm)) \(viewModel.selectedUnit.shortName)",
                            scale: scale
                        )
                    }
                    // Measurement from leftmost painting to wall left
                    if let first = layouts.first {
                        let wallLeft = CGPoint(x: 0, y: (wall.height - (first.origin.y + first.painting.height / 2)) * scale)
                        let paintingLeft = CGPoint(x: first.origin.x * scale, y: (wall.height - (first.origin.y + first.painting.height / 2)) * scale)
                        let distanceCm = first.origin.x
                        MeasurementArrow(
                            start: wallLeft,
                            end: paintingLeft,
                            label: "\(viewModel.formatForDisplay(distanceCm)) \(viewModel.selectedUnit.shortName)",
                            scale: scale
                        )
                    }
                    // Measurement from rightmost painting to wall right
                    if let last = layouts.last {
                        let wallRight = CGPoint(x: wall.width * scale, y: (wall.height - (last.origin.y + last.painting.height / 2)) * scale)
                        let paintingRight = CGPoint(x: (last.origin.x + last.painting.width) * scale, y: (wall.height - (last.origin.y + last.painting.height / 2)) * scale)
                        let distanceCm = wall.width - (last.origin.x + last.painting.width)
                        MeasurementArrow(
                            start: paintingRight,
                            end: wallRight,
                            label: "\(viewModel.formatForDisplay(distanceCm)) \(viewModel.selectedUnit.shortName)",
                            scale: scale
                        )
                    }
                    // Measurements from top and bottom of each painting to wall edges
                    ForEach(layouts) { layout in
                        // Top to wall top
                        let paintingTop = CGPoint(x: (layout.origin.x + layout.painting.width / 2) * scale, y: (wall.height - layout.origin.y - layout.painting.height) * scale)
                        let wallTop = CGPoint(x: (layout.origin.x + layout.painting.width / 2) * scale, y: 0)
                        let topDistance = wall.height - (layout.origin.y + layout.painting.height)
                        MeasurementArrow(
                            start: paintingTop,
                            end: wallTop,
                            label: "\(viewModel.formatForDisplay(topDistance)) \(viewModel.selectedUnit.shortName)",
                            scale: scale
                        )
                        // Bottom to wall bottom
                        let paintingBottom = CGPoint(x: (layout.origin.x + layout.painting.width / 2) * scale, y: (wall.height - layout.origin.y) * scale)
                        let wallBottom = CGPoint(x: (layout.origin.x + layout.painting.width / 2) * scale, y: wall.height * scale)
                        let bottomDistance = layout.origin.y
                        MeasurementArrow(
                            start: wallBottom,
                            end: paintingBottom,
                            label: "\(viewModel.formatForDisplay(bottomDistance)) \(viewModel.selectedUnit.shortName)",
                            scale: scale
                        )
                    }
                }
            }
            .frame(width: wallRect.width, height: wallRect.height)
            .offset(x: centerX, y: centerY)
        }
        .aspectRatio(wall.width / wall.height, contentMode: .fit)
    }
} 
