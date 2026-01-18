//
//  CosmoWidgetBundle.swift
//  Cosmo Trader Widget
//
//  Main widget bundle that registers all available widgets.
//
//  Widgets:
//  - MoonPhaseWidget: Lunar cycles and trading signals
//  - HoroscopeWidget: Daily cosmic forecast
//  - PortfolioWidget: Portfolio value and top holdings
//

import WidgetKit
import SwiftUI

@main
struct CosmoWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoonPhaseWidget()
        HoroscopeWidget()
        PortfolioWidget()
    }
}
