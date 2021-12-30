//
//  UITableView.swift
//  DT
//
//  Created by Apple on 30/11/2021.
//

import Foundation
import UIKit

extension UITableView {
    //MARK:- Get last indexpath..
    func lastIndexpath() -> IndexPath {
        let section = max(numberOfSections - 1, 0)
        let row = max(numberOfRows(inSection: section) - 1, 0)
        return IndexPath(row: row, section: section)
    }
}
