import Combine

public extension Array {
    func tryMapAsync<T>(_ block: @escaping (Element) async throws -> T) async throws -> [T] {
        guard let element = first else {
            return []
        }
        let output = try await block(element)
        let rest = try await dropFirst().map { $0 }.tryMapAsync(block)
        return [output] + rest
    }
}
