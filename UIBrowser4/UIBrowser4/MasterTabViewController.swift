//
//  MasterTabViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// MasterTabViewController receives the embed segue triggered by MasterSplitItemViewController in Main.storyboard and is therefore instantiated at application launch. It automatically calls loadView() to instantiate and load the master pane's master tab view. MasterTabViewController triggers three tab items relationship segues connected to BrowserViewController (the browser tab view item), OutlineViewController (the outline tab view item) and ListViewController (the list tab view item) in Main.storyboard.

import Cocoa

class MasterTabViewController: NSTabViewController {

    // MARK: - PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    // A type property that gives access to this object from any other object by referencing MasterTabViewController.sharedInstance.
    static private(set) var sharedInstance: MasterTabViewController! // set to self in viewDidLoad(); it was created in Main.storyboard at launch
    
    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
 
        // Set the shared type property to self to give access to this object from any other object by referencing MasterTabViewController.sharedInstance.
        MasterTabViewController.sharedInstance = self
}
    
    // MARK: NSWindowRestoration Protocol Support
    
    override class var restorableStateKeyPaths: [String] {
        // NSResponder override method. Returns an array of key paths referring to user interface states, causing their values to be written to disk when Cocoa's interface persistence mechanism (the Resume feature, or interface restoration) detects changes and the states to be restored at launch time. Saving and restoring these values is automatic; it is not necessary to implement NSResponder's encodeRestorableState(with:) or restoreState(with:) methods or to conform to the NSWindowRestoration formal protocol.
        return ["selectedTabViewItemIndex"] // required to restore selected tab view item, despite documentation saying this is automatic
    }
    
}
