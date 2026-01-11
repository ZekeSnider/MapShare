import SwiftUI
import CoreData
internal import CloudKit

struct DocumentShareView: View {
    let document: Document
    @Binding var isPresented: Bool
    
    @State private var share: CKShare?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Preparing share...")
                }
            } else if let share = share {
                CloudSharingView(share: share, container: CKContainer.default(), document: document)
            } else {
                VStack {
                    Text("Could not create or fetch share.")
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear(perform: loadShare)
    }
    
    private func loadShare() {
        Task {
            isLoading = true
            
            // Check if a share already exists
            let existingShare = await CloudKitService.shared.getShare(for: document)
            
            if let existingShare = existingShare {
                self.share = existingShare
            } else {
                // If not, create a new share
                await CloudKitService.shared.shareDocument(document)
                self.share = await CloudKitService.shared.getShare(for: document)
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
