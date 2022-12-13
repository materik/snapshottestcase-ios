import Combine
import XCTest

public extension XCTestCase {
    func await<Output, Failure>(
        _ publisher: AnyPublisher<Output, Failure>,
        onCancel: ((@escaping (Result<Output, Failure>) -> Void) -> Void)? = nil,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Result<Output, Failure> {
        var result: Result<Output, Failure>?

        let expectation = expectation(description: "Awaiting publisher \(line)")
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                    expectation.fulfill()
                case .finished:
                    break
                }
            },
            receiveValue: { value in
                result = .success(value)
                expectation.fulfill()
            }
        )

        onCancel? { _result in
            expectation.fulfill()
            cancellable.cancel()
            result = _result
        }

        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return unwrappedResult
    }

    func execute(
        _ publisher: AnyPublisher<some Any, some Any>,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let result = try self.await(publisher, timeout: timeout, file: file, line: line)
        switch result {
        case .success: break
        case .failure(let error): throw error
        }
    }

    func wait(_ timeInterval: TimeInterval) throws {
        _ = try self.await(
            .success(())
                .wait(timeInterval)
                .setFailureType(to: Never.self)
                .eraseToAnyPublisher()
        )
        .get()
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
