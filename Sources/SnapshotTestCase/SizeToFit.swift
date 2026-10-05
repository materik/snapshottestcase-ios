import UIKit

final class SizeToFit {
    let probeHeight: CGFloat = 10000

    private let backgroundTolerance: Int = 3

    func crop(_ image: UIImage, topInsetPoints: CGFloat) -> UIImage {
        var result = trimTrailingBackground(image)
        result = cropTop(result, byPoints: topInsetPoints)
        return result
    }

    private func trimTrailingBackground(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return image
        }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 3, width > 0, height > 0 else { return image }

        let bgSamples = backgroundSamples(bytes: bytes, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, width: width, height: height)
        let scanStride = max(1, width / 64)
        var lastContentRow = -1
        for y in stride(from: height - 1, through: 0, by: -1) {
            var rowHasContent = false
            for x in stride(from: 0, to: width, by: scanStride) {
                let p = pixel(bytes: bytes, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, x: x, y: y)
                if !bgSamples.contains(where: { matches(p, $0) }) {
                    rowHasContent = true
                    break
                }
            }
            if rowHasContent {
                lastContentRow = y
                break
            }
        }
        guard lastContentRow >= 0, lastContentRow < height - 1 else { return image }
        let padding = Int(Snapshot.renderPaddingBottom * image.scale)
        let cropHeight = min(height, lastContentRow + 1 + padding)
        guard let cropped = cgImage.cropping(to: CGRect(x: 0, y: 0, width: width, height: cropHeight)) else {
            return image
        }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    private func cropTop(_ image: UIImage, byPoints points: CGFloat) -> UIImage {
        guard points > 0, let cgImage = image.cgImage else { return image }
        let pixels = Int((points * image.scale).rounded())
        guard pixels > 0, pixels < cgImage.height else { return image }
        let rect = CGRect(x: 0, y: pixels, width: cgImage.width, height: cgImage.height - pixels)
        guard let cropped = cgImage.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    private func backgroundSamples(
        bytes: UnsafePointer<UInt8>,
        bytesPerRow: Int,
        bytesPerPixel: Int,
        width: Int,
        height: Int
    ) -> [(UInt8, UInt8, UInt8)] {
        let y = height - 1
        return [
            pixel(bytes: bytes, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, x: 0, y: y),
            pixel(bytes: bytes, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, x: width / 2, y: y),
            pixel(bytes: bytes, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, x: width - 1, y: y),
        ]
    }

    private func pixel(
        bytes: UnsafePointer<UInt8>,
        bytesPerRow: Int,
        bytesPerPixel: Int,
        x: Int,
        y: Int
    ) -> (UInt8, UInt8, UInt8) {
        let offset = y * bytesPerRow + x * bytesPerPixel
        return (bytes[offset], bytes[offset + 1], bytes[offset + 2])
    }

    private func matches(_ a: (UInt8, UInt8, UInt8), _ b: (UInt8, UInt8, UInt8)) -> Bool {
        abs(Int(a.0) - Int(b.0)) < backgroundTolerance
            && abs(Int(a.1) - Int(b.1)) < backgroundTolerance
            && abs(Int(a.2) - Int(b.2)) < backgroundTolerance
    }
}
