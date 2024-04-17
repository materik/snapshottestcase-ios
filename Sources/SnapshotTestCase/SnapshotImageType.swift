import Foundation
import UIKit

public enum SnapshotImageType {
    case png
    case jpeg(quality: CGFloat)
    
    var pathExtension: String {
        switch self {
        case .png: "png"
        case .jpeg: "jpeg"
        }
    }
}

public extension SnapshotImageType {
    static var `default`: SnapshotImageType = .png
}

extension UIImage {
    func data(_ imageType: SnapshotImageType) -> Data? {
            switch imageType {
            case .png: self.pngData()
            case .jpeg(let quality): self.jpegData(compressionQuality: quality)
            }
    }
}
