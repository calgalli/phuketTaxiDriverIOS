//
//  ChatViewController.swift
//  phuketTaxiDriverM
//
//  Created by cake on 5/20/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class ChatViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, UIWebViewDelegate, MKMapViewDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate {
    
    let _queue = dispatch_queue_create("SwiftChat Background Queue", DISPATCH_QUEUE_CONCURRENT)
    
    struct chatMessage {
        var type : String = String()
        var message : String = String()
    }
    
    var chatMessages = [chatMessage]()
    
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var pickUpButton: UIButton!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var myWebView: UIWebView!
    @IBOutlet weak var chatBoxViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var chatViewMap: MKMapView!
    var kbHeight: CGFloat!
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var locationManager: CLLocationManager?
    
    var fireOnce: Bool = true
    var customerCanel = false
    var isPickUp : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        finishButton.setTitle("Cancel", forState: UIControlState.Normal)
        pickUpButton.layer.cornerRadius = pickUpButton.layer.frame.height/2
        
        self.messageTextField.delegate = self
        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager?.delegate  = self;
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        
        //update when the different distance is greater than 100 meters
        locationManager?.distanceFilter = gUpdateDistance;
        
        if CLLocationManager.locationServicesEnabled() {
            if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("8") == true){
                
                if (locationManager?.respondsToSelector("requestAlwaysAuthorization") != nil) {
                    if #available(iOS 8.0, *) {
                        locationManager?.requestAlwaysAuthorization()
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
        }
        
        locationManager?.startUpdatingLocation()

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnCustumerResponse", name: customerResponseNotificationKey, object: nil)
        
        
        var htmlString:String! = ""
        
        
        let testHTML = NSBundle.mainBundle().pathForResource("base", ofType: "html")
        let contents = try? NSString(contentsOfFile: testHTML!, encoding: NSUTF8StringEncoding)
        let baseUrl = NSURL(fileURLWithPath: testHTML!) //for load css file
        
        htmlString = contents as! String + "<body><div class=\"commentArea\">"
        
        
        htmlString = htmlString + "</div></body>"
      
        myWebView.loadHTMLString(htmlString as String, baseURL: baseUrl)
        
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func actOnCustumerResponse(){
        
        let jsonObject : AnyObject! = try? NSJSONSerialization.JSONObjectWithData(self.delegate.custommerMessage.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers)
        
        
        let data  = JSON(jsonObject)
        
        
        
        if(data["type"] == "chat"){
            print("************ Message =", terminator: "")
            print(data["message"])
            let mm = data["message"].string!
            print(data["message"])
            chatMessages.append(chatMessage(type: "in", message: mm))
            dispatch_async(dispatch_get_main_queue()) {
               self.displayChatMessage()
            }

            
            
        } else if(data["type"] == "costumerLocation"){
            print("******************************* 888888 ********************************")
            print(data["lat"])
            print(data["lon"])
            
            let clocation = CLLocationCoordinate2D(
                latitude: data["lat"].doubleValue,
                longitude: data["lon"].doubleValue
            )
            
            self.delegate.acceptedCustomerLocation = clocation
            updateETA(self.delegate.myCurrentLocation, to: self.delegate.acceptedCustomerLocation)
            
            dispatch_async(dispatch_get_main_queue()) { // 2
                
                
                var annotationList:Array<MKPointAnnotation> = []
                
                print("Notify from messageing")
                
                self.chatViewMap.removeAnnotations(self.chatViewMap.annotations)
                
                self.chatViewMap.showsUserLocation = true
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = clocation
          
                
                self.chatViewMap.addAnnotation(annotation)
            }
            
            
        } else if(data["type"] == "cancel"){
            print("Custommer cancel")
         
            dispatch_async(dispatch_get_main_queue()) { // 2
                let cancelAlertView: UIAlertView = UIAlertView(title: "Customer canel", message: "ลูกต้ายกเลิก แต่ท่านจะได้รับค่าชดเชย", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.show()
            }
            
            
        }

        
        
        
    }

    
    func alertView(View: UIAlertView, clickedButtonAtIndex buttonIndex: Int){
        
        switch buttonIndex{
            
        case 0:
            customerCanel = true
            allDone()
            
            break;
        default:
  
            break;
            //Some code here..
            
        }
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize =  (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                kbHeight = keyboardSize.height
                print("Keyboard height = \(self.kbHeight)")
                self.animateTextField(true)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.animateTextField(false)
        UIView.animateWithDuration(0.5, animations: {
            self.chatBoxViewHeight.constant = 40
        })
    }
    
    func animateTextField(up: Bool) {
       // var movement = (up ? -kbHeight : kbHeight)
        
        UIView.animateWithDuration(0.3, animations: {
            //self.chatBoxViewHeight.constant = self.kbHeight + 40
            self.chatBoxViewHeight.constant = self.kbHeight + 40
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pickUpAction(sender: UIButton) {
        isPickUp = true
        
        finishButton.setTitle("Finish", forState: UIControlState.Normal)
        
        var data = Dictionary<String, String>()
        data["id"] = "id" + taxiId
        data["type"] = "picup"
        data["message"] = "yes"
        // data["fare"] = fareTextField.text
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
        
        
        self.delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
        
        pickUpButton.hidden = true
        pickUpButton.userInteractionEnabled = false

    }
    
    
    @IBAction func backAction(sender: AnyObject) {
              
        if isPickUp == true {
        
            dispatch_async(dispatch_get_main_queue()) {
                self.chatViewMap.removeAnnotations(self.chatViewMap.annotations)
            
            }
        
            self.delegate.acceptedCustomerLocation = CLLocationCoordinate2D(
                latitude: 0,
                longitude: 0)

        
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("transactionViewController") 
        
            self.delegate.window?.rootViewController = vc
            self.delegate.window?.makeKeyAndVisible()
        } else {
           
            
            
            var data = Dictionary<String, String>()
            data["id"] = "id" + taxiId
            data["type"] = "onthewayCancel"
            data["message"] = "yes"
            // data["fare"] = fareTextField.text
            let jsonObj = JSON(data)
            
            print(jsonObj)
            
            let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
            
            
            self.delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")


            dispatch_async(dispatch_get_main_queue()) {
                self.chatViewMap.removeAnnotations(self.chatViewMap.annotations)
                
            }
            
            self.delegate.acceptedCustomerLocation = CLLocationCoordinate2D(
                latitude: 0,
                longitude: 0)
            
            
            performSegueWithIdentifier("chatToViewcontroller", sender: nil)
            
  

            
        }
        
        //allDone()
        
   
    }
    
    
    func allDone(){
        
        //delegate.mqtt.mqttInstance.unsubscribe(gCustomerResponseTopic+"/"+self.delegate.reuestedCustomer, withCompletionHandler: nil)
        
        delegate.mqttManager!.unsubscribeTopic(gCustomerResponseTopic+"/"+self.delegate.reuestedCustomer)
        // Set status back to avaliable
        var message1 : String
        
        let pubTopic : String = "taxiLocation/"+taxiId
        
        message1 = self.createLatLonJson(taxiId, lat: self.delegate.currentLat, lon: self.delegate.currentLon, aval: 1)
        
        
        self.delegate.mqttManager!.sendMessage(pubTopic, message: message1)
        
        
        dispatch_async(dispatch_get_main_queue()) {
            self.chatViewMap.removeAnnotations(self.chatViewMap.annotations)
            
        }
        
        self.delegate.requestedMessage.removeValueForKey(self.delegate.reuestedCustomer)
        
        
        
        self.delegate.acceptedCustomerLocation = CLLocationCoordinate2D(
            latitude: 0,
            longitude: 0)
        
        
        self.delegate.reuestedCustomer = ""
        
        print(" ************************** All done *********************************")

        
    
        
        if customerCanel == true {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("viewControllerx") 
            
            self.delegate.window?.rootViewController = vc
            self.delegate.window?.makeKeyAndVisible()
            customerCanel = false
            
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("transactionViewController") 
        
            self.delegate.window?.rootViewController = vc
            self.delegate.window?.makeKeyAndVisible()
        }
 
    }
    
    @IBAction func sendAction(sender: AnyObject) {
        self.messageTextField.endEditing(true)
           
        
        
        if(self.messageTextField.text!.isEmpty == false){
           
            var data = Dictionary<String, String>()
            data["id"] = "id" + taxiId
            data["type"] = "chat"
            data["message"] = messageTextField.text
            var jsonObj = JSON(data)
            
            print(jsonObj)
            
            let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
            self.chatMessages.append(chatMessage(type: "out", message: self.messageTextField.text!))
            
            
            self.delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
          
            
            dispatch_async(dispatch_get_main_queue()) {
               
                self.displayChatMessage()
                self.messageTextField.text = ""
                
            }

            
            
        }

        
    }
    
    // MARK: Text Field delegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
    
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.5, animations: {
            self.chatBoxViewHeight.constant = 40
            self.view.layoutIfNeeded()
            }, completion: nil)
        
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }

     // MARK: - Handle location update
    //**************************************  Handle location update *********************************************
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //manager.stopUpdatingLocation()
        let location = locations[0] 
        //let geoCoder = CLGeocoder()
        
        let coorString = String(format: "%f:%f", location.coordinate.latitude, location.coordinate.longitude)
        
        let pubTopic : String = "taxiLocation/"+taxiId
        
        var message1 : String
        
        delegate.currentLat = location.coordinate.latitude
        delegate.currentLon = location.coordinate.longitude
        
        
        let clocation = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        
        self.delegate.myCurrentLocation = clocation
        
        // ====================== update location to a requested customer =======================
        
        var data = Dictionary<String, String>()
        data["id"] = "id" + taxiId
        data["type"] = "locationUpdate"
        data["lat"] = String(format: "%f", self.delegate.myCurrentLocation.latitude)
        data["lon"] = String(format: "%f", self.delegate.myCurrentLocation.longitude)
        
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
        
        delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
        
   
        updateETA(self.delegate.myCurrentLocation, to: self.delegate.acceptedCustomerLocation)
        
        if UIApplication.sharedApplication().applicationState == .Active {
            chatViewMap.showsUserLocation = true
            
            
            if(fireOnce == false) {
                let region = self.chatViewMap.region;
                // Update the center
                //region.center = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
                // apply the new region
                self.chatViewMap.region = region;
                
            } else {
                fireOnce = false
                let rgn : MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), 10000, 10000);
                
                self.chatViewMap.region = rgn;
                //mapView.setRegion(rgn, animated: true)
                
                
            }

            
            
            
        } else {
            NSLog("App is backgrounded. New location is %@", location)
        }
        
        
        
        
        
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


    
    func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(version: NSString) -> Bool {
        return UIDevice.currentDevice().systemVersion.compare(version as String,
            options: NSStringCompareOptions.NumericSearch) != NSComparisonResult.OrderedAscending
    }
    
    
    //MARK: Update ETA and distance
    func updateETA(from : CLLocationCoordinate2D, to: CLLocationCoordinate2D){
        var taxiLat = from.latitude
        var taxiLon = from.longitude
        var fLat = to.latitude
        var fLon = to.longitude
        
        var urlString = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(taxiLat),\(taxiLon)&destinations=\(fLat),\(fLon)&mode=driving&key=\(googleWebAPIkey)"
        
        
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        print(urlString)
        
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        var ETA = ""
        var dd = ""
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var placesTask = session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
            print("inside.")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            let json = JSON(data: data!)
            if json["rows"].count > 0 {
                if json["rows"][0]["elements"].count > 0 {
                    if json["rows"][0]["elements"][0]["duration"] != nil {
                        ETA = json["rows"][0]["elements"][0]["duration"]["text"].string!
                        dd = json["rows"][0]["elements"][0]["distance"]["text"].string!
                    
                    
                    
                    
                    
                    
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.distance.text = "Distance : " + dd + ",  ETA : " + ETA
                        
                    }
                    }
                    
                    
                }
            }
            
            /*if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? NSDictionary {
            println(json["rows"])
            }*/
            
        }
        
        placesTask.resume()
        
        
    }
    
    // MARK: Displat chat messages in web view
    
    func displayChatMessage(){
        var htmlString:String! = ""
        
        
        let testHTML = NSBundle.mainBundle().pathForResource("base", ofType: "html")
        let contents = try? NSString(contentsOfFile: testHTML!, encoding: NSUTF8StringEncoding)
        let baseUrl = NSURL(fileURLWithPath: testHTML!) //for load css file
        
        htmlString = contents as! String + "<body><div class=\"commentArea\">"
        for x in chatMessages{
            if x.type == "in" {
                
                
                htmlString = htmlString + "<div class=\"bubbledLeft\">"
                htmlString = htmlString + x.message
                htmlString = htmlString + "</div>"
                
                
            } else {
                
                htmlString = htmlString + "<div class=\"bubbledRight\">"
                htmlString = htmlString + x.message
                htmlString = htmlString + "</div>"
            }
        }
        
        
        
        htmlString = htmlString + "</div></body>"
        let xhtmlString = NSString(format: "<span style=\"font-family: %@; font-size: %i\">%@</span>",
            "Helvetica Neue",
            20,
            htmlString)
        
        print(htmlString)
        
        
        
        
        
        myWebView.loadHTMLString(xhtmlString as String, baseURL: baseUrl)

        
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let bottomOffset = CGPointMake(0, self.myWebView.scrollView.contentSize.height - self.myWebView.scrollView.bounds.size.height)
        self.myWebView.scrollView.setContentOffset(bottomOffset, animated: false)
        
        
    }

    
    //MARK: Mapview delegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
        
        
        //if !(annotation is CustomPointAnnotation) {
        //    return nil
        //}
        
        print("Map view delegate is called ***************************")
        
        
        //if !(annotation is MKPointAnnotation){
        //    return nil
        //}
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            let reuseId = "test"
            
            var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            if anView == nil {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                //anView.canShowCallout = true
                anView!.image = UIImage(named:"taxiIcon.png")
            }
            else {
                anView!.annotation = annotation
            }
            
            //Set annotation-specific properties **AFTER**
            //the view is dequeued or created...
            
            //let cpa = annotation as! CustomPointAnnotation
            //anView.image = UIImage(named:cpa.imageName)
            
            
            
            print("Map view delegate is called end ***************************")
            
            return anView
            
            
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //anView.canShowCallout = true
            anView!.image = UIImage(named:"custommerIcon.png")
        }
        else {
            anView!.annotation = annotation
        }
        
        //Set annotation-specific properties **AFTER**
        //the view is dequeued or created...
        
        //let cpa = annotation as! CustomPointAnnotation
        //anView.image = UIImage(named:cpa.imageName)
        
        
        
        print("Map view delegate is called end ***************************")
        
        return anView
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


    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
