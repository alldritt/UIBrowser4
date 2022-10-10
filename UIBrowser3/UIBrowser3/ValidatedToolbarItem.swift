//
//  ValidatedToolbarItem.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-03-27.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//
//  Version 3.0.0
//

import Cocoa

/**
 ValidatedToolbarItem.swift implements the ValidatedToolbarItem subclass of NSToolbarItem for view-based toolbar items in the main window's toolbar for validation.
 
 The toolbar is one of two areas in the window, located above the content view area.
 
 The toolbar items contain the Target pop-up button to choose the current running application target, the Activate button to bring the current running application target to the front, a hidden static text view made visible at launch if UI Browser is unregistered to show that it is a "TRIAL VERSION", an Access button to open *System Preferences* to enable or disable accessibility, and a Detail button to expand and collapse the detail split view item. The toolbar items are managed in several extensions on MainWindowController, each dedicated to a specific toolbar item, and in this subclass of NSToolbarItem which handles validation of each toolbar item requiring validation. The extensions are in TargetMenuExtension.swift, ActivateButtonExtension.swift, TrialVersionExtension.swift, AccessibilitButtonExtension.swift and DetailButtonExtension.swift.
 
 The toolbar items' view-based controls are implemented in MainWindowController. As a result, the controls are in the responder chain. Their action methods are implemented in toolbar item extensions on MainWindowController.swift. Their outlets are declared in MainWindowController.swift rather than the toolbar item extensions because extensions may not contain stored properties.
 
 The toolbar's toolbar items are not user configurable, and MainWindowController therefore does not conform to NSToolbarDelegate.
*/

/**
 The ValidatedToolbarItem subclass of NSToolbarItem overrides the validate() method, as required to validate view-based toolbar items.
 
 The Target pop-up button, Activate button and Access button are set to class ValidatedToolbarItem in Main.storyboard. The Trial Version field, Float button and Detail button are not because they are enabled always and do not require validation.
 */
class ValidatedToolbarItem: NSToolbarItem {

    /**
     The validate() method is called automatically because Main.storyboard sets the class of the validated toolbar items to ValidatedToolbarItem and enables their Autoactivates Behavior. See Apple's NSToolbarItemValidation protocol documentation, which says "If you want to validate a custom view item, then you have to subclass NSToolbarItem and override validate()." See also https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Toolbars/Tasks/ValidatingTBItems.html#//apple_ref/doc/uid/20000753, which says "To implement validation for a view item, you must subclass NSToolbarItem and override validate (because NSToolbarItem’s implementation of validate does nothing for view items). In your override method, do the validation specific to the behavior of the view item and then enable or disable whatever you want in the contents of the view accordingly. If the view is an NSControl you can call setEnabled:, which will in turn call setEnabled: on the control." NSToolbarItem can have only one subclass for a given toolbar, and the several toolbar items of that subclass are distinguished by their item identifiers or tags.
     
     The toolbar's Target pop-up button, Activate button and Access button are set to Class ValidatedToolbarItem in Main.storyboard. The Float button and Detail button are not because they are always enabled.
     */
    override func validate() {
        // Override method enables and disables each main toolbar item and sets the title of the Access button.
        
        guard let authorizer = (NSApp.delegate as! AppDelegate).accessAuthorizer else {
            isEnabled = false
            return
        }
        
        switch tag {
        case 0: // Target pop-up button
            // In this version of UI Browser, the Target pop-up button is always enabled because its No Target menu item is always enabled. Its other menu items are disabled in TargetMenuExtension.swift if access is not authorized. The Target pop-up button is set to ValidatedToolbarItem in case a future version of UI Browser needs to disable it always.
            isEnabled = true
        case 1: // Activate button
            isEnabled = authorizer.isAccessEnabled && MainContentViewController.sharedInstance.runningApplicationTarget != nil
        case 2: // Access button
            if let button = view as? NSButton {
                button.title = authorizer.isAccessEnabled ? NSLocalizedString("Deny Access…", comment: "Button title to deny access") : NSLocalizedString("Grant Access…", comment: "Button title to grant access")
            }
            isEnabled = true
        case 3: // Float button
            if let button = view as? NSButton {
                button.state = (MainWindowController.sharedInstance.window as! NSPanel).isFloatingPanel ? .on : .off
            }
            isEnabled = true
       default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }

}
