//
//  FloatButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-24.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The FloatButtonExtension.swift file implements an extension on MainWindowController dedicated to UI Browser's Float button.
 */
extension MainWindowController {
    
    // MARK: - ACTION METHODS
    
    /**
     Causes the UI Browser window to float when the user clicks the Float button or chooses the Window > Float menu item in the menu bar.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController floatButtonAction:\].
     
     - parameter sender: The Float button or the Window > Float menu item that sent the action.
     */
    @IBAction func float(_ sender: AnyObject) {
        // Action method connected from the Float button and the Window > Float menu item to First Responder in Main.storyboard.
        
        // Float the window.
        (window as! NSPanel).isFloatingPanel = (sender.state == NSControl.StateValue.off) ? false : true
    }
    
}
