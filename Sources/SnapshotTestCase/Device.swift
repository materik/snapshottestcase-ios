import UIKit

public struct Device: Identifiable {
    public let name: String
    public let width: CGFloat
    public let height: CGFloat
    
    public init(name: String, width: CGFloat, height: CGFloat, resolution: CGFloat = 1) {
        self.name = name
        self.width = width / resolution
        self.height = height / resolution
    }
    
    public var id: String { name }
}

public extension Device {
    static let d4dot7 = Device(name: "4.7", width: 750, height: 1334, resolution: 2)
    static let d6dot1 = Device(name: "6.1", width: 1179, height: 2556, resolution: 3)
    static let d6dot7 = Device(name: "6.7", width: 1290, height: 2796, resolution: 3)
    
    static var `default`: Device { .d6dot1 }
}
