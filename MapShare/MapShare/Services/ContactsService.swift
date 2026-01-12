import Contacts
import SwiftUI

@Observable
class ContactsService {
    static let shared = ContactsService()

    private let store = CNContactStore()
    private var photoCache: [String: Data] = [:]
    private var authorizationStatus: CNAuthorizationStatus = .notDetermined

    private init() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccessIfNeeded() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            do {
                let granted = try await store.requestAccess(for: .contacts)
                await MainActor.run {
                    authorizationStatus = granted ? .authorized : .denied
                }
                return granted
            } catch {
                print("Failed to request contacts access: \(error)")
                return false
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func fetchProfilePhoto(for participant: Participant) async -> Data? {
        // Check cache first
        if let cachedPhoto = photoCache[participant.cloudKitRecordID ?? ""] {
            return cachedPhoto
        }

        guard await requestAccessIfNeeded() else {
            return nil
        }

        // Try to find contact by email or phone
        var predicates: [NSPredicate] = []

        if let email = participant.email, !email.isEmpty {
            predicates.append(CNContact.predicateForContacts(matchingEmailAddress: email))
        }

        if let phone = participant.phoneNumber, !phone.isEmpty {
            let phoneNumber = CNPhoneNumber(stringValue: phone)
            predicates.append(CNContact.predicateForContacts(matching: phoneNumber))
        }

        // Also try by name if we have it
        if let givenName = participant.givenName, let familyName = participant.familyName,
           !givenName.isEmpty && !familyName.isEmpty {
            predicates.append(CNContact.predicateForContacts(matchingName: "\(givenName) \(familyName)"))
        }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]

        for predicate in predicates {
            do {
                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                if let contact = contacts.first {
                    let imageData = contact.thumbnailImageData ?? contact.imageData
                    if let imageData = imageData {
                        photoCache[participant.cloudKitRecordID ?? ""] = imageData
                        return imageData
                    }
                }
            } catch {
                print("Failed to fetch contact: \(error)")
            }
        }

        return nil
    }

    func getCachedPhoto(for participant: Participant) -> Data? {
        return photoCache[participant.cloudKitRecordID ?? ""]
    }
}
