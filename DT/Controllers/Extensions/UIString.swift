//
//  UIString.swift
//  DT
//
//  Created by Apple on 30/11/2021.
//

import Foundation

extension String {
    //MARK:- Check valid email using Regex..
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
}
