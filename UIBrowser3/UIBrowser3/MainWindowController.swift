//
//  MainWindowController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

import Cocoa

/**
 `MainWindowController` is designated as the *Initial Controller* (the default setting) in its Attributes inspector in *Main.storyboard*, and it is therefore instantiated when *Main.storyboard* is loaded at application launch. Its `loadWindow()` method is called automatically to instantiate and load the main window. `MainWindowController`'s `window` outlet is automatically connected to the window and the window's `delegate` outlet is manually connected to `MainWindowController` in *Main.storyboard*. `MainWindowController` triggers the window content segue automatically connected to `MainContentViewController` in *Main.storyboard*. See `MainContentViewController` for further flow of excecution.
 
 The window has two areas, the toolbar and the content view. The toolbar is at the top of the window below the title bar, and it contains several toolbar items of global import. The toolbar is managed by MainWindowController, which declares the toolbar items' IBOutlets, and by several extensions on MainWindowController that manage the individual toolbar items. The content view is at the bottom of the window and is filled by the main split view. The content view is managed by MainContentViewController and the controllers for the split view, its split view items, and their tab item views.
 
 The settings that are controlled by the toolbar items impact UI elements in the window's content view. For this reason, MainWindowController, its extensions for individual toolbar items, and the subclasses of NSToolbarItem are limited to management of the toolbar items themselves, while their more general impacts are managed by MainContentViewController. MainContentViewController also manages the toolbar items in response to global changes.
 
 Toolbar item validation is handled by overriding NSToolbarItem in ValidatedToolbarItem.swift, as described in <https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Toolbars/Tasks/ValidatingTBItems.html#//apple_ref/doc/uid/20000753-BAJGFHDD>. Validation of UI elements in the content view is handled separately by UI Browser's UserControlValidations protocol and its `ValidatedUserControlItem` subprotocol of the `NSValidatedUserInterfaceItem` formal protocol, both of which are declared in UserControlValidation.swift.
 
 Validation of menu items in the menubar that have the same action as a toolbar item is handled by the validateMenuItem(_:) NSMenuItemValidation formal protocol method implemented here, in the target of the action method.
 */
class MainWindowController: NSWindowController, NSWindowDelegate, NSMenuDelegate, NSMenuItemValidation {

    // MARK: PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    /// A type property that gives access to this object from any other object by referencing `MainWindowController.sharedInstance`. `NSApp.mainWindow!.windowController as! MainWindowController` cannot be used because `mainWindow` might be nil when the application is inactive or hidden.
    static private(set) var sharedInstance: MainWindowController! // set to self in windowDidLoad(); it was created in Main.storyboard at launch
    
    // See https://cocoa-dev.apple.narkive.com/u0relSKc/safe-cross-references-between-scenes-in-an-os-x-storyboard.
    /// An instance property that gives access to the `MainContentViewController` from this object.
    lazy var mainContentViewController: MainContentViewController? = {
        window?.contentViewController as? MainContentViewController
    }()

    // MARK: IBOutlets for the toolbar
    // The toolbar items' outlets are declared here, and their action methods and other code are in several toolbar item extensions on the main window controller. Their outlets are declared here rather than the toolbar item extensions because extensions may not contain stored properties. Other views and controls are in the main content view, in the main and detail split views and their tab item views, all of which have their own controllers.
    
    // TODO: add the "TRIAL VERSION" field
    
    /// IBOutlet property for the toolbar's Target pop-up button.
    @IBOutlet weak var targetPopUpButton: NSPopUpButton!
    
    /// IBOutlet property for the toolbar's Activate button.
    @IBOutlet weak var activateButton: NSButton!
    
    /// IBOutlet property for the toolbar's Access button.
    @IBOutlet weak var accessibilityButton: NSButton!
    
    /// IBOutlet property for the toolbar's Float button.
    @IBOutlet weak var floatButton: NSButton!
    
    /// IBOutlet property for the toolbar's Detail button.
    @IBOutlet weak var detailButton: NSButton!
    
    // MARK: - INITIALIZATION
    
    // MARK: NSWindowController Override Methods
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Set the shared type property to self to give access to this object from any other object by referencing MainWindowController.sharedInstance.
        MainWindowController.sharedInstance = self
        
        // Set the window title and the Window menu's window menu item title to No Target.
        updateWindowTitle()
        
