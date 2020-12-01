//
//  DetailViewController.swift
//  CommitsApp
//
//  Created by Ярослав Карпунькин on 30.11.2020.
//

import Foundation
import UIKit

class DetailViewController: UIViewController {
    @IBOutlet weak var detailLabel: UILabel!
    var detailItem: Commit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let detail = self.detailItem {
            detailLabel.text = detail.message
            // navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Commit
            //1/\(detail.author.commits.count)", style: .plain, target: self, action:
            //#selector(showAuthorCommits))
            //}
        }
    }
}
