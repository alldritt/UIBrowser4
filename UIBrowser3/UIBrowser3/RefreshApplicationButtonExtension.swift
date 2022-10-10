//
//  RefreshApplicationButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-20.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The RefreshApplicationButtonExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Refresh Application button.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Refreshes the application's path when the user clicks the Refresh Application button, and refreshes it to root if the Shift key is down.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController applicationRefreshAction:\], also called in \-\[PFScreenReaderController viewReportButtonAction:\].
     
     - parameter sender: The Refresh Application button that sent the action.
     */
    // TODO: Figure out why this is not called when UI Browser was just launched and no target was yet chosen.
    @IBAction func refreshApplication(_ sender: NSButton) {
        // Action method connected from the Refresh Application button to First Responder in Main.storyboard.
        
        // Refresh the application path.
        print("The Report button's action method is written but not adequately tested.")

        if NSApp.currentEvent!.modifierFlags.contains(.shift) && sender == refreshApplicationButton {
            // Holding down the Shift key resets UI Browser to the root application level by selecting the current target, so the data source methods take care of updating the data model; [[[test sender so shift key won't affect other calls to this method (e.g., when resetting name style preference)???]]].
            refreshApplicationToRoot(sender)
        } else {
            refreshApplication()
            /*
             if (sender == [[self preferencesWindowController] terminologyRadioCluster]) {
             // Refresh name style of all columns if preference is changed; test sender so this time isn't wasted when not resetting name style preference.
             for (NSInteger idx = 0; idx <= [[self elementBrowser] lastColumn]; idx++) {
             [[self elementBrowser] reloadColumn:idx];
             }
             }
             */            }
    }
    
}
