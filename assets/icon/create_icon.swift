import Cocoa

// Wczytaj droplet.png i użyj go jako ikony aplikacji
guard let sourceImage = NSImage(contentsOfFile: "droplet.png") else {
    print("Błąd: Nie można wczytać droplet.png")
    exit(1)
}

// Upewnij się, że obraz ma rozmiar 1024x1024
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// Dodaj padding (20% z każdej strony)
let padding: CGFloat = size.width * 0.15
let innerRect = NSRect(
    x: padding,
    y: padding,
    width: size.width - (padding * 2),
    height: size.height - (padding * 2)
)

sourceImage.draw(in: innerRect)
image.unlockFocus()

// Zapisz jako app_icon.png
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try? pngData.write(to: URL(fileURLWithPath: "app_icon.png"))
    print("Ikona utworzona z droplet.png z paddingiem!")
} else {
    print("Błąd: Nie można zapisać ikony")
    exit(1)
}
