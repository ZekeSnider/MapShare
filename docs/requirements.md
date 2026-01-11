# Requirements

## Overview
A native app for apple platforms that allows users to create collections of places and annotations, supporting tagging, filtering, rich notes, and sharing.

All items are grouped into different documents. Documents can be named, edited, and shared.

Technologies:
+ MapKit
+ SwiftUI
+ Core Data

Platforms:
+ iOS / iPadOS
+ macOS

## Entities

+ Place - POIs
    + Can be imported from Apple Maps POIs
    + Customizable:
        + Icon
        + Icon Color
        + Description (markdown)
+ Note — freeform pin without POI
    + Markdown content
+ Shape / Emoji annotations
+ Area - polygon
+ Route - polyline

## Functionality

Top level:
+ View documents
+ Add new document

In a document:
+ View map with entities
+ Add new entity
+ Edit entity
    + Collaboration
    +   Thumbs up / thumbs down on POIs
    +   Comment on POIs
+ Filter list of pins

## Collaboration

+ Use Apple "Shared with You" collaboration APIs to allow live editing and collaboration of documents
    + https://developer.apple.com/documentation/SharedWithYou/adding-shared-content-collaboration-to-your-app
    + https://developer.apple.com/documentation/CoreData/sharing-core-data-objects-between-icloud-users
+ View where other users are currently looking on the map
+ Allow users to Thumbs up / thumbs down on POIs 
