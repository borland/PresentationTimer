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
    var startAtInterval:NSTimeInterval
}

enum TimelineMode {
    case Paused, Running
}

class Timeline {
    private var _baseline:NSTimeInterval = NSTimeInterval(0)
    private var _timerStartedAtDate:NSDate?
    private var _timer:NSTimer?
    
    private let _changedCallback:()->()
    private let _pausedCallback:()->()
    private let _resumedCallback:()->()
    
    init(changedCallback:()->(), pausedCallback:()->(), resumedCallback:()->()) {
        _changedCallback = changedCallback
        _pausedCallback = pausedCallback
        _resumedCallback = resumedCallback
    }
    
    private func startTimer() {
        let timer = NSTimer(timeInterval: 0.5, target: self, selector: "timerTick", userInfo: nil, repeats: true)
        timer.tolerance = 0.5
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
        
        if let oldTimer = _timer {
            oldTimer.invalidate()
        }
        _timer = timer
    }
    
    @objc func timerTick() {
        _changedCallback()
    }
    
    private func stopTimer() {
        if let timer = _timer {
            timer.invalidate()
        }
    }
    
    var mode:TimelineMode {
        get {
            return _timerStartedAtDate == nil ? .Paused : .Running
        }
    }
    
    func reset() {
        pause()
        _baseline = NSTimeInterval(0)
    }
    
    func pause() {
        _baseline = current
        _timerStartedAtDate = nil
        stopTimer()
        _pausedCallback()
    }
    
    func resume() {
        _timerStartedAtDate = NSDate()
        startTimer()
        _resumedCallback()
    }
    
    func adjustByInterval(interval:NSTimeInterval) {
        _baseline += interval
        _changedCallback()
    }
    
    var current:NSTimeInterval {
        get {
            if let timerStartedAt = _timerStartedAtDate { // timer is running
                return NSDate().timeIntervalSinceDate(timerStartedAt) + _baseline
            }
            return _baseline
        }
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sectionsTableView: UITableView!
    @IBOutlet weak var addRowButton: ButtonWithBorder!
    @IBOutlet weak var startButton: ButtonWithBorder!
    @IBOutlet weak var resetButton: ButtonWithBorder!
    
    private var _presentationSections:[PresentationSection] = []
    
    private lazy var _timeline:Timeline = self.createTimeline()
        
    private func createTimeline() -> Timeline {
        return Timeline(
            changedCallback: {
                self.timelineChanged()
            }, pausedCallback: {
                self.timelinePaused()
            }, resumedCallback: {
                self.timelineResumed()
            })
    }

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
        guard let cell = tableView.dequeueReusableCellWithIdentifier("timingCell") as? TimingCell else {
            fatalError("bad cell reuse identifier")
        }
        let section = _presentationSections[indexPath.row]
        cell.setSectionName(section.name, startAtInterval: section.startAtInterval)
        return cell
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
        
        _presentationSections.append(PresentationSection(name: "Topic \(newIndex+1)", startAtInterval: _timeline.current))
        sectionsTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndex, inSection: 0)], withRowAnimation: .Automatic)
        
        try! savePresentationSections(_presentationSections)
    }
    
    @IBAction func startButtonWasClicked(sender: ButtonWithBorder) {
        if sectionsTableView.editing {
            _timeline.resume()
        } else {
            _timeline.pause()
        }
    }
    
    @IBAction func timeLabelPanned(sender: UIPanGestureRecognizer) {
        if _timeline.mode == .Running {
            return
        }
        
        let translation = sender.translationInView(view)
        
        let horizontalPanDivisor:CGFloat = 1.0
        if translation.x < -horizontalPanDivisor || translation.x > horizontalPanDivisor { // horz pan greater than threshold
            _timeline.adjustByInterval(NSTimeInterval(translation.x / horizontalPanDivisor))
            
            sender.setTranslation(CGPointMake(0,0), inView: view) // reset the recognizer
        }
    }
    
    func timelineResumed() {
        startButton.setTitle("Stop", forState: .Normal)
        
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
    
    func timelinePaused() {
        sectionsTableView.editing = true
        startButton.setTitle("Start", forState: .Normal)
        
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
    
    func timelineChanged() {
        drawTime(_timeline.current)
    }
    
    func drawTime(interval:NSTimeInterval) {
        timeLabel.text = String(format: "%02d:%02d", Int(interval / 60), Int(interval % 60))
    }
    
    @IBAction func resetButtonWasClicked(sender: ButtonWithBorder) {
        _timeline.reset()
        drawTime(_timeline.current)
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
            if let name = dict["name"] as? String, duration = dict["startAtInterval"] as? NSNumber {
                sections.append(PresentationSection(name: name , startAtInterval: NSTimeInterval(duration.doubleValue)))
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
            plist.append(["name":section.name, "startAtInterval":NSNumber(double:section.startAtInterval)])
        }
        
        let data = try NSPropertyListSerialization.dataWithPropertyList(plist, format: .XMLFormat_v1_0, options: 0)
        try data.writeToFile(plistPath, options:NSDataWritingOptions())
    }
}

class TimingCell : UITableViewCell {
    @IBOutlet private weak var startAtIntervalLabel: UILabel!
    @IBOutlet private weak var sectionNameLabel: UILabel!
    
    func setSectionName(name:String, startAtInterval:NSTimeInterval) {
        sectionNameLabel.text = name
        startAtIntervalLabel.text = String(format: "%02d:%02d", Int(startAtInterval / 60), Int(startAtInterval % 60))
    }
    
}

