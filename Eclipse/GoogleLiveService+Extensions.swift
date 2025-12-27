
//
//  GoogleLiveService+Extensions.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/16/25.
//

import UIKit

// MARK: - UIImage Extensions
extension UIImage {
    /// Resizes the image so that its largest dimension does not exceed maxDimension.
    /// Preserves aspect ratio. Returns original image if already smaller.
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage? {
        // If image is already smaller than max, just return it
        if max(size.width, size.height) <= maxDimension {
            return self
        }
        
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
