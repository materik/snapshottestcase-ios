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
        renderDelay: TimeInterval = 0.4,
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
        renderDelay: TimeInterval = 0.4,
        file: StaticString = #file,
        line: UInt = #line,
        viewControllerBuilder: @escaping () -> some UIViewController
    ) throws {
        guard let (suite, testCaseName) = getMetadata(file: file) else {
            return XCTFail("Was not able to parse testCase suite and name")
        }
        let testCase = Snapshot.TestCase(
            suite: suite,
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

    private func getMetadata(file: StaticString = #file) -> (suite: String, name: String)? {
        let suite = "\(file)"
            .replacingOccurrences(of: Snapshot().referencePath, with: "")
            .split(separator: "/")
            .first
        let testCase = name
            .replacingOccurrences(of: "-[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "Tests", with: "")
            .replacingFirst(of: "testCase", with: "")
            .split(separator: " ")
            .map { String($0) }
        guard let suite = suite?.string,
              let testCaseName = testCase.first,
              let name = testCase.last else {
            return nil
        }
        if testCaseName == name {
            return (suite: suite, name: testCaseName)
        } else {
            return (suite: suite, name: name.prepending("\(testCaseName)_"))
        }
    }
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
