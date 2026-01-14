import SwiftUI
import CoreData
import UIKit
import CloudKit

@main
struct MapShareApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @State private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            DocumentListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(appState)
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("📱 AppDelegate didFinishLaunching")
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("📱 AppDelegate configurationForConnecting")
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - SceneDelegate
// Handles CloudKit share invitations
// Requires CKSharingSupported = true in Info.plist
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("🎬 SceneDelegate willConnectTo")

        // Handle CloudKit share if app was launched via share link
        if let metadata = connectionOptions.cloudKitShareMetadata {
            print("☁️ Found CloudKit share metadata on launch!")
            acceptShare(metadata: metadata)
        }
    }

    // This is the key method - called when user taps a CloudKit share link
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        print("☁️ userDidAcceptCloudKitShareWith called!")
        print("   Share URL: \(cloudKitShareMetadata.share.url?.absoluteString ?? "nil")")
        print("   Container ID: \(cloudKitShareMetadata.containerIdentifier)")
        acceptShare(metadata: cloudKitShareMetadata)
    }

    private func acceptShare(metadata: CKShare.Metadata) {
        print("📨 Accepting share invitation...")

        let container = PersistenceController.shared.container

        // Find the shared store
        guard let sharedStore = container.persistentStoreCoordinator.persistentStores.first(where: { store in
            store.url?.lastPathComponent == "MapShare-shared.sqlite"
        }) else {
            print("❌ Shared store not found")
            return
        }

        container.acceptShareInvitations(from: [metadata], into: sharedStore) { _, error in
            if let error = error {
                let ckError = error as! CKError

                // Check if we're the owner trying to accept our own share
                if ckError.code == .partialFailure,
                   let partialErrors = ckError.partialErrorsByItemID,
                   partialErrors.values.contains(where: { partialError in
                       (partialError as? CKError)?.localizedDescription.contains("owner participant") == true
                   }) {
                    print("👤 We're the owner - navigating to our document")
                    Task { @MainActor in
                        await self.navigateToOwnedDocument(metadata: metadata)
                    }
                } else {
                    print("❌ Failed to accept share: \(error)")
                }
            } else {
                print("✅ Share accepted successfully!")

                // Navigate to the shared document after a delay for sync
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    Task { @MainActor in
                        await self.navigateToSharedDocument(metadata: metadata)
                    }
                }
            }
        }
    }

    @MainActor
    private func navigateToOwnedDocument(metadata: CKShare.Metadata) async {
        let container = PersistenceController.shared.container
        let context = container.viewContext

        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()

        do {
            let documents = try context.fetch(fetchRequest)

            // Find the document that matches the share
            for document in documents {
                if let shares = try? await container.fetchShares(matching: [document.objectID]),
                   let share = shares[document.objectID],
                   share.recordID == metadata.share.recordID {
                    print("📄 Found owned document: \(document.name ?? "unnamed")")
                    AppState.shared.documentIDToOpen = document.objectID
                    return
                }
            }

            print("⚠️ Could not find matching document")
        } catch {
            print("❌ Failed to fetch documents: \(error)")
        }
    }

    @MainActor
    private func navigateToSharedDocument(metadata: CKShare.Metadata) async {
        let container = PersistenceController.shared.container
        let context = container.viewContext

        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Document.modifiedDate, ascending: false)]

        do {
            let documents = try context.fetch(fetchRequest)

            // Find the document that matches the share
            for document in documents {
                if let shares = try? await container.fetchShares(matching: [document.objectID]),
                   let share = shares[document.objectID],
                   share.recordID == metadata.share.recordID {
                    print("📄 Found matching document: \(document.name ?? "unnamed")")
                    AppState.shared.documentIDToOpen = document.objectID
                    return
                }
            }

            // Fallback: navigate to most recent shared document
            if let sharedDoc = documents.first(where: { $0.isShared }) {
                print("📄 Using fallback - most recent shared document: \(sharedDoc.name ?? "unnamed")")
                AppState.shared.documentIDToOpen = sharedDoc.objectID
            } else {
                print("⚠️ No shared documents found")
            }
        } catch {
            print("❌ Failed to fetch documents: \(error)")
        }
    }
}