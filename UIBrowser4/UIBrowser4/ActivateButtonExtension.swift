//
//  ActivateButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-11-06.
//  Copyright © 2017-2020 PFiddlesoft. All rights reserved.
//
//  Version 3.0.0
//

import Cocoa

 /**
 The ActivateButtonExtension.swift file implements an extension on MainWindowController dedicated to UI Browser's Activate button.
 */
extension MainWindowController {

    // MARK: - ACTION METHODS
    
    /**
     Brings the current target application to the front when the user clicks the Activate button or chooses the Target > Activate Target menu item in the menu bar or the Target pop-up button.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController applicationActivateAction:\].
     
     - parameter sender: The Activate button or the UI Browser > Activate Target menu item that sent the action.
     */
     @IBAction func activateTarget(_ sender: AnyObject) {
        // Action method connected from the Activate button and the UI Browser > Activate Target menu item to First Responder in Main.storyboard.
        
        // Activate the target application.
        if let target = mainContentViewController!.runningApplicationTarget {
            target.activate(options: [.activateAllWindows, .activateIgnoringOtherApps]) // ignore return value
            
            if sender is NSMenuItem {
                // Restore the previous Target pop-up button title in case the user chose Activate Target in the Target pop-up button's menu.
                self.updateTargetPopUpButtonTitle()
            }
        }
    }
    
}
