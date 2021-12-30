//
//  ActiveChatsVC.swift
//  DT
//
//  Created by Apple on 17/11/2021.
//

import UIKit
import SDWebImage
import Loaf
import ProgressHUD
import FirebaseDatabase

class ActiveChatsVC: BaseVC {
    
    @IBOutlet weak var activeChatsTableView: UITableView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var activeChatsArray = [ActiveChatsModel]()
    
    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
        ProgressHUD.colorAnimation = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        ProgressHUD.animationType = .circleRotateChase
        self.tabBarController?.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getActiveChatsFromFirebase()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    //MARK:- Fetch Active Chats..
    func getActiveChatsFromFirebase() {
        if isInternetConnected() {
            self.hideInfoLabel()
            self.activeChatsArray.removeAll()
            let myEmail = UserDefaults.standard.string(forKey: "userEmail")!.components(separatedBy: "@").first!
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("ActiveChats").child(myEmail).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    ProgressHUD.dismiss()
                    return
                }
                if snapshot.exists() {
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot,
                           let dictionary = childSnapshot.value as? [String:Any] {
                            let email = dictionary["email"] as! String
                            let lastMsg = dictionary["lastMsg"] as! String
                            let dateAndTime = dictionary["dateAndTime"] as! String
                            let chatChannelId = dictionary["chatChannelId"] as! String
                            strongSelf.getFriendDetail(email: email,lastMsg: lastMsg, dateAndTime: dateAndTime, chatChannelId: chatChannelId)
                        }
                    }
                }else {
                    ProgressHUD.dismiss()
                    strongSelf.showInfoLabel(message: "You don't have any active chats.")
                }
            }
        }else {
            self.showInfoLabel(message: "You're not connected to the internet.")
        }
    }
    
    //MARK:- Get detail about friends..
    func getFriendDetail(email: String, lastMsg: String, dateAndTime: String, chatChannelId: String) {
        Database.database().reference().child("Users").child(email).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else {
                ProgressHUD.dismiss()
                return
            }
            if snapshot.exists() {
                guard let dictionary = snapshot.value as? [String: String] else {
                    ProgressHUD.dismiss()
                    Loaf("Unable to fetch active chats at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: strongSelf).show()
                    return
                }
                strongSelf.activeChatsArray.append(ActiveChatsModel(userName: dictionary["username"]!, userImage: dictionary["image"]!, userEmail: dictionary["email"]!, userAbout: dictionary["about"]!, userLatitude: dictionary["lat"]!, userLongitude: dictionary["lng"]!, userGender: dictionary["gender"]!, userStatus: dictionary["status"]!, userLastMsg: lastMsg, msgDateAndTime: dateAndTime, chatChannelId: chatChannelId))
                
                DispatchQueue.main.async {
                    ProgressHUD.dismiss()
                    strongSelf.activeChatsTableView.reloadData()
                }
            }else {
                ProgressHUD.dismiss()
                Loaf("Unable to fetch active chats at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: strongSelf).show()
            }
        }
    }
    
    //MARK:- Show Information Label..
    func showInfoLabel(message: String) {
        infoLabel.isHidden = false
        activeChatsTableView.isHidden = true
        infoLabel.text = message
    }
    
    //MARK:- Hide Information Label..
    func hideInfoLabel() {
        infoLabel.isHidden = true
        activeChatsTableView.isHidden = false
    }
}

//MARK:- UITableView Delegates..
extension ActiveChatsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeChatsArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveChatsCell") as? ActiveChatsCell else {return UITableViewCell()}
        cell.friendImageView.sd_setImage(with: URL(string: activeChatsArray[indexPath.row].userImage), placeholderImage: #imageLiteral(resourceName: "def"))
        cell.friendNameLabel.text = activeChatsArray[indexPath.row].userName
        cell.lastMessageLabel.text = activeChatsArray[indexPath.row].userLastMsg
        cell.dateAndTimeLabel.text = activeChatsArray[indexPath.row].msgDateAndTime
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChattingVC") as! ChattingVC
        vc.userEmail = activeChatsArray[indexPath.row].userEmail
        vc.userName = activeChatsArray[indexPath.row].userName
        vc.userGender = activeChatsArray[indexPath.row].userGender
        vc.userImg = activeChatsArray[indexPath.row].userImage
        vc.userStatus = activeChatsArray[indexPath.row].userStatus
        vc.userAbout = activeChatsArray[indexPath.row].userAbout
        vc.chatChannelExists = true
        vc.didAppearFirstTime = true
        vc.chatChannelId = activeChatsArray[indexPath.row].chatChannelId
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

