//
//  TerminologyButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-20.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The TerminologyPopUpButtonExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Terminology pop-up button.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Chooses a terminology when the user clicks the Terminology button.
     
     - note: The equivalent UI Browser 2 method is \-\[PFPreferencesWindowController terminologyRadioClusterAction:\].
     
     - parameter sender: The Terminology pop-up button that sent the action.
     */
    @IBAction func chooseTerminology(_ sender: NSButton) {
        // Action method connected from the Terminology pop-up button to First Responder in Main.storyboard.
        
        // TODO: Implement this based on UI Browser 2.
        // Pop up the menu.
        print("The Terminology button's action method is not yet written.")
    }
    
}
