//
//  ThemeManager.swift
//  DEV-Simple
//
//  Created by Daniel Chick on 11/27/20.
//  Copyright © 2020 DEV. All rights reserved.
//

import UIKit
import ForemWebView

class ThemeManager {
    private(set) static var useLightIcons = false

    static func applyTheme(to viewController: ViewController) {
        guard let webView = viewController.webView else { return }

        let theme = webView.userData?.theme() ?? .base
        let config = getThemeColor(for: theme)

        viewController.navigationToolBar.barTintColor = config.barTintColor
        viewController.view.backgroundColor = config.backgroundColor

        viewController.navigationToolBar.isTranslucent = !useLightIcons
        viewController.safariButton.tintColor = useLightIcons ? UIColor.white : ThemeColors.darkBackgroundColor
        viewController.backButton.tintColor = useLightIcons ? UIColor.white : ThemeColors.darkBackgroundColor
        viewController.forwardButton.tintColor = useLightIcons ? UIColor.white : ThemeColors.darkBackgroundColor
        viewController.refreshButton.tintColor = useLightIcons ? UIColor.white : ThemeColors.darkBackgroundColor
        viewController.activityIndicator.color = useLightIcons ? UIColor.white : ThemeColors.darkBackgroundColor
    }

    private static func getThemeColor(for theme: ForemWebViewTheme) -> ThemeConfig {
        switch theme {
        case .night:
            useLightIcons = true
            return ThemeConfig.night
        case .hacker:
            useLightIcons = true
            return ThemeConfig.hacker
        case .pink:
            useLightIcons = true
            return ThemeConfig.pink
        case .minimal:
            useLightIcons = false
            return ThemeConfig.minimal
        default:
            useLightIcons = false
            return ThemeConfig.base
        }
    }
}

private struct ThemeConfig {
    let barTintColor: UIColor
    let backgroundColor: UIColor
}

extension ThemeConfig {
    private static let devPink = UIColor(red: 250/255, green: 70/255, blue: 129/255, alpha: 1)

    static let night = ThemeConfig(barTintColor: ThemeColors.darkBackgroundColor,
                                   backgroundColor: ThemeColors.darkBackgroundColor)
    static let hacker = ThemeConfig(barTintColor: .black, backgroundColor: .black)
    static let pink = ThemeConfig(barTintColor: devPink, backgroundColor: devPink)
    static let base = ThemeConfig(barTintColor: .white, backgroundColor: .white)
    static let minimal = ThemeConfig(barTintColor: .white, backgroundColor: .white)
}
