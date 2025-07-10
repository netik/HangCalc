import Foundation

enum MountType: Hashable, Identifiable {
    case dRing(offsetFromTop: CGFloat, offsetFromEdge: CGFloat)
    case wire(offsetFromTop: CGFloat)
    
    var id: String {
        switch self {
        case .dRing(let top, let edge): return "dRing_\(top)_\(edge)"
        case .wire(let offset): return "wire_\(offset)"
        }
    }
} 