//
//  ImageViewerVC.swift
//  DT
//
//  Created by Apple on 19/11/2021.
//

import UIKit
import SDWebImage

class ImageViewerVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var userImg = ""

    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imageView.sd_setImage(with: URL(string: userImg), placeholderImage: #imageLiteral(resourceName: "def"))
    }
    
    //MARK:- Dismiss Screen..
    @IBAction func dismiss(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}
