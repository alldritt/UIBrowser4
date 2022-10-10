//
//  MasterTabViewSelectorExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-20.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Cocoa

/**
 The MasterTabViewSelectorExtension.swift file implements an extension on MasterSplitItemViewController dedicated to UI Browser's Master Tab View Selector segmented control.
 */
extension MasterSplitItemViewController {
    
    // MARK: - ACTION METHODS
    
    /**
     [[[Opens a report about the current UI element when the user clicks the Report button.???]]]
     
     - note: There is no equivalent UI Browser 2 method.
     
     - parameter sender: The Master Tab View Selector segmented control that sent the action.
     */
    @IBAction func showMasterTabItem(_ sender: Any?) {
        // Action method connected from the Master Tab View Selector segmented control and the View > UI Elements > Show menu item to First Responder in Main.storyboard. The segmented control items and menu items are tagged in Main.storyboard (0 for browser view, 1 for outline view and 3 for list view), but the segment tags are not needed here.
        
        // Show the chosen master tab view.
        print("The Master Tab View Selector segmented control's action method is written but not adequately tested.")
        if sender is NSSegmentedControl {
            masterTabViewController.selectedTabViewItemIndex = (sender as! NSSegmentedControl).selectedSegment
        } else { // if sender is NSMenuItem
            // The segmented control selection does not need to be set because it is bound to selectedTabViewItemIndex in Main.storyboard.
            masterTabViewController.selectedTabViewItemIndex = (sender as! NSMenuItem).tag
        }
        showView()
    }
    
}
