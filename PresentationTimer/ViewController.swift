//
//  ViewController.swift
//  PresentationTimer
//
//  Created by Orion Edwards on 24/07/15.
//  Copyright © 2015 Orion Edwards. All rights reserved.
//

import UIKit

struct PresentationSection {
    var name:String
    var offset:NSTimeInterval
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sectionsTableView: UITableView!
    @IBOutlet var addRowButton: ButtonWithBorder!
    @IBOutlet var tableViewToAddRowButton: NSLayoutConstraint!
    @IBOutlet weak var configureButton: ButtonWithBorder!
    
    private var sections:[PresentationSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()

//        sectionsTableView.backgroundColor = UIColor.clearColor()

//        addRowButton.hidden = true
//        NSLayoutConstraint.deactivateConstraints([tableViewToAddRowButton])
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("timingCell") else {
            fatalError("bad cell reuse identifier")
        }
        
        return cell
    }

    @IBAction func addRowButtonWasClicked(sender: ButtonWithBorder) {
        addRowButton.hidden = false
        NSLayoutConstraint.activateConstraints([tableViewToAddRowButton])
    }
    
    @IBAction func configureButtonWasClicked(sender: ButtonWithBorder) {
        if sectionsTableView.editing {
            sectionsTableView.editing = false
            configureButton.setTitle("Configure", forState: .Normal)
        } else {
            sectionsTableView.editing = true
            configureButton.setTitle("Done", forState: .Normal)
        }
    }
    
    @IBAction func resetButtonWasClicked(sender: ButtonWithBorder) {
    }
}

