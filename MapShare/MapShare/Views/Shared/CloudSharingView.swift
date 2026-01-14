import SwiftUI
import CloudKit
import UIKit
import CoreData

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let document: Document
    @Environment(\.managedObjectContext) private var viewContext

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        // Configure share options
        share[CKShare.SystemFieldKey.title] = document.name

        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.modalPresentationStyle = .formSheet
        controller.availablePermissions = [.allowReadWrite, .allowReadOnly, .allowPublic, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let parent: CloudSharingView

        init(_ parent: CloudSharingView) {
            self.parent = parent
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error)")
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Share saved successfully")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("Stopped sharing")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            parent.document.name
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Return nil for now - could add a map thumbnail later
            nil
        }
    }
}
