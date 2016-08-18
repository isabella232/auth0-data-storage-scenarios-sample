// ProfileViewController.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Lock
import AFNetworking
import Foundation

//MARK: - ProfileViewController

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    // MARK: - Properties
    
    let cellIdentifier = "CellIdentifier"
    var songs: [String]  = []
    
    // MARK: Outlets
    
    @IBOutlet var addSongButton: UIButton!
    @IBOutlet var inputSong: UITextField!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var favGenre: UILabel!
    @IBOutlet var songList: UITableView!
    
    // MARK: Overridden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getSongs()
        
        let keychain = MyApplication.sharedInstance.keychain
        let profileData:NSData! = keychain.dataForKey("profile")
        let profile:A0UserProfile = NSKeyedUnarchiver.unarchiveObjectWithData(profileData) as! A0UserProfile
        self.profileImage.setImageWithURL(profile.picture)
        
        let displayName = profile.userMetadata["displayName"]!
        
        self.welcomeLabel.text = "Welcome, \(displayName)!"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        getNameAndRole()
    }
    
}

// MARK: - Public Methods

extension ProfileViewController{
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = songs.count
        return numberOfRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        let song = songs[indexPath.row]
        cell.textLabel?.text = song
        return cell
    }
}

// MARK: - Private Methods

extension ProfileViewController{
    
    @IBAction private func addSong(sender: AnyObject) {
        
        if(self.inputSong.text == ""){
            showMessage("Please enter a song name")
        }
        else{
            let song = inputSong.text!
            let postString = "song=\(song)"
            let request = buildAPIPostRequest("/songs/add", postString: postString)
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {[unowned self](data, response,
                error) in
                
                if error != nil
                {
                    print("error=\(error)")
                    return
                }
                let addedSong = NSString(data: data!, encoding: NSUTF8StringEncoding)
                dispatch_async(dispatch_get_main_queue(), {
                    self.songs.append(addedSong! as String)
                    self.songList.beginUpdates()
                    self.songList.insertRowsAtIndexPaths([
                        NSIndexPath(forRow: self.songs.count-1, inSection: 0)
                        ], withRowAnimation: .Automatic)
                    self.songList.endUpdates()
                    self.songList.reloadData()
                    
                })
                
            }
            
            task.resume()
            
            self.inputSong.text = ""
        }
        
    }
    
    @IBAction private func getGenre(sender: AnyObject) {
        let request = buildAPIRequest("/genres/getFav")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {[unowned self](data, response, error) in
            let genre = NSString(data: data!, encoding: NSUTF8StringEncoding)
            dispatch_async(dispatch_get_main_queue(), {
                self.favGenre.text = "Favorite Genre:  \(genre!)"
            })
        }
        task.resume()
    }
    
    private func getNameAndRole(){
        let keychain = MyApplication.sharedInstance.keychain
        let profileData:NSData! = keychain.dataForKey("profile")
        let profile:A0UserProfile = NSKeyedUnarchiver.unarchiveObjectWithData(profileData) as! A0UserProfile
        
        let postString = "user_metadata"
        
        let request = buildAPIPostRequest("/displayName/get", postString: postString)
        
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {[unowned self](data, response,
            error) in
            if error != nil
            {
                print("error=\(error)")
                return
            }
            if let data_object = try? NSJSONSerialization.JSONObjectWithData(data!, options: [])
            {
                dispatch_async(dispatch_get_main_queue(), {
                    
                    let metadata = data_object.valueForKey("user_metadata")!
                    let currentName = metadata.valueForKey("displayName")!
                    let roles = profile.extraInfo["roles"]!
                    
                    if (roles.containsObject("playlist_editor") ){
                        self.welcomeLabel.text = "Welcome, Editor \(currentName)!"
                    }
                    else{
                        self.welcomeLabel.text = "Welcome, \(currentName)!"
                    }
                })
            }
            
        }
        
        task.resume()
    }
    
    private func getSongs(){
        let request = buildAPIRequest("/songs/get")
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
                    self.songs = songArray
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue(), {

                self.songList.beginUpdates()
                for i in 0 ..< self.songs.count{
                    self.songList.insertRowsAtIndexPaths([
                        NSIndexPath(forRow: i, inSection: 0)
                        ], withRowAnimation: .Automatic)
                }
                
                self.songList.endUpdates()                
            })
            
        }
        task.resume()
    }
    
    private func buildAPIRequest(path: String) -> NSURLRequest {
        let info = NSBundle.mainBundle().infoDictionary!
        let urlString = info["SampleAPIBaseURL"] as! String
        let request = NSMutableURLRequest(URL: NSURL(string: urlString + path)!)
        let keychain = MyApplication.sharedInstance.keychain
        let token = keychain.stringForKey("id_token")!
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func buildAPIPostRequest(path: String, postString: String) -> NSURLRequest {
        let info = NSBundle.mainBundle().infoDictionary!
        let urlString = info["SampleAPIBaseURL"] as! String
        let request = NSMutableURLRequest(URL: NSURL(string: urlString + path)!)
        request.HTTPMethod = "POST"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("text/html", forHTTPHeaderField: "Accept")
        let keychain = MyApplication.sharedInstance.keychain
        let token = keychain.stringForKey("id_token")!
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func showMessage(message: String) {
        let alert = UIAlertView(title: message, message: nil, delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
}