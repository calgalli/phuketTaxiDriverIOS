//
//  registerViewController.swift
//  phuketTaxiDriverM
//
//  Created by cake on 4/25/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class registerViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate, UITextFieldDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var chooseBtn: UIButton!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var idNumberTextField: UITextField!
    
    @IBOutlet weak var carModelTextField: UITextField!
    @IBOutlet weak var licensePlateNumberTextField: UITextField!
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var picker:UIImagePickerController?=UIImagePickerController()
    var popover:UIPopoverController?=nil
    
    var base64image : String = "";
    
    
    var firstName : String = ""
    var lastName : String = ""
    var email : String = ""
    var phoneNumber : String = ""
    var password : String = ""
    var idNumber : String = ""
    var carModel : String = ""
    var licensePlateNumber : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        registerButton.layer.cornerRadius = 30 //registerButton.layer.frame.height / 2
        registerButton.layer.borderColor = UIColor.whiteColor().CGColor
        registerButton.layer.borderWidth = 2
        registerButton.layer.backgroundColor = UIColor.clearColor().CGColor
        registerButton.layer.masksToBounds = true;
        
        cancelButton.layer.cornerRadius = 30 //loginButton.layer.frame.height / 2
        cancelButton.layer.borderColor = UIColor.whiteColor().CGColor
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.backgroundColor = UIColor.clearColor().CGColor
        cancelButton.layer.masksToBounds = true;

        
        picker?.delegate = self
        
        nameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        phoneNumberTextField.delegate = self
        passwordTextField.delegate = self
        idNumberTextField.delegate = self
        carModelTextField.delegate = self
        licensePlateNumberTextField.delegate = self
        
        self.addDoneButtonOnKeyboard()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("loginViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()
        
    }
    @IBAction func RegisterAction(sender: AnyObject) {
        
        
        var err: NSError?
        var allParams = Dictionary<String, String>()
        allParams["id"] = "id"+idNumber
        allParams["firstName"] = firstName
        allParams["lastname"] = lastName
        allParams["email"] = email
        allParams["phoneNumber"] = phoneNumber
        allParams["password"] = password
        allParams["idNumber"] = idNumberTextField.text
        allParams["carModel"] = carModel
        allParams["licensePlateNumber"] = licensePlateNumber
        
        if checkThaiID(idNumber) {
        
        
            let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/uploadDriverData");
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
                    return
                }
                
                // You can print out response object
                print("response = \(response)")
                
                // Print out response body
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("responseString = \(responseString)")
                
                dispatch_async(dispatch_get_main_queue()) { // 2
                    var cancelAlertView: UIAlertView = UIAlertView(title: "Thank you", message: "Thank you for being our member, we already sent the activation link email. After clicking at the link, the account will be active.", delegate: self, cancelButtonTitle: "OK");
                    cancelAlertView.show()
                }
                
                taxiId = self.idNumber
                prefs.setObject(taxiId, forKey: "taxiId")
                
            }
            
            task.resume()
            
            
            
            
            let myUrl = NSURL(string: "https://"+mainHost + ":1880/uploadImageDriver");
            let request = NSMutableURLRequest(URL:myUrl!);
            request.HTTPMethod = "POST";
            
            // Compose a query string
            
            
            var filename = idNumber+".png"
            
            
            var params = ["filename": filename, "data":base64image] as Dictionary<String, String>
            
            
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
            } catch var error as NSError {
                err = error
                request.HTTPBody = nil
            }
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            var configuration2 = NSURLSessionConfiguration.defaultSessionConfiguration()
            var session2 = NSURLSession(configuration: configuration2, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
            
            let task2 = session2.dataTaskWithRequest(request){
                data, response, error in
                
                if error != nil
                {
                    print("error=\(error)")
                    return
                }
                
                // You can print out response object
                print("response = \(response)")
                
                // Print out response body
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("responseString = \(responseString)")
                
                
            }
            
            task2.resume()
            
            
            
            /*let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            
            
            let vc = storyboard.instantiateViewControllerWithIdentifier("loginViewController") as! UIViewController
            
            self.delegate.window?.rootViewController = vc
            self.delegate.window?.makeKeyAndVisible()*/
            
        } else {
            dispatch_async(dispatch_get_main_queue()) { // 2
                var cancelAlertView: UIAlertView = UIAlertView(title: "เลขบัตรผิด", message: "เลขบัตรประชาชนผิด กรุณากรอกใหม่", delegate: nil, cancelButtonTitle: "OK");
                cancelAlertView.show()
            }
            
        }

    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("loginViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()
    }


    @IBAction func choosePhotoAction(sender: AnyObject) {
        
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone
        {
            self.presentViewController(picker!, animated: true, completion: nil)
        }
        else
        {
            popover=UIPopoverController(contentViewController: picker!)
            popover!.presentPopoverFromRect(chooseBtn.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }

    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        var imm: UIImage = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
        
        
        //imageView.image=info[UIImagePickerControllerOriginalImage] as? UIImage
        
        
        
        /* dispatch_async(dispatch_get_main_queue()) {
        self.imageView.image=imm
        }*/
        
        var scaledImage: UIImage = imm
        
        if(imm.size.width > 100){
            
            var fact  = 100.0/(imm.size.width)
            
            let size = CGSizeApplyAffineTransform(imm.size, CGAffineTransformMakeScale(fact, fact))
            let hasAlpha = false
            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
            
            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
            imm.drawInRect(CGRect(origin: CGPointZero, size: size))
            
            scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
        }
        
        var w = 150.0 as CGFloat;
        var h = 150.0*imm.size.height/imm.size.width as CGFloat
        
        imm.resize(CGSizeMake(w,h), completionHandler: { [weak self](resizedImage, data) -> () in
            
            let image = resizedImage
            var imagePngData = UIImagePNGRepresentation(image);
            
            self!.base64image = imagePngData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            
            
            })
        
        
        dispatch_async(dispatch_get_main_queue()) {
            self.imageView.image=scaledImage
        }
        
        
        
        let imageData = UIImageJPEGRepresentation(scaledImage, 1)
        let relativePath = "image_avatar.jpg"
        let path = self.documentsPathForFileName(relativePath)
        imageData!.writeToFile(path, atomically: true)
        NSUserDefaults.standardUserDefaults().setObject(relativePath, forKey: "path")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        
        //sets the selected image to image view
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        print("picker cancel.")
    }
    
    func documentsPathForFileName(name: String) -> String {
        
     
        let manager = NSFileManager.defaultManager()
        let URLs = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let fullPath = URLs[0].URLByAppendingPathComponent(name)

        /*let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true);
        let path = paths[0] ;
        //let fullPath = path.stringByAppendingPathComponent(name)
        let fullPath = path.URLByAppendingPathComponent(name)*/
        
        return fullPath.path!
    }
    
    //MARK: UITextField delegates
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        
        if textField == nameTextField {
            firstName = textField.text!
        } else if textField == lastNameTextField {
            lastName = textField.text!
        } else if textField == emailTextField {
            email = textField.text!
        } else if textField == phoneNumberTextField {
            phoneNumber = textField.text!
        } else if textField == passwordTextField {
            password = textField.text!
        }   else if textField == idNumberTextField {
            idNumber = textField.text!
        } else if textField == carModelTextField {
            carModel = textField.text!
        } else if textField == licensePlateNumberTextField{
            licensePlateNumber = textField.text!
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
    
    //MARK: Check thai ID
    func checkThaiID(id : String) -> Bool {
        var rt : Bool = true
        var i : Int
        var total : Int = 0
        if id.characters.count != 13 {
            rt = false
        } else {
            var revID = Array(id.characters.reverse())
            
            for(i = 1;i < 13;i++){
                let mul = i + 1
                total = total + Int(String(revID[i]))!*mul
            }
            let mod = total % 11
            let sub = 11 - mod
            let check_digit = sub % 10
            if check_digit == Int(String(revID[0])) {
                rt = true
            } else {
                rt = false
            }
        }
        
        return rt
    }
    // MARK: Add done button
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        doneToolbar.barStyle = UIBarStyle.Default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("doneButtonAction"))
        var items: [UIBarButtonItem]? = [UIBarButtonItem]()
        //let items = NSMutableArray()
        //items?.addObject(flexSpace)
        //items?.addObject(done)
        
        items?.append(flexSpace)
        items?.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        //self.textView.inputAccessoryView = doneToolbar
        self.phoneNumberTextField.inputAccessoryView = doneToolbar
        self.idNumberTextField.inputAccessoryView = doneToolbar
        
    }
    
    func doneButtonAction()
    {
        self.idNumberTextField.resignFirstResponder()
        self.phoneNumberTextField.resignFirstResponder()
        //self.textViewDescription.resignFirstResponder()
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


extension UIImage {
    public func resize(size:CGSize, completionHandler:(resizedImage:UIImage, data:NSData)->()) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let newSize:CGSize = size
            let rect = CGRectMake(0, 0, newSize.width, newSize.height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.drawInRect(rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let imageData = UIImageJPEGRepresentation(newImage, 0.5)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(resizedImage: newImage, data:imageData!)
            })
        })
    }
}
