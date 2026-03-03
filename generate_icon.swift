#!/usr/bin/swift
//
//  generate_icon.swift
//  Renders the Aurae app icon using CoreGraphics and saves PNG assets
//  directly into Assets.xcassets/AppIcon.appiconset/.
//
//  Run: swift /path/to/generate_icon.swift
//

import CoreGraphics
import Foundation
import ImageIO

// MARK: - Color helpers

let cs = CGColorSpaceCreateDeviceRGB()

func cgColor(hex h: String, alpha a: CGFloat = 1) -> CGColor {
    var s = h.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var rgb: UInt64 = 0
    Scanner(string: s).scanHexInt64(&rgb)
    return CGColor(
        colorSpace: cs,
        components: [
            CGFloat((rgb >> 16) & 0xFF) / 255,
            CGFloat((rgb >>  8) & 0xFF) / 255,
            CGFloat( rgb        & 0xFF) / 255,
            a
        ]
    )!
}

// MARK: - Icon renderer

/// Draws the Aurae icon into `ctx` at the given `size`.
/// Coordinate origin is bottom-left (CoreGraphics default).
func drawIcon(ctx: CGContext, size: CGFloat) {
    let cx = size / 2
    let cy = size / 2

    // ── 1. Background ──────────────────────────────────────────────────────
    ctx.setFillColor(cgColor(hex: "0D0E11"))
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // ── 2. Teal radial bloom — centered, 14 % opacity ─────────────────────
    let bloomGrad = CGGradient(
        colorsSpace: cs,
        colors: [cgColor(hex: "2D7D7D", alpha: 0.14),
                 cgColor(hex: "2D7D7D", alpha: 0.00)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        bloomGrad,
        startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
        endCenter:   CGPoint(x: cx, y: cy), endRadius: size * 0.50,
        options: []
    )

    // ── 3. Concentric halo rings ───────────────────────────────────────────
    // SwiftUI fills each ellipse with the gradient mapped to THAT ellipse's
    // own bounding box (topLeading→bottomTrailing of the frame). We must
    // replicate this: for each ring with radius r, the gradient spans from
    // the ring's top-left corner to its bottom-right corner.
    //
    // CG origin is bottom-left, so screen top-left of a ring's bbox
    // = CG point (cx - r, cy + r), and screen bottom-right = (cx + r, cy - r).
    let markGrad = CGGradient(
        colorsSpace: cs,
        colors: [cgColor(hex: "2D7D7D"), cgColor(hex: "B3A8D9")] as CFArray,
        locations: [0, 1]
    )!

    // Proportions from AuraeLogoMark: outer=1.0, middle=0.71, inner=0.41
    let outerR  = size * 0.57 / 2          // 291.8 @ 1024
    let middleR = outerR * 0.71            // 207.2
    let innerR  = outerR * 0.41            // 119.6

    func ring(_ radius: CGFloat, alpha: CGFloat) {
        let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
        // Gradient spans this ring's own bounding box (matches SwiftUI .fill behaviour)
        let gradStart = CGPoint(x: cx - radius, y: cy + radius)  // top-left in CG space
        let gradEnd   = CGPoint(x: cx + radius, y: cy - radius)  // bottom-right in CG space
        ctx.saveGState()
        ctx.setAlpha(alpha)
        ctx.addEllipse(in: rect)
        ctx.clip()
        ctx.drawLinearGradient(markGrad, start: gradStart, end: gradEnd, options: [])
        ctx.restoreGState()
    }

    ring(outerR,  alpha: 0.14)   // outer ring — very faint halo
    ring(middleR, alpha: 0.35)   // middle ring — intermediate
    ring(innerR,  alpha: 1.00)   // inner core — full opacity
}

// MARK: - PNG export

func exportPNG(to path: String, size: Int) {
    guard let ctx = CGContext(
        data: nil,
        width: size, height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("CGContext creation failed") }

    drawIcon(ctx: ctx, size: CGFloat(size))

    guard let img  = ctx.makeImage() else { fatalError("makeImage failed") }
    let url  = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { fatalError("Destination creation failed for \(path)") }

    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Finalize failed for \(path)") }
    print("  ✓  \(path)")
}

// MARK: - Run

let assetDir = FileManager.default.currentDirectoryPath
    + "/Aurae/Assets.xcassets/AppIcon.appiconset/"

print("Generating Aurae app icons into:\n  \(assetDir)\n")

exportPNG(to: assetDir + "AppIcon.png",        size: 1024)  // standard / light
exportPNG(to: assetDir + "AppIcon-Dark.png",   size: 1024)  // dark variant (same design)
exportPNG(to: assetDir + "AppIcon-Tinted.png", size: 1024)  // tinted variant

print("\nDone. Update Contents.json filenames if not already set.")
