import Foundation

extension String {
    var uppercasedFirst: String {
        guard let first else {
            return ""
        }
        return String(first).uppercased() + dropFirst()
    }
}
