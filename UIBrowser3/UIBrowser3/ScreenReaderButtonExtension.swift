//
//  ScreenReaderButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-18.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The ScreenReaderButtonExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's ScreenReader button.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Switches to the Screen Reader when the user clicks the Screen Reader button.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController screenReaderMenuAction:\], also called in \-\[PFScreenReaderController screenReaderButtonAction:\].
     
     - parameter sender: The Report button that sent the action.
     */
    @IBAction func showScreenReader(_ sender: NSButton) {
        // Action method connected from the Screen Reader button to First Responder in Main.storyboard.
        
        // TODO: Implement this based on UI Browser 2.
        // Switch to the Screen Reader.
        print("The Screen Reader button's action method is not yet written.")
    }
    
}
