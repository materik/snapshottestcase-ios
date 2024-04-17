import UIKit

extension UIImage {
    func compare(with reference: UIImage, tolerance: Int = 1000) -> Double? {
        guard size.equalTo(reference.size),
              let cgImage,
              let referenceCGImage = reference.cgImage else {
            return nil
        }

        let minBytesPerRow = min(cgImage.bytesPerRow, referenceCGImage.bytesPerRow)
        let imagePixelsData = UnsafeMutablePointer<Pixel>
            .allocate(capacity: cgImage.width * cgImage.height)
        let referencePixelsData = UnsafeMutablePointer<Pixel>
            .allocate(capacity: referenceCGImage.width * referenceCGImage.height)
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
            & CGBitmapInfo.alphaInfoMask.rawValue
        )

        guard let colorSpace = cgImage.colorSpace,
              let referenceColorSpace = referenceCGImage.colorSpace else {
            return nil
        }

        guard let imageContext = CGContext(
            data: imagePixelsData,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: minBytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        guard let referenceContext = CGContext(
            data: referencePixelsData,
            width: referenceCGImage.width,
            height: referenceCGImage.height,
            bitsPerComponent: referenceCGImage.bitsPerComponent,
            bytesPerRow: minBytesPerRow,
            space: referenceColorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        referenceContext.draw(
            referenceCGImage,
            in: CGRect(x: 0, y: 0, width: reference.size.width, height: reference.size.height)
        )

        // Go through each pixel in turn and see if it is different
        let pixelCount = referenceCGImage.width * referenceCGImage.height
        let imagePixels = UnsafeMutableBufferPointer<Pixel>(
            start: imagePixelsData,
            count: cgImage.width * cgImage.height
        )
        let referencePixels = UnsafeMutableBufferPointer<Pixel>(
            start: referencePixelsData,
            count: referenceCGImage.width * referenceCGImage.height
        )

        var numDiffPixels = 0
        for i in 0..<pixelCount {
            // If this pixel is different, increment the pixel diff count and see
            // if we have hit our limit.
            let p1 = Int(imagePixels[i].value)
            let p2 = Int(referencePixels[i].value)

            if abs(p1 - p2) > tolerance {
                numDiffPixels += 1
            }
        }

        free(imagePixelsData)
        free(referencePixelsData)

        return CGFloat(numDiffPixels) / CGFloat(pixelCount)
    }

    var pixelData: CFData? {
        (cgImage ?? ciImage?.cgImage)?.dataProvider?.data
    }
}

extension CIImage {
    var cgImage: CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(self, from: extent)
    }
}

private struct Pixel {
    var value: UInt32
    var red: UInt8 {
        get { UInt8(value & 0xFF) }
        set { value = UInt32(newValue) | (value & 0xFFFF_FF00) }
    }

    var green: UInt8 {
        get { UInt8((value >> 8) & 0xFF) }
        set { value = (UInt32(newValue) << 8) | (value & 0xFFFF_00FF) }
    }

    var blue: UInt8 {
        get { UInt8((value >> 16) & 0xFF) }
        set { value = (UInt32(newValue) << 16) | (value & 0xFF00_FFFF) }
    }

    var alpha: UInt8 {
        get { UInt8((value >> 24) & 0xFF) }
        set { value = (UInt32(newValue) << 24) | (value & 0x00FF_FFFF) }
    }
}
