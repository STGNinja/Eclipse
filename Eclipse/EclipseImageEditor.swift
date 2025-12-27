//
//  EclipseImageEditor.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

enum AdjustmentType: String, CaseIterable, Identifiable {
    case brightness = "Brightness"
    case blur = "Blur"
    case contrast = "Contrast"
    case saturation = "Saturation"
    
    var id: String { rawValue }
    
    var range: ClosedRange<Double> {
        switch self {
        case .brightness: return -0.5...0.5 // CIColorControls: inputBrightness
        case .blur: return 0...20 // CIGaussianBlur: inputRadius
        case .contrast: return 0.5...2.0 // CIColorControls: inputContrast (default 1)
        case .saturation: return 0...2.0 // CIColorControls: inputSaturation (default 1)
        }
    }
    
    var defaultValue: Double {
        switch self {
        case .brightness: return 0
        case .blur: return 0
        case .contrast: return 1.0
        case .saturation: return 1.0
        }
    }
}

class EclipseImageEditor {
    static let shared = EclipseImageEditor()
    private let context = CIContext()
    
    func applyAdjustment(image: UIImage, type: AdjustmentType, value: Double) async -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter: CIFilter
        
        switch type {
        case .brightness, .contrast, .saturation:
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = ciImage
            
            // We need to apply defaults for non-target attributes to behave correctly if chaining,
            // but for single slider editing we just apply the one value.
            // In a real editor we'd state manage all values. For now, assuming single adjustment mode or simple chaining if improved.
            
            if type == .brightness { colorFilter.brightness = Float(value) }
            if type == .contrast { colorFilter.contrast = Float(value) }
            if type == .saturation { colorFilter.saturation = Float(value) }
            
            filter = colorFilter
            
        case .blur:
            let blurFilter = CIFilter.gaussianBlur()
            blurFilter.inputImage = ciImage
            blurFilter.radius = Float(value)
            filter = blurFilter
        }
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Future: Background removal using Vision
    func removeBackground(from image: UIImage) async throws -> UIImage {
        // Placeholder for Vision Framework implementation
        // This requires iOS 17+ Vision capabilities usually, or complex CoreML models.
        // For simplicity in this demo, we might skip full implementation or return original with note.
        return image
    }
}
