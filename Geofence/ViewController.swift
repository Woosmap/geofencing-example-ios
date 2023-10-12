//
//  ViewController.swift
//  Geofence
//
//  Created by WGS on 06/10/23.
//

import UIKit
import WoosmapGeofencing
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var lblGeeofenceRadius: UILabel!
    @IBOutlet weak var lblAppProfile: UILabel!
    @IBOutlet weak var lblAppKey: UILabel!
    @IBOutlet weak var imgvAvatar: UIImageView!
    var pulseLayers = [CAShapeLayer]()
    
    @IBAction func onTapMenu(_ sender: UIBarButtonItem) {
        
        let actionSheetMenu: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let locationLogActionButton = UIAlertAction(title: "Location Log", style: .default)
        { _ in
            if let logView = self.storyboard?.instantiateViewController(identifier: "ID_LOCATION") as? UIViewController{
                self.navigationController?.pushViewController(logView, animated: true)
            }
        }
        actionSheetMenu.addAction(locationLogActionButton)
        
        let regionLogActionButton = UIAlertAction(title: "Region Log", style: .default)
        { _ in
            if let logView = self.storyboard?.instantiateViewController(identifier: "ID_REGION") as? UIViewController{
                self.navigationController?.pushViewController(logView, animated: true)
            }
        }
        actionSheetMenu.addAction(regionLogActionButton)
        self.present(actionSheetMenu, animated: true, completion: nil)
    }
    
    @IBAction func onTapReset(_ sender: Any) {
        
        let actionSheetMenu: UIAlertController = UIAlertController(title: "Reset", message: "Do you want to reset SDK Collected data?", preferredStyle: .actionSheet)
        let yesActionButton = UIAlertAction(title: "Yes", style: .default)
        { _ in
            //Clear SDK DB
            WoosmapGeofenceManager.shared.locationService.removeRegions(type: RegionType.poi)
            WoosmapGeofenceManager.shared.locationService.removeRegions(type: RegionType.none)
            WoosmapGeofenceManager.shared.locationService.removeRegions(type: RegionType.custom)
            POIs.deleteAll()
            Locations.deleteAll()
            
            //Clear app DB
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let requestLocation = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationLog")
            requestLocation.returnsObjectsAsFaults = false
            do{
                let fetchedResult = try context.fetch(requestLocation)
                for managedObject in fetchedResult {
                    if let managedObjectData: NSManagedObject = managedObject as? NSManagedObject {
                        context.delete(managedObjectData)
                    }
                }
            }catch let fetchErr {
                debugPrint(fetchErr.localizedDescription)
            }
            let requestRegion = NSFetchRequest<NSFetchRequestResult>(entityName: "RegionLog")
            requestRegion.returnsObjectsAsFaults = false
            do{
                let fetchedResult = try context.fetch(requestRegion)
                for managedObject in fetchedResult {
                    if let managedObjectData: NSManagedObject = managedObject as? NSManagedObject {
                        context.delete(managedObjectData)
                    }
                }
            }catch let fetchErr {
                debugPrint(fetchErr.localizedDescription)
            }
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            let actionSheetClose: UIAlertController = UIAlertController(title: "Restarting", message: "Please Reopen app again", preferredStyle: .alert)
           
            let okActionButton = UIAlertAction(title: "OK", style: .destructive)
            { _ in
                exit(0)
            }
            actionSheetClose.addAction(okActionButton)
            self.present(actionSheetClose, animated: true, completion: nil)
        }
        actionSheetMenu.addAction(yesActionButton)
        
        let noActionButton = UIAlertAction(title: "No", style: .destructive)
        { _ in
        }
        actionSheetMenu.addAction(noActionButton)
        self.present(actionSheetMenu, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        lblAppKey.text = setting.WoosmapKey
        lblAppProfile.text = setting.profile.rawValue
        lblGeeofenceRadius.text = "\(setting.radius) Meters"
        // Do any additional setup after loading the view.
        imgvAvatar.layer.cornerRadius = imgvAvatar.frame.size.width/2
        imgvAvatar.clipsToBounds = false
        
        if(setting.WoosmapKey == "<<private woosmap key>>"){
            let actionSheetMenu: UIAlertController = UIAlertController(title: "Configuration Error", message: "Your Woosmap private key is invalid", preferredStyle: .actionSheet)
            let saveActionButton = UIAlertAction(title: "Update Woosmap key", style: .default)
            { _ in
                exit(0)
            }
            actionSheetMenu.addAction(saveActionButton)
            self.present(actionSheetMenu, animated: true, completion: nil)
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onResume),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewRadar()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        pulseLayers.forEach { layer in
            layer.removeFromSuperlayer()
        }
        pulseLayers.removeAll()
        super.viewDidDisappear(animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    @objc func onResume(){
        pulseLayers.forEach { layer in
            layer.removeFromSuperlayer()
        }
        pulseLayers.removeAll()
        viewRadar()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    /// Created Radar view
    func viewRadar(){
        createPulse()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.animatePulse(index:0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.animatePulse(index:1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.animatePulse(index:2)
                }
            }
        }
    }
    /// Created pulse effect
    func createPulse() {
        let circularPath = UIBezierPath( arcCenter: .zero, radius: UIScreen.main.bounds.size.width/2, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        for _ in 0...2 {
            let pulseLayer = CAShapeLayer()
            pulseLayer.path = circularPath.cgPath
            pulseLayer.lineWidth = 2.0
            pulseLayer.fillColor = UIColor.clear.cgColor
            pulseLayer.lineCap = .round
            pulseLayer.position = CGPoint(x: imgvAvatar.frame.size.width/2, y: imgvAvatar.frame.size.width/2)
            imgvAvatar.layer.addSublayer(pulseLayer)
            pulseLayers.append(pulseLayer)
        }
    }
    /// Animation
    func animatePulse(index: Int){
        if(pulseLayers.indices.contains(index)){
            if self.traitCollection.userInterfaceStyle == .dark {
                pulseLayers[index].strokeColor = UIColor.white.cgColor
            } else {
                pulseLayers[index].strokeColor = UIColor.black.cgColor
            }
            
            
            let scaleAnimation = CABasicAnimation( keyPath: "transform.scale")
            scaleAnimation.duration = 2.0
            scaleAnimation.fromValue = 0
            scaleAnimation.toValue = 0.9
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            scaleAnimation.repeatCount = .greatestFiniteMagnitude
            pulseLayers[index].add(scaleAnimation, forKey: "scale")
            
            let opacityAnimation = CABasicAnimation( keyPath: #keyPath(CALayer.opacity))
            opacityAnimation.duration = 2.0
            opacityAnimation.fromValue = 0.9
            opacityAnimation.toValue = 0
            opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            opacityAnimation.repeatCount = .greatestFiniteMagnitude
            pulseLayers[index].add(opacityAnimation, forKey: "opacity")
        }
    }
}

