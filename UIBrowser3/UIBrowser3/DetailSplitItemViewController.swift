//
//  DetailSplitItemViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// DetailSplitItemViewController receives one of the split items relationship segues triggered by MainSplitViewController in Main.storyboard. The detail (bottom) split item is visible by default at first application launch and is therefore instantiated at first launch. At subsequent launches, it is only instantiated if the state restoration mechanism restores it; otherwise, it is instantiated when the user chooses the detail split item Detail button. It automatically calls loadView() to instantiate and load the main split view's master tab view. DetailSplitItemViewController's view contains, along with other UI elements, a container view that initiates or triggers an embed segue connected to DetailTabViewController in Main.storyboard; the tab view replaces the container view at application launch. DetailSplitItemViewController may also manage other UI elements that are located in the detail pane view because they are relevant to the detail pane as a whole rather than to the individual tab view items of the tab view.

import Cocoa

class DetailSplitItemViewController: NSViewController {

    // MARK: - PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    // A type property that gives access to this object from any other object by referencing DetailSplitItemViewController.sharedInstance.
    static private(set) var sharedInstance: DetailSplitItemViewController! // set to self in viewDidLoad(); it was created in Main.storyboard at launch
    
    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the shared type property to self to give access to this object from any other class by referencing DetailSplitItemViewController.sharedInstance.
        DetailSplitItemViewController.sharedInstance = self
    }
    
}
