//
//  SignUpController.swift
//  ReputationApp
//
//  Created by Omar Torres on 26/05/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import Alamofire
import Locksmith

class SignUpController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let httpHelper = HTTPHelper()
    var imageData: Data?
    
    let plusPhotoButton: UIImageView = {
        let image = UIImageView()
        image.image = #imageLiteral(resourceName: "plus_photo")
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        return image
    }()
    
    func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            plusPhotoButton.image = editedImage.withRenderingMode(.alwaysOriginal)
            imageData = UIImageJPEGRepresentation(editedImage, 0.5)
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            plusPhotoButton.image = originalImage.withRenderingMode(.alwaysOriginal)
            imageData = UIImageJPEGRepresentation(originalImage, 0.5)
        }
//        
//        
//        if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
//            plusPhotoButton.image = originalImage.withRenderingMode(.alwaysOriginal)
//        }
//        
//        imageData = UIImageJPEGRepresentation((info["UIImagePickerControllerOriginalImage"] as? UIImage)!, 0.5)
            
//            UIImageJPEGRepresentation(imagePicked, 0.5)
//            UIImagePNGRepresentation((info["UIImagePickerControllerOriginalImage"] as? UIImage)!)
        
        dismiss(animated: true, completion: nil)
    }
    
    let fullnameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Fullname"
        tf.autocapitalizationType = UITextAutocapitalizationType.none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
    }()
    
    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.autocapitalizationType = UITextAutocapitalizationType.none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
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
    
    func handleTextInputChange() {
        let isFormValid = emailTextField.text?.characters.count ?? 0 > 0 && usernameTextField.text?.characters.count ?? 0 > 0 && fullnameTextField.text?.characters.count ?? 0 > 0 && passwordTextField.text?.characters.count ?? 0 > 0
        
        if isFormValid {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = .mainBlue()
        } else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        }
    }
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.autocapitalizationType = UITextAutocapitalizationType.none
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    func updateUserLoggedInFlag() {
        // Update the NSUserDefaults flag
        let defaults = UserDefaults.standard
        defaults.set("loggedIn", forKey: "userLoggedIn")
        defaults.synchronize()
    }
    
    func saveApiTokenInKeychain(tokenString: String, idInt: Int) {
        // save API AuthToken in Keychain
        try! Locksmith.saveData(data: ["authenticationToken": tokenString], forUserAccount: "AuthToken")
        try! Locksmith.saveData(data: ["id": idInt], forUserAccount: "currentUserId")
        
        print("AuthToken recién guardado: \(Locksmith.loadDataForUserAccount(userAccount: "AuthToken")!)")
        print("currentUserId recién guardado: \(Locksmith.loadDataForUserAccount(userAccount: "currentUserId")!)")
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleSignUp() {
        guard let email = emailTextField.text, email.characters.count > 0 else { return }
        guard let username = usernameTextField.text, username.characters.count > 0 else { return }
        guard let password = passwordTextField.text, password.characters.count > 0 else { return }
        guard let fullname = fullnameTextField.text, fullname.characters.count > 0 else { return }
        
        let encrypted_password = AESCrypt.encrypt(password, password: HTTPHelper.API_AUTH_PASSWORD)
        
        let parameters = ["fullname": fullname, "username": username, "email": email, "password": encrypted_password!] as [String : Any]
        
        let url = "https://protected-anchorage-18127.herokuapp.com/api/users/signup"
        
        // Set BASIC authentication header
        let basicAuthString = "\(HTTPHelper.API_AUTH_NAME):\(HTTPHelper.API_AUTH_PASSWORD)"
        let utf8str = basicAuthString.data(using: String.Encoding.utf8)
        let base64EncodedString = utf8str?.base64EncodedString()
        
        let headers = ["Authorization": "Basic \(base64EncodedString)"]
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            if let imgData = self.imageData {
                multipartFormData.append(imgData, withName: "avatar", fileName: "avatar.jpg", mimeType: "image/png")
            }
            
            for (key, value) in parameters {
                multipartFormData.append(((value as Any) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
            }
            
        }, usingThreshold: UInt64.init() , to: url, method: .post, headers: headers, encodingCompletion: { encodingResult in
            
            switch encodingResult {
                case .success(let upload, _, _):
                    
                    self.updateUserLoggedInFlag()
//                    self.dismiss(animated: true, completion: nil)
                    print("THIS IS THE HEADER: \(headers)")
                    
                    upload.responseJSON { response in
                        print("request: \(response.request!)") // original URL request
                        print("response: \(response.response!)") // URL response
                        print("response data: \(response.data!)") // server data
                        print("result: \(response.result)") // result of response serialization
                        
                        if let JSON = response.result.value as? NSDictionary {
                            let userJSON = JSON["user"] as! NSDictionary
                            let authToken = userJSON["authenticationToken"] as! String
                            let userId = userJSON["id"] as! Int
                            print("userJSON: \(userJSON)")
                            print("JSON: \(JSON)")
                            self.saveApiTokenInKeychain(tokenString: authToken, idInt: userId)
                            print("authToken: \(authToken)")
                            print("userId: \(userId)")
                        }
                    }
                    
                case .failure(let encodingError):
                    print("Alamofire proccess failed", encodingError)
            }
        })
    }
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Already have an account?  ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.rgb(red: 17, green: 154, blue: 237)
            ]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleAlreadyHaveAccount), for: .touchUpInside)
        return button
    }()
    
    func handleAlreadyHaveAccount() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        view.backgroundColor = .white
        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.isUserInteractionEnabled = true
        plusPhotoButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 140, height: 140)
        
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePlusPhoto))
        plusPhotoButton.addGestureRecognizer(tap)
        
        setupInputFields()
        
        let dimisstap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(dimisstap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    fileprivate func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [fullnameTextField, usernameTextField, emailTextField, passwordTextField, signUpButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 200)
    }
    
}

