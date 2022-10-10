//
//  FollowFocusCheckboxExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-18.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The FollowFocusCheckboxExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Follow Focus checkbox.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Follows focus in the target application when the user selects the Follow Focus checkbox.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController followFocusButtonAction:\], also called in \-followFocusMenuAction:.
     
     - parameter sender: The FollowFocus checkbox that sent the action.
     */
    @IBAction func followFocus(_ sender: NSButton) {
        // Action method connected from the FollowFocus checkbox to First Responder in Main.storyboard.
        
        // TODO: Implement this based on UI Browser 2.
        // Select the element in the target application that currently has keyboard focus.
        print("The Follow Focus checkbox's action method is not yet written.")
    }
    
}
