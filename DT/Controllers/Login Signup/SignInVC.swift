//
//  SignInVC.swift
//  DT
//
//  Created by Apple on 09/11/2021.
//

import UIKit
import Loaf
import ProgressHUD
import FirebaseAuth
import FirebaseDatabase
import MaterialComponents.MaterialTextControls_OutlinedTextAreas
import MaterialComponents.MaterialTextControls_OutlinedTextFields

class SignInVC: BaseVC {
    
    @IBOutlet weak var emailTextField: MDCOutlinedTextField!
    @IBOutlet weak var passwordTextField: MDCOutlinedTextField!
    @IBOutlet weak var goBackButton: UIButton!
    
    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTextFields()
        hideKeyboardWhenTappedAround()
        ProgressHUD.colorAnimation = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        ProgressHUD.animationType = .circleRotateChase
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        goBackButton.roundCorners(corners: [.topRight, .bottomRight], radius: 10.0)
    }
    
    //MARK:- Customize Material Design TextFields Appearance..
    func prepareTextFields() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        customizeMaterialDesignTextFields(textField: emailTextField, labelText: "Email Address", imageName: "mail", hintText: "")
        customizeMaterialDesignPasswordTextFields(textField: passwordTextField, labelText: "Password", imageName: "password", tag: 0)
    }
    
    //MARK:- Signin..
    @IBAction func signin(_ sender: UIButton) {
        if emailTextField.text != "", passwordTextField.text != "" {
            let isValidEmail = emailTextField.text!.isValidEmail()
            if isValidEmail {
                if isInternetConnected() {
                    ProgressHUD.show("", interaction: false)
                    proceeedLogin(email: emailTextField.text!, password: passwordTextField.text!)
                }else {
                    Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }
            }else{
                Loaf("Please enter a valid email.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
            }
        }else {
            Loaf("Both email and password are required.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Proceed..
    func proceeedLogin(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error as NSError? {
                ProgressHUD.dismiss()
                switch AuthErrorCode(rawValue: error.code) {
                case .operationNotAllowed:
                    Loaf("This account is not enabled.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                case .userDisabled:
                    Loaf("The user account has been disabled by an administrator.", state: .info, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                case .wrongPassword:
                    Loaf("The password is invalid or the user does not have a password.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                case .invalidEmail:
                    Loaf("Please enter a valid email.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                default:
                    print("Error: \(error.localizedDescription)")
                    Loaf("Something went wrong while login.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }
            } else {
                Database.database().reference().child("Users/\(email.components(separatedBy: "@").first!)/status").setValue("online") { error, _ in
                    if let error = error {
                        ProgressHUD.dismiss()
                        print(error.localizedDescription)
                        Loaf("Unable to login at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    }else {
                        ProgressHUD.dismiss()
                        UserDefaults.standard.set(false, forKey: "isPartialSignup")
                        UserDefaults.standard.set(true, forKey: "isCompleteSignup")
                        UserDefaults.standard.set(email.lowercased(), forKey: "userEmail")
                        let vc = self.storyboard?.instantiateViewController(identifier: "Tabbar")
                        self.navigationController?.pushViewController(vc!, animated: true)
                    }
                }
            }
        }
    }
    
    //MARK:- Signup..
    @IBAction func signup(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(identifier: "SignupVC") as! SignupVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK:- EULA..
    @IBAction func eulaPolicy(_ sender: UIButton) {
        if isInternetConnected() {
            let vc = storyboard?.instantiateViewController(withIdentifier: "PrivacyPolicyVC") as! PrivacyPolicyVC
            vc.policyUrl = "https://irinaprihodko.wordpress.com/wiples-terms-of-use-agreement/"
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true, completion: nil)
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Privacy Policy..
    @IBAction func privacyPolicy(_ sender: UIButton) {
        if isInternetConnected() {
            let vc = storyboard?.instantiateViewController(withIdentifier: "PrivacyPolicyVC") as! PrivacyPolicyVC
            vc.policyUrl = "https://irinaprihodko.wordpress.com/2021/10/24/privacy-policy/"
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true, completion: nil)
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
}

//MARK:- UITextField delegates..
extension SignInVC: UITextFieldDelegate {
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

