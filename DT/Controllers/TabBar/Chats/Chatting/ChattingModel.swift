//
//  ChattingModel.swift
//  DT
//
//  Created by Apple on 17/11/2021.
//

import Foundation

class ChattingModel: NSObject {
    var message: String
    var messageType: String
    var senderId: String
    var dateAndTime: String
    
    init(message: String, messageType: String, senderId: String, dateAndTime: String) {
        self.message = message
        self.messageType = messageType
        self.senderId = senderId
        self.dateAndTime = dateAndTime
    }
}
