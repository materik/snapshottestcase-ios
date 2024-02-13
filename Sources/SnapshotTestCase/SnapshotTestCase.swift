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
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: StaticString = #file,
        line: UInt = #line,
        viewBuilder: @escaping () -> some View
    ) throws {
        try verifySnapshot(
            name: name,
            config: config,
            renderDelay: renderDelay,
            file: file,
            line: line,
            viewControllerBuilder: { UIHostingController(rootView: viewBuilder()) }
        )
    }

    func verifySnapshot(
        name: String? = nil,
        config: SnapshotConfig = .default,
        renderDelay: TimeInterval = .snapshotRenderDelay,
        file: StaticString = #file,
        line: UInt = #line,
        viewControllerBuilder: @escaping () -> some UIViewController
    ) throws {
        guard let filePath = getTestCasePath(file: file),
                let testCaseName = getTestCaseName() else {
            return XCTFail("Was not able to parse testCase")
        }
        let testCase = Snapshot.TestCase(
            filePath: filePath,
            name: name ?? testCaseName,
            renderDelay: renderDelay,
            viewControllerBuilder: viewControllerBuilder
        )
        try execute(
            snapshot.verify(testCase: testCase, with: config),
            timeout: TimeInterval(10 * config.count) * renderDelay,
            file: file,
            line: line
        )
    }
    
    private func getTestCasePath(file: StaticString = #file) -> String? {
        "\(file)"
            .split(separator: "/")
            .dropLast()
            .joined(separator: "/")
            .prepending("/")
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

private extension Substring {
    var string: String {
        String(self)
    }
}
