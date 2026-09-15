// Run: swift scripts/generate-app-icon.swift
// Original vector artwork: four flowing fingerprint ridges and the winner sparkle.
// iOS supplies the corner mask. Every exported variant is opaque, 1024 × 1024.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpaceCreateDeviceRGB()

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

func fingerprint(in context: CGContext) {
    context.setLineWidth(40)
    context.setLineCap(.round)
    context.setLineJoin(.round)

    let outer = CGMutablePath()
    outer.move(to: CGPoint(x: 235, y: 370))
    outer.addCurve(to: CGPoint(x: 447, y: 781), control1: CGPoint(x: 235, y: 596), control2: CGPoint(x: 250, y: 750))
    outer.addCurve(to: CGPoint(x: 745, y: 514), control1: CGPoint(x: 609, y: 807), control2: CGPoint(x: 745, y: 683))
    outer.addCurve(to: CGPoint(x: 632, y: 196), control1: CGPoint(x: 745, y: 332), control2: CGPoint(x: 695, y: 244))
    context.addPath(outer)
    context.strokePath()

    let middle = CGMutablePath()
    middle.move(to: CGPoint(x: 293, y: 302))
    middle.addCurve(to: CGPoint(x: 302, y: 526), control1: CGPoint(x: 318, y: 362), control2: CGPoint(x: 300, y: 437))
    middle.addCurve(to: CGPoint(x: 480, y: 715), control1: CGPoint(x: 306, y: 660), control2: CGPoint(x: 386, y: 716))
    middle.addCurve(to: CGPoint(x: 678, y: 511), control1: CGPoint(x: 597, y: 714), control2: CGPoint(x: 678, y: 629))
    middle.addCurve(to: CGPoint(x: 564, y: 215), control1: CGPoint(x: 678, y: 354), control2: CGPoint(x: 632, y: 267))
    context.addPath(middle)
    context.strokePath()

    let inner = CGMutablePath()
    inner.move(to: CGPoint(x: 361, y: 266))
    inner.addCurve(to: CGPoint(x: 370, y: 515), control1: CGPoint(x: 400, y: 360), control2: CGPoint(x: 370, y: 452))
    inner.addCurve(to: CGPoint(x: 480, y: 648), control1: CGPoint(x: 370, y: 598), control2: CGPoint(x: 406, y: 649))
    inner.addCurve(to: CGPoint(x: 611, y: 514), control1: CGPoint(x: 557, y: 648), control2: CGPoint(x: 611, y: 594))
    inner.addCurve(to: CGPoint(x: 541, y: 290), control1: CGPoint(x: 611, y: 394), control2: CGPoint(x: 586, y: 336))
    context.addPath(inner)
    context.strokePath()

    let heart = CGMutablePath()
    heart.move(to: CGPoint(x: 432, y: 238))
    heart.addCurve(to: CGPoint(x: 437, y: 511), control1: CGPoint(x: 466, y: 356), control2: CGPoint(x: 437, y: 459))
    heart.addCurve(to: CGPoint(x: 480, y: 581), control1: CGPoint(x: 437, y: 552), control2: CGPoint(x: 451, y: 581))
    heart.addCurve(to: CGPoint(x: 544, y: 513), control1: CGPoint(x: 519, y: 581), control2: CGPoint(x: 544, y: 554))
    heart.addCurve(to: CGPoint(x: 514, y: 373), control1: CGPoint(x: 544, y: 444), control2: CGPoint(x: 531, y: 402))
    context.addPath(heart)
    context.strokePath()
}

func sparkle(in context: CGContext, x: CGFloat, y: CGFloat) {
    context.beginPath()
    context.move(to: CGPoint(x: x, y: y + 77))
    context.addCurve(to: CGPoint(x: x + 77, y: y), control1: CGPoint(x: x + 15, y: y + 20), control2: CGPoint(x: x + 20, y: y + 15))
    context.addCurve(to: CGPoint(x: x, y: y - 77), control1: CGPoint(x: x + 20, y: y - 15), control2: CGPoint(x: x + 15, y: y - 20))
    context.addCurve(to: CGPoint(x: x - 77, y: y), control1: CGPoint(x: x - 15, y: y - 20), control2: CGPoint(x: x - 20, y: y - 15))
    context.addCurve(to: CGPoint(x: x, y: y + 77), control1: CGPoint(x: x - 20, y: y + 15), control2: CGPoint(x: x - 15, y: y + 20))
    context.fillPath()
}

for variant in ["", "-dark", "-tinted"] {
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                            bytesPerRow: size * 4, space: space,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let tinted = variant == "-tinted"
    let dark = variant == "-dark"
    context.setFillColor(color(tinted ? 0x090909 : (dark ? 0x0A100C : 0x142019)))
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    if !tinted {
        let gradient = CGGradient(colorsSpace: space,
                                  colors: [color(0x567C32, alpha: dark ? 0.11 : 0.26), color(0x142019, alpha: 0)] as CFArray,
                                  locations: [0, 1])!
        context.drawRadialGradient(gradient, startCenter: CGPoint(x: 430, y: 630), startRadius: 0,
                                   endCenter: CGPoint(x: 430, y: 630), endRadius: 720, options: [.drawsAfterEndLocation])
    }
    context.saveGState()
    context.translateBy(x: 482, y: 495)
    context.rotate(by: -.pi / 20)
    context.translateBy(x: -482, y: -495)
    context.setStrokeColor(color(tinted ? 0xF2F2F2 : 0xC4F488))
    fingerprint(in: context)
    context.restoreGState()

    context.setFillColor(color(tinted ? 0xFFFFFF : 0xC1AEF4))
    sparkle(in: context, x: 783, y: 765)

    let url = URL(fileURLWithPath: "Fingr/Assets.xcassets/AppIcon.appiconset/AppIcon\(variant).png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
    print("Wrote \(url.lastPathComponent)")
}
