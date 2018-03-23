//
//  RootViewController.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit

class RootViewController: UITableViewController {
    private var isLoadingTable = true
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Flight Plan"
            cell.detailTextLabel?.text = ""
        case 1:
            cell.textLabel?.text = "Scanner"
            cell.detailTextLabel?.text = ""
        default:
            cell.textLabel?.text = "test"
            cell.detailTextLabel?.text = "test"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLoadingTable && tableView.indexPathsForVisibleRows?.last?.row == indexPath.row {
            isLoadingTable = false
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "FlightPlanSegue", sender: nil)
        case 1:
            self.performSegue(withIdentifier: "ScannerSegue", sender: nil)
        default:
            break
        }
    }
}
