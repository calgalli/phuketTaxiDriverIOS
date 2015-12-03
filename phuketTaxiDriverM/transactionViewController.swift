//
//  transactionViewController.swift
//  phuketTaxiDriverM
//
//  Created by cake on 6/21/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class transactionViewController: UIViewController, UITextFieldDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate  {

    @IBOutlet weak var craditCardButton: UIButton!
    @IBOutlet weak var fareTextField: UITextField!
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.delegate.nationality == "Thai" || self.delegate.nationality == "Thailand" {
            craditCardButton.hidden = true
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cashAction(sender: AnyObject) {
        
        var data = Dictionary<String, String>()
        data["id"] = "id" + taxiId
        data["type"] = "done"
        data["message"] = fareTextField.text
        data["cash"] = "yes"
        // data["fare"] = fareTextField.text
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
        
        
        self.delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")

        

         allDone();
    }

    @IBAction func sendDataAction(sender: AnyObject) {
        
        //self.delegate.reuestedCustomer)
        
             

        var data = Dictionary<String, String>()
        data["id"] = "id" + taxiId
        data["type"] = "done"
        data["message"] = fareTextField.text
        data["cash"] = "no"
       // data["fare"] = fareTextField.text
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
        
        
        self.delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
        
        
        
        allDone();
   
    }
    
    func allDone(){
        
        delegate.mqttManager!.unsubscribeTopic(gCustomerResponseTopic+"/"+self.delegate.reuestedCustomer)
        var message1 : String
        
        let pubTopic : String = "taxiLocation/"+taxiId
        
        message1 = self.createLatLonJson(taxiId, lat: self.delegate.currentLat, lon: self.delegate.currentLon, aval: 1)
        
        
        self.delegate.mqttManager!.sendMessage(pubTopic, message: message1)
        
        
        
        self.delegate.requestedMessage.removeValueForKey(self.delegate.reuestedCustomer)
        
        
        
        
        self.delegate.reuestedCustomer = ""
        
        print(" ************************** All done *********************************")
        
        
    
    
    
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("viewControllerx") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()
        
        
    }

    
    //MARK: UITextField delegates
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
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

    
    func createLatLonJson(id : String, lat : Double, lon : Double, aval: Int) -> (String) {
        var jsonLoc : String = String(format: "{")
        
        jsonLoc += "\"id\":"
        jsonLoc += "\"id"
        jsonLoc += id
        jsonLoc += "\",\"lat\":"
        jsonLoc += String(format: "%f", lat)
        jsonLoc += ","
        jsonLoc += "\"lon\":"
        jsonLoc += String(format: "%f", lon)
        jsonLoc += ","
        jsonLoc += "\"aval\":"
        jsonLoc += String(format: "%d", aval)
        jsonLoc += "}"
        
        return jsonLoc
    }
    
    
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
