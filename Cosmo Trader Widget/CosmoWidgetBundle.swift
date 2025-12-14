//
//  CosmoWidgetBundle.swift
//  Cosmo Trader Widget
//
//  Main widget bundle that registers all available widgets.
//

import WidgetKit
import SwiftUI

@main
struct CosmoWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoonPhaseWidget()
    }
}
