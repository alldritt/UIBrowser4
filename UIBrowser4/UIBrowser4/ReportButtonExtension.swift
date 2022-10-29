//
//  ReportButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-15.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The ReportButtonExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Report button.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     Opens a report about the current UI element when the user clicks the Report button.
     
     - note: The equivalent UI Browser 2 method is \-\[PFBrowserController showElementWindowAction:\], also called in \-\[PFScreenReaderController viewReportButtonAction:\].
     
     - parameter sender: The Report button that sent the action.
     */
    @IBAction func showReport(_ sender: NSButton) {
        // Action method connected from the Report button to First Responder in Main.storyboard.
        
        // TODO: Implement this based on UI Browser 2.
        // Show the report.
        print("The Report button's action method is not yet written.")
    }
    
}
