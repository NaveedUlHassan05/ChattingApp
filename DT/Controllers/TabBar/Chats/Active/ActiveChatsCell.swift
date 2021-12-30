//
//  ActiveChatsCell.swift
//  DT
//
//  Created by Apple on 17/11/2021.
//

import UIKit

class ActiveChatsCell: UITableViewCell {
    
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateAndTimeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        friendImageView.layer.cornerRadius = friendImageView.frame.size.width/2
        friendImageView.layer.borderWidth = 1.5
        friendImageView.layer.borderColor = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        friendImageView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        friendImageView.image = nil
        friendNameLabel.text = ""
        lastMessageLabel.text = ""
        dateAndTimeLabel.text = ""
    }
}
