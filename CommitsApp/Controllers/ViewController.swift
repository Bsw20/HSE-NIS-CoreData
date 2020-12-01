//
//  ViewController.swift
//  CommitsApp
//
//  Created by Ярослав Карпунькин on 30.11.2020.
//

import UIKit
import CoreData
import SwiftyJSON

class ViewController: UITableViewController {
    
    var container: NSPersistentContainer!
    var commits = [Commit]()
    var commitPredicate: NSPredicate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(changeFilter))
            
        container = NSPersistentContainer(name: "CommitsApp")
        
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy =
                NSMergeByPropertyObjectTrumpMergePolicy
            if let error = error {
                print("Unresolved error \(error)") }
            }
        performSelector(inBackground: #selector(fetchCommits), with: nil)
        loadSavedData()
    }
    
    @objc func changeFilter() {
        let ac = UIAlertController(title: "Filter commits...", message: nil, preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: "Show only fixes", style: .default, handler: { [unowned self](_) in
            self.commitPredicate = NSPredicate(format: "message CONTAINS[c] 'fix'")
            self.loadSavedData()
        }))
        
        ac.addAction(UIAlertAction(title: "Ignore Pull Requests", style: .default, handler: { [unowned self](_) in
            self.commitPredicate = NSPredicate(format: "NOT message BEGINSWITH 'Merge pull request'")
            self.loadSavedData()
        }))
        
        ac.addAction(UIAlertAction(title: "Show only recent", style: .default)
        { [unowned self] _ in
            let twelveHoursAgo = Date().addingTimeInterval(-43200)
            self.commitPredicate = NSPredicate(format: "date > %@", twelveHoursAgo as
        NSDate)
            self.loadSavedData()
        })
        
        ac.addAction(UIAlertAction(title: "Show all commits", style: .default, handler: { [unowned self](_) in
            self.commitPredicate = nil
            self.loadSavedData()
        }))
        
        ac.addAction(UIAlertAction(title: "Show only Durian commits", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = NSPredicate(format: "author.name == 'Joe Groff'")
            self.loadSavedData()
        }))
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("An error occured while saving: \(error)")
            }
        }
    }
    
    @objc func fetchCommits() {
        if let data = try? Data(contentsOf: URL(string: "https://api.github.com/repos/apple/swift/commits?per_page=100")!) {
            var jsonCommits:JSON
            do {
                jsonCommits =  try JSON(data: data)
            } catch {
                fatalError()
            }
            
            let jsonCommitArray = jsonCommits.arrayValue
            
            print("Received \(jsonCommitArray.count) new commits.")
            DispatchQueue.main.async { [unowned self] in
                for jsonCommit in jsonCommitArray {
                    let commit = Commit(context: self.container.viewContext)
                    self.configure(commit: commit, usingJson: jsonCommit)
                }
                self.saveContext()
                loadSavedData()
            }

        }
    }
    
    func configure(commit: Commit, usingJson json: JSON) {
        commit.sha = json["sha"].stringValue
        commit.message = json["commit"]["message"].stringValue
        commit.url = json["html_url"].stringValue
        
        let formatter = ISO8601DateFormatter()
        commit.date = formatter.date(from: json["commit"]["commiter"]["date"].stringValue) ?? Date()
        
        var commitAuthor: Author!
        let authorRequest = Author.createFetchRequest()
        authorRequest.predicate = NSPredicate(format: "name == %@", json["commit"]["committer"]["name"].stringValue)
        if let authors = try? container.viewContext.fetch(authorRequest) {
            if authors.count > 0 {
                commitAuthor = authors[0]
            }
        }
        
        if commitAuthor == nil {
            let author = Author(context: container.viewContext)
            author.name = json["commit"]["committer"]["name"].stringValue
            author.email = json["commit"]["committer"]["email"].stringValue
            commitAuthor = author
        }
        commit.author = commitAuthor
    }
    
    func loadSavedData() {
        let request = Commit.createFetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        
        request.predicate = commitPredicate
        request.sortDescriptors = [sort]
        do {
            commits = try container.viewContext.fetch(request)
            print("Got \(commits.count) commits")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

        } catch {
            print("Fetch failed")
        }
    }

}
//MARK: -  UITableViewDelegate, UITableViewDataSource
extension ViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commits.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let commit = commits[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Commit", for: indexPath)
        cell.textLabel?.text = commit.message
        cell.detailTextLabel?.text = "By \(commit.author.name) on \(commit.date.description)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(identifier: "Detail") as? DetailViewController {
            vc.detailItem = commits[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

