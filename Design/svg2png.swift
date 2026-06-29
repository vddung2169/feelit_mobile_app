import AppKit

let args = CommandLine.arguments
guard args.count >= 4, let scale = Double(args[3]) else {
    FileHandle.standardError.write("usage: svg2png <in.svg> <out.png> <scale>\n".data(using:.utf8)!)
    exit(1)
}
let svgPath = args[1], outPath = args[2]
guard let img = NSImage(contentsOfFile: svgPath) else { fputs("cannot load svg\n", stderr); exit(2) }
let size = img.size
let w = Int((size.width * scale).rounded()), h = Int((size.height * scale).rounded())
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { exit(3) }
rep.size = size
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
// nền trong suốt — KHÔNG fill màu
img.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height),
         from: .zero, operation: .sourceOver, fraction: 1.0)
ctx.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
guard let png = rep.representation(using: .png, properties: [:]) else { exit(4) }
try! png.write(to: URL(fileURLWithPath: outPath))
print("svg pt-size \(size.width)x\(size.height) -> \(w)x\(h) px")
