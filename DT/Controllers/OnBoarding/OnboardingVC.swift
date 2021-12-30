//
//  OnboardingVC.swift
//  DT
//
//  Created by Apple on 10/11/2021.
//

import UIKit
import Loaf
import ProgressHUD
import FirebaseAuth
import paper_onboarding
import AuthenticationServices

import FirebaseDatabase

class OnboardingVC: BaseVC {
    
    @IBOutlet weak var onboardingView: PaperOnboarding!
    
    private var currentNonce: String?
    
    //MARK:- View Lifecycle..
    override func viewDidLoad() {
        super.viewDidLoad()
        ProgressHUD.colorAnimation = #colorLiteral(red: 1, green: 0.4470835328, blue: 0.3607658148, alpha: 1)
        ProgressHUD.animationType = .circleRotateChase
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    //MARK:- Login With Email..
    @IBAction func loginWithEmail(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(identifier: "SignInVC") as! SignInVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK:- Login With Apple..
    @IBAction func loginWithApple(_ sender: UIButton) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    //MARK:- Signup..
    @IBAction func signup(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(identifier: "SignupVC") as! SignupVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK:- Check User Existence..
    func checkUserExistence(email: String) {
        if isInternetConnected() {
            ProgressHUD.show("", interaction: false)
            Database.database().reference().child("Users").child(email.components(separatedBy: "@").first!).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else {
                    ProgressHUD.dismiss()
                    return
                }
                if snapshot.exists() {
                    guard let user = snapshot.value as? [String: String] else {
                        ProgressHUD.dismiss()
                        Loaf("Unable to Login at this moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: strongSelf).show()
                        return
                    }
                    if user["email"]!.lowercased() == email.lowercased() {
                        ProgressHUD.dismiss()
                        strongSelf.proceedFurther(email: email, isPartialSignup: false, isCompleteSignup: true)
                    }else {
                        ProgressHUD.dismiss()
                        strongSelf.proceedFurther(email: email, isPartialSignup: true, isCompleteSignup: false)
                    }
                }else {
                    ProgressHUD.dismiss()
                    strongSelf.proceedFurther(email: email, isPartialSignup: true, isCompleteSignup: false)
                }
            }
        }else {
            Loaf("You're not connected to the internet.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
        }
    }
    
    //MARK:- Proceed..
    func proceedFurther(email: String, isPartialSignup: Bool, isCompleteSignup: Bool) {
        UserDefaults.standard.set(isPartialSignup, forKey: "isPartialSignup")
        UserDefaults.standard.set(isCompleteSignup, forKey: "isCompleteSignup")
        UserDefaults.standard.set(email.lowercased(), forKey: "userEmail")
        if isPartialSignup {
            let vc = self.storyboard?.instantiateViewController(identifier: "extraSignupVC") as! extraSignupVC
            self.navigationController?.pushViewController(vc, animated: true)
        }else {
            Database.database().reference().child("Users/\(email.components(separatedBy: "@").first!)/status").setValue("online") { error, _ in
                if let error = error {
                    ProgressHUD.dismiss()
                    print(error.localizedDescription)
                    Loaf("Unable to login at the moment.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                }else {
                    ProgressHUD.dismiss()
                    let vc = self.storyboard?.instantiateViewController(identifier: "Tabbar")
                    self.navigationController?.pushViewController(vc!, animated: true)
                }
            }
        }
    }
}

//MARK:- ASAuthorizationController Delegate..
extension OnboardingVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                Loaf("Invalid state: A login callback was received, but no login request was sent.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                Loaf("Unable to fetch identity token.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print(appleIDToken.debugDescription)
                Loaf("Unable to serialize token string from data.", state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                return
            }
            //MARK:- Initialize a Firebase credential..
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            //MARK:- Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    Loaf(error.localizedDescription, state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
                    return
                }
                if let email = authResult?.user.email {
                    self.checkUserExistence(email: email)
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Loaf(error.localizedDescription, state: .info, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
    }
}

//MARK:- Presenting the Sign in with Apple content to the user in a modal sheet..
extension OnboardingVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

//MARK:- OnBoarding Delegates..
extension OnboardingVC: PaperOnboardingDelegate, PaperOnboardingDataSource {
    func onboardingItemsCount() -> Int {
        return 2
    }
    
    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        return [
            OnboardingItemInfo(informationImage: UIImage(named: "1") ?? UIImage(),
                               title: "Welcome",
                               description: "Welcome to Let's Chat, where you will meet new people and enjoy meeting the ones you like. Whether you need to find a boyfriend, girlfriend, or a soulmate to chat with about everything in the world, you’ll surely be satisfied with our offers. Don’t miss out on your chance to expand your social circle.",
                               pageIcon: UIImage(),
                               color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                               titleColor: .black,
                               descriptionColor: .lightGray,
                               titleFont: UIFont(name: "Poppins-Medium", size: 18)!,
                               descriptionFont: UIFont(name: "Poppins-Regular", size: 14)!),
            OnboardingItemInfo(informationImage: UIImage(named: "2") ?? UIImage(),
                               title: "Connect & Chat",
                               description: "Explore, Connect and easily start unique conversations with friends from all over the world. Send a message and introduce yourself to people you’d like to get to know better, and then take your friendship from there. Our app is a great tool for you to grow your social circle, meet and date new people.",
                               pageIcon: UIImage(),
                               color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                               titleColor: .black,
                               descriptionColor: .lightGray,
                               titleFont: UIFont(name: "Poppins-Medium", size: 18)!,
                               descriptionFont: UIFont(name: "Poppins-Regular", size: 14)!)
        ][index]
    }
}
