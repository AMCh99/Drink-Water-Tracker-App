import Cocoa

// Wczytaj droplet.png
guard let sourceImage = NSImage(contentsOfFile: "droplet.png") else {
    print("Błąd: Nie można wczytać droplet.png")
    exit(1)
}

let size = NSSize(width: 1024, height: 1024)

// Funkcja do tworzenia ikony z określonym paddingiem
func createIcon(withPadding paddingPercent: CGFloat, outputName: String) {
    let image = NSImage(size: size)
    image.lockFocus()
    
    let padding = size.width * paddingPercent
    let innerRect = NSRect(
        x: padding,
        y: padding,
        width: size.width - (padding * 2),
        height: size.height - (padding * 2)
    )
    
    sourceImage.draw(in: innerRect)
    image.unlockFocus()
    
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outputName))
        print("✓ Utworzono: \(outputName)")
    }
}

// Android - większa ikona (5% padding)
createIcon(withPadding: 0.05, outputName: "app_icon_android.png")

// iOS/macOS - mniejsza ikona (15% padding)
createIcon(withPadding: 0.15, outputName: "app_icon_ios.png")

print("Ikony utworzone!")
