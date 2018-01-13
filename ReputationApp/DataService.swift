//
//  DataService.swift
//  ReputationApp
//
//  Created by Omar Torres on 25/05/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import Foundation
import Photos
import Alamofire

class DataService {
    
    static let instance = DataService()
    
    func savePhoto(image: UIImage, view: UIView) {
        let library = PHPhotoLibrary.shared()
        
        library.performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (success, err) in
            if let err = err {
                print("Failed to save image to photo library: ", err)
            }
            print("Successfully saved image to library")
            
            DispatchQueue.main.async {
                let savedLabel = UILabel()
                savedLabel.text = "Se guardó!"
                savedLabel.font = UIFont.boldSystemFont(ofSize: 18)
                savedLabel.textColor = .white
                savedLabel.numberOfLines = 0
                savedLabel.backgroundColor = UIColor(white: 0, alpha: 0.3)
                savedLabel.textAlignment = .center
                
                savedLabel.frame = CGRect(x: 0, y: 0, width: 150, height: 80)
                savedLabel.center = view.center
                
                view.addSubview(savedLabel)
                
                savedLabel.layer.transform = CATransform3DMakeScale(0, 0, 0)
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    
                    savedLabel.layer.transform = CATransform3DMakeScale(1, 1, 1)
                    
                }, completion: { (completed) in
                    
                    UIView.animate(withDuration: 0.5, delay: 0.75, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                        
                        savedLabel.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1)
                        savedLabel.alpha = 0
                        
                    }, completion: { (_) in
                        
                        savedLabel.removeFromSuperview()
                        
                    })
                    
                })
            }
        }
    }
    
    func saveVideo(url: URL, view: UIView) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { (success, err) in
            if let err = err {
                print("Failed to save video to library: ", err)
            }
            print("Successfully saved video to library")
            
            DispatchQueue.main.async {
                let savedLabel = UILabel()
                savedLabel.text = "Se guardó!"
                savedLabel.font = UIFont.boldSystemFont(ofSize: 18)
                savedLabel.textColor = .white
                savedLabel.numberOfLines = 0
                savedLabel.backgroundColor = UIColor(white: 0, alpha: 0.3)
                savedLabel.textAlignment = .center
                
                savedLabel.frame = CGRect(x: 0, y: 0, width: 150, height: 80)
                savedLabel.center = view.center
                
                view.addSubview(savedLabel)
                
                savedLabel.layer.transform = CATransform3DMakeScale(0, 0, 0)
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    
                    savedLabel.layer.transform = CATransform3DMakeScale(1, 1, 1)
                    
                }, completion: { (completed) in
                    
                    UIView.animate(withDuration: 0.5, delay: 0.75, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                        
                        savedLabel.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1)
                        savedLabel.alpha = 0
                        
                    }, completion: { (_) in
                        
                        savedLabel.removeFromSuperview()
                        
                    })
                    
                })
            }
        }
    }
    
    func shareVideo(authToken: String, videoCaption: UITextView, videoUrl: URL, duration: String, completion: @escaping (Bool) -> ()) {
        guard let caption = videoCaption.text else { return }
        
        // Set Authorization header
        let header = ["Authorization": "Token token=\(authToken)"]
        
        let parameters = ["description": caption, "duration": duration] as [String : Any]
        
        let url = URL(string: "https://protected-anchorage-18127.herokuapp.com/api/writeEvent")!
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            multipartFormData.append(videoUrl, withName: "video", fileName: ".mp4", mimeType: "video/mp4")
            
            for (key, value) in parameters {
                multipartFormData.append(((value as Any) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
            }
            
        }, usingThreshold: UInt64.init() , to: url, method: .post, headers: header, encodingCompletion: { encodingResult in
            
            switch encodingResult {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in
                    print("request: \(response.request!)") // original URL request
                    print("response: \(response.response!)") // URL response
                    print("response data: \(response.data!)") // server data
                    print("result: \(response.result)") // result of response serialization
                    
                    if let JSON = response.result.value {
                        print("JSON: \(JSON)")
                        print("send video successfully")
                        completion(true)
                    }
                }
                
            case .failure(let encodingError):
                print("Alamofire proccess failed", encodingError)
                completion(false)
            }
        })
    }
    
}
