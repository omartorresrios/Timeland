//
//  LoginController.swift
//  ReputationApp
//
//  Created by Omar Torres on 10/05/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import Alamofire
import Locksmith

class LoginController: UIViewController {
    
    let logoContainerView: UIView = {
        let view = UIView()
        
        let logoImageView = UIImageView(image: #imageLiteral(resourceName: "pio"))
        logoImageView.contentMode = .scaleAspectFill
        
        view.addSubview(logoImageView)
        logoImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 50)
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.backgroundColor = UIColor.rgb(red: 0, green: 120, blue: 175)
        return view
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.autocapitalizationType = UITextAutocapitalizationType.none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
    }()
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    func handleTextInputChange() {
        let isFormValid = emailTextField.text?.characters.count ?? 0 > 0 && passwordTextField.text?.characters.count ?? 0 > 0
        
        if isFormValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.rgb(red: 17, green: 154, blue: 237)
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        }
    }
    
    func displayAlertMessage(_ alertTitle:String, alertDescription:String) -> Void {
        // hide activityIndicator view and display alert message
        let errorAlert = UIAlertView(title:alertTitle, message:alertDescription, delegate:nil, cancelButtonTitle:"OK")
        errorAlert.show()
    }

    func updateUserLoggedInFlag() {
        // Update the NSUserDefaults flag
        let defaults = UserDefaults.standard
        defaults.set("loggedIn", forKey: "userLoggedIn")
        defaults.synchronize()
    }
    
    func saveApiTokenInKeychain(tokenString: String, idInt: Int, nameString: String) {
        // save API AuthToken in Keychain
        try! Locksmith.saveData(data: ["authenticationToken": tokenString], forUserAccount: "AuthToken")
        try! Locksmith.saveData(data: ["id": idInt], forUserAccount: "currentUserId")
        try! Locksmith.saveData(data: ["name": nameString], forUserAccount: "currentUserName")
        
        print("AuthToken recién guardado: \(Locksmith.loadDataForUserAccount(userAccount: "AuthToken")!)")
        print("currentUserId recién guardado: \(Locksmith.loadDataForUserAccount(userAccount: "currentUserId")!)")
        print("currentUserName recién guardado: \(Locksmith.loadDataForUserAccount(userAccount: "currentUserName")!)")
        
    }
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    func handleLogin() {
        guard let userEmail = emailTextField.text else { return }
        guard let userPassword = passwordTextField.text else { return }
        
        let encrypted_password = AESCrypt.encrypt(userPassword, password: HTTPHelper.API_AUTH_PASSWORD)
        
        let parameters = ["email": userEmail, "password": encrypted_password!] as [String : Any]
        
        let url = URL(string: "https://protected-anchorage-18127.herokuapp.com/api/users/signin")!
        
        // Set BASIC authentication header
        let basicAuthString = "\(HTTPHelper.API_AUTH_NAME):\(HTTPHelper.API_AUTH_PASSWORD)"
        let utf8str = basicAuthString.data(using: String.Encoding.utf8)
        let base64EncodedString = utf8str?.base64EncodedString()
        
        let headers = ["Authorization": "Basic \(base64EncodedString)"]
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            for (key, value) in parameters {
                multipartFormData.append(((value as Any) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
            }
            
        }, usingThreshold: UInt64.init() , to: url, method: .post, headers: headers, encodingCompletion: { encodingResult in
            
            switch encodingResult {
                case .success(let upload, _, _):
                    
                    self.updateUserLoggedInFlag()
                    
                    upload.responseJSON { response in
                        print("request: \(response.request!)") // original URL request
                        print("response: \(response.response!)") // URL response
                        print("response data: \(response.data!)") // server data
                        print("result: \(response.result)") // result of response serialization
                        
                        if let JSON = response.result.value as? NSDictionary {
                            let userJSON = JSON["user"] as! NSDictionary
                            let authToken = userJSON["authenticationToken"] as! String
                            let userId = userJSON["id"] as! Int
                            let userName = userJSON["fullname"] as! String
                            print("userJSON: \(userJSON)")
                            print("JSON: \(JSON)")
                            self.saveApiTokenInKeychain(tokenString: authToken, idInt: userId, nameString: userName)
                            print("authToken: \(authToken)")
                            print("userId: \(userId)")
                            
                            self.view.endEditing(true)
                            
                            let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDel.logUser(forAppDelegate: true)
                            
                        }
                    }
                    
                
                    
                case .failure(let encodingError):
                    print("Alamofire proccess failed", encodingError)
            }
        })
        
    }
    
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.rgb(red: 17, green: 154, blue: 237)
            ]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    func handleShowSignUp() {
        let signUpController = SignUpController()
        navigationController?.pushViewController(signUpController, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(logoContainerView)
        logoContainerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150)
        
        navigationController?.isNavigationBarHidden = true
        
        view.backgroundColor = .white
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        setupInputFields()
    }
    
    fileprivate func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton])
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: logoContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 40, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 140)
    }
    
    
    
}
