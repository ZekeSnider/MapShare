internal import CloudKit
import CoreData
import CoreLocation
import Foundation
import Observation

@Observable
class CloudKitService {
    static let shared = CloudKitService()

    private let persistentContainer = PersistenceController.shared.container
    private let cloudKitContainer = CKContainer(identifier: CloudKitConfig.containerIdentifier)

    var isAvailable = false
    var userPresences: [String: UserPresence] = [:]

    private init() {
        checkCloudKitAvailability()
        requestUserDiscoverability()
    }

    private func checkCloudKitAvailability() {
        cloudKitContainer.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.isAvailable = (status == .available)
            }
        }
    }

    private func requestUserDiscoverability() {
        Task {
            do {
                let status = try await cloudKitContainer.requestApplicationPermission(.userDiscoverability)
                print("User discoverability status: \(status.rawValue)")
            } catch {
                print("Failed to request user discoverability: \(error)")
            }
        }
    }
    
    // MARK: - Document Sharing

    func getShare(for document: Document) async -> CKShare? {
        do {
            let shares = try await persistentContainer.fetchShares(matching: [document.objectID])
            return shares[document.objectID]
        } catch {
            print("Failed to fetch share for document: \(error)")
            return nil
        }
    }

    func shareDocument(_ document: Document) async {
        do {
            _ = try await persistentContainer.share([document], to: nil)
        } catch {
            print("Failed to share document: \(error)")
        }
    }

    func createShare(for document: Document) async -> CKShare? {
        do {
            print("Attempting to create share for document: \(document.objectID)")
            let (objectIDs, share, container) = try await persistentContainer.share([document], to: nil)
            print("Share created - objectIDs: \(objectIDs), share: \(share), container: \(container)")
            return share
        } catch let error as NSError {
            print("Failed to create share: \(error)")
            print("Error domain: \(error.domain), code: \(error.code)")
            print("Error userInfo: \(error.userInfo)")
            return nil
        }
    }

    func stopSharing(share: CKShare) async {
//        do {
//            try await persistentContainer.purgeObjectsAndRecords(in: [share.recordID], in: .private)
//        } catch {
//            print("Failed to stop sharing: \(error)")
//        }
    }

    func getCurrentUserRecordID() async -> CKRecord.ID? {
        do {
            return try await cloudKitContainer.userRecordID()
        } catch {
            print("Failed to fetch user record ID: \(error)")
            return nil
        }
    }

    func getCurrentUserDisplayName() async -> String? {
        do {
            let recordID = try await cloudKitContainer.userRecordID()
            let identity = try await cloudKitContainer.userIdentity(forUserRecordID: recordID)
            if let nameComponents = identity?.nameComponents {
                return PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .short)
            }
            return nil
        } catch {
            print("Failed to fetch user identity: \(error)")
            return nil
        }
    }

    func getCurrentUserIdentity() async -> CKUserIdentity? {
        do {
            let recordID = try await cloudKitContainer.userRecordID()
            return try await cloudKitContainer.userIdentity(forUserRecordID: recordID)
        } catch {
            print("Failed to fetch user identity: \(error)")
            return nil
        }
    }

    func getCurrentUserAsParticipant(in context: NSManagedObjectContext) async -> Participant? {
        guard let recordID = await getCurrentUserRecordID() else {
            return nil
        }

        let identity = await getCurrentUserIdentity()
        let nameComponents = identity?.nameComponents
        let lookupInfo = identity?.lookupInfo

        return await MainActor.run {
            return Participant.findOrCreate(
                cloudKitRecordID: recordID.recordName,
                givenName: nameComponents?.givenName ?? "Me",
                familyName: nameComponents?.familyName,
                email: lookupInfo?.emailAddress,
                phoneNumber: lookupInfo?.phoneNumber,
                in: context
            )
        }
    }

    // MARK: - User Presence
    
    func updateUserPresence(for document: Document, location: CLLocationCoordinate2D?) async {
        guard isAvailable else { return }
        
        let presence = UserPresence(
            userID: (try? await cloudKitContainer.userRecordID().recordName) ?? "currentUser",
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
