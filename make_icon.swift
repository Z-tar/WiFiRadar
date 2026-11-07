import AppKit

func renderIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let insetRect = rect.insetBy(dx: size * 0.08, dy: size * 0.08)
    let cornerRadius = size * 0.22

    // Background squircle with drop shadow
    let bgPath = CGPath(roundedRect: insetRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.04), blur: size * 0.08, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.6))
    ctx.addPath(bgPath)
    ctx.setFillColor(CGColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Deep modern dark gradient
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgGradColors = [
        CGColor(red: 0.10, green: 0.14, blue: 0.24, alpha: 1.0),
        CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1.0)
    ] as CFArray
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgGradColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
    }

    // Outer subtle luminous rim
    ctx.addPath(bgPath)
    ctx.setLineWidth(size * 0.015)
    ctx.setStrokeColor(CGColor(red: 0.25, green: 0.60, blue: 1.0, alpha: 0.45))
    ctx.strokePath()

    let center = CGPoint(x: size * 0.5, y: size * 0.42)

    // Ambient radial glow from center
    let glowColors = [
        CGColor(red: 0.1, green: 0.75, blue: 1.0, alpha: 0.35),
        CGColor(red: 0.5, green: 0.2, blue: 0.9, alpha: 0.0)
    ] as CFArray
    if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glowGradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: size * 0.42, options: [])
    }

    // Radar Concentric Grid Rings
    let ringRadii = [size * 0.12, size * 0.22, size * 0.32]
    for r in ringRadii {
        let ringPath = CGMutablePath()
        ringPath.addArc(center: center, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.addPath(ringPath)
        ctx.setLineWidth(size * 0.01)
        ctx.setStrokeColor(CGColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.25))
        ctx.strokePath()
    }

    // Radar Crosshairs
    ctx.move(to: CGPoint(x: center.x - size * 0.36, y: center.y))
    ctx.addLine(to: CGPoint(x: center.x + size * 0.36, y: center.y))
    ctx.move(to: CGPoint(x: center.x, y: center.y - size * 0.36))
    ctx.addLine(to: CGPoint(x: center.x, y: center.y + size * 0.36))
    ctx.setLineWidth(size * 0.008)
    ctx.setStrokeColor(CGColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.20))
    ctx.strokePath()

    // Radar Sweep Wedge
    let wedgePath = CGMutablePath()
    wedgePath.move(to: center)
    wedgePath.addArc(center: center, radius: size * 0.34, startAngle: .pi * 0.15, endAngle: .pi * 0.45, clockwise: false)
    wedgePath.closeSubpath()
    ctx.addPath(wedgePath)
    ctx.setFillColor(CGColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.18))
    ctx.fillPath()

    // Wi-Fi Radiating Signal Arcs (Top Section)
    let wifiRadii = [size * 0.18, size * 0.26, size * 0.34]
    let startAngle: CGFloat = .pi * 0.25
    let endAngle: CGFloat = .pi * 0.75

    for (idx, r) in wifiRadii.enumerated() {
        let arcPath = CGMutablePath()
        arcPath.addArc(center: center, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        ctx.addPath(arcPath)
        ctx.setLineCap(.round)
        ctx.setLineWidth(size * 0.032)
        let alpha = 0.5 + CGFloat(idx) * 0.22
        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.85, blue: 1.0, alpha: alpha))
        ctx.strokePath()
    }

    // Central Radiant Pulse Dot
    let dotRadius = size * 0.045
    let dotRect = CGRect(x: center.x - dotRadius, y: center.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
    ctx.addEllipse(in: dotRect)
    ctx.setFillColor(CGColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0))
    ctx.fillPath()

    let innerDot = CGRect(x: center.x - dotRadius * 0.5, y: center.y - dotRadius * 0.5, width: dotRadius, height: dotRadius)
    ctx.addEllipse(in: innerDot)
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
    ctx.fillPath()

    ctx.restoreGState()

    img.unlockFocus()
    return img
}

let image = renderIcon(size: 1024)
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let outPath = "/Users/r/Documents/antigravity/WiFiRadar/Resources/icon_1024.png"
    try! pngData.write(to: URL(fileURLWithPath: outPath))
    print("Base icon rendered: \(outPath)")
}
