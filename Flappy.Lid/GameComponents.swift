import SwiftUI

struct BirdView: View {
    let rotation: Double
    
    var body: some View {
        // Placeholder for Bird Image
        Rectangle()
            .fill(Color.yellow) // TODO: Replace with Image("Bird")
            //.overlay(Image("Bird").resizable())
            .frame(width: 40, height: 40)
            .border(Color.black, width: 2)
            .rotationEffect(.degrees(rotation))
    }
}

struct PipeView: View {
    let isTop: Bool
    let height: CGFloat
    let width: CGFloat = 52
    
    var body: some View {
        // Placeholder for Pipe Image
        // If Top, flipped? 
        Rectangle()
            .fill(Color.green) // TODO: Replace with Image("PipeUp") or Image("PipeDown")
            //.overlay(Image(isTop ? "PipeDown" : "PipeUp").resizable())
            .frame(width: width, height: height)
            .border(Color.black, width: 2)
            .overlay(
                // Rim for placeholder detail
                Rectangle()
                    .fill(Color.green.opacity(0.8))
                    .frame(height: 20)
                    .border(Color.black, width: 2),
                alignment: isTop ? .bottom : .top
            )
    }
}
