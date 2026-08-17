import SwiftUI

enum Pixel {
    static let red = Color(red: 0.93, green: 0.08, blue: 0.08)
    static let darkRed = Color(red: 0.65, green: 0.05, blue: 0.05)
    static let cream = Color(red: 0.97, green: 0.97, blue: 0.90)
    static let navy = Color(red: 0.12, green: 0.13, blue: 0.20)
    static let yellow = Color(red: 1.0, green: 0.80, blue: 0.11)
    static let blue = Color(red: 0.20, green: 0.44, blue: 0.85)
    static let green = Color(red: 0.30, green: 0.70, blue: 0.34)
    static let border = Color.black

    static func font(_ size: CGFloat) -> Font {
        Font.custom("Menlo", size: size).monospaced().weight(.bold)
    }
}

struct PixelBoxModifier: ViewModifier {
    var fill: Color = Pixel.cream
    var stroke: Color = Pixel.border
    var lineWidth: CGFloat = 3

    func body(content: Content) -> some View {
        content
            .background(fill)
            .overlay(
                Rectangle().stroke(stroke, lineWidth: lineWidth)
            )
    }
}

extension View {
    func pixelBox(fill: Color = Pixel.cream, stroke: Color = Pixel.border, lineWidth: CGFloat = 3) -> some View {
        modifier(PixelBoxModifier(fill: fill, stroke: stroke, lineWidth: lineWidth))
    }
}

struct PixelButtonStyle: ButtonStyle {
    var tint: Color = Pixel.yellow
    var textColor: Color = Pixel.navy

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Pixel.font(11))
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint)
            .overlay(Rectangle().stroke(Pixel.border, lineWidth: 2))
            .offset(y: configuration.isPressed ? 2 : 0)
            .shadow(color: configuration.isPressed ? .clear : Pixel.border, radius: 0, x: 0, y: configuration.isPressed ? 0 : 2)
    }
}
