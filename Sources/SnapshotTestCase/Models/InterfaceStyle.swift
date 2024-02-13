import UIKit

public enum InterfaceStyle: String, Identifiable, Sendable {
    case light
    case dark

    public var id: String { rawValue }
}

public extension InterfaceStyle {
    static var `default`: InterfaceStyle = .light
}

extension InterfaceStyle {
    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}
