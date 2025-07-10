import Foundation

struct Painting: Identifiable {
    let id = UUID()
    var name: String
    var width: CGFloat
    var height: CGFloat
    var mountType: MountType
} 