//
//  SidebarView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/26/25.
//

import SwiftUI
import CoreData // If needed, though not explicitly used in the struct body

enum SidebarMode {
    case main
    case chats
    case projects
    case profile
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var isShowing: Bool
    @StateObject private var authManager = AuthManager.shared
    @State private var currentMode: SidebarMode = .main
    let sessions: [ChatSession]
    let onSelectSession: (ChatSession) -> Void
    let onDeleteSession: (UUID) -> Void
    let onNewChat: () -> Void
    let onShowSettings: () -> Void
    let onShowArtifacts: () -> Void
    let onShowApps: () -> Void
    let onStartPluginChat: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Group {
                switch currentMode {
                case .main:
                    MainSidebarView(
                        isShowing: $isShowing,
                        currentMode: $currentMode,
                        sessions: sessions,
                        onSelectSession: onSelectSession,
                        onDeleteSession: onDeleteSession,
                        onNewChat: onNewChat,
                        onShowSettings: onShowSettings,
                        onShowArtifacts: onShowArtifacts,
                        onShowApps: onShowApps,
                        onStartPluginChat: onStartPluginChat
                    )
                case .chats:
                    ChatsListView(
                        currentMode: $currentMode,
                        isShowing: $isShowing,
                        sessions: sessions,
                        onSelectSession: onSelectSession,
                        onDeleteSession: onDeleteSession
                    )
                case .projects:
                    ProjectsView(
                        currentMode: $currentMode
                    )
                case .profile:
                    SidebarProfileView(
                        currentMode: $currentMode
                    )
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .frame(width: 300)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentMode)
    }
}

// MARK: - Main Sidebar View

struct MainSidebarView: View {
    @Binding var isShowing: Bool
    @Binding var currentMode: SidebarMode
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appManager = AppManager.shared
    let sessions: [ChatSession]
    let onSelectSession: (ChatSession) -> Void
    let onDeleteSession: (UUID) -> Void
    let onNewChat: () -> Void
    let onShowSettings: () -> Void
    let onShowArtifacts: () -> Void
    let onShowApps: () -> Void
    let onStartPluginChat: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Eclipse")
                .font(.system(size: 38, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 24)
            
            // Navigation Items
            VStack(alignment: .leading, spacing: 2) {
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation {
                        currentMode = .chats
                    }
                } label: {
                    NavigationItem(icon: "bubble.left", title: "Chats", isSelected: false)
                }
                
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation {
                        currentMode = .projects
                    }
                } label: {
                    NavigationItem(icon: "shippingbox", title: "Projects", isSelected: false)
                }
                
                Button {
                    HapticManager.shared.impact(.light)
                    onShowArtifacts()
                } label: {
                    NavigationItem(icon: "brain", title: "Artifacts", isSelected: false)
                }
                
                Button {
                    HapticManager.shared.impact(.light)
                    isShowing = false
                    onShowApps()
                } label: {
                    NavigationItem(icon: "square.grid.2x2.fill", title: "App Store", isSelected: false)
                }
                
                if !appManager.myApps.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(appManager.myApps) { app in
                                Button {
                                    HapticManager.shared.impact(.light)
                                    isShowing = false
                                    onStartPluginChat(app.id)
                                } label: {
                                    AppIconView(app: app, size: 32)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 24)
            
            // Recents Section
            HStack {
                Text("Recents")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                Spacer()
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    if sessions.isEmpty {
                        Text("No conversations yet")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(sessions) { session in
                            SessionItem(
                                session: session,
                                onSelect: { onSelectSession(session) },
                                onDelete: { onDeleteSession(session.id) }
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Bottom Bar
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // User Profile Pill
                    Button {
                        HapticManager.shared.impact(.light)
                        onShowSettings()
                    } label: {
                        HStack(spacing: 12) {
                            Group {
                                if let photoURL = authManager.userPhotoURL {
                                    AsyncImage(url: photoURL) { phase in
                                        switch phase {
                                        case .empty:
                                            Circle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 32, height: 32)
                                                .clipShape(Circle())
                                        case .failure:
                                            Circle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Text(authManager.userInitial)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundStyle(.white)
                                                )
                                        @unknown default:
                                            Circle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(authManager.userInitial)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(.white)
                                        )
                                }
                            }
                            
                            Text(authManager.userName)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .glassEffect(.regular, in: .capsule)
                    }
                    
                    Spacer()
                    
                    // New Chat Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        onNewChat()
                    } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.85, green: 0.45, blue: 0.25), Color(red: 0.75, green: 0.35, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "plus.message.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.white)
                            )
                            .shadow(color: Color(red: 0.85, green: 0.45, blue: 0.25).opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 50) // Pushing sidebar bottom bar up slightly higher
        }
    }
}

// MARK: - Chats List View

struct ChatsListView: View {
    @Binding var currentMode: SidebarMode
    @Binding var isShowing: Bool
    let sessions: [ChatSession]
    let onSelectSession: (ChatSession) -> Void
    let onDeleteSession: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            chatsScrollView
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Button {
                HapticManager.shared.impact(.light)
                withAnimation {
                    currentMode = .main
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            
            Text("All Chats")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 64)
        .padding(.bottom, 24)
    }
    
