#!/usr/bin/env swift

import AppKit

struct AssetGenerator {
    let assetsRoot: URL

    private let appIconSpecs: [(name: String, pixelSize: Int)] = [
        ("appicon-16.png", 16),
        ("appicon-16@2x.png", 32),
        ("appicon-32.png", 32),
        ("appicon-32@2x.png", 64),
        ("appicon-128.png", 128),
        ("appicon-128@2x.png", 256),
        ("appicon-256.png", 256),
        ("appicon-256@2x.png", 512),
        ("appicon-512.png", 512),
        ("appicon-512@2x.png", 1_024)
    ]

    private let menuBarSpecs: [(name: String, pixelSize: Int)] = [
        ("MenuBarIcon.png", 18),
        ("MenuBarIcon@2x.png", 36)
    ]

    var appIconDirectory: URL {
        assetsRoot.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
    }

    var menuBarDirectory: URL {
        assetsRoot.appendingPathComponent("MenuBarIcon.imageset", isDirectory: true)
    }

    func run() throws {
        try FileManager.default.createDirectory(at: appIconDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: menuBarDirectory, withIntermediateDirectories: true)

        for spec in appIconSpecs {
            try writeBitmap(named: spec.name, pixelSize: spec.pixelSize, to: appIconDirectory) { size in
                drawAppIcon(canvasSize: size)
            }
        }

        for spec in menuBarSpecs {
            try writeBitmap(named: spec.name, pixelSize: spec.pixelSize, to: menuBarDirectory) { size in
                drawMenuBarIcon(canvasSize: size)
            }
        }
    }

    private func writeBitmap(
        named name: String,
        pixelSize: Int,
        to directory: URL,
        draw: (CGFloat) -> Void
    ) throws {
        let bitmap = makeBitmap(pixelSize: pixelSize)

        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            fatalError("Could not create graphics context for \(name).")
        }

