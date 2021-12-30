//
//  SignupVC.swift
//  DT
//
//  Created by Apple on 09/11/2021.
//

import UIKit
import Loaf
import ProgressHUD
import FirebaseAuth
import MaterialComponents.MaterialTextControls_OutlinedTextAreas
import MaterialComponents.MaterialTextControls_OutlinedTextFields

class SignupVC: BaseVC {
    
    @IBOutlet weak var emailTextField: MDCOutlinedTextField!
    @IBOutlet weak var passwordTextField: MDCOutlinedTextField!
    @IBOutlet weak var confirmPasswordTextField: MDCOutlinedTextField!
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
        confirmPasswordTextField.delegate = self
        customizeMaterialDesignTextFields(textField: emailTextField, labelText: "Email Address", imageName: "mail", hintText: "")
        customizeMaterialDesignPasswordTextFields(textField: passwordTextField, labelText: "Password", imageName: "password", tag: 0)
        customizeMaterialDesignPasswordTextFields(textField: confirmPasswordTextField, labelText: "Confirm Password", imageName: "password", tag: 1)
    }
    
    //MARK:- Signup..
    @IBAction func signup(_ sender: UIButton) {
        if emailTextField.text != "", passwordTextField.text != "", confirmPasswordTextField.text != "" {
            if emailTextField.text!.isValidEmail() {
                if passwordTextField.text == confirmPasswordTextField.text {
                    let isValidPassword = isValidPassword(passwordTextField.text!)
                    if isValidPassword {
                        if isInternetConnected() {
                            ProgressHUD.show("", interaction: false)
                            proceedSignup(email: emailTextField.text!, password: passwordTextField.text!)
                        }else {
                            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                        }
                    }else {
                        Loaf("The password must be 6 characters long or more.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    }
                }else {
                    Loaf("Passwords do not match.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }
            }else{
                Loaf("Please enter a valid email.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
            }
        }else {
            Loaf("All empty fields are required.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Proceed Signup..
    func proceedSignup(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                ProgressHUD.dismiss()
                switch AuthErrorCode(rawValue: error.code) {
                case .operationNotAllowed:
                    Loaf("Unable to signup at this time. Please try again.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                case .emailAlreadyInUse:
                    Loaf("The email address is already in use by another account.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                case .invalidEmail:
                    Loaf("Please enter a valid email.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                case .weakPassword:
                    Loaf("The password must be 6 characters long or more.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                default:
                    print("Error: \(error.localizedDescription)")
                    Loaf("Something went wrong while signing up.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }
            } else {
                ProgressHUD.dismiss()
                UserDefaults.standard.set(true, forKey: "isPartialSignup")
                UserDefaults.standard.set(false, forKey: "isCompleteSignup")
                UserDefaults.standard.set(email.lowercased(), forKey: "userEmail")
                let vc = self.storyboard?.instantiateViewController(identifier: "extraSignupVC") as! extraSignupVC
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

//MARK:- UITextField delegates..
extension SignupVC: UITextFieldDelegate {
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

