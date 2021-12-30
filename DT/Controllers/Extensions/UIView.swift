//
//  UIView.swift
//  DT
//
//  Created by Apple on 30/11/2021.
//

import Foundation
import UIKit

extension UIView {
    //MARK:- Round Corners..
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    //MARK:- Add Border..
    func addBorder() {
        self.layer.borderWidth = 1.0
        self.layer.borderColor = #colorLiteral(red: 1, green: 0.4470588235, blue: 0.3607843137, alpha: 1)
    }
}
