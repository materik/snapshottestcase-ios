import Combine
import SwiftUI
import UIKit

let snapshot = Snapshot()

public protocol SnapshotTestCase: AnyObject { }

public extension SnapshotTestCase {
    func verifySnapshot(
        name: String? = nil,
        config: SnapshotConfig = .default,
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: String = #file,
        function: String = #function,
        viewBuilder: @escaping @MainActor () -> some View
    ) async throws {
        try await verifySnapshot(
            name: name,
            config: config,
            renderDelay: renderDelay,
            file: file,
            function: function,
            viewControllerBuilder: { UIHostingController(rootView: viewBuilder()) }
        )
    }

    func verifySnapshot(
        name: String? = nil,
        config: SnapshotConfig = .default,
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: String = #file,
        function: String = #function,
        viewControllerBuilder: @escaping @MainActor () -> some UIViewController
    ) async throws {
        let testCase = Snapshot.TestCase(
            filePath: getFilePath(file: file),
            name: name ?? getTestCaseName(file: file, function: function) ?? "Test",
            renderDelay: renderDelay,
            viewControllerBuilder: viewControllerBuilder
        )
        try await snapshot.verify(testCase: testCase, with: config)
    }

    private func getFilePath(file: String = #file) -> URL {
        URL(fileURLWithPath: file)
            .deletingLastPathComponent()
    }

    private func getTestCaseName(file: String = #file, function: String = #function) -> String? {
        let testSuite = file
            .filename
            .replacingOccurrences(of: "Tests", with: "")
        let testCase = function
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingFirst(of: "test", with: "")
            .uppercasedFirst
        return testCase == "" || testCase == testSuite
            ? testSuite
            : testCase.prepending("\(testSuite)_")
    }
}

public extension TimeInterval {
    static var snapshotRenderDelay: TimeInterval = 0.4
}
