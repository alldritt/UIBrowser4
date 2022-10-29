//
//  AppDelegate.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-09.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

import Cocoa
import PFAssistiveFramework4 // TODO: TESTING
import PFAccessibilityAuthorizer2

/**
 *Main.storyboard*'s *Application Scene* contains UI Browser's shared *Application* object with its *Main Menu* and *AppDelegate* objects. *Info.plist* designates *Main.storyboard* as the application's `NSMainStoryboardFile`, so the standard main function loads *Main.storyboard* and its *Application*, *Main Menu* and *AppDelegate* objects at launch. *Main.storyboard* designates `MainWindowController` as its *Initial Controller* (this is the default setting; the *Is Initial Controller* setting is selected in the *MainWindowController Scene*'s Attributes inspector). It therefore also instantiates `MainWindowController` at launch. See `MainWindowController` for further flow of excecution.
 
 `AppDelegate` conforms to the `NSApplicationDelegate` protocol, and it is connected to the *Application* object's `delegate` property in *Main.storyboard*. `AppDelegate` also conforms to the `NSMenuDelegate` protocol to respond to menu items in the Application's main menu bar, but it may call methods in `MainToolbarController`, `MainContentViewController` or subcontrollers when menus or other controls that do identical work exist in the main window.
 
 The user's first step after launching UI Browser is to choose a target in order to examine, monitor and control the User Interface elements in the target's accessibility hierarchy. UI Browser's model object is `ElementDataModel`, an array of arrays of dictionaries representing the hierarchy, and the current running application target always provides the root UI element of the current hierarchy. The user chooses the target by using the Target menu in UI Browser's main menu bar or the identical Target menu in the main window toolbar's Target pop-up button. UI Browser updates the main menu bar's Target menu when it is opened by calling `AppDelegate`'s `menuNeedsUpdate(_:)` `NSMenuDelegate` protocol method, which in turn calls `MainContentViewController`'s `updateTargetMenu(_:)` utility method (in *TargetMenuExtension.swift*) to do the work. `MainContentViewController` also implements the `menuNeedsUpdate(_:)` `NSMenuDelegate` protocol method. UI Browser updates the identical menu in the main window toolbar's Target pop-up button when it is opened by calling the `MainContentViewController`'s `menuNeedsUpdate(_:)` `NSMenuDelegate` protocol method, which also calls the same `updateTargetMenu(_:)` utility method to do the work.
 
 `MainContentViewController`'s `updateTargetMenu(_:)` method sets represented objects and action methods for both Target menus' menu items. All of these action methods and their supporting utility methods are implemented in `MainContentViewController` (in *TargetMenuExtension.swift*), which mediates between the model object and the main window's views in accordance with the *MVC* design pattern. `MainContentViewController` declares a `runningApplicationTarget` instance property, which the action methods update based on the user's choice of a target from either Target menu. `MainContentViewController`'s `updateTargetMenu(_:)` method uses its `runningApplicationTarget` value to place a checkmark on the menu item representing the current selection.
 
 See `MainWindowController` and `MainContentViewController` for additional information.
 */
