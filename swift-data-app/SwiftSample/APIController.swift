//
//  APIController.swift
//  SwiftSample
//
//  Created by Elias Harkins on 8/9/16.
//  Copyright © 2016 Auth0. All rights reserved.
//

import Foundation
import UIKit
import Lock
import AFNetworking

protocol APIControllerProtocol {
    func didReceiveAPIResults(results: NSArray)
}

class APIController{
    var results = [String: AnyObject]()
    var delegate: APIControllerProtocol?
    
    func getNameAndRole(){
        let keychain = MyApplication.sharedInstance.keychain
        let profileData:NSData! = keychain.dataForKey("profile")
        let profile:A0UserProfile = NSKeyedUnarchiver.unarchiveObjectWithData(profileData) as! A0UserProfile
        
        let info = NSBundle.mainBundle().infoDictionary!
        let urlString = info["SampleAPIBaseURL"] as! String
        let url = NSURL(string: urlString + "/displayName/get")!
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        
        let postString = "user_metadata"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let token = keychain.stringForKey("id_token")!
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("text/html", forHTTPHeaderField: "Accept")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {[unowned self](data, response,
            error) in
            if error != nil
            {
                print("error=\(error)")
                return
            }
            if let data_object = try? NSJSONSerialization.JSONObjectWithData(data!, options: [])
            {
                let metadata = data_object.valueForKey("user_metadata")!
                let currentName = metadata.valueForKey("displayName")!
                let roles = profile.extraInfo["roles"]!
                self.results["roles"] = roles
                self.results["currentName"] = currentName
//                dispatch_async(dispatch_get_main_queue(), {
//                    
//                    let metadata = data_object.valueForKey("user_metadata")!
//                    let currentName = metadata.valueForKey("displayName")!
//                    let roles = profile.extraInfo["roles"]!
//                    
//                    if (roles.containsObject("playlist_editor") ){
//                        results. = "Welcome, Editor \(currentName)!"
//                    }
//                    else{
//                        self.welcomeLabel.text = "Welcome, \(currentName)!"
//                    }
//                })
            }
            
        }
        
        task.resume()
    }
    
    
    
    func getSongs(){
        let request = buildAPIRequest("/songs/get", type: "GET")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {[unowned self](data, response,
            error) in
            if error != nil
            {
                print("error=\(error)")
                return
            }
            var songArray : [String]
            
            do {
                if let allSongs = try NSJSONSerialization.JSONObjectWithData(data! , options: []) as? NSDictionary{
                    songArray = allSongs.objectForKey("Songs") as! [String]
                    self.results["songs"] = songArray
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            
//            dispatch_async(dispatch_get_main_queue(), {
//                
//                self.songList.beginUpdates()
//                for i in 0 ..< self.songs.count{
//                    self.songList.insertRowsAtIndexPaths([
//                        NSIndexPath(forRow: i, inSection: 0)
//                        ], withRowAnimation: .Automatic)
//                }
//                
//                self.songList.endUpdates()
//                self.songList.reloadData()
//                
//            })
            
        }
        task.resume()
    }
    
    
    
    func buildAPIRequest(path: String, type: String) -> NSURLRequest {
        let info = NSBundle.mainBundle().infoDictionary!
        let urlString = info["SampleAPIBaseURL"] as! String
        let request = NSMutableURLRequest(URL: NSURL(string: urlString + path)!)
        if (type == "POST")
        {
            let song = inputSong.text
            request.HTTPMethod = "POST"
            let postString = "song=\(song!)"
            
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.addValue("text/html", forHTTPHeaderField: "Accept")
        }
        
        
        let keychain = MyApplication.sharedInstance.keychain
        let token = keychain.stringForKey("id_token")!
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
}