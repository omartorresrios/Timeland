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
import GoogleSignIn
import Google

class LoginController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    let googleButton = GIDSignInButton()
    var imageData: Data?

    func updateUserLoggedInFlag() {
        // Update the NSUserDefaults flag
        let defaults = UserDefaults.standard
        defaults.set("loggedIn", forKey: "userLoggedIn")
        defaults.synchronize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        var error: NSError?
        
        GGLContext.sharedInstance().configureWithError(&error)
        
        if error != nil {
            print(error ?? "some error")
            return
        }
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        view.addSubview(googleButton)
        googleButton.center = view.center
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
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print("Some error while configuring Google login: ", error)
            return
        }
        
        print("user id: ", GIDSignIn.sharedInstance().currentUser.userID)
        print("user name: ", user.profile.name)
        print("user email: ", user.profile.email)
        print("user profile image: ", user.profile.imageURL(withDimension: 400))
        
        guard let google_id = GIDSignIn.sharedInstance().currentUser.userID else { return }
        guard let fullname = user.profile.name else { return }
        guard let email = user.profile.email else { return }
        guard let avatar = user.profile.imageURL(withDimension: 400) else { return }
        
        if let data = try? Data(contentsOf: avatar) {
            self.imageData = data
        }
        
        let parameters = ["google_id": google_id, "fullname": fullname, "email": email] as [String : Any]
        
        let url = URL(string: "https://protected-anchorage-18127.herokuapp.com/api/users/google/login")!
        
        // Set BASIC authentication header
        let basicAuthString = "\(HTTPHelper.API_AUTH_NAME):\(HTTPHelper.API_AUTH_PASSWORD)"
        let utf8str = basicAuthString.data(using: String.Encoding.utf8)
        let base64EncodedString = utf8str?.base64EncodedString()
        
        let headers = ["Authorization": "Basic \(String(describing: base64EncodedString))"]
        
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
    
}
