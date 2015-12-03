//
//  loginViewController.swift
//  phuketTaxiDriverM
//
//  Created by cake on 6/11/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class loginViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, UITextFieldDelegate  {
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var signInButton: UIButton!

    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        registerButton.layer.cornerRadius = 30 //registerButton.layer.frame.height / 2
        registerButton.layer.borderColor = UIColor.whiteColor().CGColor
        registerButton.layer.borderWidth = 2
        registerButton.layer.backgroundColor = UIColor.clearColor().CGColor
        registerButton.layer.masksToBounds = true;
        
        signInButton.layer.cornerRadius = 30 //loginButton.layer.frame.height / 2
        signInButton.layer.borderColor = UIColor.whiteColor().CGColor
        signInButton.layer.borderWidth = 2
        signInButton.layer.backgroundColor = UIColor.clearColor().CGColor
        signInButton.layer.masksToBounds = true;
        
        
        emailTextField.attributedPlaceholder =
            NSAttributedString(string: "E-mail", attributes:[NSForegroundColorAttributeName : UIColor.grayColor()])
        passwordTextField.attributedPlaceholder =
            NSAttributedString(string: "Password", attributes:[NSForegroundColorAttributeName : UIColor.grayColor()])

        
        emailTextField.delegate = self
        passwordTextField.delegate = self

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signInAction(sender: AnyObject) {
        if emailTextField.text!.characters.count > 0 &&  passwordTextField.text!.characters.count > 0 {
            var email = emailTextField.text
            var password = passwordTextField.text
            
            let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/driverLogin");
            let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
            request1.HTTPMethod = "POST";
            let requestString = "email="+email!+"&" + "password="+password!
            let data = (requestString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            request1.HTTPBody =  data
            
            
            
            var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
            
            let task = session.dataTaskWithRequest(request1){
                data, response, error in
                
                if error != nil
                {
                    print("error=\(error)")
                    return
                }
                
                // You can print out response object
                print("response = \(response)")
                
                if let httpResponse = response as? NSHTTPURLResponse {
                   // if httpResponse.statusCode == 200 {
                        
                        
                        
                        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        print("******************************** Response from Server **********************")
                        // You can print out response object
                        //println("response = \(response)")
                        print("responseString = \(responseString)")
                        
                        let json = JSON(data: data!)
                        
                        if(json.count > 0){
                            taxiId = json[0]["idNumber"].string!
                            prefs.setObject(taxiId, forKey: "taxiId")
                            
                           // self.delegate.mqtt.start("id"+taxiId)
                            
                            //self.delegate.startMqtt("id"+taxiId)
                            //self.delegate.startMqtt("id"+taxiId)
                            
                            print(taxiId)
                            self.delegate.requestTopic = "cli/" + "id"+taxiId
                            self.delegate.removeCustomer = "removeContomer/" + "id"+taxiId
                            self.delegate.pongTopic = "pong/"+"id"+taxiId
                            
                            //self.delegate.initMQTT()
                            //self.delegate.startMqtt("id"+taxiId)
                            //self.delegate.startTimer()
                            
                            self.delegate.ccFlag = true
                            NSNotificationCenter.defaultCenter().postNotificationName(mqttConnectedNotificationKey, object: self)
                            
                            print("Did login =============================== true ===")
                            didLogin = true
                            
                            
                            prefs.setObject(email, forKey: "username")
                            prefs.setObject(password, forKey: "password")
                            prefs.setObject("yes", forKey: "haveLogin")

                            
                           // self.delegate.imageID = json[0]["id"].string!
                            
                            var url = "http://" + mainHost + pathToImage + taxiId + ".png"
                            print(url)
                            
                            if let checkedUrl = NSURL(string: url) {
                                self.downloadImage(checkedUrl)
                            }
                            
                            print(url)

                            //Goto page after finish loading image
                            
                            
                            
                        } else {
                            dispatch_async(dispatch_get_main_queue()) { // 2
                                var cancelAlertView: UIAlertView = UIAlertView(title: "Login fail", message: "Invalid login.", delegate: self, cancelButtonTitle: "OK");
                                cancelAlertView.show()
                            }
                        }
                        
                        
     
                        
                        
                 /*   } else {
                        dispatch_async(dispatch_get_main_queue()) { // 2
                            var cancelAlertView: UIAlertView = UIAlertView(title: "Login fail", message: "Invalid login.", delegate: self, cancelButtonTitle: "OK");
                            cancelAlertView.show()
                        }
                    }*/
                    
                    
                }
                
                
                
                // Print out response body
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("responseString = \(responseString)")
                
                
                
                
            }
        
            task.resume()

        } else {
            dispatch_async(dispatch_get_main_queue()) { // 2
                var cancelAlertView: UIAlertView = UIAlertView(title: "Login fail", message: "Incomplete data.", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.show()
            }
        }
        
        
    
    }

    @IBAction func registerAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("registerViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()
        
    }
    
    @IBAction func forgotPasswordAction(sender: AnyObject) {
        let email = emailTextField.text
        var password = passwordTextField.text
        
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/driverForgetPassword");
        let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
        request1.HTTPMethod = "POST";
        let requestString = "email="+email!
        let data = (requestString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        request1.HTTPBody =  data
        
        
        
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
        let task = session.dataTaskWithRequest(request1){
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            // You can print out response object
            print("response = \(response)")
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    
                    dispatch_async(dispatch_get_main_queue()) { // 2
                        var cancelAlertView: UIAlertView = UIAlertView(title: "OK", message: "ส่ง password ไปที่ e-mail แล้ว", delegate: self, cancelButtonTitle: "OK");
                        cancelAlertView.show()
                    }
                    
                } else {
                    dispatch_async(dispatch_get_main_queue()) { // 2
                        var cancelAlertView: UIAlertView = UIAlertView(title: "Wrong e-mail", message: "Invalid e-mail address", delegate: self, cancelButtonTitle: "OK");
                        cancelAlertView.show()
                    }
                }
                
                
            }
            
            
            
            // Print out response body
           // let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
           // println("responseString = \(responseString)")
            
            
            
            
        }
        
        task.resume()
        

        
    }
    
    //MARK: Download image
    
    func getDataFromUrl(urL:NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(urL) { (data, response, error) in
            completion(data: data)
            }.resume()
    }
    
    func downloadImage(url:NSURL){
        //print("Started downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
        getDataFromUrl(url) { data in
            dispatch_async(dispatch_get_main_queue()) {
               // print("Finished downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
                self.delegate.userImage = UIImage(data: data!)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("viewControllerx") 
                
                self.delegate.window?.rootViewController = vc
                self.delegate.window?.makeKeyAndVisible()

            }
        }
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

    //MARK: UITextField delegates
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
