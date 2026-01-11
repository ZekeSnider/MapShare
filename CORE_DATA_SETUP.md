# Core Data Setup for MapShare

The build errors are likely because your Core Data model doesn't have the required entities. Here's how to fix this:

## Step 1: Update Your Core Data Model

1. **Open your `.xcdatamodeld` file** in Xcode (usually named `DataModel.xcdatamodeld` or similar)

2. **Delete the default Entity** that Xcode created

3. **Add these entities** with the exact attributes:

### Document Entity
- **Entity Name**: `Document`
- **Attributes**:
  - `id` - UUID (Optional: No)
  - `name` - String (Optional: Yes)
  - `createdDate` - Date (Optional: Yes)
  - `modifiedDate` - Date (Optional: Yes)  
  - `isShared` - Boolean (Optional: Yes, Default: NO)
  - `shareMetadata` - Binary Data (Optional: Yes)

### Place Entity
- **Entity Name**: `Place`
- **Attributes**:
  - `id` - UUID (Optional: No)
  - `name` - String (Optional: Yes)
  - `latitude` - Double (Optional: Yes, Default: 0)
  - `longitude` - Double (Optional: Yes, Default: 0)
  - `iconName` - String (Optional: Yes)
  - `iconColor` - String (Optional: Yes)
  - `descriptionText` - String (Optional: Yes)
  - `createdDate` - Date (Optional: Yes)
  - `modifiedDate` - Date (Optional: Yes)
  - `appleMapsPOIIdentifier` - String (Optional: Yes)

### Other Entities (Add these too):

#### Note Entity
- `id` - UUID (Optional: No)
- `content` - String (Optional: Yes)
- `latitude` - Double (Optional: Yes, Default: 0)
- `longitude` - Double (Optional: Yes, Default: 0)
- `createdDate` - Date (Optional: Yes)
- `modifiedDate` - Date (Optional: Yes)

#### Comment Entity  
- `id` - UUID (Optional: No)
- `content` - String (Optional: Yes)
- `authorName` - String (Optional: Yes)
- `createdDate` - Date (Optional: Yes)

#### Reaction Entity
- `id` - UUID (Optional: No)
- `type` - String (Optional: Yes)
- `authorName` - String (Optional: Yes)

## Step 2: Set Up Relationships

1. **Document to Places**: One-to-Many
   - Document: `places` (To-Many, Delete Rule: Cascade, Destination: Place, Inverse: document)
   - Place: `document` (To-One, Delete Rule: Nullify, Destination: Document, Inverse: places)

2. **Document to Notes**: One-to-Many
   - Document: `notes` (To-Many, Delete Rule: Cascade, Destination: Note, Inverse: document)
   - Note: `document` (To-One, Delete Rule: Nullify, Destination: Document, Inverse: notes)

3. **Place to Comments**: One-to-Many
   - Place: `comments` (To-Many, Delete Rule: Cascade, Destination: Comment, Inverse: place)
   - Comment: `place` (To-One, Delete Rule: Nullify, Destination: Place, Inverse: comments)

4. **Place to Reactions**: One-to-Many
   - Place: `reactions` (To-Many, Delete Rule: Cascade, Destination: Reaction, Inverse: place)
   - Reaction: `place` (To-One, Delete Rule: Nullify, Destination: Place, Inverse: reactions)

## Step 3: Configure Code Generation

For each entity:
1. Select the entity in Core Data model
2. In Data Model Inspector (right panel):
   - Set **Codegen** to "Category/Extension"
   - This auto-generates the classes

## Step 4: Update PersistenceController

Make sure your PersistenceController uses the correct model name:

```swift
container = NSPersistentCloudKitContainer(name: "YourModelName") // Use your actual .xcdatamodeld name
```

## Step 5: Build Settings

In Xcode Build Settings:
1. Make sure **Info.plist File** points to the correct Info.plist
2. Remove any duplicate asset references

## Quick Test

After setting up the entities, try building again. The errors should be resolved!

If you still get entity errors, make sure:
- Entity names match exactly (case-sensitive)
- All required attributes are present
- Relationships are properly configured
- Codegen is set correctly