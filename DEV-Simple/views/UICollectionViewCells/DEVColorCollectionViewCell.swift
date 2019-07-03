//
//  DEVColorCollectionViewCell.swift
//  DEV-Simple
//
//  Created by Jacob Boyd on 7/3/19.
//  Copyright © 2019 DEV. All rights reserved.
//

import UIKit

class DEVColorCollectionViewCell: UICollectionViewCell {
    static let cellId = "DEVColorCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layer.borderColor = UIColor.darkGray.cgColor
    }

    func configureCell(bgColor: UIColor) {
        self.clipsToBounds = true
        self.layer.cornerRadius = self.bounds.width / 2
        self.backgroundColor = bgColor
    }

    func setSelected(_ selected: Bool) {
        if selected {
            self.layer.borderWidth = 2
        } else {
            self.layer.borderWidth = 0
        }
    }

}
