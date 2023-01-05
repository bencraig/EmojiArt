//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Benjamin Craig on 12/23/22.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    let defaultEmojiFontSize: CGFloat = 40
    var body: some View {
        VStack(spacing: 0){
            documentBody
            palette
        }
    }
    
    let selectionColors: [Color] = [.teal, .red, .orange, .yellow, .green,
                           .blue, .purple, .pink, .mint, .indigo]

    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                )
                .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(3)
                } else {
                    ForEach(document.emojis) { emoji in
                        ZStack {
                                Circle()
                                .frame(width:fontSize(for: emoji) * (emoji.isSelected ? selectedEmojiZoomScale : zoomScale) * 1.5 * (emoji.isSelected ? 1 : 0), height:fontSize(for: emoji) * (emoji.isSelected ? selectedEmojiZoomScale : zoomScale) * 1.5 * (emoji.isSelected ? 1 : 0))
                                    .position(position(for: emoji, in: geometry))
                                    .foregroundColor(selectionColors[(emoji.id%selectionColors.count)])
                            Text(emoji.text)
                                .font(.system(size: fontSize(for: emoji)))
                                .scaleEffect((emoji.isSelected ? selectedEmojiZoomScale : zoomScale))
                                .position(position(for: emoji, in: geometry))
                                .gesture (tapEmoji(emoji).simultaneously(with: longPressEmoji(emoji)).simultaneously(with:emoji.isSelected ? panEmoji() : nil))
                        }
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted:nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()).simultaneously(with: backgroundTapGesture()))
        }
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType:URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }
        if !found {
            found = providers.loadObjects(ofType:UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale)
                }
            }
        }
        
        return found
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        var panOffset = CGSize.zero
        if emoji.isSelected {
            panOffset = emojiGesturePanOffset
        }
        return convertFromEmojiCoordinates((emoji.x + Int(panOffset.width), emoji.y + Int(panOffset.height)), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - center.x - backgroundPanOffset.width) / zoomScale,
            y: (location.y - center.y - backgroundPanOffset.height) / zoomScale
        )
        
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint (
            x: center.x + CGFloat(location.x) * zoomScale + backgroundPanOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + backgroundPanOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func backgroundTapGesture() -> some Gesture {
        TapGesture()
            .onEnded {
                withAnimation {
                    document.deselectEmojis()
                }
            }
    }
    
    private func tapEmoji(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture()
            .onEnded() {
                withAnimation (Animation.spring()) {
                    document.select(emoji)
                }
            }
    }
    
    private func longPressEmoji(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        LongPressGesture()
            .onEnded() { _ in
                document.delete(emoji)
            }
    }
    
    @State private var backgroundSteadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var backgroundGesturePanOffset: CGSize = CGSize.zero

    private var backgroundPanOffset: CGSize {
        (backgroundSteadyStatePanOffset + backgroundGesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($backgroundGesturePanOffset) { latestDragGestureValue, backgroundGesturePanOffset, _ in
                backgroundGesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                backgroundSteadyStatePanOffset = backgroundSteadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    @GestureState private var emojiGesturePanOffset: CGSize = CGSize.zero
    
    private func panEmoji() -> some Gesture {
        DragGesture()
            .updating($emojiGesturePanOffset) { latestDragGestureValue, emojiGesturePanOffset, _ in
                emojiGesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                document.updateSelectedEmojiPositions(byOffset: (finalDragGestureValue.translation / zoomScale))
            }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: (background: CGFloat, selection: CGFloat) = (1, 1)
        
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale.background
    }
    
    private var selectedEmojiZoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale.selection
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                if document.emojiSelected() {
                    gestureZoomScale.selection = latestGestureScale
                } else {
                    gestureZoomScale.background = latestGestureScale
                }
            }
            .onEnded { gestureScaleAtEnd in
                if document.emojiSelected() {
                    document.scaleSelectedEmojis(by: gestureScaleAtEnd)
                } else {
                    steadyStateZoomScale *= gestureScaleAtEnd
                }
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "😀😷🦠💉👻👀🐶🌲🌎🌞🔥🍎⚽️🚗🚓🚲🛩🚁🚀🛸🏠⌚️🎁🗝🔐❤️⛔️❌❓✅⚠️🎶➕➖🏳️"
}

struct ScrollingEmojisView: View {
    let emojis: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}








struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
