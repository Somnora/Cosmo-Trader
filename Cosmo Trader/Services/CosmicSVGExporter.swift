import Foundation
import SwiftUI

final class CosmicSVGExporter {
    static func generateAlignmentSVG(user: UserProfile, result: PortfolioCompatibilityResult) -> String {
        let width = 600
        let height = 600
        
        let dominantSignStr = user.sunSign.displayName.uppercased()
        let dominantElementStr = user.element.displayName.uppercased()
        let scoreStr = String(format: "%.0f%%", result.overallScore)
        let ratingStr = result.rating.displayName.uppercased()
        let portfolioVal = user.formattedPortfolioValue
        
        // Colors matching terminal theme
        let bgHex = "#000000"
        let borderHex = "#242629"
        let goldHex = "#AA8800"
        let greenHex = "#00FF00"
        let textMutedHex = "#6E737A"
        let textPrimaryHex = "#E6E6E6"
        let fireHex = "#AA4400"
        let earthHex = "#558855"
        let airHex = "#AA8800"
        let waterHex = "#446688"
        
        // Build elemental composition bars
        var barsSVG = ""
        let elements: [ZodiacSign.Element] = [.fire, .earth, .air, .water]
        for (index, element) in elements.enumerated() {
            let y = 340 + (index * 40)
            let pct = result.elementBreakdown[element] ?? 0
            let barWidth = Int(250.0 * (pct / 100.0))
            let elementColor: String
            switch element {
            case .fire: elementColor = fireHex
            case .earth: elementColor = earthHex
            case .air: elementColor = airHex
            case .water: elementColor = waterHex
            }
            
            barsSVG += """
            <!-- \(element.displayName) -->
            <text x="50" y="\(y + 12)" fill="\(elementColor)" font-family="Courier New, monospace" font-size="12" font-weight="bold">\(element.displayName.uppercased())</text>
            <rect x="150" y="\(y)" width="250" height="15" fill="\(borderHex)" rx="2"/>
            <rect x="150" y="\(y)" width="\(barWidth)" height="15" fill="\(elementColor)" rx="2"/>
            <text x="415" y="\(y + 12)" fill="\(textPrimaryHex)" font-family="Courier New, monospace" font-size="12" font-weight="bold">\(Int(pct))%</text>
            """
        }
        
        // Wrap everything in a nice vector wrapper
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) \(height)" width="100%" height="100%">
          <rect width="100%" height="100%" fill="\(bgHex)"/>
          
          <!-- Outer border -->
          <rect x="20" y="20" width="560" height="560" fill="none" stroke="\(borderHex)" stroke-width="1.5"/>
          
          <!-- Header -->
          <text x="40" y="55" fill="\(goldHex)" font-family="Courier New, monospace" font-size="14" font-weight="bold">COSMO TRADER TERMINAL v2.0</text>
          <text x="560" y="55" fill="\(textMutedHex)" font-family="Courier New, monospace" font-size="10" text-anchor="end">SYSTEM: SECURE CLOUD SYNC</text>
          <line x1="40" y1="65" x2="560" y2="65" stroke="\(borderHex)" stroke-width="1.5"/>
          
          <!-- Title -->
          <text x="40" y="100" fill="\(textPrimaryHex)" font-family="Courier New, monospace" font-size="22" font-weight="bold">ZODIAC PORTFOLIO ALIGNMENT REPORT</text>
          
          <!-- Large Score Circle & Text -->
          <circle cx="140" cy="210" r="70" fill="none" stroke="\(borderHex)" stroke-width="4"/>
          <circle cx="140" cy="210" r="70" fill="none" stroke="\(greenHex)" stroke-dasharray="440" stroke-dashoffset="\(440 - Int(440.0 * (result.overallScore / 100.0)))" stroke-width="8" transform="rotate(-90 140 210)"/>
          
          <text x="140" y="205" fill="\(greenHex)" font-family="Courier New, monospace" font-size="32" font-weight="bold" text-anchor="middle">\(scoreStr)</text>
          <text x="140" y="222" fill="\(textMutedHex)" font-family="Courier New, monospace" font-size="9" text-anchor="middle">ALIGNMENT</text>
          <text x="140" y="238" fill="\(goldHex)" font-family="Courier New, monospace" font-size="10" font-weight="bold" text-anchor="middle">\(ratingStr)</text>
          
          <!-- Profile info -->
          <text x="240" y="160" fill="\(textMutedHex)" font-family="Courier New, monospace" font-size="12" font-weight="bold">INVESTOR PROFILE</text>
          <text x="240" y="182" fill="\(textPrimaryHex)" font-family="Courier New, monospace" font-size="16" font-weight="bold">\(user.displayName.uppercased())</text>
          
          <rect x="240" y="195" width="135" height="26" fill="none" stroke="\(goldHex)" stroke-width="1" rx="2"/>
          <text x="307" y="212" fill="\(goldHex)" font-family="Courier New, monospace" font-size="10" font-weight="bold" text-anchor="middle">SIGN: \(dominantSignStr)</text>
          
          <rect x="385" y="195" width="135" height="26" fill="none" stroke="\(goldHex)" stroke-width="1" rx="2"/>
          <text x="452" y="212" fill="\(goldHex)" font-family="Courier New, monospace" font-size="10" font-weight="bold" text-anchor="middle">ELEMENT: \(dominantElementStr)</text>
          
          <text x="240" y="255" fill="\(textMutedHex)" font-family="Courier New, monospace" font-size="12" font-weight="bold">PORTFOLIO VALUE</text>
          <text x="240" y="275" fill="\(textPrimaryHex)" font-family="Courier New, monospace" font-size="15" font-weight="bold">\(portfolioVal)</text>
          
          <line x1="40" y1="305" x2="560" y2="305" stroke="\(borderHex)" stroke-width="1.5"/>
          
          <!-- Element breakdown section -->
          \(barsSVG)
          
          <line x1="40" y1="510" x2="560" y2="510" stroke="\(borderHex)" stroke-width="1.5"/>
          
          <!-- Footer -->
          <text x="40" y="545" fill="\(textMutedHex)" font-family="Courier New, monospace" font-size="11">Trade with the stars.</text>
          <text x="560" y="545" fill="\(goldHex)" font-family="Courier New, monospace" font-size="12" font-weight="bold" text-anchor="end">cosmotrade.app</text>
        </svg>
        """
        
        return svg
    }
}
