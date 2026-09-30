import Cocoa

let output = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
func rounded(_ rect: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func sparkle(_ x: CGFloat, _ y: CGFloat, _ size: CGFloat) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: x, y: y + size))
    path.curve(to: NSPoint(x: x + size, y: y), controlPoint1: NSPoint(x: x + size * 0.18, y: y + size * 0.18), controlPoint2: NSPoint(x: x + size * 0.18, y: y + size * 0.18))
    path.curve(to: NSPoint(x: x, y: y - size), controlPoint1: NSPoint(x: x + size * 0.18, y: y - size * 0.18), controlPoint2: NSPoint(x: x + size * 0.18, y: y - size * 0.18))
    path.curve(to: NSPoint(x: x - size, y: y), controlPoint1: NSPoint(x: x - size * 0.18, y: y - size * 0.18), controlPoint2: NSPoint(x: x - size * 0.18, y: y - size * 0.18))
    path.curve(to: NSPoint(x: x, y: y + size), controlPoint1: NSPoint(x: x - size * 0.18, y: y + size * 0.18), controlPoint2: NSPoint(x: x - size * 0.18, y: y + size * 0.18))
    path.close()
    NSColor.white.setFill()
    path.fill()
}
for (name, pixels) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(pixels) / 1024
    let transform = AffineTransform(scale: scale)
    (transform as NSAffineTransform).concat()
    let background = NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 192, yRadius: 192)
    NSGradient(starting: NSColor(calibratedRed: 0.15, green: 0.78, blue: 0.77, alpha: 1), ending: NSColor(calibratedRed: 0.04, green: 0.36, blue: 0.65, alpha: 1))!.draw(in: background, angle: -70)
    rounded(NSRect(x: 167, y: 260, width: 690, height: 385), 76, NSColor(calibratedWhite: 0.05, alpha: 0.16))
    rounded(NSRect(x: 167, y: 280, width: 690, height: 385), 76, NSColor(calibratedWhite: 0.97, alpha: 1))
    let keyColor = NSColor(calibratedRed: 0.12, green: 0.47, blue: 0.61, alpha: 1)
    for row in 0..<3 {
        for column in 0..<8 {
            rounded(NSRect(x: 214 + column * 76, y: 466 + row * 54, width: 58, height: 37), 10, keyColor)
        }
    }
    rounded(NSRect(x: 214, y: 365, width: 76, height: 63), 13, keyColor)
    rounded(NSRect(x: 311, y: 365, width: 326, height: 63), 13, keyColor)
    rounded(NSRect(x: 658, y: 365, width: 58, height: 63), 13, keyColor)
    rounded(NSRect(x: 737, y: 365, width: 58, height: 63), 13, keyColor)
    sparkle(747, 754, 103)
    sparkle(597, 791, 41)
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output + "/" + name + ".png"))
}
