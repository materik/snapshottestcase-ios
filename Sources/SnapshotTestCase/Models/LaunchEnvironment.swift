import Foundation

enum LaunchEnvironment {
    enum Key {
        static let referencePath: String = "snapshotReferences"
        static let failurePath: String = "snapshotFailures"
        static let tolerance: String = "snapshotTolerance"
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
}
