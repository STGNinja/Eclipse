import SwiftUI

struct CanvaDesignPreview: View {
    let designId: String
    let title: String
    let editUrl: String
    var thumbnailUrl: String? = nil
    
    @State private var isHovering = false
    @State private var freshThumbnailUrl: String? = nil
    @State private var isLoadingThumbnail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview Image or Gradient Header
            // Use fresh thumbnail if available, otherwise fall back to initial thumbnail
            if let thumbnailUrl = freshThumbnailUrl ?? thumbnailUrl, let url = URL(string: thumbnailUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.3), .clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    } else if phase.error != nil {
                        // Fallback gradient if image fails
                        headerGradient
                    } else {
                        // Loading state
                        ZStack {
                            Color.black.opacity(0.3)
                            ProgressView()
                                .tint(.white)
                        }
                        .frame(height: 160)
                    }
                }
            } else {
                headerGradient
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Header Label
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 14))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 124/255, green: 77/255, blue: 255/255), // Purple
                                            Color(red: 0/255, green: 196/255, blue: 204/255)   // Teal
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    
                    Text("Created in Canva")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Spacer()
                }
                
                // Content Title
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.bottom, 4)
                
                // Action Button
                Button {
                    if let url = URL(string: editUrl) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("Edit in Canva")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(
            ZStack {
                Color.black.opacity(0.6)
                
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 124/255, green: 77/255, blue: 255/255).opacity(0.5),
                                Color(red: 0/255, green: 196/255, blue: 204/255).opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(width: 280) // Fixed width for chat bubble consistency
        .onAppear {
            // Fetch fresh thumbnail URL on appear (URLs expire after 15 min)
            Task {
                do {
                    if let freshUrl = try await CanvaService.shared.getDesignThumbnail(designId: designId) {
                        await MainActor.run {
                            freshThumbnailUrl = freshUrl
                        }
                    }
                } catch {
                    print("⚠️ Failed to fetch fresh thumbnail for design \(designId): \(error)")
                    // Fall back to initial thumbnail or gradient
                }
            }
        }
    }
    
    var headerGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 124/255, green: 77/255, blue: 255/255).opacity(0.8), // Purple
                Color(red: 0/255, green: 196/255, blue: 204/255).opacity(0.8)   // Teal
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 60)
        .overlay(
            Image(systemName: "paintpalette.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
                .foregroundStyle(.white.opacity(0.4))
        )
    }
}

#Preview {
    ZStack {
        Color.black
        CanvaDesignPreview(
            designId: "DAGBvkv1234", // Example design ID
            title: "Grand Opening: Coffee Shop",
            editUrl: "https://www.google.com"
        )
    }
}
