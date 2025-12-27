//
//  MusicMiniPlayerView.swift
//  Eclipse
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import MusicKit

struct MusicMiniPlayerView: View {
    @StateObject private var playerState = MusicPlayerState.shared
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if playerState.isPlaying || playerState.currentTrack != nil {
                miniPlayerCompact
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playerState.isPlaying)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playerState.currentTrack != nil)
    }

    // MARK: - Compact Mini Player

    private var miniPlayerCompact: some View {
        HStack(spacing: 12) {
            // Artwork
            if let artworkURL = playerState.currentArtworkURL {
                AsyncImage(url: artworkURL) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(playerState.currentTrack?.title ?? "Not Playing")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(playerState.currentTrack?.artistName ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            // Play/Pause button
            Button {
                Task {
                    if playerState.isPlaying {
                        try? await MusicPlaybackController.shared.pause()
                    } else {
                        try? await MusicPlaybackController.shared.play()
                    }
                }
            } label: {
                Image(systemName: playerState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .buttonStyle(ScaleButtonStyle())

            // Skip button
            Button {
                Task {
                    try? await MusicPlaybackController.shared.skipToNext()
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Blurred background
                if let artworkURL = playerState.currentArtworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image.resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.black
                    }
                    .blur(radius: 40)
                    .opacity(0.5)
                } else {
                    Color.black.opacity(0.5)
                }

                // Gradient overlay
                LinearGradient(
                    colors: [.black.opacity(0.4), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 90) // Above text input
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = true
            }
        }
        .sheet(isPresented: $isExpanded) {
            MusicNowPlayingView()
        }
    }
}

// MARK: - Now Playing View (Full Screen)

struct MusicNowPlayingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerState = MusicPlayerState.shared
    @State private var isDraggingSlider = false
    @State private var sliderValue: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.08)
                .ignoresSafeArea()

            // Blurred artwork background
            if let artworkURL = playerState.currentArtworkURL {
                AsyncImage(url: artworkURL) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .blur(radius: 80)
                .opacity(0.3)
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    if let playlistTitle = playerState.currentPlaylistTitle {
                        VStack(spacing: 2) {
                            Text("Playing from")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(playlistTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    Button {
                        // More options
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Large Artwork
                if let artworkURL = playerState.currentArtworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image.resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                    .frame(width: 320, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
                }

                Spacer()

                // Track Info
                VStack(spacing: 8) {
                    Text(playerState.currentTrack?.title ?? "Not Playing")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(playerState.currentTrack?.artistName ?? "")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .padding(.horizontal, 40)

                // Progress Slider
                VStack(spacing: 6) {
                    Slider(value: $sliderValue, in: 0...max(playerState.totalDuration, 1)) { editing in
                        isDraggingSlider = editing
                        if !editing {
                            Task {
                                try? await MusicPlaybackController.shared.seek(to: sliderValue)
                            }
                        }
                    }
                    .tint(Color(hex: "#FC3C44"))
                    .padding(.horizontal, 40)

                    HStack {
                        Text(playerState.formattedPlaybackTime)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer()

                        Text(playerState.formattedDuration)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.top, 20)

                // Playback Controls
                HStack(spacing: 40) {
                    Button {
                        Task {
                            try? await MusicPlaybackController.shared.skipToPrevious()
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        Task {
                            if playerState.isPlaying {
                                try? await MusicPlaybackController.shared.pause()
                            } else {
                                try? await MusicPlaybackController.shared.play()
                            }
                        }
                    } label: {
                        Image(systemName: playerState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72, weight: .regular))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        Task {
                            try? await MusicPlaybackController.shared.skipToNext()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            sliderValue = playerState.playbackTime
        }
        .onChange(of: playerState.playbackTime) { _, newValue in
            if !isDraggingSlider {
                sliderValue = newValue
            }
        }
    }
}

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
