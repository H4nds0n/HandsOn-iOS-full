//
//  HistoryTableViewController.swift
//  handsOnAi
//
//  Created by Florian Kainberger on 13.12.23.
//

import UIKit

class HistoryTableViewController: UITableViewController {
    private var entries = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refresh()
    }
    
    @objc private func refresh() {
        if !(refreshControl?.isRefreshing ?? false) {
            refreshControl?.beginRefreshing()
        }
        
        entries = UserDefaults.standard.stringArray(forKey: "history") ?? []
        
        print("[e] \(entries)")
        refreshControl?.endRefreshing()
        
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "entryCell", for: indexPath)
        
        if indexPath.row < entries.count {
            cell.textLabel?.text = entries[indexPath.row]
            
        }
        
        return cell
    }
}
