//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Benjamin Craig on 12/23/22.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
