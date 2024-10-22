import Combine
import SwiftUI
import UIKit

let snapshot = Snapshot()

public protocol SnapshotTestCase: AnyObject { }

public extension SnapshotTestCase {
    func verifySnapshot(
        name: String = #function,
        config: SnapshotConfig = .default,
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        viewBuilder: @escaping @MainActor () -> some View
    ) async throws {
        try await verifySnapshot(
            name: name,
            config: config,
            renderDelay: renderDelay,
            file: file,
            function: function,
            line: line,
            viewControllerBuilder: { UIHostingController(rootView: viewBuilder()) }
        )
    }

    func verifySnapshot(
        name: String = #function,
        config: SnapshotConfig = .default,
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: String = #file,
        function _: String = #function,
        line _: Int = #line,
        viewControllerBuilder: @escaping @MainActor () -> some UIViewController
    ) async throws {
        let testCase = Snapshot.TestCase(
            filePath: getFilePath(file: file),
            name: getTestCaseName(name),
            renderDelay: renderDelay,
            viewControllerBuilder: viewControllerBuilder
        )
        try await snapshot.verify(testCase: testCase, with: config)
    }

    private func getFilePath(file: String = #file) -> URL {
        URL(fileURLWithPath: file)
            .deletingLastPathComponent()
    }

    private func getTestCaseName(_ name: String = #function) -> String {
        let testCase = name
            .replacingOccurrences(of: "-[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "Tests", with: "")
            .replacingFirst(of: "test", with: "")
            .split(separator: " ")
            .map { String($0) }
        guard let testCaseName = testCase.first,
              let name = testCase.last else {
            return name
        }
        return testCaseName == name
            ? testCaseName
            : name.prepending("\(testCaseName)_")
    }
}

public extension TimeInterval {
    static var snapshotRenderDelay: TimeInterval = 0.4
}

private extension String {
    func replacingFirst(of pattern: String, with replacement: String) -> String {
        if let range = range(of: pattern) {
            return replacingCharacters(in: range, with: replacement)
        } else {
            return self
        }
    }

    func prepending(_ string: String) -> String {
        "\(string)\(self)"
    }
}
