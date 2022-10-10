//
//  DetailTabViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// DetailTabViewController receives the embed segue triggered by DetailSplitItemViewController in Main.storyboard and is therefore instantiated at first application launch and at subsequent launches if the state restoration mechanism restores it; otherwise, it is instantiated when the user chooses the detail pane Detail button. It automatically calls loadView() to instantiate and load the detail pane's detail tab view. DetailTabViewController triggers three tab items relationship segues connected to AttributesTabItemViewController (the attributes tab item), ActionsTabItemViewController (the actions tab item) and NotificationsTabItemViewController (the notifications tab item) in Main.storyboard.

import Cocoa

class DetailTabViewController: NSTabViewController {

    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        /*
        let myTabView = tabView
       // let myDetailTabView = detailTabView
        let myView = view
        let myTabViewItems = tabViewItems
        //print("ENTERED DetailTabViewController.viewDidLoad()")
        //print("myTabView: \(myTabView)")
       // print("myDetailTabView: \(myDetailTabView)")
        //print("myView: \(myView)")
        //print("myTabViewItems: \(myTabViewItems)")
        tabView.font = NSFont.messageFont(ofSize: NSFont.smallSystemFontSize)
        //print("myTabView.font: \(myTabView.font)")
        //print("myTabViewItems[0].label: \(myTabViewItems[0].label)")
        */
    }
    
    // MARK: NSWindowRestoration Protocol Support
    
    override class var restorableStateKeyPaths: [String] {
        // NSResponder override method. Returns an array of key paths referring to user interface states, causing their values to be written to disk when Cocoa's interface persistence mechanism (the Resume feature, or interface restoration) detects changes and the states to be restored at launch time. Saving and restoring these values is automatic; it is not necessary to implement NSResponder's encodeRestorableStateWithCoder(_:) or restoreStateWithCoder(_:) methods or to conform to the NSWindowRestoration formal protocol.
        return ["selectedTabViewItemIndex"] // required to restore selected tab view item, despite documentation saying this is automatic
    }
}
