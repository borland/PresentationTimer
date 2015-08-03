//
//  ViewController.swift
//  PresentationTimer
//
//  Created by Orion Edwards on 24/07/15.
//  Copyright © 2015 Orion Edwards. All rights reserved.
//

import UIKit
import Foundation

struct PresentationSection {
    var name:String
    var duration:NSTimeInterval
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sectionsTableView: UITableView!
    @IBOutlet weak var addRowButton: ButtonWithBorder!
    @IBOutlet weak var startButton: ButtonWithBorder!
    @IBOutlet weak var resetButton: ButtonWithBorder!
    
    private var _presentationSections:[PresentationSection] = []
    
    private var _startTime:NSDate?
    private var _pauseTime:NSDate?
    private var _timer:NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _presentationSections = loadPresentationSections();

        sectionsTableView.backgroundColor = UIColor.clearColor()

        sectionsTableView.editing = true
        
        timeLabel.userInteractionEnabled = true
        timeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "startButtonWasClicked:"))
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _presentationSections.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("timingCell") else {
            fatalError("bad cell reuse identifier")
        }
        return cell
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let moved = _presentationSections.removeAtIndex(sourceIndexPath.row)
        _presentationSections.insert(moved, atIndex: destinationIndexPath.row)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            _presentationSections.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
         
            try! savePresentationSections(_presentationSections)
        }
    }
    @IBAction func addRowButtonWasClicked(sender: ButtonWithBorder) {
        let newIndex = _presentationSections.count
        
        _presentationSections.append(PresentationSection(name: "Topic \(newIndex+1)", duration: 5 * 60))
        sectionsTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndex, inSection: 0)], withRowAnimation: .Automatic)
        
        try! savePresentationSections(_presentationSections)
    }
    
    @IBAction func startButtonWasClicked(sender: ButtonWithBorder) {
        if sectionsTableView.editing {
            startTimer()
        } else {
            pauseTimer()
        }
    }
    
    func startTimer() {
        startButton.setTitle("Stop", forState: .Normal)
        
        if _timer == nil {
            _startTime = NSDate()
            _pauseTime = nil
            
            let timer = NSTimer(timeInterval: 0.5, target: self, selector: "updateTimer", userInfo: nil, repeats: true)
            timer.tolerance = 0.5
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
            _timer = timer
            
        } else if let startTime = _startTime, let pauseTime = _pauseTime {
            // else it's paused, resume it
            let pauseDuration = NSDate().timeIntervalSinceDate(pauseTime)
            _startTime = startTime.dateByAddingTimeInterval(pauseDuration)
            _pauseTime = nil
        }
        
        self.resetButton.alpha = 0
        self.addRowButton.alpha = 0
        self.startButton.alpha = 0
        
        UIView.animateWithDuration(0.25, animations: {
            if self._presentationSections.count == 0 {
                self.sectionsTableView.hidden = true
            }
            self.sectionsTableView.editing = false
            self.resetButton.hidden = true
            self.addRowButton.hidden = true
            self.startButton.hidden = true
        })
    }
    
    func pauseTimer() {
        sectionsTableView.editing = true
        startButton.setTitle("Start", forState: .Normal)
        
        _pauseTime = NSDate()
        
        UIView.animateWithDuration(0.25, animations: {
            self.sectionsTableView.hidden = false
            self.sectionsTableView.editing = true
            self.resetButton.hidden = false
            self.addRowButton.hidden = false
            self.startButton.hidden = false
        }, completion: { (Bool) in
            self.resetButton.alpha = 1
            self.addRowButton.alpha = 1
            self.startButton.alpha = 1
        })
    }
    
    func updateTimer() {
        if _pauseTime != nil {
            return // simply don't redraw, the timer carries on
        }
        if let start = _startTime {
            drawTime(NSDate(), since:start)
        }
    }
    
    func drawTime(time:NSDate, since:NSDate) {
        let components = NSCalendar.currentCalendar().components([NSCalendarUnit.Minute, NSCalendarUnit.Second],
            fromDate: since, toDate: time, options: NSCalendarOptions())
        
        timeLabel.text = String(format: "%02d:%02d", components.minute, components.second)
    }
    
    @IBAction func resetButtonWasClicked(sender: ButtonWithBorder) {
        _timer?.invalidate()
        
        _timer = nil
        _startTime = nil
        
        drawTime(NSDate(), since: NSDate())
    }
    
    func loadPresentationSections() -> [PresentationSection] {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first else {
            return [PresentationSection]()
        }
        // get the path to our Data/plist file
        let plistPath = documentsPath + "presentationSections.plist"
        
        // check to see if Data.plist exists in documents
        guard NSFileManager.defaultManager().fileExistsAtPath(plistPath) else {
            return [PresentationSection]()
        }
        
        // read property list into memory as an NSData object
        guard let data = NSFileManager.defaultManager().contentsAtPath(plistPath) else {
            return [PresentationSection]()
        }
        
        var rawResult:AnyObject?
        do {
            rawResult = try NSPropertyListSerialization.propertyListWithData(data,
                options: NSPropertyListReadOptions.Immutable,
                format: nil)
        } catch {
            return [PresentationSection]()
        }
        
        guard let result = rawResult as? [NSDictionary] else {
            return [PresentationSection]()
        }
        
        var sections = [PresentationSection]()
        for dict in result {
            if let name = dict["name"] as? String, duration = dict["duration"] as? NSNumber {
                sections.append(PresentationSection(name: name , duration: NSTimeInterval(duration.doubleValue)))
            }
        }
        return sections
    }
    
    func savePresentationSections(sections:[PresentationSection]) throws {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        // get the path to our Data/plist file
        let plistPath = documentsPath + "presentationSections.plist"
        
        var plist = [NSDictionary]()
        for section in _presentationSections {
            plist.append(["name":section.name, "duration":NSNumber(double:section.duration)])
        }
        
        let data = try NSPropertyListSerialization.dataWithPropertyList(plist, format: .XMLFormat_v1_0, options: 0)
        try data.writeToFile(plistPath, options:NSDataWritingOptions())
    }
}

