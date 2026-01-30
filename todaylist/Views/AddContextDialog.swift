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
            VStack(alignment: .leading, spacing: 20) {
                // 1. Large Input
                TextField("New Context Name", text: $contextName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .medium))
                    .focused($isFocused)
                    .onSubmit {
                        if !contextName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onAdd(contextName)
                            dismiss()
                        }
                    }
                
                // 2. Metadata Pill (Parent Context)
                if let parent = parent {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption)
                        Image(systemName: Theme.Icons.folder)
                            .font(.subheadline)
                        Text(parent.name)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)
                } else {
                    // Show "Root Context" indicator if no parent
                    Text("Top Level Context")
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // 3. Action Buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .controlSize(.large)
                    
                    Spacer()
                    
                    Button("Create") {
                        onAdd(contextName)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(contextName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(width: 500, height: 200)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
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
