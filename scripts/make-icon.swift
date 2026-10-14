// Gera assets/AppIcon.iconset a partir de um desenho vetorial: curvas de crescimento sobre squircle.
// Uso: swift scripts/make-icon.swift
import AppKit

let canvas: CGFloat = 1024
let image = NSImage(size: NSSize(width: canvas, height: canvas))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("sem contexto gráfico") }

// Squircle da grade de ícones do macOS: 824 pt centrados, raio ~185.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 186, cornerHeight: 186, transform: nil)

// Sombra suave.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 34, color: NSColor.black.withAlphaComponent(0.32).cgColor)
ctx.addPath(tilePath)
ctx.setFillColor(NSColor.black.cgColor)
ctx.fillPath()
ctx.restoreGState()

// Fundo em gradiente diagonal (azul-petróleo para azul-marinho).
ctx.saveGState()
ctx.addPath(tilePath)
ctx.clip()
let colors = [
    NSColor(srgbRed: 0.10, green: 0.62, blue: 0.62, alpha: 1).cgColor,
    NSColor(srgbRed: 0.07, green: 0.30, blue: 0.48, alpha: 1).cgColor,
    NSColor(srgbRed: 0.08, green: 0.16, blue: 0.33, alpha: 1).cgColor,
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: tile.minX, y: tile.maxY), end: CGPoint(x: tile.maxX, y: tile.minY), options: [])

// Brilho no topo.
let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                      colors: [NSColor.white.withAlphaComponent(0.20).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 380, y: 860), startRadius: 0,
                       endCenter: CGPoint(x: 380, y: 860), endRadius: 560, options: [])

// Grade discreta.
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.08).cgColor)
ctx.setLineWidth(3)
for i in 1...5 {
    let x = tile.minX + CGFloat(i) * tile.width / 6
    ctx.move(to: CGPoint(x: x, y: tile.minY + 90)); ctx.addLine(to: CGPoint(x: x, y: tile.maxY - 90))
    let y = tile.minY + CGFloat(i) * tile.height / 6
    ctx.move(to: CGPoint(x: tile.minX + 90, y: y)); ctx.addLine(to: CGPoint(x: tile.maxX - 90, y: y))
}
ctx.strokePath()

// Curvas de crescimento: forma de estatura para idade (sobe rápido e desacelera), em leque de -3 a +3 DP.
func curve(_ k: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let x0 = tile.minX + 120, x1 = tile.maxX - 110
    let steps = 60
    for s in 0...steps {
        let t = CGFloat(s) / CGFloat(steps)
        let x = x0 + (x1 - x0) * t
        let base = 1 - pow(1 - t, 1.9)
        let spread = (0.10 + 0.22 * t) * k
        let y = tile.minY + 150 + (tile.height - 330) * (0.06 + 0.70 * base + spread * 0.55)
        s == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    return path
}
ctx.setLineCap(.round)
for (k, alpha, width) in [(-3.0, 0.22, 7.0), (-2.0, 0.34, 8.0), (2.0, 0.34, 8.0), (3.0, 0.22, 7.0)] as [(CGFloat, CGFloat, CGFloat)] {
    ctx.addPath(curve(k)); ctx.setStrokeColor(NSColor.white.withAlphaComponent(alpha).cgColor); ctx.setLineWidth(width); ctx.strokePath()
}
for k in [-1.0, 1.0] as [CGFloat] {
    ctx.addPath(curve(k)); ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.5).cgColor); ctx.setLineWidth(9); ctx.strokePath()
}
ctx.addPath(curve(0)); ctx.setStrokeColor(NSColor.white.cgColor); ctx.setLineWidth(16); ctx.strokePath()

// Ponto de medida (coral) sobre a mediana.
let t: CGFloat = 0.62
let px = tile.minX + 120 + (tile.width - 230) * t
let py = tile.minY + 150 + (tile.height - 330) * (0.06 + 0.70 * (1 - pow(1 - t, 1.9)))
ctx.restoreGState()
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 12, color: NSColor.black.withAlphaComponent(0.35).cgColor)
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillEllipse(in: CGRect(x: px - 46, y: py - 46, width: 92, height: 92))
ctx.restoreGState()
ctx.setFillColor(NSColor(srgbRed: 1.0, green: 0.48, blue: 0.36, alpha: 1).cgColor)
ctx.fillEllipse(in: CGRect(x: px - 32, y: py - 32, width: 64, height: 64))

image.unlockFocus()

// Exporta o iconset nos tamanhos exigidos pelo iconutil.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("assets/AppIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = base * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: pixels, height: pixels)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try rep.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
print("ícones gerados em \(iconset.path)")
