import SwiftUI
import UIKit

func safeSymbol(primary: String, fallbacks: [String] = []) -> Image {
    for name in [primary] + fallbacks where UIImage(systemName: name) != nil {
        return Image(systemName: name)
    }
    return Image(systemName: "questionmark.circle")
}
