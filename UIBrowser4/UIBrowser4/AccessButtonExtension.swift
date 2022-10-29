//
//  AccessButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-11-07.
//  Copyright © 2017-2020 PFiddlesoft. All rights reserved.
//
//  Version 3.0.0
//

import Cocoa
import PFAccessibilityAuthorizer2

/**
 The AccessButtonExtension.swift file implements an extension on MainWindowController dedicated to the Access button in the toolbar.
 */
extension MainWindowController {
    
    // MARK: - ACTION METHODS
    
    /**
     Launches or activates *System Preferences* and opens the *Accessibility* list in the *Privacy* tab of the *Security & Privacy* pane when the user clicks the Access button or chooses the UI Browser > Access menu item, adding a UI Browser checkbox to the Accessibility list if necessary.
     
     Access cannot be granted or denied programmatically in macOS for security reasons. This action method opens System Preferences for the user. To toggle access, the user must then manually unlock the *Security & Privacy* pane with an administrator password, scroll to the *UI Browser* checkbox in the Accessibility list, and select or deselect it.
     
     If System Preferences was already running when the user clicked the Access button, it is left running after the user toggles access, on the assumption that the user is currently using System Preferences for general purposes. If it was not already running, System Preferrences will be terminated automatically for convenience when the user toggles access, on the assumption that the user has no other current use for it. However, if the user does not toggle access within a short time after System Preferences is launched, System Preferences is left running after the user toggles access, on the assumption that the user was distracted or is unsure what to do and might want to toggle access back to its previous status.
     
     An alert sheet is presented confirming that access was granted or denied. The alert can be suppressed by the user.
     
     Identical code to terminate System Preferences if it is opened at launch in response to Access Authorizer's requestAccess() method is implemented in AppDelegate applicationWillFinishLaunching(_:).
     
     UI Browser uses the `PFAccessibilityAuthorizer2` framework to manage accessibility.
     
     - note: The equivalent UI Browser 2 method is `-[PFBrowserController setAccessAction:]`.
     
     - parameter sender: The Access button or the UI Browser > Access menu item that sent the action.
     */
     @IBAction func toggleAccess(_ sender: AnyObject) {
        // Action method connected from the Access button and the UI Browser > Access menu item to First Responder in Main.storyboard.
        
        // If System Preferences is not running, register to observe PFAccessibilityAuthorizer2 framework's didChangeAccessStatusNotification notification in order to terminate System Preferences after the user grants or denies access. Also unregisters as an observer if the user does not toggle access within a short time.
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences").isEmpty {
            // System Preferences is not running, so register as an observer and arrange to unregister after a short time.
            NotificationCenter.default.addObserver(self, selector: #selector(didToggleAccess(_:)), name: AccessAuthorizer.didChangeAccessStatusNotification, object: nil)
            perform(#selector(removeToggleAccessObserver), with: nil, afterDelay: 60.0)
        }

        // Launch or activate System Preferences, and open the Accessibility list in the Security & Privacy pane.
        let appDelegate = NSApp.delegate as! AppDelegate
        appDelegate.accessAuthorizer!.openAccessibilityList(update: true)
    }
    
    @objc func didToggleAccess(_ notification: NSNotification) {
        // Notification method called when the user toggles access, but only if System Preferences was not running when the user clicked the Access button. The observer was added in the toggleAccess action method if System Preferences was not running. The observer is removed here when the user toggles access, or in removeToggleAccessObserver() if the user does not toggle access within a short time after clicking the Access button.
        
        // Unregister as an observer.
        NotificationCenter.default.removeObserver(self, name: AccessAuthorizer.didChangeAccessStatusNotification, object: nil)
        
        // Terminate the System Preferences application.
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences")
        if !runningApps.isEmpty {
            // System Preferences is running, so terminate it.
            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences")[0].terminate()
        }
    }
    
    @objc func removeToggleAccessObserver() {
        // Remove the observer if the user did not toggle access within a short time after clicking the Access button.
        NotificationCenter.default.removeObserver(self, name: AccessAuthorizer.didChangeAccessStatusNotification, object: nil)
    }

}
