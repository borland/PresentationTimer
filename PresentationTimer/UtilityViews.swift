//
//  UtilityViews.swift
//  PresentationTimer
//
//  Created by Orion Edwards on 24/07/15.
//  Copyright © 2015 Orion Edwards. All rights reserved.
//

import Foundation
import UIKit

struct Utils {
    static var TintColor:UIColor {
        get {
            return UIColor(red: 1, green: 0.961, blue: 0.094, alpha: 1)
        }
    }
}

class ButtonWithBorder : UIButton {
    override func awakeFromNib() {
        layer.borderColor = Utils.TintColor.CGColor
        layer.borderWidth = 1.0
    }
}