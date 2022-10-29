//
//  HighlightCheckboxExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-18.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The HighlightCheckboxExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Highlight checkbox.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Highlights the current UI element in the target application when the user selects the Highlight checkbox.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController highlightAction:\], called in \-highlightButtonAction:, \-highlightMenuAction: and \-highlightDoubleClickAction:.
     
     - parameter sender: The Highlight checkbox that sent the action.
     */
    @IBAction func highlightElement(_ sender: NSButton) {
        // Action method connected from the Highlight checkbox to First Responder in Main.storyboard.
        
        // TODO: Implement this based on UI Browser 2.
        // Highlight the current element.
        print("The Highlight checkbox's action method is not yet written.")
        
        if MainContentViewController.sharedInstance.runningApplicationTarget != nil {
            // The Highlight checkbox is always enabled to allow the user to set up a working session before enabling access or choosing a target, but there is nothing to be highlighted unless access is enabled and a target has been chosen.
            (sender.state == NSControl.StateValue.off) ? unhighlightCurrentElement() : highlightCurrentElement()
        }
    }
    
    // MARK: - SUPPORT METHODS
    
    func highlightCurrentElement() {
        print("HIGHLIGHT")
    }
    
    func unhighlightCurrentElement() {
        print("UNHIGLIGHT")
    }
    
}
