import XCTest
import SwiftUI
import SnapshotTestCase

class SnapshotTestCaseTests: XCTestCase, SnapshotTestCase {
    func test() throws {
        try verifySnapshot {
            VStack {
                Rectangle().foregroundColor(.blue)
                Circle().foregroundColor(.yellow)
            }
        }
    }
}
