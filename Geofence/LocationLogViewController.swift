//
//  LocationLogViewController.swift
//  Geofence
//
//  Created by WGS on 10/10/23.
//

import UIKit
import CoreData
import Toast

class LocationLogViewController: UIViewController {
    @IBOutlet weak var tblLog: UITableView!
    
    var logList: [LocationLog] = [] //List of Logs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
        rightButton()
    }
    ///
    ///Add Notification
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.reload), name: .newLocationSaved, object: nil)
    }
    ///
    ///Remove notification
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    ///
    ///Remove view from screen
    @IBAction func onTapBack(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    ///Fetching Log from history
    func fetchData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationLog")
        request.sortDescriptors = [NSSortDescriptor(key:"recordedon" , ascending:false)]
        request.returnsObjectsAsFaults = false
        do{
            let fetchedResult = try context.fetch(request)
            
            logList =  fetchedResult as? [LocationLog] ?? []
        }catch let fetchErr {
            debugPrint(fetchErr.localizedDescription)
        }
    }
    ///
    ///REload list when new log capture
    @objc func reload(){
        fetchData()
        tblLog.reloadData()
    }
}
extension LocationLogViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellLocationLog.identifier, for: indexPath) as! CellLocationLog
        let cellData = logList[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy-MM-d HH:mm:ss"
        cell.lblRecordTime.text = dateFormatter.string(from: cellData.recordedon ?? Date())
        cell.lblLocation.text = "(\(String(format: "%.6f",cellData.lat)),\(String(format: "%.6f",cellData.lng)))"
        return cell
    }
}
extension LocationLogViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellData = logList[indexPath.row]
        UIPasteboard.general.string = "(\(cellData.lat),\(cellData.lng))"
        self.view.makeToast("Location copied")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

internal class CellLocationLog: UITableViewCell {
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblRecordTime: UILabel!
    
    static let identifier: String = "ID_LOG"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
//TODO: For testing - Start
extension LocationLogViewController {
    func rightButton(){
        let rightBarButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.down.circle"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.shareDatabase(_:)))
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    
    @objc func shareDatabase(_ sender: UIButton) {
        sender.isHidden = true
        let relPath = ("~/Library/Application Support/Woosmap.sqlite" as NSString).expandingTildeInPath
        let fileManager = FileManager.default
        let zipName: String = "woozieApp.zip"
        if fileManager.fileExists(atPath: relPath) {
            
            do {
                //Delete perviously saved file
                let lastSaved = ("~/Documents/\(zipName)" as NSString).expandingTildeInPath
                if fileManager.fileExists(atPath: lastSaved) {
                    try fileManager.removeItem(atPath: lastSaved)
                }
                
                let sourceURL = URL(fileURLWithPath: ("~/Library/Application Support" as NSString).expandingTildeInPath)
                let destURL = URL(fileURLWithPath:  ("~/Documents/\(zipName)" as NSString).expandingTildeInPath)
                let outcome = try sourceURL.zip(toFileAt: destURL)
                
                // Create the Array which includes the files you want to share
                var filesToShare = [Any]()
                
                // Add the path of the file to the Array
                filesToShare.append(outcome)
                
                // Make the activityViewContoller which shows the share-view
                let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                
                // Show the share-view
                self.present(activityViewController, animated: true){
                    // nothing
                }
                
                sender.isHidden = false
            } catch {
                debugPrint("sampleapp: Failed to read database")
                sender.isHidden = false
            }
        }
        else{
            debugPrint("sampleapp: No Database found")
            sender.isHidden = false
        }
        
    }
}

internal extension URL {
    
    /// Creates a zip archive of the file or folder represented by this URL and returns a references to the zipped file
    ///
    /// - parameter dest: the destination URL; if nil, the destination will be this URL with ".zip" appended
    func zip(toFileAt dest: URL? = nil) throws -> URL
    {
        let destURL = dest ?? self.appendingPathExtension("zip")
        
        let fm = FileManager.default
        var isDir: ObjCBool = false
        
        let srcDir: URL
        let srcDirIsTemporary: Bool
        if self.isFileURL && fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue == true {
            // this URL is a directory: just zip it in-place
            srcDir = self
            srcDirIsTemporary = false
        }
        else {
            // otherwise we need to copy the simple file to a temporary directory in order for
            // NSFileCoordinatorReadingOptions.ForUploading to actually zip it up
            srcDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try fm.createDirectory(at: srcDir, withIntermediateDirectories: true, attributes: nil)
            let tmpURL = srcDir.appendingPathComponent(self.lastPathComponent)
            try fm.copyItem(at: self, to: tmpURL)
            srcDirIsTemporary = true
        }
        
        let coord = NSFileCoordinator()
        var readError: NSError?
        var copyError: NSError?
        var errorToThrow: NSError?
        
        var readSucceeded:Bool = false
        // coordinateReadingItemAtURL is invoked synchronously, but the passed in zippedURL is only valid
        // for the duration of the block, so it needs to be copied out
        coord.coordinate(readingItemAt: srcDir,
                         options: NSFileCoordinator.ReadingOptions.forUploading,
                         error: &readError)
        {
            (zippedURL: URL) -> Void in
            readSucceeded = true
            // assert: read succeeded
            do {
                try fm.copyItem(at: zippedURL, to: destURL)
            } catch let caughtCopyError {
                copyError = caughtCopyError as NSError
            }
        }
        
        if let theReadError = readError, !readSucceeded {
            // assert: read failed, readError describes our reading error
            debugPrint("sampleapp: zipping failed")
            errorToThrow =  theReadError
        }
        else if readError == nil && !readSucceeded  {
            debugPrint("sampleapp: NSFileCoordinator has violated its API contract. It has errored without throwing an error object")
            errorToThrow = NSError.init(domain: Bundle.main.bundleIdentifier!, code: 0, userInfo: nil)
        }
        else if let theCopyError = copyError {
            // assert: read succeeded, copy failed
            debugPrint("sampleapp: zipping succeeded but copying the zip file failed")
            errorToThrow = theCopyError
        }
        
        if srcDirIsTemporary {
            do {
                try fm.removeItem(at: srcDir)
            }
            catch {
                // Not going to throw, because we do have a valid output to return. We're going to rely on
                // the operating system to eventually cleanup the temporary directory.
                debugPrint("sampleapp: Warning. Zipping succeeded but could not remove temporary directory afterwards")
            }
        }
        if let error = errorToThrow { throw error }
        return destURL
    }
}
//TODO: For testing - End