    private var chatsScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    chatsListView
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.top, 60)
            
            Text("No conversations yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            Text("Start a new chat to begin")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var chatsListView: some View {
        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
            ChatRowView(
                session: session,
                onSelect: {
                    HapticManager.shared.impact(.light)
                    onSelectSession(session)
                    withAnimation {
                        isShowing = false
                    }
                },
                onDelete: {
                    onDeleteSession(session.id)
                }
            )
        }
    }
}

// MARK: - Chat Row View

struct ChatRowView: View {
    let session: ChatSession
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.title)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text(session.preview)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                
                Text(session.date, style: .relative)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Projects View

struct ProjectsView: View {
    @Binding var currentMode: SidebarMode
    @State private var projects: [Project] = []
    @State private var showingCreateProject = false
    @State private var newProjectName = ""
    @State private var newProjectDescription = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with back button
            HStack(spacing: 16) {
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation {
                        currentMode = .main
                    }
                } label: {
                    Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                
                Text("Projects")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    HapticManager.shared.impact(.light)
                    showingCreateProject = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 24)
            
            // Projects List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if projects.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange.opacity(0.8))
                                .padding(.top, 60)
                            
                            Text("No projects yet")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text("Create a project to organize your work")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button {
                                HapticManager.shared.impact(.medium)
                                showingCreateProject = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Create Project")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, Color(red: 0.9, green: 0.5, blue: 0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(projects) { project in
                            ProjectCard(project: project)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectSheet(
                projectName: $newProjectName,
                projectDescription: $newProjectDescription,
                onSave: {
                    let newProject = Project(
                        name: newProjectName,
                        description: newProjectDescription,
                        createdAt: Date()
                    )
                    projects.append(newProject)
                    newProjectName = ""
                    newProjectDescription = ""
                    showingCreateProject = false
                }
            )
        }
    }
}

// MARK: - Sidebar Profile View

struct SidebarProfileView: View {
    @Binding var currentMode: SidebarMode
    @StateObject private var authManager = AuthManager.shared
    @State private var showingSignOutAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with back button
            HStack(spacing: 16) {
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation {
                        currentMode = .main
                    }
                } label: {
                    Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                
                Text("Profile")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 32)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Profile Picture & Name
                    VStack(spacing: 16) {
                        Group {
                            if let photoURL = authManager.userPhotoURL {
                                AsyncImage(url: photoURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Text(authManager.userInitial)
                                                    .font(.system(size: 32, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            )
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(authManager.userInitial)
                                            .font(.system(size: 32, weight: .semibold))
                                            .foregroundStyle(.white)
                                    )
                            }
                        }
                        .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 4) {
                            Text(authManager.userName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text(authManager.userEmail)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    
                    // Account Info
                    VStack(spacing: 12) {
                        ProfileInfoRow(
                            icon: "envelope.fill",
                            title: "Email",
                            value: authManager.userEmail
                        )
                        
                        ProfileInfoRow(
                            icon: "person.fill",
                            title: "Display Name",
                            value: authManager.userName
                        )
                        
                        ProfileInfoRow(
                            icon: "key.fill",
                            title: "Account Type",
                            value: authManager.userPhotoURL != nil ? "Google" : "Email"
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Sign Out Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        showingSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .medium))
                            Text("Sign Out")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
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
    }
}

// MARK: - Supporting Views

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)
                
                Spacer()
                
                Text(project.createdAt, style: .relative)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Text(project.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct CreateProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var projectName: String
    @Binding var projectDescription: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        ZStack(alignment: .leading) {
                            if projectName.isEmpty {
                                Text("My Awesome Project")
                                    .foregroundStyle(.white.opacity(0.4))
                                    .padding(.leading, 16)
                            }
                            TextField("", text: $projectName)
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        ZStack(alignment: .topLeading) {
                            if projectDescription.isEmpty {
                                Text("What's this project about?")
                                    .foregroundStyle(.white.opacity(0.4))
                                    .padding(.leading, 16)
                                    .padding(.top, 16)
                            }
                            TextField("", text: $projectDescription, axis: .vertical)
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                                .lineLimit(4...6)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        HapticManager.shared.impact(.medium)
                        onSave()
                    }
                    .foregroundStyle(.orange)
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Project Model

struct Project: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let createdAt: Date
}

// MARK: - Session Item

struct SessionItem: View {
    let session: ChatSession
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            onSelect()
        } label: {
            HStack(spacing: 0) {
                Text(session.title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let pluginId = session.pluginId,
                   let app = AppManager.shared.availableApps.first(where: { $0.id == pluginId }) {
                    Image(systemName: app.iconName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: app.tintColor))
                        .padding(4)
                        .background(Circle().fill(Color(hex: app.tintColor).opacity(0.1)))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isHovering ? 0.05 : 0))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                HapticManager.shared.notification(.warning)
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Navigation Item

struct NavigationItem: View {
    let icon: String
    let title: String
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .frame(width: 22)
            
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
