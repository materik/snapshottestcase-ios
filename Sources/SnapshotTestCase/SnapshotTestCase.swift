import Combine
import SwiftUI
import UIKit
import XCTest

let snapshot = Snapshot()

public protocol SnapshotTestCase: AnyObject { }

public extension SnapshotTestCase where Self: XCTestCase {
    func verifySnapshot(
        suffix: String? = nil,
        size: Snapshot.Size = .normal,
        configs: [Snapshot.Config] = .default,
        renderDelay: TimeInterval = 0.4,
        file: StaticString = #file,
        line: UInt = #line,
        viewBuilder: @escaping () -> some View
    ) throws {
        try verifySnapshot(
            suffix: suffix,
            size: size,
            configs: configs,
            renderDelay: renderDelay,
            file: file,
            line: line,
            viewControllerBuilder: { UIHostingController(rootView: viewBuilder()) }
        )
    }

    func verifySnapshot(
        suffix: String? = nil,
        size: Snapshot.Size = .normal,
        configs: [Snapshot.Config] = .default,
        renderDelay: TimeInterval = 0.4,
        file: StaticString = #file,
        line: UInt = #line,
        viewControllerBuilder: @escaping () -> some UIViewController
    ) throws {
        guard let (suite, name) = getTestCase(file: file) else {
            return XCTFail("Was not able to parse test suite and name")
        }
        let test = Snapshot.TestCase(
            suite: suite,
            name: name,
            suffix: suffix,
            size: size,
            renderDelay: renderDelay,
            viewControllerBuilder: viewControllerBuilder
        )
        try execute(
            snapshot.verify(test: test, with: configs),
            timeout: TimeInterval(10 * configs.count) * renderDelay,
            file: file,
            line: line
        )
    }

    private func getTestCase(file: StaticString = #file) -> (suite: String, name: String)? {
        let suite = "\(file)"
            .replacingOccurrences(of: Snapshot().referencePath, with: "")
            .split(separator: "/")
            .first
        let testCase = name
            .replacingOccurrences(of: "-[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "Tests", with: "")
            .replacingFirst(of: "test", with: "")
            .split(separator: " ")
            .map { String($0) }
        guard let suite = suite?.string,
              let suiteName = testCase.first,
              let name = testCase.last else {
            return nil
        }
        if suiteName == name {
            return (suite: suite, name: suiteName)
        } else {
            return (suite: suite, name: name.prepending("\(suiteName)_"))
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
