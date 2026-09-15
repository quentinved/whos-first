#!/usr/bin/env swift
// Draws the Game Center achievement badges into Artwork/Achievements.
//
//   swift scripts/generate-achievement-art.swift
//
// App Store Connect wants 512 x 512 with no alpha channel, so every badge is drawn onto an
// opaque After Hours background rather than left transparent. The motifs are the app's own
// language — rings under fingers — so a badge reads as this app at list size.

import AppKit
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
import Foundation

let size = 512.0
let background = CGColor(red: 0x10 / 255, green: 0x12 / 255, blue: 0x1B / 255, alpha: 1)
let accent = CGColor(red: 0xC9 / 255, green: 0xF2 / 255, blue: 0x7A / 255, alpha: 1)
let secondary = CGColor(red: 0xB9 / 255, green: 0xA5 / 255, blue: 0xFF / 255, alpha: 1)
let tertiary = CGColor(red: 0xFF / 255, green: 0xB9 / 255, blue: 0x9B / 255, alpha: 1)
let ink = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

/// The six theme accents, for the badge that asks you to play all of them.
let themeAccents = [
    CGColor(red: 0xC9 / 255, green: 0xF2 / 255, blue: 0x7A / 255, alpha: 1),
    CGColor(red: 0xCF / 255, green: 0xBC / 255, blue: 0xFA / 255, alpha: 1),
    CGColor(red: 0xFF / 255, green: 0xB1 / 255, blue: 0x84 / 255, alpha: 1),
    CGColor(red: 0x8E / 255, green: 0xDF / 255, blue: 0xEB / 255, alpha: 1),
    CGColor(red: 0xF6 / 255, green: 0xAA / 255, blue: 0xCB / 255, alpha: 1),
    CGColor(red: 0xCE / 255, green: 0xDB / 255, blue: 0xA0 / 255, alpha: 1),
]

func context() -> CGContext {
    // No alpha: premultipliedNone with an opaque fill is what App Store Connect accepts.
    guard let context = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fatalError("could not make a bitmap context")
    }
    context.setFillColor(background)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    // A soft glow, the same one the board has behind the rings.
    let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [CGColor(red: 0x20 / 255, green: 0x23 / 255, blue: 0x31 / 255, alpha: 1),
                                   background] as CFArray,
                          locations: [0, 1])!
    context.drawRadialGradient(glow, startCenter: CGPoint(x: size / 2, y: size * 0.58), startRadius: 0,
                               endCenter: CGPoint(x: size / 2, y: size * 0.58), endRadius: size * 0.55,
                               options: [])
    return context
}

func ring(_ context: CGContext, radius: Double, width: Double, color: CGColor, alpha: Double = 1) {
    context.setStrokeColor(color.copy(alpha: alpha) ?? color)
    context.setLineWidth(width)
    context.strokeEllipse(in: CGRect(x: size / 2 - radius, y: size / 2 - radius,
                                     width: radius * 2, height: radius * 2))
}

func dot(_ context: CGContext, at point: CGPoint, radius: Double, color: CGColor) {
    context.setFillColor(color)
    context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius,
                                   width: radius * 2, height: radius * 2))
}

func text(_ context: CGContext, _ string: String, size fontSize: Double, color: CGColor, dy: Double = 0) {
    let font = CTFontCreateWithName("SFProRounded-Bold" as CFString, fontSize, nil)
    let attributed = NSAttributedString(string: string, attributes: [
        .font: font,
        .foregroundColor: NSColor(cgColor: color) ?? .white,
        .kern: -fontSize * 0.04,
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    context.textPosition = CGPoint(x: (size - bounds.width) / 2 - bounds.minX,
                                   y: (size - bounds.height) / 2 - bounds.minY + dy)
    CTLineDraw(line, context)
}

/// Every badge: an outer ring, then its own motif.
func draw(_ id: String) -> CGContext {
    let context = context()
    ring(context, radius: 196, width: 6, color: accent, alpha: 0.22)

    switch id {
    case "first.call":
        ring(context, radius: 140, width: 10, color: accent, alpha: 0.5)
        dot(context, at: CGPoint(x: size / 2, y: size / 2), radius: 92, color: accent)
        text(context, "1", size: 150, color: background)
    case "rounds.10":
        ring(context, radius: 150, width: 12, color: accent)
        text(context, "10", size: 150, color: ink)
    case "rounds.50":
        ring(context, radius: 150, width: 12, color: secondary)
        text(context, "50", size: 140, color: ink)
    case "rounds.250":
        ring(context, radius: 150, width: 14, color: tertiary)
        text(context, "250", size: 112, color: ink)
    case "teams.first":
        // Two rings facing off, the A and B of a split room.
        dot(context, at: CGPoint(x: size * 0.34, y: size / 2), radius: 96, color: accent)
        dot(context, at: CGPoint(x: size * 0.66, y: size / 2), radius: 96, color: secondary)
        context.setFillColor(background)
        context.fill(CGRect(x: size / 2 - 7, y: 0, width: 14, height: size))
    case "table.ten":
        // Ten fingers, arranged the way they land on the board.
        for index in 0 ..< 10 {
            let angle = Double(index) / 10 * 2 * .pi - .pi / 2
            dot(context, at: CGPoint(x: size / 2 + cos(angle) * 140, y: size / 2 + sin(angle) * 140),
                radius: 34, color: index.isMultiple(of: 2) ? accent : secondary)
        }
        text(context, "10", size: 96, color: ink)
    case "dare.ten":
        ring(context, radius: 150, width: 12, color: tertiary)
        text(context, "!", size: 210, color: tertiary)
    case "themes.all":
        // One dot per theme, in the order they appear in Appearance.
        for (index, colour) in themeAccents.enumerated() {
            let angle = Double(index) / Double(themeAccents.count) * 2 * .pi - .pi / 2
            dot(context, at: CGPoint(x: size / 2 + cos(angle) * 128, y: size / 2 + sin(angle) * 128),
                radius: 54, color: colour)
        }
    default:
        fatalError("no artwork defined for \(id)")
    }
    return context
}

let ids = ["first.call", "rounds.10", "rounds.50", "rounds.250",
           "teams.first", "table.ten", "dare.ten", "themes.all"]

let output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Artwork/Achievements")
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for id in ids {
    guard let image = draw(id).makeImage() else { fatalError("\(id): could not render") }
    let url = output.appendingPathComponent("\(id).png")
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        fatalError("\(id): could not open \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("\(id): could not write \(url.path)") }
    print("wrote \(url.lastPathComponent)")
}
