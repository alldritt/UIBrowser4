//
//  ActionsTabItemViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// ActionsTabItemViewController receives a tab items relationship segue triggered by DetailTabViewController in Main.storyboard. At launches after the first launch, it is only instantiated if the state restoration mechanism restores it; otherwise, it is instantiated when the user selects the Actions tab view item. It calls loadView() to instantiate and load the tab view item's view.

import Cocoa

class ActionsTabItemViewController: NSViewController {

    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
