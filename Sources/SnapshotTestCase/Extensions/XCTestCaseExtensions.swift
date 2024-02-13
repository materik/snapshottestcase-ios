import Combine
import XCTest

public extension XCTestCase {
    func execute(
        _ publisher: AnyPublisher<some Any, some Any>,
        timeout: TimeInterval = 5,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async throws {
        _ = try await publisher.async(timeout: timeout, file: file, function: function, line: line)
    }

    func wait(_ timeInterval: TimeInterval) async throws {
        try await Task.sleep(for: .seconds(timeInterval))
    }
}

public extension Result {
    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}
