import Combine
import SwiftUI
import UIKit
import XCTest

let snapshot = Snapshot()

public protocol SnapshotTestCase: AnyObject { }

public extension SnapshotTestCase where Self: XCTestCase {
    func verifySnapshot(
        name: String? = nil,
        config: SnapshotConfig = .default,
        imageType: SnapshotImageType = .default,
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        viewBuilder: @escaping @MainActor () -> some View
    ) async throws {
        try await verifySnapshot(
            name: name,
            config: config,
            imageType: imageType,
            renderDelay: renderDelay,
            file: file,
            function: function,
            line: line,
            viewControllerBuilder: { UIHostingController(rootView: viewBuilder()) }
        )
    }

    func verifySnapshot(
        name: String? = nil,
        config: SnapshotConfig = .default,
        imageType: SnapshotImageType = .default,
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: String = #file,
        function _: String = #function,
        line _: Int = #line,
        viewControllerBuilder: @escaping @MainActor () -> some UIViewController
    ) async throws {
        let testCase = Snapshot.TestCase(
            filePath: getFilePath(file: file),
            name: name ?? getTestCaseName() ?? "Test",
            imageType: imageType,
            renderDelay: renderDelay,
            viewControllerBuilder: viewControllerBuilder
        )
        try await snapshot.verify(testCase: testCase, with: config)
    }

    private func getFilePath(file: String = #file) -> URL {
        URL(fileURLWithPath: file)
            .deletingLastPathComponent()
    }

    private func getTestCaseName() -> String? {
        let testCase = name
            .replacingOccurrences(of: "-[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "Tests", with: "")
            .replacingFirst(of: "test", with: "")
            .split(separator: " ")
            .map { String($0) }
        guard let testCaseName = testCase.first,
              let name = testCase.last else {
            return nil
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
