//
//  AppDelegate.swift
//  phuketTaxiDriverM
//
//  Created by cake on 3/15/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CoreLocation

let mySpecialNotificationKey = "com.cake.specialNotificationKey"
let customerResponseNotificationKey = "com.cake.customerResponseNotificationKey"
let mqttConnectedNotificationKey =  "mqttConnectedNotificationKey"

var taxiId : String = "0891001044"
let mainHost : String = "128.199.97.22";
var didLogin : Bool = false
let gCustomerResponseTopic : String = "customerResponse"
let gTaxiResponseTopic : String = "taxiResponse"
let prefs = NSUserDefaults.standardUserDefaults()
let gUpdateDistance : Double = 10

let googleWebAPIkey : String = "AIzaSyCkkgvHEbB9Q0k4ICWzZBJNd_wV5GEYNzc"

let pathToImage : String = "/images/drivers/"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MQTTSessionManagerDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate{

    var window: UIWindow?
    
   
   
    
    var requestTopic : String = "cli/" + "id"+taxiId
    var removeCustomer : String = "removeContomer/" + "id"+taxiId
    var pongTopic : String = "pong/"+"id"+taxiId
    
    var currentLat : Double = 0.0
    var currentLon : Double = 0.0
    
    var requestedMessage = Dictionary<String, String>()
    
    var custommerMessage : String = ""
    var reuestedCustomer : String = ""
    var nationality : String = ""
    
    var acceptedCustomerLocation = CLLocationCoordinate2D(
        latitude: 0,
        longitude: 0
    )
    
    var timerReconnect = NSTimer()
    var pingTimer = NSTimer()
    var countDown = 60;
    
    
    var myCurrentLocation = CLLocationCoordinate2D(
        latitude: 0,
        longitude: 0
    )
    
    var mqttIsClosed = false
    
    var mqttManager : MQTTSessionManager?
    var ccFlag = false
    
    
    var userImage : UIImage?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startMqtt", name: mqttConnectedNotificationKey, object: nil)
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        UIApplication.sharedApplication().idleTimerDisabled = true
        
       /* if((prefs.objectForKey("firstRun")) == nil){
            prefs.setObject("Yes", forKey: "firstRun")
            //taxiId = NSUUID().UUIDString
            //prefs.setObject(taxiId, forKey: "taxiId")
            println("First run")
            
            let vc = storyboard.instantiateViewControllerWithIdentifier("registerViewController") as! UIViewController
            
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
            
        } else { */
            //taxiId = prefs.objectForKey("taxiId") as! String
            print("run leaw")
        if((prefs.objectForKey("haveLogin")) != nil){
            
            if(prefs.objectForKey("haveLogin") as! String == "yes"){
                let email = prefs.objectForKey("username") as! String
                let password1 = prefs.objectForKey("password") as! String
                login(email, password: password1)
            } else {
                let vc = storyboard.instantiateViewControllerWithIdentifier("loginViewController") 
                
                self.window?.rootViewController = vc
                self.window?.makeKeyAndVisible()
                
            }
            
        } else {
            
            let vc = storyboard.instantiateViewControllerWithIdentifier("loginViewController") 
            
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
        }

        //}
        
        /*
        
        mqtt.start("id"+taxiId)
        
        println(taxiId)
        self.requestTopic = "cli/" + "id"+taxiId
        self.removeCustomer = "removeContomer/" + "id"+taxiId
        
        initMQTT()
        */
        
 
        return true
    }
    
    
    func login(email: String, password: String){
      //  var email = emailTextField.text
      //  var password = passwordTextField.text
        
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/driverLogin");
        let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
        request1.HTTPMethod = "POST";
        let requestString = "email="+email+"&" + "password="+password
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
                    self.requestTopic = "cli/" + "id"+taxiId
                    self.removeCustomer = "removeContomer/" + "id"+taxiId
                    self.pongTopic = "pong/"+"id"+taxiId
                    
                    //self.delegate.initMQTT()
                    //self.delegate.startMqtt("id"+taxiId)
                    //self.delegate.startTimer()
                    
                    self.ccFlag = true
                    NSNotificationCenter.defaultCenter().postNotificationName(mqttConnectedNotificationKey, object: self)
                    
                    print("Did login =============================== true ===")
                    didLogin = true
                    
                    // self.delegate.imageID = json[0]["id"].string!
                    
                    let url = "http://" + mainHost + pathToImage + taxiId + ".png"
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
    }
    
    
    func getDataFromUrl(urL:NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(urL) { (data, response, error) in
            completion(data: data)
            }.resume()
    }
    
    
    func downloadImage(url:NSURL){
       // print("Started downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
        getDataFromUrl(url) { data in
            dispatch_async(dispatch_get_main_queue()) {
         //       print("Finished downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
                self.userImage = UIImage(data: data!)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                let vc = storyboard.instantiateViewControllerWithIdentifier("viewControllerx") 
                
                self.window?.rootViewController = vc
                self.window?.makeKeyAndVisible()
                
            }
        }
    }
    
    //MARK: Mqtt delegate
    
    func handleMessage(data: NSData!, onTopic topic: String!, retained: Bool) {
        
        let payload : String = NSString(data:data, encoding:NSUTF8StringEncoding) as! String
        if(topic == self.requestTopic) {
            
            print("Get request cli")
            print(payload)
            
            let jsonObject : AnyObject! = try? NSJSONSerialization.JSONObjectWithData(payload.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers)
            
            
            let data  = JSON(jsonObject)
            
            print(data["id"])
            
            let idd = data["id"].string
            
            self.requestedMessage.updateValue(payload, forKey: idd!)// = theMessage.body
            
            NSNotificationCenter.defaultCenter().postNotificationName(mySpecialNotificationKey, object: self)
        } else if (topic == self.removeCustomer) {
            print("********************************* Removing ******************************")
            print(payload)
            self.requestedMessage.removeValueForKey(payload)
            NSNotificationCenter.defaultCenter().postNotificationName(mySpecialNotificationKey, object: self)
            
            
        } else if (topic == gCustomerResponseTopic+"/"+self.reuestedCustomer) {
            print("********************************* Customer response ******************************")
            print(payload)
            self.custommerMessage = payload
            
            NSNotificationCenter.defaultCenter().postNotificationName(customerResponseNotificationKey, object: self)
            
            
        } else if (topic == self.pongTopic){
            print("Ping ok!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            //self.pingTimer.invalidate()
        } else {
            print("Somethingelse")
        }
    

    
    }





    func initMQTT(){
        
        mqttManager!.subscribeToTopic(requestTopic)
        mqttManager!.subscribeToTopic(removeCustomer)
        mqttManager!.subscribeToTopic("mmm")
        mqttManager!.subscribeToTopic(pongTopic)
        
        if(!self.reuestedCustomer.isEmpty){
            self.mqttManager!.subscribeToTopic(gCustomerResponseTopic+"/"+self.reuestedCustomer)
            
        }

        self.updateCurrentLocation()
      
         
        
    }
    
    func startMqtt(){
        print("=================== Try to connect to MQTT")
        
        mqttManager = MQTTSessionManager()
        
        let id = "id"+taxiId
        print("xxxxxxxxxxxxxxxx Taxi id = \(id)")
        
        mqttManager!.delegate = self
        mqttManager!.addObserver(self, forKeyPath: "state", options: [NSKeyValueObservingOptions.Initial, NSKeyValueObservingOptions.New], context: nil)
        let willMessage = taxiId.dataUsingEncoding(NSUTF8StringEncoding)
        mqttManager!.connectTo(mainHost, port: 1883, tls: false, keepalive: 60, clean: true, auth: false, user: nil, pass: nil, willTopic: "taxiDriver/will", will: willMessage, willQos: MQTTQosLevel.AtMostOnce, willRetainFlag: false, withClientId: "id"+taxiId)
       
        
      
        
       // mqttManager.disconnect()
              // mqttManager.connectToLast()
       
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        print("=================== Trying to connect to MQTT")
        switch self.mqttManager!.state {
        case MQTTSessionManagerState.Closed:
            print("============== CLosed =================")
            mqttIsClosed = true
            break
        case MQTTSessionManagerState.Closing:
            print("============== Closing =================")
            break
        case MQTTSessionManagerState.Connected:
            print("============== MQTT connected =================")
          
            initMQTT()
            mqttIsClosed = false
            //startTimer()
           
            break
        case MQTTSessionManagerState.Connecting:
            print("============== Connecting =================")
            break
        case MQTTSessionManagerState.Error:
            print("============== ERROR =================")
            print("")
            break
        case MQTTSessionManagerState.Starting:
            print("============== STarting =================")
            break
        default:
            print("============== Confused =================")
            break
        }
    
    }
    
    
    func startTimer() {
        timerReconnect = NSTimer.scheduledTimerWithTimeInterval(300, target: self, selector: Selector("reconnect"), userInfo: nil, repeats: true)
        
    }
    
    
    func reconnect() {
        countDown = 60;
        mqttManager!.sendMessage("ping/"+"id"+taxiId, message: "id"+taxiId)
        
        //pingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("checkPong"), userInfo: nil, repeats: true)
        
        
    }
    
    func checkPong(){
        countDown--
        print("Counter = \(countDown)")
      
        mqttManager!.sendMessage("ping/"+"id"+taxiId, message: "id"+taxiId)
        if countDown < 0 {

            
            if(didLogin == true){
                self.mqttManager!.reconnect()
                
                print("try to reconnect from pong")
                while(self.mqttManager!.state != MQTTSessionManagerState.Connected){
                   NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
                }
                
                if(!self.reuestedCustomer.isEmpty){
                    self.mqttManager!.subscribeToTopic(gCustomerResponseTopic+"/"+self.reuestedCustomer)
                    
                }
                
                self.initMQTT()
                self.updateCurrentLocation()
            }

            countDown = 60;
            pingTimer.invalidate()
        }
    }
    
    
    
    
    func removeFromManager(){
        
        
        // Remove location from the manager
        
        let id = taxiId
        
        let topic1 : String = "removeTaxi/"+"id"+taxiId
        
        var jsonLoc : String = String(format: "{")
        jsonLoc += "\"id\":"
        jsonLoc += "\"id"
        jsonLoc += id
        jsonLoc += "\"}"
        
        print("Trying to send removing taxi message")
        
      
        
        mqttManager!.sendMessageSpecial(topic1, message: jsonLoc)

        
        // Remove location from all clients
        for (key, value) in requestedMessage {
            let topic2 : String = "removeTaxi/" + key
        
            mqttManager!.sendMessage(topic2, message: "id"+taxiId)
        }
        requestedMessage.removeAll(keepCapacity: false)
        NSNotificationCenter.defaultCenter().postNotificationName(mySpecialNotificationKey, object: self)
        
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        //mqtt.mqttInstance.disconnectWithCompletionHandler(nil)
        if(didLogin == true){
            removeFromManager()
        }
    
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //removeFromManager()
        //mqtt.mqttInstance.disconnectWithCompletionHandler(nil)
       /* if(didLogin == true){
            self.mqttManager!.reconnect()
            
            println("try to reconnect from pong Enter background")
            while(self.mqttManager!.state != MQTTSessionManagerState.Connected){
              //  NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
            }
            removeFromManager()
        }*/
        

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        if(didLogin == true){
            if self.mqttManager!.state != MQTTSessionManagerState.Connected {
                self.mqttManager!.reconnect()
            
                print("try to reconnect from pong")
                while(self.mqttManager!.state != MQTTSessionManagerState.Connected){
                    NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
                }
            }
            
            if(!self.reuestedCustomer.isEmpty){
                self.mqttManager!.subscribeToTopic(gCustomerResponseTopic+"/"+self.reuestedCustomer)
                
            }
            
           // self.initMQTT()
            self.updateCurrentLocation()
        }
 
    
    
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if(didLogin == true){
            if self.mqttManager!.state != MQTTSessionManagerState.Connected {
                self.mqttManager!.reconnect()
                
                print("try to reconnect from pong")
                while(self.mqttManager!.state != MQTTSessionManagerState.Connected){
                    NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
                }
            }
            
            if(!self.reuestedCustomer.isEmpty){
                self.mqttManager!.subscribeToTopic(gCustomerResponseTopic+"/"+self.reuestedCustomer)
                
            }
            
            // self.initMQTT()
            self.updateCurrentLocation()
        }

      

    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print("*********************** Quiting ************************")
        
        
        if(didLogin == true){
       
            removeFromManager()
            
            
        }
        
        mqttManager?.disconnect()
        self.saveContext()
    }
    
    func updateCurrentLocation(){
        var message1 : String
    
        let pubTopic : String = "taxiLocation/"+taxiId
    
        message1 = createLatLonJson(taxiId, lat: currentLat, lon: currentLon, aval: 1)
    
    
        mqttManager!.sendMessage(pubTopic, message: message1)
    }
    
    // ========================== JSON ================================
    
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

    
     
    

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "aa.phuketTaxiDriverM" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("phuketTaxiDriverM", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("phuketTaxiDriverM.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
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
    


}

