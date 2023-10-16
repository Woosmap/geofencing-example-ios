//
//  RegionLogViewController.swift
//  Geofence
//
//  Created by WGS on 10/10/23.
//

import UIKit
import CoreData
class RegionLogViewController: UIViewController {
    @IBOutlet weak var tblLog: UITableView!
    var logList: [RegionLog] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.reload), name: .didEventPOIRegion, object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func onTapBack(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func fetchData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RegionLog")
        request.sortDescriptors = [NSSortDescriptor(key:"recordedon" , ascending:false)]
        request.returnsObjectsAsFaults = false
        do{
            let fetchedResult = try context.fetch(request)
            logList =  fetchedResult as? [RegionLog] ?? []
        }catch let fetchErr {
            debugPrint(fetchErr.localizedDescription)
        }
    }
    @objc func reload(){
        fetchData()
        tblLog.reloadData()
    }
}

extension RegionLogViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellRegionLog.identifier, for: indexPath) as! CellRegionLog
        let cellData = logList[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy-MM-d HH:mm:ss"
        cell.lblPoiName.text = cellData.poiname ?? "-"
        cell.lblRecordTime.text = dateFormatter.string(from: cellData.recordedon ?? Date())
        cell.lblRegionInfo.text = "Radius is \(cellData.radius ?? "300") meters and POI Id is \(cellData.poi ?? "-")"
        cell.lblEventName.text = cellData.isenter ? "Entered event": "Exited event"
        cell.imgStatus.image = UIImage(systemName: cellData.isenter ? "arrowshape.right": "arrowshape.left")
        return cell
    }
}
extension RegionLogViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellData = logList[indexPath.row]
        UIPasteboard.general.string = "\(cellData.poi ?? ""),\(cellData.poiname ?? "-") \n\(cellData.isenter ? "Entered event":"Exited event")"
        self.view.makeToast("Region copied")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

internal class CellRegionLog: UITableViewCell {
    @IBOutlet weak var lblRegionInfo: UILabel!
    @IBOutlet weak var lblRecordTime: UILabel!
    @IBOutlet weak var imgStatus: UIImageView!
    @IBOutlet weak var lblPoiName: UILabel!
    @IBOutlet weak var lblEventName: UILabel!
    static let identifier: String = "ID_REGION"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
