//
//  FriendsCell.swift
//  DT
//
//  Created by Apple on 16/11/2021.
//

import UIKit

class FriendsCell: UITableViewCell {

    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var activeStatusLabel: UILabel!

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
        activeStatusLabel.text = ""
    }

}
