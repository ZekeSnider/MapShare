import SwiftUI
import CloudKit
import CoreData
import Observation

@Observable
@MainActor
class AppState {
    static let shared = AppState()

    var pendingShareURL: URL?
    var documentIDToOpen: NSManagedObjectID?
    var isProcessingShare = false

    private init() {}

    func handleShareURL(_ url: URL) async {
        print("📥 handleShareURL called with: \(url)")

        guard !isProcessingShare else {
            print("⚠️ Already processing a share, ignoring")
            return
        }
        isProcessingShare = true

        defer { isProcessingShare = false }

        // Fetch share metadata from the URL
        print("🔍 Fetching share metadata...")
        guard let metadata = await CloudKitService.shared.fetchShareMetadata(from: url) else {
            print("❌ Failed to fetch share metadata from URL")
            return
        }
        print("✅ Got share metadata: \(metadata)")

        // Check if we already have this document
        if let existingDocumentID = await findExistingDocumentID(for: metadata) {
            print("📄 Document already exists, navigating to it: \(existingDocumentID)")
            documentIDToOpen = existingDocumentID
            return
        }

        // Accept the share invitation
        print("📨 Accepting share invitation...")
        if let documentID = await CloudKitService.shared.acceptShareInvitationReturningID(from: metadata) {
            print("✅ Share accepted, navigating to document: \(documentID)")
            documentIDToOpen = documentID
        } else {
            print("❌ Failed to accept share or find document")
        }
    }

    private func findExistingDocumentID(for metadata: CKShare.Metadata) async -> NSManagedObjectID? {
        let context = PersistenceController.shared.container.viewContext
        let container = PersistenceController.shared.container
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()

        do {
            let documents = try context.fetch(fetchRequest)

            for document in documents {
                do {
                    let shares = try await container.fetchShares(matching: [document.objectID])
                    if let share = shares[document.objectID],
                       share.recordID == metadata.share.recordID {
                        return document.objectID
                    }
                } catch {
                    continue
                }
            }
        } catch {
            print("Failed to fetch existing documents: \(error)")
        }

        return nil
    }

    func clearPendingNavigation() {
        documentIDToOpen = nil
    }

    func handleShareMetadata(_ metadata: CKShare.Metadata) async {
        print("☁️ handleShareMetadata called")

        guard !isProcessingShare else {
            print("⚠️ Already processing a share, ignoring")
            return
        }
        isProcessingShare = true

        defer { isProcessingShare = false }

        // Check if we already have this document
        if let existingDocumentID = await findExistingDocumentID(for: metadata) {
            print("📄 Document already exists, navigating to it: \(existingDocumentID)")
            documentIDToOpen = existingDocumentID
            return
        }

        // Accept the share invitation
        print("📨 Accepting share invitation...")
        if let documentID = await CloudKitService.shared.acceptShareInvitationReturningID(from: metadata) {
            print("✅ Share accepted, navigating to document: \(documentID)")
            documentIDToOpen = documentID
        } else {
            print("❌ Failed to accept share or find document")
        }
    }
}
