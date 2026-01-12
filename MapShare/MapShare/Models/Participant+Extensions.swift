import Foundation
import CoreData
import SwiftUI

extension Participant {
    convenience init(cloudKitRecordID: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.cloudKitRecordID = cloudKitRecordID
    }

    var displayName: String {
        let given = givenName ?? ""
        let family = familyName ?? ""

        if !given.isEmpty && !family.isEmpty {
            return "\(given) \(family)"
        } else if !given.isEmpty {
            return given
        } else if !family.isEmpty {
            return family
        } else if let email = email {
            return email.components(separatedBy: "@").first ?? email
        } else {
            return "Unknown"
        }
    }

    var initials: String {
        let given = givenName ?? ""
        let family = familyName ?? ""

        let givenInitial = given.first.map { String($0).uppercased() } ?? ""
        let familyInitial = family.first.map { String($0).uppercased() } ?? ""

        if !givenInitial.isEmpty && !familyInitial.isEmpty {
            return "\(givenInitial)\(familyInitial)"
        } else if !givenInitial.isEmpty {
            return givenInitial
        } else if !familyInitial.isEmpty {
            return familyInitial
        } else if let email = email, let firstChar = email.first {
            return String(firstChar).uppercased()
        } else {
            return "?"
        }
    }

    var avatarColor: Color {
        // Generate a consistent color based on the cloudKitRecordID
        let hash = (cloudKitRecordID ?? id?.uuidString ?? "").hashValue
        let colors: [Color] = [
            Color(red: 255/255, green: 59/255, blue: 48/255),   // Red
            Color(red: 255/255, green: 149/255, blue: 0/255),   // Orange
            Color(red: 52/255, green: 199/255, blue: 89/255),   // Green
            Color(red: 0/255, green: 122/255, blue: 255/255),   // Blue
            Color(red: 88/255, green: 86/255, blue: 214/255),   // Purple
            Color(red: 175/255, green: 82/255, blue: 222/255),  // Violet
            Color(red: 255/255, green: 45/255, blue: 146/255),  // Pink
            Color(red: 90/255, green: 200/255, blue: 250/255),  // Teal
        ]
        return colors[abs(hash) % colors.count]
    }

    static func findOrCreate(
        cloudKitRecordID: String,
        givenName: String?,
        familyName: String?,
        email: String?,
        phoneNumber: String?,
        in context: NSManagedObjectContext
    ) -> Participant {
        let request: NSFetchRequest<Participant> = Participant.fetchRequest()
        request.predicate = NSPredicate(format: "cloudKitRecordID == %@", cloudKitRecordID)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            // Update with latest info
            if let givenName = givenName { existing.givenName = givenName }
            if let familyName = familyName { existing.familyName = familyName }
            if let email = email { existing.email = email }
            if let phoneNumber = phoneNumber { existing.phoneNumber = phoneNumber }
            return existing
        }

        let participant = Participant(cloudKitRecordID: cloudKitRecordID, context: context)
        participant.givenName = givenName
        participant.familyName = familyName
        participant.email = email
        participant.phoneNumber = phoneNumber
        return participant
    }
}
