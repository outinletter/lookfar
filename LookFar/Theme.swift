import SwiftUI

enum Palette {
    static let background = Color(red: 0.075, green: 0.045, blue: 0.09)
    static let card = Color(red: 0.13, green: 0.095, blue: 0.145)
    static let ivory = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let coral = Color(red: 1, green: 0.49, blue: 0.37)
    static let muted = Color(red: 0.69, green: 0.64, blue: 0.70)
    static let sage = Color(red: 0.70, green: 0.79, blue: 0.65)
}

struct FilledButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 19)
            .background(Palette.coral.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 22))
            .foregroundStyle(Palette.background)
    }
}

struct HorizonView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle().fill(Palette.coral).frame(width: h * 0.38, height: h * 0.38)
                    .position(x: w * 0.68, y: h * 0.36)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.75))
                    p.addCurve(to: CGPoint(x: w, y: h * 0.65), control1: CGPoint(x: w * 0.3, y: h * 0.15), control2: CGPoint(x: w * 0.6, y: h * 1.05))
                    p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
                }.fill(Palette.sage.opacity(0.4))
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.85))
                    p.addCurve(to: CGPoint(x: w, y: h * 0.66), control1: CGPoint(x: w * 0.6, y: h * 1.1), control2: CGPoint(x: w * 0.5, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
                }.fill(Palette.sage)
            }
        }.accessibilityHidden(true)
    }
}

extension View {
    func lookFarCard() -> some View {
        padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 26))
    }
}
