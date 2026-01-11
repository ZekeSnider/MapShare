import SwiftUI
import CoreData

struct DocumentShareView: View {
    let document: Document
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isSharing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if document.isShared {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Document is Shared")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This document is being shared with others.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Stop Sharing") {
                            stopSharing()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Share \"\(document.name ?? "Document")\"")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Share this map with others for collaboration.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button(isSharing ? "Setting up sharing..." : "Start Sharing") {
                            startSharing()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSharing)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func startSharing() {
        isSharing = true
        
        // Simulate sharing setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            document.isShared = true
            document.modifiedDate = Date()
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to enable sharing: \(error)")
            }
            
            isSharing = false
        }
    }
    
    private func stopSharing() {
        document.isShared = false
        document.modifiedDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to stop sharing: \(error)")
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