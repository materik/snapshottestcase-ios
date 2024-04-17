import Foundation

public enum SnapshotError: Error {
    case loadSnapshot
    case invalidContext
    case takeSnapshot
    case saveSnapshot(Error)
    case copySnapshot(Error)
    case deleteSnapshot(Error)
    case imageData
    case referenceImageDoesNotExist
    case createFolder(Error)
    case createView
    case didRecord
    case comparison(Error)
    case referenceImageNotEqual(Double)
    case cropSnapshot
    case timeout(String)
    case unknown(Error)
}

extension Error {
    func asSnapshotError() -> SnapshotError {
        if let error = self as? SnapshotError {
            return error
        } else {
            return .unknown(self)
        }
    }
}
