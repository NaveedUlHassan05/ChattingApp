//
//  DetailPopupVC.swift
//  DT
//
//  Created by Apple on 11/11/2021.
//

import UIKit
import Loaf
import SDWebImage
import ProgressHUD
import BottomPopup
import FirebaseDatabase

class DetailPopupVC: BottomPopupViewController {
    
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userGenderLabel: UILabel!
    @IBOutlet weak var userAboutLabel: UILabel!
    @IBOutlet weak var acceptRejectView: UIView!
    @IBOutlet weak var sendCancelRequestView: UIView!
    @IBOutlet weak var blockUnfriendView: UIView!
    @IBOutlet weak var unblockView: UIView!
    @IBOutlet weak var sendCancelRequestButton: UIButton!
    @IBOutlet weak var unfriendButton: UIButton!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var unblockButton: UIButton!
    
    var userEmail = ""
    var userName = ""
    var userImg = ""
    var userAbout = ""
    var userGender = ""
    var myEmail = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        checkIfBlockedUserExists()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageContainerView.layer.cornerRadius = imageContainerView.frame.size.width/2
        imageContainerView.addBorder()
        imageContainerView.clipsToBounds = true
        sendCancelRequestButton.addBorder()
        unfriendButton.addBorder()
        blockButton.addBorder()
        acceptButton.addBorder()
        rejectButton.addBorder()
        unblockButton.addBorder()
    }
    
    //MARK:- Specifying Popup Height..
    override var popupHeight: CGFloat { return UIScreen.main.bounds.height/2 }
    
    //MARK:- Popup Radius..
    override var popupTopCornerRadius: CGFloat { return CGFloat(30) }
    
    //MARK:- Popup Present/Dismiss Duration..
    override var popupPresentDuration: Double { return 0.3 }
    override var popupDismissDuration: Double { return 0.3 }
    
    //MARK:- Tap outside to hide popup..
    override var popupShouldDismissInteractivelty: Bool { return false }
    
    //MARK:- Updating UI..
    func updateUI() {
        sendCancelRequestView.isHidden = true
        blockUnfriendView.isHidden = true
        acceptRejectView.isHidden = true
        unblockView.isHidden = true
        self.userNameLabel.text = userName
        self.userGenderLabel.text = userGender
        self.userAboutLabel.text = userAbout
        userImageView.sd_setImage(with: URL(string: userImg), placeholderImage: #imageLiteral(resourceName: "def"))
        myEmail = UserDefaults.standard.string(forKey: "userEmail")!.components(separatedBy: "@").first!
        userEmail = userEmail.components(separatedBy: "@").first!
    }
    
    func checkIfBlockedUserExists() {
        if BaseVC().isInternetConnected() {
            Database.database().reference().child("BlockedUsers").child(myEmail).child(userEmail).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    return
                }
                if snapshot.exists() {
                    strongSelf.sendCancelRequestView.isHidden = true
                    strongSelf.blockUnfriendView.isHidden = true
                    strongSelf.acceptRejectView.isHidden = true
                    strongSelf.unblockView.isHidden = false
                }else {
                    print("Passing Blocked")
                    strongSelf.checkIfFriendExists()
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Check if this user is already in friends list..
    func checkIfFriendExists() {
        if BaseVC().isInternetConnected() {
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("Friends").child(userEmail).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    return
                }
                if snapshot.exists() {
                    strongSelf.sendCancelRequestView.isHidden = true
                    strongSelf.blockUnfriendView.isHidden = false
                    strongSelf.acceptRejectView.isHidden = true
                    strongSelf.unblockView.isHidden = true
                }else {
                    print("Passing Friends")
                    strongSelf.checkSentRequests()
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Check if this user is already in sent requests..
    func checkSentRequests() {
        if BaseVC().isInternetConnected() {
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("SentRequests").child(userEmail).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    return
                }
                if snapshot.exists() {
                    strongSelf.sendCancelRequestView.isHidden = false
                    strongSelf.blockUnfriendView.isHidden = true
                    strongSelf.acceptRejectView.isHidden = true
                    strongSelf.unblockView.isHidden = true
                    strongSelf.sendCancelRequestButton.setTitle("Cancel Request", for: .normal)
                }else {
                    print("Passing Sent")
                    strongSelf.checkReceivedRequests()
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Check if this user is already in received requests..
    func checkReceivedRequests() {
        if BaseVC().isInternetConnected() {
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("ReceivedRequests").child(userEmail).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    return
                }
                if snapshot.exists() {
                    strongSelf.sendCancelRequestView.isHidden = true
                    strongSelf.blockUnfriendView.isHidden = true
                    strongSelf.acceptRejectView.isHidden = false
                    strongSelf.unblockView.isHidden = true
                }else {
                    print("hell yeah")
                    strongSelf.sendCancelRequestView.isHidden = false
                    strongSelf.sendCancelRequestButton.setTitle("Send Request", for: .normal)
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Dismiss Popup..
    @IBAction func dismissPopup(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Send/Cancel Request..
    @IBAction func sendCancelRequest(_ sender: UIButton) {
        if BaseVC().isInternetConnected() {
            if sender.titleLabel?.text == "Send Request" {
                ProgressHUD.show("", interaction: false)
                Database.database().reference().child("FriendsAndRequests").child(userEmail).child("ReceivedRequests").child(myEmail).setValue(["email":"\(myEmail)"]) { error, _ in
                    if let error = error {
                        ProgressHUD.dismiss()
                        print(error.localizedDescription)
                        Loaf("Something went wrong while sending request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    }else {
                        Database.database().reference().child("FriendsAndRequests").child(self.myEmail).child("SentRequests").child(self.userEmail).setValue(["email":"\(self.userEmail)"]) { error, _ in
                            if let error = error {
                                ProgressHUD.dismiss()
                                print(error.localizedDescription)
                                Loaf("Something went wrong while sending request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                            }else {
                                ProgressHUD.dismiss()
                                UserDefaults.standard.set("Request has been sent.", forKey: "requestMessage")
                                self.dismiss(animated: true) {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dismissDetailPopup"), object: nil, userInfo: nil)
                                }
                            }
                        }
                    }
                }
            }else {
                rejectCancelRequest(message: "Request has been cancelled.", userChildName: "ReceivedRequests", myChildName: "SentRequests")
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Accept Request..
    @IBAction func acceptRequest(_ sender: UIButton) {
        if BaseVC().isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("FriendsAndRequests").child(userEmail).child("Friends").child(myEmail).setValue(["email":"\(myEmail)"]) { error, _ in
                if let error = error {
                    ProgressHUD.dismiss()
                    print(error.localizedDescription)
                    Loaf("Something went wrong while accepting request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }else {
                    Database.database().reference().child("FriendsAndRequests").child(self.myEmail).child("Friends").child(self.userEmail).setValue(["email":"\(self.userEmail)"]) { error, _ in
                        if let error = error {
                            ProgressHUD.dismiss()
                            print(error.localizedDescription)
                            Loaf("Something went wrong while accepting request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                        }else {
                            self.rejectCancelRequest(message: "Request has been accepted.", userChildName: "SentRequests", myChildName: "ReceivedRequests")
                        }
                    }
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Reject Request..
    @IBAction func rejectRequest(_ sender: UIButton) {
        rejectCancelRequest(message: "Request from \(self.userEmail) has been rejected successfully.", userChildName: "SentRequests", myChildName: "ReceivedRequests")
    }
    
    //MARK:- Reject Cancel Request..
    func rejectCancelRequest(message: String, userChildName: String, myChildName: String) {
        if BaseVC().isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("FriendsAndRequests").child(userEmail).child(userChildName).child(myEmail).removeValue { error,_ in
                if let error = error {
                    ProgressHUD.dismiss()
                    print(error.localizedDescription)
                    Loaf("Something went wrong with the request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }else {
                    Database.database().reference().child("FriendsAndRequests").child(self.myEmail).child(myChildName).child(self.userEmail).removeValue { error,_ in
                        if let error = error {
                            ProgressHUD.dismiss()
                            print(error.localizedDescription)
                            Loaf("Something went wrong with the request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                        }else {
                            ProgressHUD.dismiss()
                            UserDefaults.standard.set(message, forKey: "requestMessage")
                            self.dismiss(animated: true) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dismissDetailPopup"), object: nil, userInfo: nil)
                            }
                        }
                    }
                }
            }
        }else {
            ProgressHUD.dismiss()
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Unfriend User..
    @IBAction func unfriend(_ sender: UIButton) {
        if BaseVC().isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("Friends").child(userEmail).removeValue { error,_ in
                if let error = error {
                    ProgressHUD.dismiss()
                    print(error.localizedDescription)
                    Loaf("Something went wrong while unfriending user.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }else {
                    Database.database().reference().child("FriendsAndRequests").child(self.userEmail).child("Friends").child(self.myEmail).removeValue { error,_ in
                        if let error = error {
                            ProgressHUD.dismiss()
                            print(error.localizedDescription)
                            Loaf("Something went wrong while unfriending user.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                        }else {
                            ProgressHUD.dismiss()
                            UserDefaults.standard.set("\(self.userName) removed from friends list.", forKey: "requestMessage")
                            self.dismiss(animated: true) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dismissDetailPopup"), object: nil, userInfo: nil)
                            }
                        }
                    }
                }
            }
        }else {
            ProgressHUD.dismiss()
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Block User..
    @IBAction func block(_ sender: UIButton) {
        if BaseVC().isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("Friends").child(userEmail).removeValue()
            Database.database().reference().child("FriendsAndRequests").child(userEmail).child("Friends").child(myEmail).removeValue()
            Database.database().reference().child("BlockedUsers").child(myEmail).child(userEmail).setValue(["email":"\(userEmail)"]) { error, _ in
                if let error = error {
                    ProgressHUD.dismiss()
                    print(error.localizedDescription)
                    Loaf("Something went wrong while blocking \(self.userName).", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }else {
                    ProgressHUD.dismiss()
                    UserDefaults.standard.set("\(self.userName) has been blocked.", forKey: "requestMessage")
                    self.dismiss(animated: true) {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dismissDetailPopup"), object: nil, userInfo: nil)
                    }
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Unblock User..
    @IBAction func unblock(_ sender: UIButton) {
        if BaseVC().isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("BlockedUsers").child(myEmail).child(userEmail).removeValue { error,_ in
                if let error = error {
                    ProgressHUD.dismiss()
                    print(error.localizedDescription)
                    Loaf("Something went wrong while unblocking \(self.userName).", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }else {
                    ProgressHUD.dismiss()
                    UserDefaults.standard.set("\(self.userName) has been unblocked.", forKey: "requestMessage")
                    self.dismiss(animated: true) {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dismissDetailPopup"), object: nil, userInfo: nil)
                    }
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
}
