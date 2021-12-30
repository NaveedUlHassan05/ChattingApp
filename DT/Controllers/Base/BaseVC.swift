//
//  BaseVC.swift
//  DT
//
//  Created by Apple on 09/11/2021.
//

import UIKit
import ProgressHUD
import AuthenticationServices
import CryptoKit
import MaterialComponents.MaterialTextControls_OutlinedTextAreas
import MaterialComponents.MaterialTextControls_OutlinedTextFields

class BaseVC: UIViewController {
    
    var pwdTextField = MDCOutlinedTextField()
    var confirmPwdTextField = MDCOutlinedTextField()
    
    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK:- Go Back..
    @IBAction func goBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK:- Hide keyboard when tapped outisde keyboard..
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    //MARK:- keyboard hidden..
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK:- Check internet connectivity..
    func isInternetConnected() -> Bool {
        if ReachAbility.isConnectedToNetwork() { return true }
        else {
            return false
        }
    }
    
    //MARK:- Check Password Strength..
    func isValidPassword(_ password: String) -> Bool {
        let minPasswordLength = 8
        return password.count >= minPasswordLength
    }
    
    //MARK:- Getting current time..
    func getCurrentTime(isGeneratingNode: Bool) -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        if isGeneratingNode {
            dateFormatter.dateFormat = "yyyy_MM_dd HH_mm_ss_SSSZ"
        }else {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        }
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: date)
    }
    
    //MARK:- Display location services access alert..
    func locationServicesAlert(title: String, message: String) {
        let alertWarning = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: .default) { (_) in }
        let SettingsButton = UIAlertAction(title: "Settings", style: .default) { (_) in
            self.openAppSettings()
        }
        alertWarning.addAction(cancelButton)
        alertWarning.addAction(SettingsButton)
        present(alertWarning, animated: true, completion: nil)
    }
    
    //MARK:- Open device settings..
    func openAppSettings() {
        if let url = URL(string:UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    //MARK:- Select Gallery/Camera Action Sheet..
    func openGalleryCameraActionSheet(imagePicker: UIImagePickerController) {
        let alert = UIAlertController(title: "Title", message: "Select an Option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction)in
            self.Camera(imagePicker: imagePicker)
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction)in
            self.Gallery(imagePicker: imagePicker)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: {})
    }
    
    //MARK:- Open Gallery..
    func Gallery(imagePicker: UIImagePickerController) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            imagePicker.modalPresentationStyle = .popover
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have the permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK:- Open Camera..
    func Camera(imagePicker: UIImagePickerController) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            imagePicker.modalPresentationStyle = .popover
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have a camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK:- Material design textfields customization..
    func customizeMaterialDesignTextFields(textField: MDCOutlinedTextField, labelText: String, imageName: String, hintText: String) {
        textField.containerRadius = 10.0
        textField.label.text = labelText
        textField.setOutlineColor(#colorLiteral(red: 0.7803921569, green: 0.7843137255, blue: 0.8039215686, alpha: 1), for: .normal)
        textField.setOutlineColor(#colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1), for: .editing)
        textField.setNormalLabelColor(#colorLiteral(red: 0.7803921569, green: 0.7843137255, blue: 0.8039215686, alpha: 1), for: .normal)
        textField.setFloatingLabelColor(#colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1), for: .editing)
        textField.setFloatingLabelColor(#colorLiteral(red: 0.7803921569, green: 0.7843137255, blue: 0.8039215686, alpha: 1), for: .normal)
        if hintText != "" {
            textField.leadingAssistiveLabel.text = hintText
        }
        if imageName != "" {
            textField.leadingView = UIImageView(image: UIImage(named: imageName))
            textField.leadingViewMode = .always
        }
    }
    
    //MARK:- Material design error textfields customization..
    func customizeMaterialDesignErrorTextFields(textField: MDCOutlinedTextField, color: UIColor) {
        textField.setOutlineColor(color, for: .normal)
        textField.setOutlineColor(color, for: .editing)
        textField.setFloatingLabelColor(color, for: .normal)
        textField.setFloatingLabelColor(color, for: .editing)
    }
    
    //MARK:- Material design password textfields customization..
    func customizeMaterialDesignPasswordTextFields(textField: MDCOutlinedTextField, labelText: String, imageName: String, tag: Int) {
        textField.containerRadius = 10.0
        textField.label.text = labelText
        textField.setOutlineColor(#colorLiteral(red: 0.7803921569, green: 0.7843137255, blue: 0.8039215686, alpha: 1), for: .normal)
        textField.setOutlineColor(#colorLiteral(red: 1, green: 0.4470588235, blue: 0.3607843137, alpha: 1), for: .editing)
        textField.setNormalLabelColor(#colorLiteral(red: 0.7803921569, green: 0.7843137255, blue: 0.8039215686, alpha: 1), for: .normal)
        textField.setFloatingLabelColor(#colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1), for: .editing)
        textField.setFloatingLabelColor(#colorLiteral(red: 0.7803921569, green: 0.7843137255, blue: 0.8039215686, alpha: 1), for: .normal)
        if imageName != "" {
            textField.leadingView = UIImageView(image: UIImage(named: imageName))
            textField.leadingViewMode = .always
        }
        let passwordButton = UIButton(type: .custom)
        passwordButton.frame = CGRect(x: CGFloat(0), y: CGFloat(0),
                                      width: CGFloat(15), height: CGFloat(15))
        passwordButton.setImage(UIImage(named: "showPassword"), for: .normal)
        passwordButton.setImage(UIImage(named: "hidePassword"), for: .selected)
        passwordButton.tag = tag
        if tag == 0 {
            pwdTextField = textField
        }else{
            confirmPwdTextField = textField
        }
        passwordButton.addTarget(self, action: #selector(hideShowPassword), for: .touchUpInside)
        textField.trailingView = passwordButton
        textField.trailingViewMode = .always
    }
    
    //MARK:- Hide/Show Password..
    @objc func hideShowPassword(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.tag == 0 {
            pwdTextField.isSecureTextEntry = !sender.isSelected
        }else {
            confirmPwdTextField.isSecureTextEntry = !sender.isSelected
        }
    }
    
    //MARK:- You will send the SHA256 hash of the nonce with your sign-in request, which Apple will pass unchanged in the response. Firebase validates the response by hashing the original nonce and comparing it to the value passed by Apple..
    @available(iOS 13, *)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    //MARK:- For every sign-in request, generate a random string—a "nonce"—which you will use to make sure the ID token you get was granted specifically in response to your app's authentication request. This step is important to prevent replay attacks. You can generate a cryptographically secure nonce with SecRandomCopyBytes(_:_:_), as in the following example..
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}





