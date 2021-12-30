//
//  ChatSenderCell.swift
//  DT
//
//  Created by Apple on 17/11/2021.
//

import UIKit

class ChatSenderCell: UITableViewCell {

    @IBOutlet weak var senderIdentityLabel: UILabel!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var chattingImageView: UIImageView!
    @IBOutlet weak var chatImageHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        chattingImageView.layer.cornerRadius = 10.0
        chattingImageView.layer.borderWidth = 1.0
        chattingImageView.layer.borderColor = #colorLiteral(red: 0.9764726758, green: 0.4980676174, blue: 0.4627049565, alpha: 1)
        messageView.layer.cornerRadius = 10.0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        senderIdentityLabel.text = ""
        messageLabel.text = ""
        chattingImageView.image = nil
    }
    
}
