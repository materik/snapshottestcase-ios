import Foundation

extension String {
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

    var filename: String {
        split(separator: "/").last?.split(separator: ".").first?.string ?? ""
    }
}

extension Substring {
    var string: String {
        String(self)
    }
}
