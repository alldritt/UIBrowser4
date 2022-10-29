//
//  AppleScriptButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-18.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The AppleScriptButtonExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Generate AppleScript button.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Generates an AppleScript statement when the user choose a menu item in the Generate AppleScript pop-up button.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController generateAppleScriptAction:\].
     
     - parameter sender: The Generate AppleScript pop-up button that sent the action.
     */
    @IBAction func generateAppleScript(_ sender: NSButton) {
        // Action method connected from the Generate AppleScript pop-up button to First Responder in Main.storyboard.
        
        // TODO: Implement this based on UI Browser 2. The action method actually has to do with the selected pop-up menu item.
        // Open the Generate AppleScript pop-up button.
        print("The Generate AppleScript button's action method is not yet written.")
    }
    
}
