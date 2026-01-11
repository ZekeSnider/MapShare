import CloudKit
import CoreData
import CoreLocation
import Foundation

class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    private let container = CKContainer(identifier: "iCloud.com.mapshare.app")
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    @Published var isAvailable = false
    @Published var userPresences: [String: UserPresence] = [:]
    
    private init() {
        publicDatabase = container.publicCloudDatabase
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        
        checkCloudKitAvailability()
    }
    
    private func checkCloudKitAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.isAvailable = (status == .available)
            }
        }
    }
    
    // MARK: - Document Sharing
    
    func shareDocument(_ document: Document) async throws -> CKShare {
        guard let documentID = document.objectID.uriRepresentation().absoluteString.data(using: .utf8) else {
            throw CloudKitError.invalidDocument
        }
        
        let recordID = CKRecord.ID(recordName: document.id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: "Document", recordID: recordID)
        
        record["name"] = document.name
        record["createdDate"] = document.createdDate
        record["modifiedDate"] = document.modifiedDate
        record["documentData"] = documentID
        
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = document.name
        share.publicPermission = .none
        
        let operation = CKModifyRecordsOperation(
            recordsToSave: [record, share],
            recordIDsToDelete: nil
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
    }
    
    func stopSharingDocument(_ document: Document) async throws {
        guard let shareRecordName = document.shareMetadata else { return }
        
        // In a real implementation, you would:
        // 1. Get the CKShare record
        // 2. Delete it from CloudKit
        // 3. Update the local document
        
        // For now, we'll just update locally
        document.isShared = false
        document.shareMetadata = nil
    }
    
    // MARK: - User Presence
    
    func updateUserPresence(for document: Document, location: CLLocationCoordinate2D?) async {
        guard isAvailable else { return }
        
        let presence = UserPresence(
            userID: await getCurrentUserID(),
            documentID: document.id?.uuidString ?? "",
            location: location,
            lastSeen: Date()
        )
        
        // Update local presence
        await MainActor.run {
            userPresences[presence.userID] = presence
        }
        
        // In a real implementation, you would save this to CloudKit
        // For now, we'll simulate it
    }
    
    func observeUserPresence(for document: Document) async {
        // In a real implementation, you would:
        // 1. Set up a CKQuerySubscription for presence updates
        // 2. Handle real-time notifications
        // 3. Update the userPresences dictionary
        
        // For demo purposes, we'll simulate some users
        let simulatedUsers = ["user1", "user2"]
        
        for userID in simulatedUsers {
            let presence = UserPresence(
                userID: userID,
                documentID: document.id?.uuidString ?? "",
                location: CLLocationCoordinate2D(
                    latitude: 37.7749 + Double.random(in: -0.01...0.01),
                    longitude: -122.4194 + Double.random(in: -0.01...0.01)
                ),
                lastSeen: Date()
            )
            
            await MainActor.run {
                userPresences[userID] = presence
            }
        }
    }
    
    private func getCurrentUserID() async -> String {
        // In a real implementation, you would get the actual CloudKit user ID
        return "currentUser"
    }
}

// MARK: - Supporting Types

struct UserPresence {
    let userID: String
    let documentID: String
    let location: CLLocationCoordinate2D?
    let lastSeen: Date
}

enum CloudKitError: Error {
    case invalidDocument
    case sharingFailed
    case networkUnavailable
    
    var localizedDescription: String {
        switch self {
        case .invalidDocument:
            return "Invalid document for sharing"
        case .sharingFailed:
            return "Failed to set up document sharing"
        case .networkUnavailable:
            return "CloudKit is not available"
        }
    }
}