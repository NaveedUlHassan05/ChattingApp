//
//  ProfileVC.swift
//  DT
//
//  Created by Apple on 11/11/2021.
//

import UIKit
import Loaf
import ProgressHUD
import CoreLocation
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import MaterialComponents.MaterialTextControls_OutlinedTextAreas
import MaterialComponents.MaterialTextControls_OutlinedTextFields

class ProfileVC: BaseVC {
    
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var imageUploadIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var userNameTextField: MDCOutlinedTextField!
    @IBOutlet weak var aboutTextField: MDCOutlinedTextField!
    @IBOutlet weak var maleRadioImage: UIImageView!
    @IBOutlet weak var femaleRadioImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var gender = ""
    var uploadedImageUrl = ""
    var userLatitude = ""
    var userLongitude = ""
    var isImageUploaded: Bool = false
    let locationManager = CLLocationManager()
    let databaseReference = Database.database().reference()
    
    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTextFields()
        hideKeyboardWhenTappedAround()
        imageUploadIndicator.isHidden = true
        ProgressHUD.colorAnimation = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        ProgressHUD.animationType = .circleRotateChase
        self.tabBarController?.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getProfileInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageContainerView.layer.cornerRadius = imageContainerView.frame.size.width/2
        imageContainerView.layer.borderWidth = 2.0
        imageContainerView.layer.borderColor = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        imageContainerView.clipsToBounds = true
    }
    
    //MARK:- Customize Material Design TextFields Appearance..
    func prepareTextFields() {
        userNameTextField.delegate = self
        aboutTextField.delegate = self
        customizeMaterialDesignTextFields(textField: userNameTextField, labelText: "User Name", imageName: "", hintText: "")
        customizeMaterialDesignTextFields(textField: aboutTextField, labelText: "About", imageName: "", hintText: "")
    }
    
    //MARK:- Get Profile Data..
    func getProfileInfo() {
        scrollView.isHidden = true
        if isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            let email = UserDefaults.standard.string(forKey: "userEmail")!
            Database.database().reference().child("Users").child((email.components(separatedBy: "@").first)!).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    ProgressHUD.dismiss()
                    return
                }
                if snapshot.exists() {
                    guard let user = snapshot.value as? [String: String] else {
                        ProgressHUD.dismiss()
                        Loaf("Unable to fetch profile data at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: strongSelf).show()
                        return
                    }
                    DispatchQueue.main.async {
                        strongSelf.userNameTextField.text = user["username"]!
                        strongSelf.aboutTextField.text = user["about"]!
                        strongSelf.userImage.sd_setImage(with: URL(string: user["image"]!), placeholderImage: #imageLiteral(resourceName: "def"))
                        if user["gender"]!.lowercased() == "male" {
                            strongSelf.gender = user["gender"]!
                            strongSelf.maleRadioImage.image = UIImage(named: "radioChecked")
                            strongSelf.femaleRadioImage.image = UIImage(named: "radioUnchecked")
                        }else {
                            strongSelf.gender = user["gender"]!
                            strongSelf.maleRadioImage.image = UIImage(named: "radioUnchecked")
                            strongSelf.femaleRadioImage.image = UIImage(named: "radioChecked")
                        }
                        strongSelf.uploadedImageUrl = user["image"]!
                        strongSelf.userLatitude = user["lat"]!
                        strongSelf.userLongitude = user["lng"]!
                        strongSelf.isImageUploaded = true
                        strongSelf.scrollView.isHidden = false
                        ProgressHUD.dismiss()
                    }
                }else {
                    ProgressHUD.dismiss()
                    Loaf("Unable to fetch profile data at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: strongSelf).show()
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- User is Male..
    @IBAction func male(_ sender: UIButton) {
        gender = "Male"
        maleRadioImage.image = UIImage(named: "radioChecked")
        femaleRadioImage.image = UIImage(named: "radioUnchecked")
    }
    
    //MARK:- User is Female..
    @IBAction func female(_ sender: UIButton) {
        gender = "Female"
        maleRadioImage.image = UIImage(named: "radioUnchecked")
        femaleRadioImage.image = UIImage(named: "radioChecked")
    }
    
    //MARK:- Select Image..
    @IBAction func chooseImage(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        openGalleryCameraActionSheet(imagePicker: imagePicker)
        imagePicker.delegate = self
    }
    
    //MARK:- Proceed further..
    @IBAction func update(_ sender: UIButton) {
        if userNameTextField.text != "", aboutTextField.text != "" {
            if isImageUploaded {
                if userLatitude != "" || userLongitude != "" {
                    let email = UserDefaults.standard.string(forKey: "userEmail")!
                    let data = [
                        "email": email,
                        "image": uploadedImageUrl,
                        "username": userNameTextField.text!,
                        "gender": gender,
                        "about": aboutTextField.text!,
                        "lat": userLatitude,
                        "lng": userLongitude,
                        "status": "online",
                    ] as [String : String]
                    if isInternetConnected() {
                        ProgressHUD.show("", interaction: false)
                        self.databaseReference.child("Users").child(email.components(separatedBy: "@").first!).setValue(data) { error, _ in
                            if let error = error {
                                ProgressHUD.dismiss()
                                print(error.localizedDescription)
                                Loaf("Unable to update profile at this moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                            }else {
                                ProgressHUD.dismiss()
                                Loaf("Profile has been updated successfully.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                            }
                        }
                    }else {
                        Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    }
                }else {
                    checkAuthorizationStatus()
                }
            }else {
                Loaf("Profile picture is not uploaded yet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
            }
        }else {
            Loaf("Both username and about are required.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Check location permisssion authorization status..
    func checkAuthorizationStatus() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let locationAuthorizationStatus = CLLocationManager.authorizationStatus()
        switch locationAuthorizationStatus {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.startUpdatingLocation()
            }
        case .restricted, .denied:
            self.locationServicesAlert(title: "Warning", message: "The app does not have access to your current location. To enable access, tap Settings > Privacy > Location Services and allow location access.")
        @unknown default:
            break
        }
    }
    
    //MARK:- Logout..
    @IBAction func logout(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            let email = UserDefaults.standard.string(forKey: "userEmail")!.components(separatedBy: "@").first!
            if isInternetConnected() {
                self.databaseReference.child("Users/\(email)/status").setValue("offline") { error, _ in
                    if let error = error {
                        print(error.localizedDescription)
                        Loaf("Unable to logout at this time.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    }else {
                        UserDefaults.standard.set(false, forKey: "isPartialSignup")
                        UserDefaults.standard.set(false, forKey: "isCompleteSignup")
                        let delegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
                        let initialVC = (self.storyboard?.instantiateViewController(identifier: "OnboardingVC"))!
                        let nav = UINavigationController(rootViewController: initialVC)
                        delegate?.window?.rootViewController = nav
                    }
                }
            } else {
                Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
            }
        } catch {
            Loaf("Unable to logout at this time.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Show spinner while uploading image..
    func showImageUploadSpinner() {
        cameraButton.isEnabled = false
        imageUploadIndicator.isHidden = false
        imageUploadIndicator.startAnimating()
    }
    
    //MARK:- Hide spinner while uplaoding image..
    func hideImageUploadSpinner() {
        cameraButton.isEnabled = true
        imageUploadIndicator.isHidden = true
        imageUploadIndicator.stopAnimating()
    }
    
    //MARK:- Upload image on firebase storage..
    func uploadImage(pickedImage: UIImage) {
        if isInternetConnected() {
            guard let imageData: Data = pickedImage.jpegData(compressionQuality: 1) else {
                isImageUploaded = false
                hideImageUploadSpinner()
                Loaf("Something went wrong while uplaoding image.", state: .info, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                return
            }
            let metaDataConfig = StorageMetadata()
            metaDataConfig.contentType = "image/jpg"
            let myEmail = UserDefaults.standard.string(forKey: "userEmail")!
            let storageRef = Storage.storage().reference().child("Users/").child("\(myEmail).jpg")
            storageRef.putData(imageData, metadata: metaDataConfig){ (metaData, error) in
                if let error = error {
                    self.isImageUploaded = false
                    self.hideImageUploadSpinner()
                    Loaf("Unable to upload image at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    print(error.localizedDescription)
                    return
                }
                storageRef.downloadURL(completion: { (url: URL?, error: Error?) in
                    self.userImage.image = pickedImage
                    self.isImageUploaded = true
                    self.hideImageUploadSpinner()
                    self.uploadedImageUrl =  url?.absoluteString ?? ""
                })
            }
        }else {
            isImageUploaded = false
            hideImageUploadSpinner()
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
}

//MARK:- UITextField delegates..
extension ProfileVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//MARK:- ImagePicker delegate..
extension ProfileVC: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            userImage.image = nil
            isImageUploaded = false
            showImageUploadSpinner()
            uploadImage(pickedImage: pickedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK:- CLLocationManagerDelegates..
extension ProfileVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            break
        case .authorizedWhenInUse, .authorizedAlways:
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.startUpdatingLocation()
            }
        case .restricted, .denied:
            self.locationServicesAlert(title: "Warning", message: "The app does not have access to your current location. To enable access, tap Settings > Privacy > Location Services and allow location access.")
        @unknown default:
            break
        }
    }
    
    //MARK:- Getting User's location coordinates and extracting address from coordinates..
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        locationManager.stopUpdatingLocation()
        self.userLatitude = "\(location.coordinate.latitude)"
        self.userLongitude = "\(location.coordinate.longitude)"
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Loaf("Something went wrong while fetching your current location.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
    }
}