@NSApplicationMain // implicitly calls a standard main function
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    // MARK: - PROPERTIES
    // MARK: AccessAuthorizer
    
    /// The *PFAccessibilityAuthorizer2* framework's `AccessAuthorizer` class handles accessibility authorization. See documentation in the *PFAccessibilityAuthorizer2* framework for usage.
    var accessAuthorizer: AccessAuthorizer? // created and initialized in applicationWillFinishLaunching(_:)
    
    // MARK: OUTLETS
    
    /// The Target menu in UI Browser's main menu bar.
    @IBOutlet weak var targetMenu: NSMenu! // connected to the main menu bar's Target menu in Main.storyboard
    
    // MARK: - ACTION METHODS
    // Action methods for menu items in the menubar.
    
    // MARK: Application menu
    
    /**
     Opens the *Security & Privacy* pane of *System Preferences* to the *Privacy* tab's *Accessibility* list when the user selects or deselects the Accessibility checkbox, adding UI Browser to the list if necessary.
     
     Access cannot be granted or denied programmatically for security reasons. This action method updates and opens the *Accessibility* list for the user. The user must then unlock the preference pane with an administrator password, scroll to the *UI Browser* checkbox, and select or deselect it to enable or disable accessibility manually.
     
     UI Browser uses the `PFAccessibilityAuthorizer2` framework to manage accessibility authorization.
     
     - note: The equivalent UI Browser 2 method is `-[PFBrowserController setAccessAction:]`.
     
     - parameter sender: The Accessibility checkbox that sent the action.
     */
   @IBAction func openAccessibilityList(_ sender: NSMenuItem) {
        // Action method connected from the UI Browser > Set Access... menu item to First Responder in Main.storyboard.

        // Open the System Preferences Accessibility list.
        accessAuthorizer?.openAccessibilityList(update: true)
    }

    
    // MARK: - DELEGATE METHODS
    // MARK: NSApplicationDelegate Protocol Support
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        // Registers initial user defaults and creates the AccessAuthorizer object.
        
        // Register initial user defaults. Swift 4 does not allow use of an Objective-C +initialize class method to do this.
        let initialDefaults: [String: Any] = [
            MASTER_TAB_VIEW_ITEM_DEFAULTS_KEY: MasterTabViewItemIndex.Browser.rawValue,
            //                ACCESS_TAB_VIEW_ITEM_IDENTIFIER_DEFAULTS_KEY: ATTRIBUTES_IDENTIFIER,
            DISPLAYS_BACKGROUND_APPLICATIONS_DEFAULTS_KEY: false,
            DISPLAYS_BACKGROUND_APPLICATIONS_SEPARATELY_DEFAULTS_KEY: false,
            CHOOSING_TARGET_ACTIVATES_APPLICATION_DEFAULTS_KEY: false,
            TERMINOLOGY_DEFAULTS_KEY: Terminology.raw.rawValue
        ]
        UserDefaults.standard.register(defaults: initialDefaults)
        
        // Create and initialize the AccessAuthorizer object implemented in the PFAccessibilityAuthorizer2 framework. It automatically prompts the user to grant access for UI Browser when UI Browser finishes launching if access is not already authorized. It is also used in TargetMenuExtension to prompt the user to grant access when either Target menu is closed if access is not already authorized, and in AccessButtonExtension to open the System Preferences Accessibility list when the Access button is clicked.
        // The designated initializer is used rather than calling the convenience initializer with the sheets parameter set to false because the designated initializer is more efficent. Either approach forces AccessAuthorizer to present its access alerts as application-modal dialogs instead of document-modal sheets, to facilitate UI Browser's ability to open multiple windows. (Note that with UI Browser's MainWindow declared as a subclass of NSPanel so its windows can float, AccessAuthorizer uses dialogs instead of sheets anyway.)
        accessAuthorizer = AccessAuthorizer() // designated initializer
        
        // If System Preferences is not running, register to observe PFAccessibilityAuthorizer2 framework's didChangeAccessStatusNotification notification in order to terminate System Preferences after the user grants or denies access. Also unregisters as an observer if the user does not toggle access within a short time. This code is identical to the code in the AccessButtonExtension toggleAccess(_:) action method to terminate System Preferences.
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences").isEmpty {
            // System Preferences is not running, so register as an observer and arrange to unregister after a short time.
            NotificationCenter.default.addObserver(self, selector: #selector(didToggleAccess(_:)), name: AccessAuthorizer.didChangeAccessStatusNotification, object: nil)
            perform(#selector(removeToggleAccessObserver), with: nil, afterDelay: 60.0)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // TODO: Remove if unused.
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // TODO: Remove if unused.
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Set the color of appropriate buttons to match the system current tint after the application becomes active. This also sets the appropriate color when the application launches. UI Browser must use the applicationDidBecomeActive(_:) delegate method instead of applicationWillBecomeActive(_:) because the MainContentViewController.systemTintDidChange(_:) notification method that it calls tests the current state of the isActive property.
        MainContentViewController.sharedInstance.systemTintDidChange(notification)
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        // Set the color of appropriate buttons to graphite after the application becomes inactive. UI Browser must use the applicationDidBecomeActive(_:) delegate method instead of applicationWillBecomeActive(_:) because the systemTintDidChange() notification method that it calls tests the current state of the isActive property.
       MainContentViewController.sharedInstance.systemTintDidChange(notification)
    }
    
    // MARK: AccessAuthorizer Support
    // These notification methods are identical to those in AccessButtonExtension.swift. AppDelegate is registered to observe PFAccessibilityAuthorizer2 framework's didChangeAccessStatusNotification notification in appplicationWillFinishLaunching(_:).
    
    @objc func didToggleAccess(_ notification: NSNotification) {
        // Notification method called when the user toggles access, but only if System Preferences was not running when the user launched UI Browser. The observer was added in applicationWillFinishLaunching(_:) if System Preferences was not running. The observer is removed here when the user toggles access, or in removeToggleAccessObserver() if the user does not toggle access within a short time after launching UI Browser.
        
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
        // Remove the observer if the user did not toggle access within a short time after launching UI Browser.
        NotificationCenter.default.removeObserver(self, name: AccessAuthorizer.didChangeAccessStatusNotification, object: nil)
    }

    // MARK: NSMenuDelegate Protocol Support
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        // Called when the user clicks the Target menu in the menu bar to choose a target. It populates the Target menu before it opens by calling updateTargetMenu(_:) in TargetMenuExtension, just as TargetMenuExtension's targetPopUpButtonWillPopUp(_:) notification method does when the user clicks the Target pop-up button. This method then uses techniques designed specifically for menus to ensure that the correct menu item shows a check mark when it opens.
        // The main menu bar was instantiated and connected when Main.storyboard was automatically loaded at launch. Its Target Menu contains no menu items in the Main.storyboard file but is instead populated at run time with some fixed menu items and menu items for whatever applications are running when the user opens the menu. Main.storyboard must contain a main menu bar with a Target menu bar item, and the menu bar item's associated Target submenu's delegate outlet must be connected to AppDelegate.
        
        if menu == targetMenu {
            
            /// The content view controller for UI Browser's main window.
            let contentViewController = MainContentViewController.sharedInstance
            
            /// The window controller for UI Browser's main window.
            let windowController = MainWindowController.sharedInstance
            
            // Populate the Target menu.
            windowController!.updateTargetMenu(menu)
            
            // Turn on the state value of the current running application target menu item, or the "No Target" or "SystemWide Target" menu item, in order to display a checkmark on it reflecting the current selection.            
            if contentViewController!.runningApplicationTarget == nil {
                if contentViewController!.currentElementData == nil || contentViewController!.currentElementData!.isEmpty {
                    menu.item(withTag: NO_TARGET_MENU_ITEM_TAG)!.state = NSControl.StateValue.on
                } else {
                    menu.item(withTag: SYSTEMWIDE_TARGET_MENU_ITEM_TAG)!.state = NSControl.StateValue.on
                }
            } else {
                let itemName = contentViewController!.displayNameForTargetApplication() // may be empty if an error occurs
                if let menuItem = menu.item(withTitle: itemName) {
                    menuItem.state = NSControl.StateValue.on
                } else {
                    // The current running application target is not in the menu, so add it. This happens when UI Browser's preferences are set to show only regular applications in the Target menu, and the current running application target is a background application (other than the Dock or systemUIServer) chosen in the Target menu's Open panel.
                    // This menu item does not need a represented object because the user is prevented from choosing the current running application target in the Target menu's list of running applications. An action method is connected only to cover the possibility that UI Browser might perform validation on running applications listed in the menu.
                    menu.addItem(NSMenuItem.separator())
                    menu.addItem(withTitle: itemName, action: #selector(windowController!.chooseRunningTarget(_:)), keyEquivalent: "")
                    menu.item(withTitle: itemName)!.state = NSControl.StateValue.on
                }
            }
        }
    }
    
/*
     // FIXME: This is called at launch while a request access sheet or dialog is already open or after it is dismissed...
     // ... resulting in duplicate alerts, even though no menu was opened or closed. Mysterious.
     func menuDidClose(_ menu: NSMenu) {
        // Called after the user dismisses any menu controlled by the application delegate, whether or not a menu item was chosen. The only menu the method acts upon is the Target menu in the main menu bar. The alert is presented to remind the user that UI Browser can do nothing, not even choose a target application, without enabling access.
        // Presents the `AccessAuthorizer` Request Access alert when the Target menu is dismissed, if accessibility is disabled.

        if menu == targetMenu {
            accessAuthorizer!.requestAccess()
        }
    }
*/
    
}
