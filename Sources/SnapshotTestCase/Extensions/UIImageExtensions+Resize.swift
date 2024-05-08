import UIKit

extension UIImage {
    func resized(toScale scale: CGFloat) -> UIImage? {
        guard scale > 0, scale != 1 else {
            return self
        }
        return resized(toWidth: scale * size.width)
    }

    func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width / size.width * size.height)))
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}
