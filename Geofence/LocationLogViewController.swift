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
        dateFormatter.dateFormat = "MMM d \nHH:mm:ss"
        cell.lblRecordTime.text = dateFormatter.string(from: cellData.recordedon ?? Date())
        cell.lblLocation.text = "(\(cellData.lat),\(cellData.lng))"
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
