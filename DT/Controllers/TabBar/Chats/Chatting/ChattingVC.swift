//
//  ChattingVC.swift
//  DT
//
//  Created by Apple on 17/11/2021.
//

import UIKit
import SDWebImage
import Loaf
import ProgressHUD
import FirebaseStorage
import FirebaseDatabase
import UITextView_Placeholder

class ChattingVC: BaseVC {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userActiveStatusLabel: UILabel!
    @IBOutlet weak var chattingTableView: UITableView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var blockedInfoLabel: UILabel!
    
    var myEmail = ""
    var userEmail = ""
    var userName = ""
    var userImg = ""
    var userAbout = ""
    var userGender = ""
    var userStatus = ""
    var chatChannelId = ""
    var chatChannelExists: Bool = false
    var didAppearFirstTime : Bool = false
    var chatMessagesArray = [ChattingModel]()
    
    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
        chatTextView.delegate = self
        hideKeyboardWhenTappedAround()
        ProgressHUD.colorAnimation = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        chatTextView.placeholder = "Message.."
        ProgressHUD.animationType = .circleRotateChase
        self.tabBarController?.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        myEmail = UserDefaults.standard.string(forKey: "userEmail")!.components(separatedBy: "@").first!
        userEmail = userEmail.components(separatedBy: "@").first!
        checkUserStatus()
        if chatChannelExists, chatChannelId != "" {
            getChatMessages(chatChannelId: chatChannelId)
        }else {
            showInfoLabel(message: "You don't have any chat history.")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        userImageView.layer.cornerRadius = userImageView.frame.size.width/2
        userImageView.layer.borderWidth = 2.0
        userImageView.layer.borderColor = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        userImageView.clipsToBounds = true
        chatTextView.layer.cornerRadius = 10.0
        chatTextView.layer.borderWidth = 1.0
        chatTextView.layer.borderColor = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
    }
    
    //MARK:- Updating UI..
    func updateUI() {
        blockedInfoLabel.isHidden = true
        userNameLabel.text = userName
        userActiveStatusLabel.text = userStatus
        if userStatus.lowercased() == "online" { userActiveStatusLabel.textColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1) }
        else {
            userActiveStatusLabel.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        }
        userImageView.sd_setImage(with: URL(string: userImg), placeholderImage: #imageLiteral(resourceName: "def"))
    }
 
    //MARK:- Check User Status..
    func checkUserStatus() {
        if isInternetConnected() {
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("Friends").child(userEmail).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    return
                }
                if snapshot.exists() {
                    strongSelf.messageView.isHidden = false
                    strongSelf.messageViewHeight.constant = 40
                    strongSelf.blockedInfoLabel.isHidden = true
                }else {
                    strongSelf.messageView.isHidden = true
                    strongSelf.messageViewHeight.constant = 0
                    strongSelf.blockedInfoLabel.isHidden = false
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Get chat messages..
    func getChatMessages(chatChannelId: String) {
        if isInternetConnected() {
            self.hideInfoLabel()
            self.chatMessagesArray.removeAll()
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("ChatChannels").child(chatChannelId).observe(.childAdded) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    ProgressHUD.dismiss()
                    return
                }
                if snapshot.exists() {
                    guard let snap = snapshot.value as? [String: String] else {
                        ProgressHUD.dismiss()
                        strongSelf.showInfoLabel(message: "You don't have any chat history.")
                        return
                    }
                    strongSelf.chatMessagesArray.append(ChattingModel(message: snap["message"]!, messageType: snap["messageType"]!, senderId: snap["senderId"]!, dateAndTime: snap["time"]!))
                    strongSelf.chattingTableView.insertRows(at: [IndexPath(row: strongSelf.chatMessagesArray.count-1, section: 0)], with: .automatic)
                    if !strongSelf.didAppearFirstTime {
                        strongSelf.chattingTableView.scrollToRow(at: strongSelf.chattingTableView.lastIndexpath(), at: .none, animated: true)
                    }
                    ProgressHUD.dismiss()
                    DispatchQueue.main.async {
                        strongSelf.chattingTableView.reloadData()
                    }
                }else {
                    ProgressHUD.dismiss()
                    strongSelf.showInfoLabel(message: "You don't have any chat history.")
                }
            }
        }else {
            self.showInfoLabel(message: "You're not connected to the internet.")
        }
    }
    
    //MARK:- Show Information Label..
    func showInfoLabel(message: String) {
        infoLabel.isHidden = false
        chattingTableView.isHidden = true
        infoLabel.text = message
    }
    
    //MARK:- Hide Information Label..
    func hideInfoLabel() {
        infoLabel.isHidden = true
        chattingTableView.isHidden = false
    }
    
    //MARK:- Current Time..
    func getCurrentTime() -> String{
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "HH:mm a"
        df.amSymbol = "AM"
        df.pmSymbol = "PM"
        let dateString = df.string(from: date)
        return dateString
    }
    
    //MARK:- Capture image from camera..
    @IBAction func openCamera(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        Camera(imagePicker: imagePicker)
    }
    
