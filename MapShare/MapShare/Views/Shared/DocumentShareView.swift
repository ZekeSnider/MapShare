import SwiftUI
import CoreData
internal import CloudKit

struct DocumentShareView: View {
    let document: Document
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext

    @State private var share: CKShare?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Preparing share...")
                    Text("Syncing to iCloud...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Could not share")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Close") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let share = share {
                CloudSharingView(share: share, container: CloudKitService.shared.container, document: document)
            } else {
                VStack(spacing: 16) {
                    Text("Could not create share.")
                    Button("Try Again") {
                        loadShare()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear(perform: loadShare)
    }

    private func loadShare() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil

            // First, make sure the document is saved
            if viewContext.hasChanges {
                do {
                    try viewContext.save()
                } catch {
                    errorMessage = "Failed to save document: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
            }

            // Check if a share already exists
            do {
                if let existingShare = await CloudKitService.shared.getShare(for: document) {
                    print("Found existing share: \(existingShare)")
                    self.share = existingShare
                    isLoading = false
                    return
                }
            }

            // If not, create a new share
            print("Creating new share for document: \(document.name ?? "unnamed")")
            if let newShare = await CloudKitService.shared.createShare(for: document) {
                print("Share created successfully: \(newShare)")
                self.share = newShare
            } else {
                errorMessage = "Failed to create share. Make sure the document is synced to iCloud."
            }

            isLoading = false
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(name: "Sample Document", context: context)
    
    return DocumentShareView(
        document: document,
        isPresented: .constant(true)
    )
    .environment(\.managedObjectContext, context)
}
