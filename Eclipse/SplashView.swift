import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Logo & Title
                HStack(spacing: 20) {
                    Image("betterlunr") // Using the asset name based on "betterlunr.PNG"
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .frame(maxWidth: 60, maxHeight: 60) // Explicit max constraints
                        .clipped() // Clip any overflow
                        .clipShape(Circle()) // Assuming circular logo based on app icon style
                        .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    Text("Eclipse")
                        .font(.system(size: 42, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .tracking(1)
                }
                .opacity(opacity)
                .scaleEffect(scale)
                
                Spacer()
                
                // Bottom Copyright
                Text("BY SMITH SOFTWARE©")
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(2)
                    .padding(.bottom, 20)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}
