import Combine
import Foundation

extension Publisher {
    static func success(_ output: Output) -> AnyPublisher<Output, Failure> {
        Just(output)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }

    static func failure(_ failure: Failure) -> AnyPublisher<Output, Failure> {
        Future { $0(.failure(failure)) }.eraseToAnyPublisher()
    }

    func wait(
        _ timeout: TimeInterval,
        on queue: DispatchQueue = .main,
        on condition: @escaping (Output) -> Bool = { _ in true }
    ) -> AnyPublisher<Output, Failure> {
        flatMap { output -> AnyPublisher<Output, Failure> in
            guard condition(output) else {
                return .success(output)
            }
            return Future { promise in
                queue.asyncAfter(deadline: .now() + timeout) {
                    promise(.success(()))
                }
            }
            .map { _ in output }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    func `do`(_ block: @escaping (Output) -> Void) -> AnyPublisher<Output, Failure> {
        map { output in
            block(output)
            return output
        }
        .eraseToAnyPublisher()
    }
}

extension Publishers {
    static func Serial<Output, Failure>(
        _ publishers: [AnyPublisher<Output, Failure>]
    ) -> AnyPublisher<[Output], Failure> {
        if let publisher = publishers.first {
            return publisher.flatMap { output -> AnyPublisher<[Output], Failure> in
                let rest = Array(publishers.suffix(from: 1))
                return Publishers.Serial(rest)
                    .map { [output] + $0 }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        } else {
            return .success([])
        }
    }
}
