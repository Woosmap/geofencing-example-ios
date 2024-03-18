//
//  AppDelegate.swift
//  Geofence
//
//  Created by WGS on 06/10/23.
//

import UIKit
import CoreData
import WoosmapGeofencing
import CoreLocation
import FirebaseCore

class setting {
    static let WoosmapKey: String = "a440454c-046c-441b-8f87-ac0d207fc298"
    static let profile: ConfigurationProfile = .passiveTracking
    static let radius: String = "300"
}

///
///This class capture event raised by geofence SDK
internal class WoosmapEvent: LocationServiceDelegate, SearchAPIDelegate, RegionsServiceDelegate{

    internal init() {}
    
    ///Updated when new location capture by device
    internal func tracingLocation(location: Location) {
        //Save it in history
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let newRec:LocationLog = LocationLog(context:context)
        newRec.lat = location.latitude
        newRec.lng = location.longitude
        newRec.recordedon = Date()
        do {
            try   newRec.managedObjectContext?.save()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        NotificationCenter.default.post(name: .newLocationSaved, object: self, userInfo: ["Location": location])
    }
    ///
    ///Location error
    internal func tracingLocationDidFailWithError(error: Error) {
        debugPrint("sampleapp: \(error)")
    }
    ///
    ///Search response fetch from woos server
    internal func searchAPIResponse(poi: POI) {
        NotificationCenter.default.post(name: .newPOISaved, object: self, userInfo: ["POI": poi])
    }

    ///
    ///Search error
    internal func searchAPIError(error: String) {

    }
    ///CAlled ehen geofance region created
    internal func updateRegions(regions: Set<CLRegion>) {
        NotificationCenter.default.post(name: .updateRegions, object: self, userInfo: ["Regions": regions])
    }

    /// Called  when user is inside Geofence zone
    internal func didEnterPOIRegion(POIregion: Region) {
        
        //Save it in history
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let newRec:RegionLog = RegionLog(context:context)
        newRec.poi = POIregion.identifier
        if let moreInfo = POIs.getPOIbyIdStore(idstore: POIregion.identifier){
            newRec.poiname = moreInfo.name
        }
        else{
            newRec.poiname = "Missing Info (Something wrong)"
        }
        newRec.isenter = true
        newRec.radius = "\(POIregion.radius)"
        newRec.recordedon = Date()
        do {
            try   newRec.managedObjectContext?.save()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        NotificationCenter.default.post(name: .didEventPOIRegion, object: self, userInfo: ["Region": POIregion])
        sendNotification(POIregion: POIregion, didEnter: true)
    }

    /// Called  when user is exited Geofence zone
    internal func didExitPOIRegion(POIregion: Region) {
        //Save it in history
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let newRec:RegionLog = RegionLog(context:context)
        newRec.poi = POIregion.identifier
        if let moreInfo = POIs.getPOIbyIdStore(idstore: POIregion.identifier){
            newRec.poiname = moreInfo.name
        }
        else{
            newRec.poiname = "Missing Info (Something wrong)"
        }
        newRec.isenter = false
        newRec.radius = "\(POIregion.radius)"
        newRec.recordedon = Date()
        do {
            try   newRec.managedObjectContext?.save()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        NotificationCenter.default.post(name: .didEventPOIRegion, object: self, userInfo: ["Region": POIregion])
        sendNotification(POIregion: POIregion, didEnter: false)
    }
    
    /// Called  when user is inside Work Geofence zone
    internal func workZOIEnter(classifiedRegion: Region) {
        NotificationCenter.default.post(name: .didEventPOIRegion, object: self, userInfo: ["Region": classifiedRegion])
    }
    
    /// Called  when user is inside home Geofence zone
    internal func homeZOIEnter(classifiedRegion: Region) {
        NotificationCenter.default.post(name: .didEventPOIRegion, object: self, userInfo: ["Region": classifiedRegion])
    }
    
    ///Local notification format
    private func sendNotification(POIregion: Region, didEnter: Bool){
        let content = UNMutableNotificationContent()
        if(didEnter){
            content.title = "Region enter: \(POIregion.identifier)"
        }else {
            content.title = "Region exit: \(POIregion.identifier)"
        }
        content.body = ""
        if let moreInfo = POIs.getPOIbyIdStore(idstore: POIregion.identifier){
            content.body += "Name = \(moreInfo.name ?? "-")"
        }
        if(POIregion.type == "circle") {
            if(!didEnter){
                content.body += "\nTime spent:\(String(format: "%.0f Seconds", POIregion.spentTime))"
            }
            else{
                content.body += "\nradius: \(POIregion.radius) meters"
            }
        }
        else {
            content.body += "\n Radius = " + String(POIregion.radius)
            content.body += "\n Duration = " + POIregion.durationText
            content.body += "\n Distance = " + POIregion.distanceText
        }
        // Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: nil)
        
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request)
    }
}

/// Notification raised by SDK
extension Notification.Name {
    static let newLocationSaved = Notification.Name("newLocationSaved")
    static let newPOISaved = Notification.Name("newPOISaved")
    static let updateRegions = Notification.Name("updateRegions")
    static let didEventPOIRegion = Notification.Name("didEventPOIRegion")
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let woosmapDelegate = WoosmapEvent()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //debugPrint(WoosmapGeofenceManager.shared.getDatabaseFileURL()?.absoluteString)
        FirebaseApp.configure()
        WoosmapGeofenceManager.shared.logLevel = .debug
        WoosmapGeofenceManager.shared.getLocationService().locationServiceDelegate = woosmapDelegate
        WoosmapGeofenceManager.shared.getLocationService().searchAPIDataDelegate = woosmapDelegate
        WoosmapGeofenceManager.shared.getLocationService().regionDelegate = woosmapDelegate
        
        // Optional
        //WoosmapGeofenceManager.shared.getLocationService().visitDelegate = woosmapDelegate
        //WoosmapGeofenceManager.shared.getLocationService().distanceAPIDataDelegate = woosmapDelegate
        WoosmapGeofenceManager.shared.setWoosmapAPIKey(key: setting.WoosmapKey)
        WoosmapGeofenceManager.shared.startTracking(configurationProfile: setting.profile)
        WoosmapGeofenceManager.shared.setPoiRadius(radius: Double(setting.radius) ?? 200)
        // Check if the authorization Status of location Manager
        if CLLocationManager().authorizationStatus != .notDetermined {
            WoosmapGeofenceManager.shared.startMonitoringInBackground()
        }
        
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in }
        } else {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
        }
        application.registerForRemoteNotifications()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14, *) {
            completionHandler([.banner,.badge, .list])
        }
        else{
            completionHandler([.alert,.badge])
        }
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Geofence")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

