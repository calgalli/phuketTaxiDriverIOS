//
//  ViewController.swift
//  phuketTaxiDriverM
//
//  Created by cake on 3/15/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewControllerx: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var driverImage: UIImageView!
    @IBOutlet weak var fromAddress: UITextView!
    @IBOutlet weak var toAddress: UITextView!
    @IBOutlet weak var chat: UIButton!
    @IBOutlet weak var endTransaction: UIButton!
    @IBOutlet weak var counter: UILabel!
    @IBOutlet weak var displayGoto: UILabel!
    @IBOutlet weak var displayFrom: UILabel!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var tempDisplayData: UITextView!
    @IBOutlet weak var customerList: UITableView!
    var locationManager: CLLocationManager?
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var customers = Dictionary<String, Any>()
    
    var customersIDs = [String]()
    
    //var requestedCustomerId = [String]()
    var fireOnce: Bool = true
    
    var timer = NSTimer()
    var startTime = NSTimeInterval()
    var countDown : Int = 60
    
    override func viewDidLoad() {
        
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tempDisplayData.hidden = true
        
        driverImage.image = self.delegate.userImage
        driverImage.contentMode = UIViewContentMode.ScaleAspectFill
        driverImage.layer.cornerRadius = 25
        driverImage.clipsToBounds = true

        
        
       // customerList.hidden = true
        print("Loading view")
        
        // Do any additional setup after loading the view, typically from a nib.
        
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
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnEnterbackgroundlNotification", name: mySpecialNotificationKey, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnCustumerResponse", name: customerResponseNotificationKey, object: nil)
        
        
        
        // self.customList.registerClass(UITableViewCell.self, forCellReuseIdentifier: "customerList")
  

        alertView.hidden = true
        
        
        
                  endTransaction.hidden = true
            endTransaction.userInteractionEnabled = false
            chat.hidden = true
            chat.userInteractionEnabled = false
            
        

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func actOnCustumerResponse(){
        
        let jsonObject : AnyObject! = try? NSJSONSerialization.JSONObjectWithData(self.delegate.custommerMessage.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers)
        
        
        let data  = JSON(jsonObject)
        
        
        
        if(data["type"] == "costumerLocation"){
            print(data["lat"])
            print(data["lon"])
            
            let clocation = CLLocationCoordinate2D(
                latitude: data["lat"].doubleValue,
                longitude: data["lon"].doubleValue
            )
            
            self.delegate.acceptedCustomerLocation = clocation
            
                
        }

    }
    
    func actOnEnterbackgroundlNotification() {
        
        var displayString : String = ""
        
        for (key, value) in self.delegate.requestedMessage{
            
            let jsonObject : AnyObject! = try? NSJSONSerialization.JSONObjectWithData(value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers)
            
            
            let data  = JSON(jsonObject)
            
            displayString += data["From"].string!
            displayString += "\n"
            displayString +=  data["id"].string!
            displayString += "\n"
            
            if(data["requestFlag"] == "1"){
                
                self.delegate.reuestedCustomer = data["id"].string!
                self.delegate.nationality = data["nationality"].string!
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.alertView.hidden = false
                    self.displayFrom.text = data["From"].string!
                    self.fromAddress.text = data["fromAddress"].string!
                    self.displayGoto.text = data["to"].string!
                    self.toAddress.text = data["toAddress"].string!

                    self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)
                    
                    
                }
                
                //requestedCustomerId[0] = data["id"].string!
                
                
                print("Request Flag OK");
            }
            
        }

        
       
        
        
        dispatch_async(dispatch_get_main_queue()) { // 2
            
            //self.customerList.reloadData()
            self.tempDisplayData.text = displayString
        }
        
        
        
        print("New message")
    }

    //========================== Count down handle ======================
    func updateTime() {
        
        self.countDown--
 
        
        if(self.countDown > 0){
            dispatch_async(dispatch_get_main_queue()) { // 2
                self.counter.text = "\(self.countDown)"
                
            }
   
            
        } else {
            self.countDown = 60
            timer.invalidate()
            
            dispatch_async(dispatch_get_main_queue()) { // 2
                self.alertView.hidden = true
                
            }
            
        }
    }
    
    
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
        
        message1 = createLatLonJson(taxiId, lat: location.coordinate.latitude, lon: location.coordinate.longitude, aval: 1)
        
        
        
        self.delegate.mqttManager!.sendMessage(pubTopic, message: message1)
        print("****************** location update data ^^^^^^^^^^^^^^^^^^^^^^^")
        print(message1)
        print(pubTopic)
        
        if(self.delegate.requestedMessage.count > 0){
        
            for (key, value) in self.delegate.requestedMessage{
                
                let jsonObject : AnyObject! = try? NSJSONSerialization.JSONObjectWithData(value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers)
            
            
                let data  = JSON(jsonObject)
            
                let topic1 : String = "updateTaxiLocation/"+data["id"].string!
            
                self.delegate.mqttManager!.sendMessage(topic1, message: message1)
                print("Update location to customer")
                print(topic1)
            
            }
        }
        
        let clocation = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        
        self.delegate.myCurrentLocation = clocation
        
        // TODO ====================== update location to a requested customer =======================
        
        var data = Dictionary<String, String>()
        data["id"] = "id" + taxiId
        data["type"] = "locationUpdate"
        data["lat"] = String(format: "%f", self.delegate.myCurrentLocation.latitude)
        data["lon"] = String(format: "%f", self.delegate.myCurrentLocation.longitude)
        
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
        
        delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
        
        
        if UIApplication.sharedApplication().applicationState == .Active {
            
            mapView.showsUserLocation = true
            if(fireOnce == false) {
                let region = self.mapView.region;
                // Update the center
                //region.center = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
                // apply the new region
                self.mapView.region = region;
            
            } else {
                 fireOnce = false
                let rgn : MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), 10000, 10000);
                
                self.mapView.region = rgn;
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


    @IBAction func acceptAction(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            self.timer.invalidate()
            self.alertView.hidden = true
        }
        
        var data = Dictionary<String, String>()
        data["id"] = "id" + taxiId
        data["type"] = "ack"
        data["value"] = "OK"
        data["lat"] = String(format: "%f", self.delegate.myCurrentLocation.latitude)
        data["lon"] = String(format: "%f", self.delegate.myCurrentLocation.longitude)
        
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
        
        // ====================== send current lat lon tp the requested customer =======================
        
        delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
        
        timer.invalidate()
        self.countDown = 60
 
        // ====================== Change status to unavaliable  ==========================
        let pubTopic : String = "taxiLocation/"+taxiId
        var message1 : String
        message1 = createLatLonJson(taxiId, lat: self.delegate.myCurrentLocation.latitude, lon: self.delegate.myCurrentLocation.longitude, aval: 0)
        self.delegate.mqttManager!.sendMessage(pubTopic, message: message1)
        
        
        //  ====================== Subscript to the requested customer channel ==========================
        
        
        delegate.mqttManager!.subscribeToTopic(gCustomerResponseTopic+"/"+self.delegate.reuestedCustomer)
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()

        
        
        dispatch_async(dispatch_get_main_queue()) { // 2
            self.alertView.hidden = true
          /*  self.endTransaction.hidden = false
            self.endTransaction.userInteractionEnabled = true
            self.chat.hidden = false
            self.chat.userInteractionEnabled = true
            */
            
        }


    }
    
    
    @IBAction func cancelAction(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            self.timer.invalidate()
            self.alertView.hidden = true
        }
        
        var data = Dictionary<String, String>()
        data["id"] = "id" + taxiId
        data["type"] = "ack"
        data["value"] = "REJECT"
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gTaxiResponseTopic+"/id"+taxiId
        
        delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
        
        timer.invalidate()
        self.countDown = 60
        //requestedCustomerId.removeAll(keepCapacity: false)
        
        dispatch_async(dispatch_get_main_queue()) { // 2
            self.alertView.hidden = true
            
        }


    }
    
    
    @IBAction func profileAction(sender: UIButton) {
        performSegueWithIdentifier("viewcontrollerToProfile", sender: nil)
    }
    
    func updateCurrentLocation(){
        var message1 : String
        
        let pubTopic : String = "taxiLocation/"+taxiId
        
        message1 = createLatLonJson(taxiId, lat: self.delegate.currentLat, lon: self.delegate.currentLon, aval: 1)
        
        
        self.delegate.mqttManager!.sendMessage(pubTopic, message: message1)
    }

    
    func cancelAlert(){
       /* if objc_getClass("UIAlertController") != nil {
            
            println("UIAlertController can be instantiated")
            
            //make and use a UIAlertController
            
            var alert = UIAlertController(title: "Customer cancel", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, ha*ndler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
        } else {
            
            println("UIAlertController can NOT be instantiated")
            */
           /* let alert = UIAlertView()
            alert.title = "Customer cancel"
            alert.addButtonWithTitle("OK")
            alert.show()*/
            
            //make and use a UIAlertView
       // }
        
    }

    
    @IBAction func endTransactionAction(sender: AnyObject) {
        delegate.mqttManager!.unsubscribeTopic(gCustomerResponseTopic+"/"+self.delegate.reuestedCustomer)
       
            
            self.updateCurrentLocation()
            
            
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.endTransaction.hidden = true
                self.endTransaction.userInteractionEnabled = false
                self.chat.hidden = true
                self.chat.userInteractionEnabled = false

                
            }

            self.delegate.requestedMessage.removeValueForKey(self.delegate.reuestedCustomer)
            
            var displayString : String = ""
            
            for (key, value) in self.delegate.requestedMessage{
                
                let jsonObject : AnyObject! = try? NSJSONSerialization.JSONObjectWithData(value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers)
                
                
                let data  = JSON(jsonObject)
                
                displayString += data["From"].string!
                displayString += "\n"
                displayString +=  data["id"].string!
                displayString += "\n"
                
                
            }
            
            dispatch_async(dispatch_get_main_queue()) { // 2
                
                //self.customerList.reloadData()
                self.tempDisplayData.text = displayString
            }
            

         
            self.delegate.acceptedCustomerLocation = CLLocationCoordinate2D(
            latitude: 0,
            longitude: 0)
            
     
    }
    
    
    @IBAction func chatAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()
    }
    


}

/*
class cellView: UIView{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

*/


