//
//  RequestsVC.swift
//  DT
//
//  Created by Apple on 11/11/2021.
//

import UIKit
import Loaf
import SDWebImage
import ProgressHUD
import FirebaseDatabase

class RequestsVC: BaseVC {
    
    @IBOutlet weak var requestsTableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var infoLabel: UILabel!
    
    var sentRequestArray = [UsersModel]()
    var receivedRequestArray = [UsersModel]()
    
    var myEmail = ""
    
    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
        ProgressHUD.colorAnimation = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        ProgressHUD.animationType = .circleRotateChase
        self.tabBarController?.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        myEmail = UserDefaults.standard.string(forKey: "userEmail")!.components(separatedBy: "@").first!
        segmentedControl.selectedSegmentIndex = 0
        getSentRequestsFromfirebase()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    //MARK:- Segmented Control Indexes..
    @IBAction func indexChanged(_ sender: Any) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            sentRequestArray.removeAll()
            getSentRequestsFromfirebase()
        case 1:
            receivedRequestArray.removeAll()
            getReceivedRequestsFromfirebase()
        default:
            break
        }
    }
    
    //MARK:- Fetch Sent Requests..
    func getSentRequestsFromfirebase() {
        if isInternetConnected() {
            self.hideInfoLabel()
            self.sentRequestArray.removeAll()
            let myEmail = UserDefaults.standard.string(forKey: "userEmail")!.components(separatedBy: "@").first!
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("SentRequests").observeSingleEvent(of: .value) {  [weak self] (snapshot) in
                guard let strongSelf = self else {
                    ProgressHUD.dismiss()
                    return
                }
                if snapshot.exists() {
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot,
                           let dictionary = childSnapshot.value as? [String:Any] {
                            strongSelf.getFriendDetail(email: dictionary["email"] as! String, isReceivedList: false)
                        }
                    }
                }else {
                    ProgressHUD.dismiss()
                    strongSelf.showInfoLabel(message: "You don't have any sent requests.")
                }
            }
        }else {
            self.showInfoLabel(message: "You're not connected to the internet.")
        }
    }
    
    //MARK:- Fetch Recevied Requests..
    func getReceivedRequestsFromfirebase() {
        if isInternetConnected() {
            self.hideInfoLabel()
            self.receivedRequestArray.removeAll()
            let myEmail = UserDefaults.standard.string(forKey: "userEmail")!.components(separatedBy: "@").first!
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("FriendsAndRequests").child(myEmail).child("ReceivedRequests").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    ProgressHUD.dismiss()
                    return
                }
                if snapshot.exists() {
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot,
                           let dictionary = childSnapshot.value as? [String:Any] {
                            strongSelf.getFriendDetail(email: dictionary["email"] as! String, isReceivedList: true)
                        }
                    }
                }else {
                    ProgressHUD.dismiss()
                    strongSelf.showInfoLabel(message: "You didn't receive any requests.")
                }
            }
        }else {
            self.showInfoLabel(message: "You're not connected to the internet.")
        }
    }
    
    //MARK:- Get detail about friends..
    func getFriendDetail(email: String, isReceivedList: Bool) {
        Database.database().reference().child("Users").child(email).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else {
                ProgressHUD.dismiss()
                return
            }
            if snapshot.exists() {
                guard let dictionary = snapshot.value as? [String: String] else {
                    ProgressHUD.dismiss()
                    Loaf("Unable to fetch friends reqests at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: strongSelf).show()
                    return
                }
                if isReceivedList {
                    strongSelf.receivedRequestArray.append(UsersModel(userName: dictionary["username"]!, userImage: dictionary["image"]!, userEmail: dictionary["email"]!, userAbout: dictionary["about"]!, userLatitude: dictionary["lat"]!, userLongitude: dictionary["lng"]!, userGender: dictionary["gender"]!, userStatus: dictionary["status"]!))
                }else {
                    strongSelf.sentRequestArray.append(UsersModel(userName: dictionary["username"]!, userImage: dictionary["image"]!, userEmail: dictionary["email"]!, userAbout: dictionary["about"]!, userLatitude: dictionary["lat"]!, userLongitude: dictionary["lng"]!, userGender: dictionary["gender"]!, userStatus: dictionary["status"]!))
                }
                DispatchQueue.main.async {
                    ProgressHUD.dismiss()
                    strongSelf.requestsTableView.reloadData()
                }
            }else {
                ProgressHUD.dismiss()
                Loaf("Unable to fetch friends reqests at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: strongSelf).show()
            }
        }
    }
    
    //MARK:- Show Information Label..
    func showInfoLabel(message: String) {
        infoLabel.isHidden = false
        requestsTableView.isHidden = true
        infoLabel.text = message
    }
    
    //MARK:- Hide Information Label..
    func hideInfoLabel() {
        infoLabel.isHidden = true
        requestsTableView.isHidden = false
    }
    
    //MARK:- Accept Request..
    @objc func acceptRequest(sender:UIButton) {
        var userEmail = ""
        if segmentedControl.selectedSegmentIndex == 0 {
            userEmail = sentRequestArray[sender.tag].userEmail.components(separatedBy: "@").first!
        }else {
            userEmail = receivedRequestArray[sender.tag].userEmail.components(separatedBy: "@").first!
        }
        if isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("FriendsAndRequests").child(userEmail).child("Friends").child(myEmail).setValue(["email":"\(myEmail)"]) { error, _ in
                if let error = error {
                    ProgressHUD.dismiss()
                    print(error.localizedDescription)
                    Loaf("Something went wrong while accepting request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }else {
                    Database.database().reference().child("FriendsAndRequests").child(self.myEmail).child("Friends").child(userEmail).setValue(["email":"\(userEmail)"]) { error, _ in
                        if let error = error {
                            ProgressHUD.dismiss()
                            print(error.localizedDescription)
                            Loaf("Something went wrong while accepting request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                        }else {
                            self.cancelRequest(userEmail: userEmail, userChildName: "SentRequests", myChildName: "ReceivedRequests", message: "Request has been accepted.")
                        }
                    }
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Reject Request..
    @objc func rejectRequest(sender:UIButton) {
        if isInternetConnected() {
            showConfirmationAlert(title: "Confirmation", message: "Are you sure you want to cancel the request?", indexPath: sender.tag)
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Display confirmation alert..
    func showConfirmationAlert(title: String, message: String, indexPath: Int) {
        let alertWarning = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: "Dismiss", style: .default) { (_) in }
        let cancelRequestButton = UIAlertAction(title: "Cancel Request", style: .destructive) { (_) in
            if self.segmentedControl.selectedSegmentIndex == 0 {
                ProgressHUD.show("", interaction: false)
                self.cancelRequest(userEmail: self.sentRequestArray[indexPath].userEmail.components(separatedBy: "@").first!, userChildName: "ReceivedRequests", myChildName: "SentRequests", message: "Request has been cancelled.")
            }else {
                ProgressHUD.show("", interaction: false)
                self.cancelRequest(userEmail: self.receivedRequestArray[indexPath].userEmail.components(separatedBy: "@").first!, userChildName: "SentRequests", myChildName: "ReceivedRequests", message: "Request has been cancelled.")
            }
        }
        alertWarning.addAction(dismissButton)
        alertWarning.addAction(cancelRequestButton)
        present(alertWarning, animated: true, completion: nil)
    }
    
    //MARK:- Reject/Cancel..
    func cancelRequest(userEmail: String, userChildName: String, myChildName: String, message: String) {
        Database.database().reference().child("FriendsAndRequests").child(userEmail).child(userChildName).child(myEmail).removeValue { error,_ in
            if let error = error {
                ProgressHUD.dismiss()
                print(error.localizedDescription)
                Loaf("Something went wrong with the request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
            }else {
                Database.database().reference().child("FriendsAndRequests").child(self.myEmail).child(myChildName).child(userEmail).removeValue { error,_ in
                    if let error = error {
                        ProgressHUD.dismiss()
                        print(error.localizedDescription)
                        Loaf("Something went wrong with the request.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    }else {
                        if self.segmentedControl.selectedSegmentIndex == 0 {
                            self.sentRequestArray.removeAll()
                            self.getSentRequestsFromfirebase()
                        }else {
                            self.receivedRequestArray.removeAll()
                            self.getReceivedRequestsFromfirebase()
                        }
                        ProgressHUD.dismiss()
                        Loaf(message, state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    }
                }
            }
        }
    }
}

//MARK:- UITableView Delegates..
extension RequestsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return sentRequestArray.count
        }else {
            return receivedRequestArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RequestsCell") as? RequestsCell else {return UITableViewCell()}
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.acceptRequestButton.isHidden = true
            cell.friendImageView.sd_setImage(with: URL(string: sentRequestArray[indexPath.row].userImage), placeholderImage: #imageLiteral(resourceName: "def"))
            cell.friendNameLabel.text = sentRequestArray[indexPath.row].userName
            cell.rejectRequestButton.tag = indexPath.row
        }else {
            cell.acceptRequestButton.isHidden = false
            cell.friendImageView.sd_setImage(with: URL(string: receivedRequestArray[indexPath.row].userImage), placeholderImage: #imageLiteral(resourceName: "def"))
            cell.friendNameLabel.text = receivedRequestArray[indexPath.row].userName
            cell.acceptRequestButton.tag = indexPath.row
            cell.rejectRequestButton.tag = indexPath.row
        }
        cell.acceptRequestButton.addTarget(self, action: #selector(acceptRequest(sender:)), for: .touchUpInside)
        cell.rejectRequestButton.addTarget(self, action: #selector(rejectRequest(sender:)), for: .touchUpInside)
        return cell
    }
}


