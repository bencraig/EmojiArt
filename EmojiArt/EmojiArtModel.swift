//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Benjamin Craig on 12/23/22.
//

import Foundation

struct EmojiArtModel {
    var background = Background.blank
    var emojis = [Emoji]()
        
    struct Emoji: Identifiable, Hashable {
        let text: String
        var x: Int // UI independent model, not cgfloats.
        var y: Int // offset from center
        var size: Int
        var id: Int
        var isSelected: Bool = false
        
        fileprivate init (text: String, x: Int, y: Int, size: Int, id: Int){
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    init () { }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int ) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
    

}
