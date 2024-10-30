import SwiftUI
import UIKit
import WidgetKit

public enum InterfaceStyle: Identifiable, Sendable {
    case light
    case dark
    case widgetRenderingMode(WidgetRenderingMode)

    public var id: String {
        switch self {
        case .light: "light"
        case .dark: "dark"
        case .widgetRenderingMode(let mode): "widget\(mode.rawValue.uppercasedFirst)"
        }
    }

    init?(id: String) {
        switch id {
        case InterfaceStyle.light.id: self = .light
        case InterfaceStyle.dark.id: self = .dark
        case InterfaceStyle.widgetRenderingMode(.accented).id:
            self = .widgetRenderingMode(.accented)
        case InterfaceStyle.widgetRenderingMode(.fullColor).id:
            self = .widgetRenderingMode(.fullColor)
        case InterfaceStyle.widgetRenderingMode(.vibrant).id:
            self = .widgetRenderingMode(.vibrant)
        default: return nil
        }
    }
}

public extension InterfaceStyle {
    static var `default`: InterfaceStyle = .light
}

extension InterfaceStyle {
    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark: .dark
        case .light: .light
        case .widgetRenderingMode: .dark
        }
    }
}

// MARK: Equatable

extension InterfaceStyle: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension View {
    @ViewBuilder
    func interfaceStyle(_ interfaceStyle: InterfaceStyle) -> some View {
        switch interfaceStyle {
        case .light: environment(\.colorScheme, .light)
        case .dark: environment(\.colorScheme, .dark)
        case .widgetRenderingMode(let mode): environment(\.widgetRenderingMode, mode)
        }
    }
}

extension UIViewController {
    func interfaceStyle(_ interfaceStyle: InterfaceStyle) -> UIViewController {
        var viewController = self
        if case .widgetRenderingMode = interfaceStyle,
           let hostingController = self as? AnyUIHostingController {
            viewController = hostingController.rootViewInterfaceStyle(interfaceStyle)
        }
        viewController.overrideUserInterfaceStyle = interfaceStyle.overrideUserInterfaceStyle
        return viewController
    }
}

private protocol AnyUIHostingController: UIViewController {
    func rootViewInterfaceStyle(_ interfaceStyle: InterfaceStyle) -> UIHostingController<AnyView>
}

// MARK: - UIHostingController + AnyUIHostingController

extension UIHostingController: AnyUIHostingController {
    fileprivate func rootViewInterfaceStyle(_ interfaceStyle: InterfaceStyle)
        -> UIHostingController<AnyView> {
        .init(rootView: AnyView(rootView.interfaceStyle(interfaceStyle)))
    }
}

private extension WidgetRenderingMode {
    var rawValue: String { "\(self)" }
}
