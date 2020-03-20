//
//  Bundle+Extensions.swift
//  DEV-Simple
//
//  Created by Fernando Valverde on 3/10/20.
//  Kudos to samwize @ SO
//  Copyright © 2020 DEV. All rights reserved.
//

import UIKit

extension Bundle {
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
