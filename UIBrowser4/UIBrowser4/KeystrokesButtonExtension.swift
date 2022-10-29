//
//  KeystrokesButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-20.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The KeystrokesButtonExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Keystrokes button.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Opens a [[[window???]]] to send keystrokes to the target application when the user clicks the Keystrokes button.
     
     - note: There is no equivalent UI Browser 2 method because Keystrokes were sent in a drawer.
     
     - parameter sender: The Keystrokes button that sent the action.
     */
    @IBAction func showKeystrokes(_ sender: NSButton) {
        // Action method connected from the Keystrokes button to First Responder in Main.storyboard.
        
        // TODO: Implement this based on UI Browser 2.
        // Open the [[[window???]]].
        print("The Keystrokes button's action method is not yet written.")
    }
    
}
