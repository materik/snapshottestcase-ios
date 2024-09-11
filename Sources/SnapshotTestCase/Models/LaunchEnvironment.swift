import Foundation

enum LaunchEnvironment {
    enum Key {
        static let referencePath: String = "snapshotReferences"
        static let failurePath: String = "snapshotFailures"
        static let tolerance: String = "snapshotTolerance"
        static let renderOffsetY: String = "snapshotRenderOffsetY"
        static let renderScale: String = "snapshotRenderScale"
        static let interfaceStyle: String = "snapshotInterfaceStyle"
        static let recordMode: String = "-RecordingSnapshot"
    }

    static var referencePath: String {
        ProcessInfo.processInfo.environment[Key.referencePath] ?? "."
    }

    static var failurePath: String {
        ProcessInfo.processInfo.environment[Key.failurePath] ?? "../_Failures"
    }

    static var recordMode: Bool {
        ProcessInfo.processInfo.arguments.contains(Key.recordMode)
    }

    static var tolerance: Double {
        guard let tolerance = ProcessInfo.processInfo.environment[Key.tolerance] else {
            return 0
        }
        return Double(tolerance) ?? 0
    }

    static var renderOffsetY: CGFloat {
        guard let renderOffsetY = ProcessInfo.processInfo.environment[Key.renderOffsetY] else {
            return 0
        }
        return Double(renderOffsetY) ?? 0
    }

    static var renderScale: CGFloat {
        guard let renderScale = ProcessInfo.processInfo.environment[Key.renderScale] else {
            return 1
        }
        return Double(renderScale) ?? 1
    }
    
    static var interfaceStyle: InterfaceStyle? {
        guard let rawValue = ProcessInfo.processInfo.environment[Key.interfaceStyle] else {
            return nil
        }
        return InterfaceStyle(rawValue: rawValue)
    }
}