    //MARK:- Choose image from gallery..
    @IBAction func openGallery(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        Gallery(imagePicker: imagePicker)
    }
    
    //MARK:- Sending messages..
    @IBAction func send(_ sender: UIButton) {
        if isInternetConnected() {
            if chatTextView.text != "" {
                sendMessage(message: self.chatTextView.text!, messageType: "0")
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Send Message..
    func sendMessage(message: String, messageType: String) {
        if !chatChannelExists {
            chatChannelId = "\(myEmail)\(userEmail)Channel"
        }
        let currentTime = getCurrentTime()
        let myActiveChatsData = ["chatChannelId": chatChannelId, "dateAndTime": currentTime, "email": userEmail, "lastMsg": (messageType == "1") ? "Image.png" : message] as [String : String]
        Database.database().reference().child("ActiveChats").child(myEmail).child(userEmail).setValue(myActiveChatsData)
        let friendsActiveChatsData = ["chatChannelId": chatChannelId, "dateAndTime": currentTime, "email": self.myEmail, "lastMsg": (messageType == "1") ? "Image.png" : message] as [String : String]
        Database.database().reference().child("ActiveChats").child(self.userEmail).child(self.myEmail).setValue(friendsActiveChatsData)
        
        let nodeTime = self.getCurrentTime(isGeneratingNode: true)
        let chatData = ["message": message, "messageType": messageType, "senderId": self.myEmail, "time": currentTime] as [String : String]
        Database.database().reference().child("ChatChannels").child(chatChannelId).child(nodeTime).setValue(chatData)
        if !chatChannelExists {
            chatChannelExists = true
            getChatMessages(chatChannelId: chatChannelId)
        }else {
            self.didAppearFirstTime = false
        }
        self.chatTextView.text = ""
    }
    
    //MARK:- Upload image on firebase storage..
    func uploadImage(pickedImage: UIImage) {
        if isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            guard let imageData: Data = pickedImage.jpegData(compressionQuality: 1) else {
                ProgressHUD.dismiss()
                Loaf("Something went wrong while sending image.", state: .info, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                return
            }
            let metaDataConfig = StorageMetadata()
            metaDataConfig.contentType = "image/jpg"
            let storageRef = Storage.storage().reference().child(chatChannelId == "" ? "\(myEmail)\(userEmail)Channel" : chatChannelId).child("\(Date()).png")
            storageRef.putData(imageData, metadata: metaDataConfig){ (metaData, error) in
                if let error = error {
                    ProgressHUD.dismiss()
                    Loaf("Unable to send image at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    print(error.localizedDescription)
                    return
                }
                storageRef.downloadURL(completion: { (url: URL?, error: Error?) in
                    self.sendMessage(message: url?.absoluteString ?? "123.png", messageType: "1")
                })
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
}

//MARK:- UITextView delegates..
extension ChattingVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.becomeFirstResponder()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//MARK:- ImagePicker delegate..
extension ChattingVC: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            uploadImage(pickedImage: pickedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK:- UITableView Delegates..
extension ChattingVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessagesArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = chatMessagesArray[indexPath.row].message
        let messageType = chatMessagesArray[indexPath.row].messageType
        let senderId = chatMessagesArray[indexPath.row].senderId
        if senderId == myEmail {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatSenderCell") as? ChatSenderCell else {
                return UITableViewCell()
            }
            cell.senderIdentityLabel.text = "You"
            if messageType == "1" {
                cell.messageLabel.text = ""
                cell.messageView.isHidden = true
                cell.messageViewHeight.constant = 0
                cell.chattingImageView.isHidden = false
                cell.chattingImageView.sd_setImage(with: URL(string: message), placeholderImage: #imageLiteral(resourceName: "def"))
                cell.chatImageHeight.constant = 100
            }else {
                cell.messageLabel.text =  message
                cell.messageView.isHidden = false
                cell.chattingImageView.isHidden = true
                cell.chatImageHeight.constant = 0
            }
            cell.messageView.layer.cornerRadius = 10.0
            cell.messageView.clipsToBounds = true
            return cell
        }else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCell") as? ChatReceiverCell else {
                return UITableViewCell()
            }
            cell.receiverIdentityLabel.text = userName
            if messageType == "1" {
                cell.messageLabel.text = ""
                cell.messageView.isHidden = true
                cell.messageViewHeight.constant = 0
                cell.chattingImageView.isHidden = false
                cell.chattingImageView.sd_setImage(with: URL(string: message), placeholderImage: #imageLiteral(resourceName: "def"))
                cell.chatImageHeight.constant = 100
            }else {
                cell.messageLabel.text =  message
                cell.messageView.isHidden = false
                cell.chattingImageView.isHidden = true
                cell.chatImageHeight.constant = 0
            }
            cell.messageView.layer.cornerRadius = 10.0
            cell.messageView.clipsToBounds = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if chatMessagesArray[indexPath.row].messageType == "1" {
            let vc = storyboard.instantiateViewController(withIdentifier: "ImageViewerVC") as! ImageViewerVC
            vc.userImg = chatMessagesArray[indexPath.row].message
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true, completion: nil)
        }
    }
}

