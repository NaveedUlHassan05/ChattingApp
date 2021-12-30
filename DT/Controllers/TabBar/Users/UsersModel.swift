//
//  UsersModel.swift
//  DT
//
//  Created by Apple on 11/11/2021.
//

import Foundation

class UsersModel: NSObject {
    var userName: String
    var userImage: String
    var userEmail: String
    var userAbout: String
    var userLatitude: String
    var userLongitude: String
    var userGender: String
    var userStatus: String
    
    init(userName: String, userImage: String, userEmail: String, userAbout: String, userLatitude: String, userLongitude: String, userGender: String, userStatus: String) {
        self.userName = userName
        self.userImage = userImage
        self.userEmail = userEmail
        self.userAbout = userAbout
        self.userLatitude = userLatitude
        self.userLongitude = userLongitude
        self.userGender = userGender
        self.userStatus = userStatus
    }
}
