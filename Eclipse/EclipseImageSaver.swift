import SwiftUI
import UIKit

class EclipseImageSaver: NSObject {
    static let shared = EclipseImageSaver()
    
    // Completion handler type definition
    typealias SaveCompletion = (Bool, Error?) -> Void
    private var completion: SaveCompletion?
    
    // Usage with completion handler (matched to ContentView usage)
    func saveImage(_ image: UIImage, completion: @escaping SaveCompletion) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    // Legacy support if needed
    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let completion = completion {
            completion(error == nil, error)
        }
    }
}
