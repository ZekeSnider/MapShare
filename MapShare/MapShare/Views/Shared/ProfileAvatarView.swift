import SwiftUI
import UIKit
import CoreData

struct ProfileAvatarView: View {
    let participant: Participant
    let size: CGFloat

    @State private var photoData: Data?
    @State private var hasLoadedPhoto = false

    var body: some View {
        Group {
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Initials fallback
                Circle()
                    .fill(participant.avatarColor)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(participant.initials)
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
        }
        .task {
            guard !hasLoadedPhoto else { return }
            hasLoadedPhoto = true

            // First check cache
            if let cached = ContactsService.shared.getCachedPhoto(for: participant) {
                photoData = cached
                return
            }

            // Then fetch async
            photoData = await ContactsService.shared.fetchProfilePhoto(for: participant)
        }
    }
}

struct ProfileAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let participant = Participant(context: context)
        participant.givenName = "John"
        participant.familyName = "Doe"
        participant.cloudKitRecordID = "test-user-123"

        return VStack(spacing: 20) {
            ProfileAvatarView(participant: participant, size: 24)
            ProfileAvatarView(participant: participant, size: 36)
            ProfileAvatarView(participant: participant, size: 50)
        }
        .padding()
    }
}