        // Add the No Target menu item to the Target pop-up button's menu when the window loads because the menu does not contain any menu items in Main.storyboard. NSPopUpButton's setTitle(_:) method need not be called because this adds only one item to the empty menu and it automatically displays as the title. MainWindowController is set as the target pop-up button's delegate here so the menuDidClose(_:) delegate method (in TargetMenuExtension.swift) will be called.
        targetPopUpButton.addItem(withTitle: NSLocalizedString(NO_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to deselect target")) // no target has been chosen yet
        targetPopUpButton.menu?.delegate = self
        
        // Register as an observer of the targetPopUpButton's willPopUpNotification notification in order to update the Target menu as the user opens it.
        NotificationCenter.default.addObserver(self, selector: #selector(targetPopUpButtonWillPopUp(_:)), name: NSPopUpButton.willPopUpNotification, object: targetPopUpButton)
        
        // Set the main window's initial first responder.
        // This is not needed given the current layout of the main window, because the same thing is accomplished automatically based on the position of targetPopUpButton relative to the other UI elements in the window. We nevertheless call it here in case the layout is changed in the future, because targetPopUpButton should still be the first responder.
        window!.initialFirstResponder = targetPopUpButton
    }
    
    // MARK: - DELEGATE METHODS
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Called when the user closes the window, not when the user explicitly quits the application.
        // Returns false to prevent the window from closing and, in the next iteration of the run loop, terminates the application. This technique allows the user to terminate the application by closing the main window even if other windows and panels remain open. It takes the place of returning true in AppDelegate's applicationShouldTerminateAfterLastWindowClosed(_:) delegate method, which does not terminate the application when the main window is closed if other windows (as opposed to panels) remain open. Using this technique is appropriate for a library-style or "shoebox" application like UI Browser that has no standalone windows other than the main window, but only secondary or auxiliary windows. This technique avoids having to make all secondary windows panels.
        // Because the window remains open until the application is terminated a moment later, the frameAutosaveName mechanism will automatically use its last size and position when the application is relaunched and reopens the window. If, instead of using this technique, AppDelegate's applicationShouldTerminateAfterLastWindowClosed(_:) delegate method were implemented to return true, the frameAutosaveName mechanism would be unable to save the frame if the user quit by closing the main window because the window would no longer be open. As a result, the window would reopen at its default size and position when the application was relaunched; the window would only reopen at its saved size and position if the user quit by using the Quit command while the window was open.
        // The Autosave setting in the window's storyboard scene is set to "MainWindowAutosaveName". In addition, the Behavior - Restorable setting is turned on (the default setting), which allows the frameAutosaveName mechanism to work and also automatically saves the position and collapsed status of the main split view. Additional code is required to implement autosaving and restoration of the selected tab view items in the tab views; see restorableStateKeyPaths() in TopTabViewController and BottomTabViewController.
        
        if window != nil {
            NSApp.perform(#selector(NSApplication.terminate(_:)), with: self, afterDelay: 0.0)
            return false // keep main window open until "terminate:" selector is performed in next iteration of run loop
        }
        return true
    }
    
    // MARK: - WINDOW MANAGEMENT
    
    // TODO: Add application icons
    func updateWindowTitle() {
        // Updates UI Browser's main window title and the Window menu's window menu item title to UI Browser's display name followed by an em dash followed by the current running application target's display name or path, or followed by "No Target" or "SystemWide Target" if there is no current running application target.
        // Called from windowDidLoad() at launch and from MainContentViewController.updateApplication(forNewTarget:usingTargetElement:) after the user has chosen a new target.
        // Equivalent UI Browser 2 code is inlined in many methods in many classes.

        guard let UIBrowserPath = NSRunningApplication.current.bundleURL?.path,
            let UIBrowserWindow = window else {
                assertionFailure("Failed to obtain UI Browser's bundle path, display name or window needed to set its main window title.")
                return
        }

        /// UI Browser's display name (or "UIBrowser3" when debugging in Xcode).
        let UIBrowserName = FileManager.default.displayName(atPath: UIBrowserPath)
        
        /// The target's menu item title.
        let targetName: String
        
        // Set targetName to the display name of the current running application, or 'No Target" or "SystemWide Target".
        if mainContentViewController!.runningApplicationTarget == nil {
            if mainContentViewController!.currentElementData == nil || mainContentViewController!.currentElementData!.isEmpty {
                targetName = NSLocalizedString(NO_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to deselect target") // no target has been chosen yet
            } else {
                targetName = NSLocalizedString(SYSTEMWIDE_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to choose the SystemWide Target")
            }
        } else {
            targetName = mainContentViewController!.displayNameForTargetApplication() // may be empty if an error occurs
        }

        /// The title for UI Browser's window.
        let windowTitle: String
        if targetName.isEmpty {
            windowTitle = UIBrowserName
        } else {
            windowTitle = UIBrowserName + " \u{2014} " + targetName // \u{2014} is Unicode em dash
        }
        
        // Set the window title and the Window menu's window menu item.
        UIBrowserWindow.title = windowTitle
        NSApp.changeWindowsItem(UIBrowserWindow, title: windowTitle, filename: false)
    }
    
    // MARK: - PROTOCOL SUPPORT
    
    // MARK: NSMenuItemValidation protocol
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Protocol method per the NSMenuItemValidation formal protocol to enable or disable menu items.
        
        guard let authorizer = (NSApp.delegate as! AppDelegate).accessAuthorizer else {
            return false
        }
        
        // Most menu items are disabled if accessibility is not authorized.
        switch menuItem.action {
        case #selector(toggleAccess(_:)):
            menuItem.title = authorizer.isAccessEnabled ? NSLocalizedString("Deny Access…", comment: "Menu item title to deny access") : NSLocalizedString("Grant Access…", comment: "Menu item title to grant access")
            return true
        case #selector(float(_:)):
            menuItem.state = (window as! NSPanel).isFloatingPanel ? .on : .off
            return true
        default:
            return true
        }
    }
    
}
