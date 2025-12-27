//
//  PhotoSaver.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import UIKit
import Photos

class PhotoSaver: NSObject {
    static let shared = PhotoSaver()
    
    private var completionHandler: ((Bool, Error?) -> Void)?
    
    func saveImage(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        self.completionHandler = completion
        
        // Check authorization status
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            saveImageToLibrary(image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    self?.saveImageToLibrary(image)
                } else {
                    DispatchQueue.main.async {
                        completion(false, PhotoSaverError.accessDenied)
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                completion(false, PhotoSaverError.accessDenied)
            }
        @unknown default:
            DispatchQueue.main.async {
                completion(false, PhotoSaverError.unknown)
            }
        }
    }
    
    private func saveImageToLibrary(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                self?.completionHandler?(false, error)
            } else {
                self?.completionHandler?(true, nil)
            }
            self?.completionHandler = nil
        }
    }
}

enum PhotoSaverError: LocalizedError {
    case accessDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to photo library denied. Please enable in Settings."
        case .unknown:
            return "Unknown error occurred while saving photo."
        }
    }
}
