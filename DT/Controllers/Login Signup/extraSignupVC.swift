//
//  extraSignupVC.swift
//  DT
//
//  Created by Apple on 09/11/2021.
//

import UIKit
import Loaf
import ProgressHUD
import CoreLocation
import FirebaseStorage
import FirebaseDatabase
import MaterialComponents.MaterialTextControls_OutlinedTextAreas
import MaterialComponents.MaterialTextControls_OutlinedTextFields

class extraSignupVC: BaseVC {
    
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var imageUploadIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var userNameTextField: MDCOutlinedTextField!
    @IBOutlet weak var aboutTextField: MDCOutlinedTextField!
    @IBOutlet weak var maleRadioImage: UIImageView!
    @IBOutlet weak var femaleRadioImage: UIImageView!
    
    var gender = "Male"
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
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gender = "Male"
        maleRadioImage.image = UIImage(named: "radioChecked")
        femaleRadioImage.image = UIImage(named: "radioUnchecked")
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
    
    //MARK:- Select Image..
    @IBAction func chooseImage(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        openGalleryCameraActionSheet(imagePicker: imagePicker)
        imagePicker.delegate = self
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
    
    //MARK:- Proceed further..
    @IBAction func go(_ sender: UIButton) {
        if userNameTextField.text != "", aboutTextField.text != "" {
            if isImageUploaded {
                if userLatitude != "" || userLongitude != "" {
                    ProgressHUD.show("", interaction: false)
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
                        self.databaseReference.child("Users").child(email.components(separatedBy: "@").first!).setValue(data) { error, _ in
                            if let error = error {
                                ProgressHUD.dismiss()
                                Loaf(error.localizedDescription, state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                            }else {
                                ProgressHUD.dismiss()
                                UserDefaults.standard.set(false, forKey: "isPartialSignup")
                                UserDefaults.standard.set(true, forKey: "isCompleteSignup")
                                let vc = self.storyboard?.instantiateViewController(identifier: "Tabbar")
                                self.navigationController?.pushViewController(vc!, animated: true)
                            }
                        }
                    }else {
                        ProgressHUD.dismiss()
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
            let storageRef = Storage.storage().reference().child("Users/").child("\(myEmail).png")
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
}

//MARK:- UITextField delegates..
extension extraSignupVC: UITextFieldDelegate {
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
extension extraSignupVC: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
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
extension extraSignupVC: CLLocationManagerDelegate {
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


