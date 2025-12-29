//
//  AddContextDialog.swift
//  todaylist
//
//  A macOS HIG-compliant dialog for creating new contexts
//

import SwiftUI

struct AddContextDialog: View {
    // MARK: - Bindings
    @Binding var isPresented: Bool
    let parent: ContextNode?
    let onAdd: (String) -> Void
    
    // MARK: - Internal State
    @State private var contextName = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // MARK: - Background Overlay (Tap to dismiss)
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // MARK: - Dialog Container
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("New Context")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                // Parent breadcrumb (if adding child)
                if let parent = parent {
                    HStack(spacing: 4) {
                        Image(systemName: Theme.Icons.folder)
                            .font(.caption)
                        Text("Adding to: \(parent.name)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // MARK: - Custom Input Field (Full Width)
                HStack(spacing: 8) {
                    Image(systemName: Theme.Icons.folder)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    
                    TextField("Context Name", text: $contextName)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isFocused ? 2 : 1)
                )
                
                Spacer()
                    .frame(height: 8)
                
                // MARK: - Action Buttons (Right-aligned)
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Add") {
                        onAdd(contextName)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(contextName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(30)
            .frame(width: 440)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.dialog))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.dialog)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, y: 15)
        }
        .onAppear {
            // Reset state on appear for clean slate each time
            contextName = ""
            isFocused = true
        }
    }
    
    private func dismiss() {
        withAnimation(Theme.Animation.dialog) {
            isPresented = false
        }
    }
}

#Preview {
    AddContextDialog(
        isPresented: .constant(true),
        parent: nil,
        onAdd: { name in print("Added: \(name)") }
    )
}