        NSGraphicsContext.current = context
        draw(CGFloat(pixelSize))
        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not encode \(name).")
        }

        try data.write(to: directory.appendingPathComponent(name))
    }

    private func makeBitmap(pixelSize: Int) -> NSBitmapImageRep {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            fatalError("Could not allocate bitmap for \(pixelSize)x\(pixelSize).")
        }

        bitmap.size = NSSize(width: pixelSize, height: pixelSize)
        return bitmap
    }

    private func drawAppIcon(canvasSize size: CGFloat) {
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        NSColor.clear.setFill()
        rect.fill()

        let cardRect = rect.insetBy(dx: size * 0.08, dy: size * 0.08)
        let cardRadius = size * 0.18
        let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: cardRadius, yRadius: cardRadius)

        withShadow(
            color: NSColor(calibratedWhite: 0, alpha: 0.18),
            blur: size * 0.045,
            offset: NSSize(width: 0, height: -size * 0.014)
        ) {
            NSColor.black.setFill()
            cardPath.fill()
        }

        let blueGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.32, green: 0.77, blue: 0.93, alpha: 1),
            NSColor(calibratedRed: 0.44, green: 0.73, blue: 0.97, alpha: 1),
            NSColor(calibratedRed: 0.54, green: 0.86, blue: 0.86, alpha: 1)
        ])!
        blueGradient.draw(in: cardPath, angle: 42)

        drawRadialGlow(
            center: CGPoint(x: cardRect.maxX - size * 0.2, y: cardRect.midY),
            startRadius: size * 0.04,
            endRadius: size * 0.32,
            innerColor: NSColor(calibratedRed: 0.83, green: 0.98, blue: 0.35, alpha: 0.9),
            outerColor: NSColor(calibratedRed: 0.83, green: 0.98, blue: 0.35, alpha: 0.0)
        )

        drawRadialGlow(
            center: CGPoint(x: cardRect.midX, y: cardRect.minY + size * 0.11),
            startRadius: size * 0.03,
            endRadius: size * 0.2,
            innerColor: NSColor.white.withAlphaComponent(0.18),
            outerColor: NSColor.white.withAlphaComponent(0)
        )

        NSColor.white.withAlphaComponent(0.16).setStroke()
        cardPath.lineWidth = size * 0.01
        cardPath.stroke()

        drawReflection(size: size, in: cardRect)
        drawSeatedFigure(canvasSize: size, baseRect: cardRect, isAppIcon: true)
    }

    private func drawMenuBarIcon(canvasSize size: CGFloat) {
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        NSColor.clear.setFill()
        rect.fill()

        drawRadialGlow(
            center: CGPoint(x: size * 0.68, y: size * 0.5),
            startRadius: size * 0.04,
            endRadius: size * 0.33,
            innerColor: NSColor(calibratedRed: 0.83, green: 0.98, blue: 0.35, alpha: 0.42),
            outerColor: NSColor(calibratedRed: 0.83, green: 0.98, blue: 0.35, alpha: 0)
        )

        drawSeatedFigure(
            canvasSize: size,
            baseRect: rect.insetBy(dx: size * 0.02, dy: size * 0.05),
            isAppIcon: false
        )
    }

    private func drawSeatedFigure(canvasSize size: CGFloat, baseRect: NSRect, isAppIcon: Bool) {
        let chairBlue = NSColor(calibratedRed: 0.54, green: 0.85, blue: 0.98, alpha: 0.78)
        let chairBlueDark = NSColor(calibratedRed: 0.29, green: 0.73, blue: 0.9, alpha: 0.92)
        let checkGreen = NSColor(calibratedRed: 0.44, green: 0.86, blue: 0.17, alpha: 1)
        let checkGreenDark = NSColor(calibratedRed: 0.26, green: 0.78, blue: 0.18, alpha: 1)
        let spineYellow = NSColor(calibratedRed: 0.99, green: 0.78, blue: 0.14, alpha: 1)
        let bodyWhite = NSColor(calibratedWhite: 0.99, alpha: 1)
        let bodyShade = NSColor(calibratedRed: 0.9, green: 0.95, blue: 0.98, alpha: 1)

        let chairStroke = max(size * (isAppIcon ? 0.045 : 0.062), 1.15)
        let figureStroke = max(size * (isAppIcon ? 0.07 : 0.085), 1.5)
        let armStroke = max(size * (isAppIcon ? 0.05 : 0.058), 1.2)
        let spineStroke = max(size * (isAppIcon ? 0.012 : 0.028), 0.9)
        let shadowBlur = size * (isAppIcon ? 0.03 : 0.05)

        let backPath = NSBezierPath()
        backPath.move(to: CGPoint(x: baseRect.minX + size * 0.22, y: baseRect.minY + size * 0.56))
        backPath.line(to: CGPoint(x: baseRect.minX + size * 0.3, y: baseRect.minY + size * 0.2))
        backPath.lineCapStyle = .round
        backPath.lineWidth = chairStroke

        let seatPath = NSBezierPath()
        seatPath.move(to: CGPoint(x: baseRect.minX + size * 0.29, y: baseRect.minY + size * 0.19))
        seatPath.line(to: CGPoint(x: baseRect.minX + size * 0.55, y: baseRect.minY + size * 0.19))
        seatPath.lineCapStyle = .round
        seatPath.lineWidth = chairStroke

        withShadow(color: NSColor.black.withAlphaComponent(0.12), blur: shadowBlur, offset: NSSize(width: 0, height: -size * 0.01)) {
            chairBlue.setStroke()
            backPath.stroke()
            seatPath.stroke()
        }

        chairBlueDark.withAlphaComponent(0.72).setStroke()
        backPath.lineWidth = max(chairStroke * 0.16, 0.8)
        seatPath.lineWidth = max(chairStroke * 0.18, 0.8)
        backPath.stroke()
        seatPath.stroke()

        let headRect = NSRect(
            x: baseRect.minX + size * 0.36,
            y: baseRect.minY + size * 0.62,
            width: size * 0.18,
            height: size * 0.18
        )
        let headPath = NSBezierPath(ovalIn: headRect)

        withShadow(color: NSColor.black.withAlphaComponent(0.12), blur: shadowBlur, offset: NSSize(width: 0, height: -size * 0.01)) {
            let headGradient = NSGradient(colors: [
                NSColor(calibratedWhite: 1.0, alpha: 1),
                NSColor(calibratedRed: 0.91, green: 0.97, blue: 1.0, alpha: 1)
            ])!
            headGradient.draw(in: headPath, angle: 90)
        }

        let torsoPath = NSBezierPath()
        torsoPath.move(to: CGPoint(x: baseRect.minX + size * 0.43, y: baseRect.minY + size * 0.64))
        torsoPath.curve(
            to: CGPoint(x: baseRect.minX + size * 0.39, y: baseRect.minY + size * 0.36),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.36, y: baseRect.minY + size * 0.55),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.34, y: baseRect.minY + size * 0.46)
        )
        torsoPath.curve(
            to: CGPoint(x: baseRect.minX + size * 0.51, y: baseRect.minY + size * 0.31),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.43, y: baseRect.minY + size * 0.31),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.48, y: baseRect.minY + size * 0.3)
        )
        torsoPath.lineCapStyle = .round
        torsoPath.lineJoinStyle = .round
        torsoPath.lineWidth = figureStroke

        let torsoFill = NSBezierPath()
        torsoFill.move(to: CGPoint(x: baseRect.minX + size * 0.45, y: baseRect.minY + size * 0.62))
        torsoFill.curve(
            to: CGPoint(x: baseRect.minX + size * 0.42, y: baseRect.minY + size * 0.34),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.38, y: baseRect.minY + size * 0.55),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.36, y: baseRect.minY + size * 0.43)
        )
        torsoFill.curve(
            to: CGPoint(x: baseRect.minX + size * 0.52, y: baseRect.minY + size * 0.31),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.45, y: baseRect.minY + size * 0.3),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.49, y: baseRect.minY + size * 0.3)
        )
        torsoFill.curve(
            to: CGPoint(x: baseRect.minX + size * 0.49, y: baseRect.minY + size * 0.6),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.5, y: baseRect.minY + size * 0.42),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.5, y: baseRect.minY + size * 0.53)
        )
        torsoFill.close()

        let thighPath = NSBezierPath()
        thighPath.move(to: CGPoint(x: baseRect.minX + size * 0.47, y: baseRect.minY + size * 0.29))
        thighPath.curve(
            to: CGPoint(x: baseRect.minX + size * 0.63, y: baseRect.minY + size * 0.28),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.56, y: baseRect.minY + size * 0.28),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.6, y: baseRect.minY + size * 0.28)
        )
        thighPath.lineCapStyle = .round
        thighPath.lineWidth = figureStroke

        let shinPath = NSBezierPath()
        shinPath.move(to: CGPoint(x: baseRect.minX + size * 0.63, y: baseRect.minY + size * 0.28))
        shinPath.line(to: CGPoint(x: baseRect.minX + size * 0.63, y: baseRect.minY + size * 0.04))
        shinPath.lineCapStyle = .round
        shinPath.lineWidth = figureStroke

        let armPath = NSBezierPath()
        armPath.move(to: CGPoint(x: baseRect.minX + size * 0.5, y: baseRect.minY + size * 0.44))
        armPath.curve(
            to: CGPoint(x: baseRect.minX + size * 0.63, y: baseRect.minY + size * 0.37),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.54, y: baseRect.minY + size * 0.38),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.59, y: baseRect.minY + size * 0.38)
        )
        armPath.lineCapStyle = .round
        armPath.lineWidth = armStroke

        withShadow(color: NSColor.black.withAlphaComponent(0.12), blur: shadowBlur, offset: NSSize(width: 0, height: -size * 0.012)) {
            let bodyGradient = NSGradient(colors: [bodyWhite, bodyShade])!
            bodyGradient.draw(in: torsoFill, angle: 90)
            bodyWhite.setStroke()
            torsoPath.stroke()
            thighPath.stroke()
            shinPath.stroke()
            armPath.stroke()
        }

        let seatFill = NSBezierPath(roundedRect: NSRect(
            x: baseRect.minX + size * 0.43,
            y: baseRect.minY + size * 0.26,
            width: size * 0.12,
            height: size * 0.08
        ), xRadius: size * 0.05, yRadius: size * 0.05)
        bodyGradientFill(path: seatFill, topColor: bodyWhite, bottomColor: bodyShade)

        let spinePath = NSBezierPath()
        spinePath.move(to: CGPoint(x: baseRect.minX + size * 0.39, y: baseRect.minY + size * 0.57))
        spinePath.curve(
            to: CGPoint(x: baseRect.minX + size * 0.4, y: baseRect.minY + size * 0.31),
            controlPoint1: CGPoint(x: baseRect.minX + size * 0.35, y: baseRect.minY + size * 0.48),
            controlPoint2: CGPoint(x: baseRect.minX + size * 0.36, y: baseRect.minY + size * 0.38)
        )
        spinePath.lineWidth = spineStroke
        spinePath.lineCapStyle = .round
        spinePath.setLineDash([size * 0.022, size * 0.018], count: 2, phase: 0)
        spineYellow.setStroke()
        spinePath.stroke()

        let checkPath = NSBezierPath()
        checkPath.move(to: CGPoint(x: baseRect.minX + size * 0.58, y: baseRect.minY + size * 0.5))
        checkPath.line(to: CGPoint(x: baseRect.minX + size * 0.65, y: baseRect.minY + size * 0.42))
        checkPath.line(to: CGPoint(x: baseRect.minX + size * 0.8, y: baseRect.minY + size * 0.57))
        checkPath.lineCapStyle = .round
        checkPath.lineJoinStyle = .round
        checkPath.lineWidth = max(size * (isAppIcon ? 0.055 : 0.078), 1.3)

        withShadow(
            color: NSColor(calibratedRed: 0.75, green: 0.98, blue: 0.33, alpha: 0.5),
            blur: size * (isAppIcon ? 0.05 : 0.06),
            offset: .zero
        ) {
            checkGreen.setStroke()
            checkPath.stroke()
        }

        checkGreenDark.withAlphaComponent(0.45).setStroke()
        checkPath.lineWidth = max(checkPath.lineWidth * 0.22, 0.8)
        checkPath.stroke()

        if isAppIcon {
            let baseShadowRect = NSRect(
                x: baseRect.minX + size * 0.2,
                y: baseRect.minY + size * 0.08,
                width: size * 0.42,
                height: size * 0.08
            )
            let baseShadow = NSBezierPath(ovalIn: baseShadowRect)
            drawRadialGlow(
                center: CGPoint(x: baseShadowRect.midX, y: baseShadowRect.midY),
                startRadius: size * 0.02,
                endRadius: size * 0.2,
                innerColor: chairBlueDark.withAlphaComponent(0.24),
                outerColor: chairBlueDark.withAlphaComponent(0)
            )
            NSColor.white.withAlphaComponent(0.13).setFill()
            baseShadow.fill()
        }
    }

    private func bodyGradientFill(path: NSBezierPath, topColor: NSColor, bottomColor: NSColor) {
        let gradient = NSGradient(colors: [topColor, bottomColor])!
        gradient.draw(in: path, angle: 90)
    }

    private func drawReflection(size: CGFloat, in cardRect: NSRect) {
        let reflectionRect = NSRect(
            x: cardRect.minX + size * 0.18,
            y: cardRect.minY + size * 0.01,
            width: size * 0.36,
            height: size * 0.12
        )
        let reflectionPath = NSBezierPath(ovalIn: reflectionRect)
        let color = NSColor(calibratedRed: 0.2, green: 0.64, blue: 0.83, alpha: 0.22)
        drawRadialGlow(
            center: CGPoint(x: reflectionRect.midX, y: reflectionRect.midY),
            startRadius: size * 0.01,
            endRadius: size * 0.18,
            innerColor: color,
            outerColor: color.withAlphaComponent(0)
        )
        NSColor.white.withAlphaComponent(0.14).setFill()
        reflectionPath.fill()
    }

    private func drawRadialGlow(
        center: CGPoint,
        startRadius: CGFloat,
        endRadius: CGFloat,
        innerColor: NSColor,
        outerColor: NSColor
    ) {
        guard let cgContext = NSGraphicsContext.current?.cgContext else {
            return
        }

        let colors = [innerColor.cgColor, outerColor.cgColor] as CFArray
        let space = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0, 1]

        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations) else {
            return
        }

        cgContext.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: startRadius,
            endCenter: center,
            endRadius: endRadius,
            options: [.drawsAfterEndLocation]
        )
    }

    private func withShadow(
        color: NSColor,
        blur: CGFloat,
        offset: NSSize,
        draw: () -> Void
    ) {
        let shadow = NSShadow()
        shadow.shadowColor = color
        shadow.shadowBlurRadius = blur
        shadow.shadowOffset = offset

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        draw()
        NSGraphicsContext.restoreGraphicsState()
    }
}

let defaultRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    .appendingPathComponent("PostureCheck/Assets.xcassets", isDirectory: true)

let assetsRoot = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first ?? defaultRoot.path,
    isDirectory: true
)

try AssetGenerator(assetsRoot: assetsRoot).run()
