//
//  UsersCell.swift
//  DT
//
//  Created by Apple on 11/11/2021.
//

import UIKit

class UsersCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.frame.size.width/2
        userImageView.layer.borderWidth = 1.5
        userImageView.layer.borderColor = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        userImageView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userImageView.image = nil
        userNameLabel.text = ""
    }

}
