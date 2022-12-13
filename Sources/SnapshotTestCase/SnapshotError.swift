import Foundation

public enum SnapshotError: Error {
    case loadSnapshot
    case invalidContext
    case takeSnapshot
    case saveSnapshot(Error)
    case copySnapshot(Error)
    case deleteSnapshot(Error)
    case pngRepresentation
    case referenceImageDoesNotExist
    case createFolder(Error)
    case createView
    case didRecord
    case comparison(Error)
    case referenceImageNotEqual(Double)
    case cropSnapshot
}
