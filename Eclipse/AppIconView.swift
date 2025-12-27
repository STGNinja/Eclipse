//
//  AppIconView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI

struct AppIconView: View {
    let app: EclipseAppInfo
    let size: CGFloat

    var body: some View {
        Group {
            if let logoUrl = app.logoUrl {
                // Try loading as local image first
                if let localImage = loadLocalImage(named: logoUrl) {
                    Image(uiImage: localImage)
                        .resizable()
                        .scaledToFill()
                } else if let url = URL(string: logoUrl), logoUrl.hasPrefix("http") {
                    // Fall back to remote URL
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: size, height: size)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallbackIcon
                        @unknown default:
                            fallbackIcon
                        }
                    }
                } else {
                    fallbackIcon
                }
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
    
    private func loadLocalImage(named: String) -> UIImage? {
        // Try to load as named asset
        if let image = UIImage(named: named) {
            return image
        }
        
        // Try with common extensions
        let extensions = ["png", "jpg", "jpeg"]
        let baseName = named.replacingOccurrences(of: ".png", with: "")
                             .replacingOccurrences(of: ".jpg", with: "")
                             .replacingOccurrences(of: ".jpeg", with: "")
        
        for ext in extensions {
            if let path = Bundle.main.path(forResource: baseName, ofType: ext),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        
        return nil
    }

    var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(hex: app.tintColor))

            Image(systemName: app.iconName)
                .font(.system(size: size * 0.5))
                .foregroundStyle(.white)
        }
    }
}
