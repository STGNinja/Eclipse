
import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import Combine

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var historyService: HistoryService
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedUIImage: UIImage?
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingClearHistoryAlert = false
    @State private var isUploadingPhoto = false
    
    // Compute the provider name (e.g., "Google", "Email", etc.)
    private var providerType: String {
        guard let user = Auth.auth().currentUser else { return "Guest" }
        if let provider = user.providerData.first {
            switch provider.providerID {
            case "google.com": return "Google"
            case "password": return "Email & Password"
            case "apple.com": return "Apple"
            default: return provider.providerID
            }
        }
        return "Email"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    profileHeader
                    
                    linkedAccountSection
                    
                    Spacer()
                    
                    accountActions
                }
                .padding(.top, 24)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .onAppear {
                Task {
                    await authManager.refreshUserData()
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await authManager.deleteAccount()
                        } catch {
                            print("Delete failed: \(error.localizedDescription)")
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to permanently delete your account? This action cannot be undone.")
            }
            .alert("Clear All Chats", isPresented: $showingClearHistoryAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    historyService.clearAll()
                    HapticManager.shared.notification(.success)
                }
            } message: {
                Text("This will permanently delete all your chat history. This action cannot be undone.")
            }
            .onChange(of: selectedItem) { oldValue, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                        selectedUIImage = uiImage
                        await uploadProfilePhoto(uiImage)
                    }
                }
            }
        }
        .presentationBackground {
            Color.clear
                .glassEffect(.regular.interactive(), in: .rect)
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .colorScheme(.dark)
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                if let selectedImage {
                    selectedImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let photoURL = authManager.userPhotoURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(authManager.userInitial)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .background(Circle().fill(Color.gray.opacity(0.3)))
                } else {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text(authManager.userInitial)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 120, height: 120)
                }
                
                if isUploadingPhoto {
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 120, height: 120)
                    ProgressView()
                        .tint(.white)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.blue))
                                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        }
                        .disabled(isUploadingPhoto)
                    }
                }
                .frame(width: 120, height: 120)
            }
            
            VStack(spacing: 4) {
                Text(authManager.userName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(authManager.userEmail)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var linkedAccountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Linked Account")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)
            
            HStack {
                Image(systemName: providerType == "Google" ? "g.circle.fill" : "envelope.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(providerType)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    Text("Signed in via \(providerType)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .padding(.horizontal)
        }
    }

    private var accountActions: some View {
        VStack(spacing: 16) {
            Button(action: { showingSignOutAlert = true }) {
                Text("Sign Out")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
            }
            .padding(.horizontal)
            
            Button(action: { showingClearHistoryAlert = true }) {
                Text("Delete All Chats")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
            }
            .padding(.horizontal)
            
            Button(action: { showingDeleteAlert = true }) {
                Text("Delete Account")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
            }
            .padding(.bottom, 20)
        }
    }

    private func uploadProfilePhoto(_ image: UIImage) async {
        guard let userID = Auth.auth().currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        
        await MainActor.run { isUploadingPhoto = true }
        let storageRef = Storage.storage().reference().child("profile_photos/\(userID).jpg")
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.cacheControl = "public, max-age=3600"
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            
            if let currentUser = Auth.auth().currentUser {
                let changeRequest = currentUser.createProfileChangeRequest()
                changeRequest.photoURL = downloadURL
                try await changeRequest.commitChanges()
                try await currentUser.reload()
                
                await MainActor.run {
                    isUploadingPhoto = false
                    selectedImage = nil
                    selectedUIImage = nil
                    authManager.user = Auth.auth().currentUser
                    authManager.objectWillChange.send()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            await MainActor.run {
                isUploadingPhoto = false
                selectedImage = nil
            }
        }
    }
}
