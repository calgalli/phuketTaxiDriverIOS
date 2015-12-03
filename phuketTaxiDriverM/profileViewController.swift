//
//  profileViewController.swift
//  phuketTaxiDriverM
//
//  Created by cake on 8/12/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class profileViewController: UIViewController,  NSURLSessionTaskDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    struct transactionDetail {
        var custommerName : String = String()
        var date : String = String()
        var time : String = String()
        var fare : String = String()
    }
    
    var transDetails = Dictionary<String, transactionDetail>()
    var tableData = [transactionDetail]()
    var tt : transactionDetail = transactionDetail()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoutButton.layer.cornerRadius = logoutButton.layer.frame.height / 2
        backButton.layer.cornerRadius = backButton.layer.frame.height / 2
        
        var err: NSError?
        
        var allParams = Dictionary<String, String>()
        
        allParams["idNumber"] = "id"+taxiId
        
        
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/getTaxiTransactions");
        let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
        request1.HTTPMethod = "POST";
        
        do {
            request1.HTTPBody = try NSJSONSerialization.dataWithJSONObject(allParams, options: [])
        } catch var error as NSError {
            err = error
            request1.HTTPBody = nil
        }
        request1.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request1.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
        let task = session.dataTaskWithRequest(request1){
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                
            }
            
            // You can print out response object
            //println("response = \(response)")
            
            if let httpResponse = response as? NSHTTPURLResponse {
                //if httpResponse.statusCode == 200 {
                
                
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                // println("******************************** Response from Server **********************")
                // You can print out response object
                //println("response = \(response)")
                // println("responseString = \(responseString)")
                
                let json = JSON(data: data!)
                
                //self.delegate.userData = json
                
                if(json.count > 0){
                    var i : Int = 0
                    for (i = 0; i < json.count; i++) {
                        
                        
                        
                        self.tt.date = json[i]["date"].string!
                        self.tt.time = json[i]["time"].string!
                        self.tt.fare = json[i]["fare"].string!
                        
                        var userId : String = json[i]["customerID"].string!
                        
                        var key : String = self.randomStringWithLength(10) as String
                        self.transDetails[key] = self.tt
                        
                        let sliced = userId.substringFromIndex(userId.startIndex.advancedBy(2))
                        print("******* \(sliced)")
                        
                        self.getTaxiCustommerInfo(sliced, key: key)
                        
                        /* var cc : String = json[i]["company"].string!
                        var type : String = json[i]["type"].string!
                        var status : String = json[i]["status"].string!
                        var price : String = json[i]["price"].string!
                        println("\(cc) \(type) \(status) \(price)");
                        
                        
                        var x : statusDetail = statusDetail(company: cc, type: type, status: status, price: price)
                        
                        self.statuses.append(x)*/
                    }
                    
                    //self.tableView.reloadData()
                    // self.delegate.userID = json[0]["passportID"].string!
                    // self.tableView.reloadData()
                    
                } else {
                    
                }
            }
        }
        
        
        
        
        
        
        task.resume()
        
        


        // Do any additional setup after loading the view.
    }

    
    func getTaxiCustommerInfo(taxiID: String, key:String){
        
        var err: NSError?
        
        var allParams = Dictionary<String, String>()
        
        allParams["passportID"] = taxiID
        
        
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/getCustommerData");
        let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
        request1.HTTPMethod = "POST";
        
        do {
            request1.HTTPBody = try NSJSONSerialization.dataWithJSONObject(allParams, options: [])
        } catch var error as NSError {
            err = error
            request1.HTTPBody = nil
        }
        request1.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request1.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
        let task = session.dataTaskWithRequest(request1){
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                
            }
            
            // You can print out response object
            // println("response = \(response)")
            
            if let httpResponse = response as? NSHTTPURLResponse {
                //if httpResponse.statusCode == 200 {
                
                
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                //println("******************************** Response from Server **********************")
                // You can print out response object
                //println("response = \(response)")
               //  println("responseString = \(responseString)")
                
                let json = JSON(data: data!)
                
                //self.delegate.userData = json
                
                if(json.count > 0){
                    
                    self.transDetails[key]?.custommerName = json[0]["name"].string!
                    
               /*     self.transDetails[key]?.driverName = json[0]["firstName"].string! + " " + json[0]["lastname"].string!
                    self.transDetails[key]?.licensePlate = json[0]["licensePlanateNumber"].string!
                    */
                   // print(self.transDetails[key]?.driverName)
                    print(self.transDetails[key]?.custommerName, terminator: "")
                    print(self.transDetails[key]?.date, terminator: "")
                    print(self.transDetails[key]?.time, terminator: "")
                    print(self.transDetails[key]?.fare) 
                    
                    self.tableData.append(self.transDetails[key]!)
                    
                    self.tableView.reloadData()
                    
                } else {
                    
                }
            }
        }
        
        
        
        
        
        
        task.resume()
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backAction(sender: AnyObject) {
        performSegueWithIdentifier("profileToView", sender: nil)
    }

    //MARK: Table View handles
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableData.count
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("custommerItem", forIndexPath: indexPath) 
        
        let dd = tableData[indexPath.row]
        cell.textLabel!.text = "Name : " + dd.custommerName
        cell.detailTextLabel!.text = dd.date + " : " + dd.time + " Fare : " + dd.fare + " Bath"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    
    @IBAction func logoutAction(sender: AnyObject) {
        
        self.delegate.removeFromManager()
        
        NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
        
        
        self.delegate.mqttManager?.removeObserver(self.delegate, forKeyPath: "state")
        
        
        self.delegate.mqttManager?.disconnect()
        prefs.setObject("no", forKey: "haveLogin")
        performSegueWithIdentifier("profileToLogin", sender: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: URL session delegate
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler:(NSURLSessionAuthChallengeDisposition,
        NSURLCredential?) -> Void) {
            completionHandler(
                NSURLSessionAuthChallengeDisposition.UseCredential,
                NSURLCredential(forTrust:
                    challenge.protectionSpace.serverTrust!))
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        let newRequest : NSURLRequest? = request
        print(newRequest?.description);
        completionHandler(newRequest)
    }
    //Progress bar
    func URLSession(session: NSURLSession,
        task: NSURLSessionTask,
        bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64){
            
            
    }
    
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }



}
