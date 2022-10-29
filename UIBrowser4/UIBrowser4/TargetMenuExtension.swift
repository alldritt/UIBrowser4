//
//  TargetMenuExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-09-01.
//  Copyright © 2017-2020 PFiddlesoft. All rights reserved.
//
//  Version 3.0.0
//

import Cocoa
import PFAssistiveFramework4
import PFAccessibilityAuthorizer2

/**
 The TargetMenuExtension.swift file implements an extension on MainWindowController dedicated to UI Browser's Target menu. UI Browser has two Target menus, one in the main menu bar and one in the Target pop-up button in the window's toolbar. They are identical, and each of them is referred to as the Target menu. Opening the menu bar's Target menu triggers the menuNeedsUpdate(_:) NSMenuDelegate delegate method in AppDelegate. Opening the Target pop-up button's menu triggers the targetPopUpButtonWillPopUp(_:) notification method in this extension. The code for populating the Target menu and handling its menu items is concentrated in this extension for convenience.
 
 The Target menu is populated, and its menu items' action methods and represented objects are set, in the updateTargetMenu(_:) utility method when the user opens the menu to choose a target. The Target menu is not provided with menu items in the Main.storyboard file because the menu lists applications that are running when the menu is opened. The updateTargetMenu(_:) method first populates the Target menu with the No Target menu item and NO_TARGET_MENU_ITEM_TAG tag at index 0, the SystemWide Target menu item and SYSTEMWIDE_TARGET_MENU_ITEM_TAG tag at index 1, and the Choose Target… menu item at index 3 following a separator. It adds the remaining menu items using titles that are the display names of running applications, or their paths if no name is available.
 
 On entry, an action method's sender is the menu item that the user chose. If the chosen menu item represents a running application, its representedObject is a dictionary with typealias RunningApplicationInfo containing the NSRunningApplication object that will become the target in the runningApplicationTarget stored instance property and its display name.
 
 The connected action method responds when the user (a) chooses the No Target menu item to deselect the current running application target, (b) chooses the SystemWide Target menu item to create an accessibility system-wide UI element and display it, (c) chooses the `Choose Target…` menu item to present an Open panel to select a new target from all applications installed on the computer whether or not running, or (d) chooses a menu item representing an application that is currently running. If the user chooses the `Choose Target…` menu item, an inline completion handler responds to the user's choice of the Open panel's Open or Cancel button. If the user chooses `Open` and the selected application is not already running, the completion handler attempts to launch it and handles any failure to launch. If the launch is successful, the completion handler relies on Key Value Observing (KVO) to monitor the "isFinishedLaunching" or "runningApplications" key path to handle completion of the launch. Whenever a chosen application is already running or is successfully launched, KVO observing is set up for the "isTerminated" key path to handle the new target's eventual termination.
 
 If the chosen application is running or is successfully launched, and it passes validation, these action methods call updateApplication(forNewTarget:usingTargetElement:). It cleans up the old target and prepares the new target. It then calls updateData(usingTargetElement:) to update UI Browser's ElementDataModel object by caching information about the new target as the root application UI element in the current accessibility hierarchy. If successful, it then calls updateView() to update UI Browser views that display information about the current accessibility hierarchy, including the browser, outline or list view in the master split view pane and the attributes, actions or notifications view in the detail split view pane. Among other things, updateView() calls selectElement(_:) to programmatically select the new target's application UI element in UI Browser's browser, outline or list view in the top split view pane, which causes UI Browser to update the ElementDataModel object and display the new target's child elements. UI Browser is then ready for the user to explore and manipulate the current accessibility hierarchy of the target, for example, by selecting UI elements in the browser, outline or list view using the mouse or keyboard.
 */
extension MainWindowController {
    
    /// The type of the represented object associated with running application menu items in the Target menu.
    typealias RunningApplicationInfo = [String: AnyObject] // a dictionary in the form [RUNNING_APPLICATION_KEY: NSRunningApplication, RUNNING_APPLICATION_DISPLAY_NAME_KEY: String?]

    // MARK: - ACTION METHODS
    
    /**
     Clears UI Browser's data and display when the user chooses No Target in the Target menu.
     
     When the user opened the Target menu, the `menuNeedsUpdate(_:)` `NSMenuDelegate` delegate method in `AppDelegate` or the `TargetPopUpButtonWillPopUp(_:)` notification method called the `updateTargetMenu(_:)` utility method to populate the Target menu in the main menu bar or the Target pop-up button's menu. The utility method programmatically connected this action method to the No Target menu item.
     
    *See also:* `chooseSystemWideTarget(_:)`, `chooseAnyTarget(_:)` and `chooseRunningTarget(_:)`.

     - note: The equivalent UI Browser 2 methods are \-\[PFBrowserController noTargetMenuItemAction:\] and \-\[PFBrowserController chooseApplicationPopUpAction:\] (the first if-else else branch).
     
     - parameter sender: The menu item that sent the action.
     */
    @objc func chooseNoTarget(_ sender: NSMenuItem) {
        
        // Update UI Browser for no target. This passes nil to both optional parameters.
        mainContentViewController!.updateApplication(forNewTarget: nil)
    }
    
    /**
     Clears UI Browser's data and display when the user chooses SystemWide Target in the Target menu, and displays the limited information that is made available by the accessibility API's system-wide UI element.
     
     When the user opened the Target menu, the `menuNeedsUpdate(_:)` `NSMenuDelegate` delegate method in `AppDelegate` or the TargetPopUpButtonWillPopUp(_:) notification method called the `updateTargetMenu(_:)` utility method to populate the Target menu in the main menu bar or the Target pop-up button's menu. The utility method programmatically connected this action method to the SystemWide Target menu item.
     
     *See also:* `chooseNoTarget(_:),`chooseAnyTarget(_:)` and `chooseRunningTarget(_:)`.
     
     - parameter sender: The menu item that sent the action.
     */
    @objc func chooseSystemWideTarget(_ sender: NSMenuItem) {

        // Update UI Browser for the SystemWide Target.
        if let systemWideElement = AccessibleElement.makeSystemWideElement() as? AccessibleElement {
            mainContentViewController!.updateApplication(forNewTarget: nil, usingTargetElement: systemWideElement)
        }
    }
    
    /**
     Updates UI Browser's data and display when the user chooses Choose Target… in the Target menu to present an Open panel and uses the Open panel to choose an application.
     
     This action method presents an Open panel defaulting to the System Applications folder to let the user choose any application installed on the computer. If the user chooses an application that is not running, the method launches it. Once it is running, the method validates it and, if it passes validation, updates UI Browser's data and display. If the application fails to launch or fails validation, the method aborts and leaves the current running application target unchanged. Validation tests whether the running application has made accessibility features available to assistive applications.
     
     If the user clicks Open in the Open panel, the Open panel's completion handler first determines whether the chosen application is running, and, if it is, immediately validates it. If it passes validation, the completion handler udpates UI Browser's data and display.
     
     If the chosen application is not running, the completion handler launches it using the `NSWorkspace` `launchApplication(...)` method, which, if the launch attempt succeeds,  provides its `NSRunningApplication` object. However, the application has not necessarily finished launching and may not yet have made accessibility features available. This method therefore employs several techniques to wait for the application to make accessibility features available. For `regular` applications, it uses key-value observing (KVO) on the `NSWorkspace` `isFinishedLaunching` key path to delay validation until the target has finished launching. However, `accessory` (`LSUIElement`) and `prohibited` (`LSBackgroundOnly`) applications do not post the `didLaunchApplicationNotification` notification and their `isFinishedLaunching` property therefore cannot be observed. For these applications, the `NSWorkspace` `runningApplications` property is observed by KVO, instead, to delay validation until the application is added to the `NSWorkspace` array of running applications. When the target finishes launching or is added to running applications, the KVO observer is removed, and the application is validated. However, the application may still not have made accessibility features available because, if it is not a `regular` application, it may not yet have finished launching. In addition, a very small number of applications are known to make accessibility features available a short time after they finish launching. An example is Adobe Photoshop CS6. If the application fails the initial attempt at validation, the method therefore schedules a repeating timer to give the application a little more time to make accessibility features available. If the launch attempt or validation fails, or if the user clicks Cancel in the Open panel, the completion handler leaves the previous target data and display unchanged and restores the previous Target pop-up button's title.
     
     When the user opened the Target menu, the `menuNeedsUpdate(_:)` `NSMenuDelegate` delegate method in `AppDelegate` or the TargetPopUpButtonWillPopUp(_:) notification method called the `updateTargetMenu(_:)` utility method to populate the Target menu in the main menu bar or the Target pop-up button's menu. The utility method programmatically connected this action method to the Choose Target… menu item.
     
     *See also:* `chooseNoTarget(_:)`, `chooseSystemWideTarget(_:) and `chooseRunningTarget(_:)`.
     
     - note: The equivalent UI Browser 2 methods are \-\[PFBrowserController chooseApplicationMenuItemAction:\] and \-\[PFBrowserController chooseApplicationPopUpAction:\] (the second if-else else branch).
     
     - parameter sender: The menu item that sent the action
     */
    @objc func chooseAnyTarget(_ sender: NSMenuItem) {
        
        /// A repeating scheduled timer to validate a proposed target.
        var timer: Timer? = nil
        
        /// An Open panel listing applications available to be chosen as the current running application target.
        let sheet = NSOpenPanel()
        
        /// An array of urls representing the `System Applications` folder.
        let directoryUrls = FileManager.default.urls(for: .applicationDirectory, in: .systemDomainMask)
        
        if !directoryUrls.isEmpty {
            sheet.directoryURL = directoryUrls[0]
            sheet.allowedFileTypes = ["app"]
            sheet.beginSheetModal(for: window!, completionHandler: {
                (_ result: NSApplication.ModalResponse) -> Void in
                
                // MARK: Completion handler for Open panel
                // This closure handles the user's choice of an application that is already running or, if it is not already running, launches it and then handles it.
                // The equivalent UI Browser 2 method is -[PFBrowserController didChooseApplicationInSheet:result:sender:].
                
                switch result {
                case NSApplication.ModalResponse.OK:
                    // The user clicked OK to choose an application, so handle the proposed target.
                    
                    // Unregister the KVO observer of the isFinishedLaunching key path for any previous launchingApplicationTarget that has not yet finished launching, and nullify the launchingApplicationTarget property.
                    if self.mainContentViewController!.launchingApplicationTarget != nil {
                        // KVO removes observers automatically when they are deinited in Swift 4 or later.
                        self.mainContentViewController!.isFinishedLaunchingObservation = nil
                        self.mainContentViewController!.launchingApplicationTarget = nil
                    }
                    
                    /// The file url of the application chosen in the Open panel.
                    let proposedTargetURL = sheet.urls[0].standardizedFileURL // ensure valid comparisons
                    if NSWorkspace.shared.runningApplications.contains(where: {$0.bundleURL == proposedTargetURL || $0.executableURL == proposedTargetURL}) {
                        // The proposed target is already running, so validate it immediately and update UI Browser's data and display.
                        
                        /// The `NSRunningApplication` object of the application chosen in the Open panel.
                        var proposedTarget: NSRunningApplication? = nil
                        
                        // Get the proposed target's NSRunningApplication object.
                        do {
                            // The proposed target is already running, so the launchApplicaton(at:options:configuration:) method does not launch it but only returns its NSRunningApplication object. It does this without relying on the proposed target's bundle identifier or process identifier, which is important because the user can choose an application that does not have a bundle identifier or process identifier.
                            proposedTarget = try NSWorkspace.shared.launchApplication(at: proposedTargetURL, options: [.withoutActivation], configuration: [:])
                        } catch let error as NSError {
                            // The proposed application is already running so launching it should never cause an error.
                            // preconditionFailure(error.localizedDescription)
                            self.mainContentViewController!.sheetForApplicationFailedToLaunch(name: proposedTargetURL.lastPathComponent, error: error)
                            self.updateTargetPopUpButtonTitle()
                            return
                        }
                        
                        // Do nothing if the proposed target is the current running application target.
                        guard proposedTarget! != self.mainContentViewController!.runningApplicationTarget else {
                            // The user chose a proposed target that is already the current running application target, so do nothing except change the title of the Target pop-up button from "Choose Target…" back to the application's display name.
                            self.updateTargetPopUpButtonTitle()
                            return
                        }
                        
                        // Validate the proposed target.
                        /// The accessibility application element for the application chosen in the Open panel.
                        if let proposedTargetElement = self.validatedTargetElement(for: proposedTarget!) {
                            // The proposed target passed validation, so update UI Browser' data and display.
                            self.mainContentViewController!.updateApplication(forNewTarget: proposedTarget, usingTargetElement: proposedTargetElement)
                        } else {
                            // The proposed target failed validation because accessibility is not yet available. If an already running application fails validation, there is no point in creating a timer to give it more time, so do nothing except alert the user.
                            self.updateTargetPopUpButtonTitle()
                            self.mainContentViewController!.sheetForApplicationUIElementNotCreated()
                        }
                        
                    } else {
                        // The proposed target is not yet running, so launch it, then delay validation until a regular application finishes launching or a background application is added to the list of running applications, then validate it and update UI Browser's data and display.
                        // Apple's reference documentation for the NSWorkspace didLaunchApplicationNotification notification states the following: "The system does not post this notification for background apps or for apps that have the LSUIElement key in their Info.plist file. If you want to know when all apps (including background apps) are launched or terminated, use key-value observing to monitor the value returned by the runningApplications method."

                        // Register to observe the NSWorkspace runningApplications property in case the proposed target is an accessory (LSUIElement) or prohibited (LSBackgroundOnly) application whose isFinishedLaunching property cannot be observed.
                        self.mainContentViewController!.runningApplicationsObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new]) { (shared, change) in
                            
                            // MARK: KVO observer for NSWorkspace's runningApplications key path
                            // This closure will fire when the user chooses a non-running application in the Open panel, it launches successfully, and it is added to NSWorkspace's runningApplications property. This always happens before an NSRunningApplication's isFinishedLaunching observer fires, but we have to register this runningApplications observer now because we don't yet know whether the chosen application is a regular application whose isFinishedLaunching property can be observed. This observer must be registered before the chosen application is launched. It will be unregistered after the target is launched if it turns out to be a regular application.
                            
                            // Get the NSRunningApplication object of the application chosen in the Open panel, which was successfully launched and ___________.
                            if let proposedTarget = change.newValue?[0] {
                                if proposedTargetURL == proposedTarget.bundleURL || proposedTargetURL == proposedTarget.executableURL {
                                    // The new NSRunningApplication object observed in runningApplications is the proposed target.
                                    
                                    if proposedTarget.activationPolicy != NSApplication.ActivationPolicy.regular {
                                        
                                        // Unregister to observe the NSWorkspace runningApplications property because the addition of the proposed target to running applications has been observed and it is a background application. If it is never observed being added, it will be unregistered in MainViewController's deinit method when UI Browser terminates.
                                        // KVO removes observers automatically when they are deinited in Swift 4.
                                        self.mainContentViewController!.runningApplicationsObservation = nil
                                        
                                        /// The accessibility application element for the application chosen in the Open panel.
                                        if let proposedTargetElement = self.validatedTargetElement(for: proposedTarget) {
                                            // Update UI Browser for the proposed target if it passed validation. Most applications make accessibility features available immediately when they finish launching, so the use of a timer to allow more time is not usually needed.
                                            self.mainContentViewController!.updateApplication(forNewTarget: proposedTarget, usingTargetElement: proposedTargetElement)
                                        } else {
                                            // The proposed target failed validation because accessibility is not yet available, so a timer to allow more time is needed.
                                            if timer == nil {
                                                timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.targetElementValidationTimer(_:)), userInfo: proposedTarget, repeats: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Launch the chosen application.
                        do {
                            self.mainContentViewController!.launchingApplicationTarget = try NSWorkspace.shared.launchApplication(at: proposedTargetURL, options:[.withoutActivation], configuration: [:])
                            
                        } catch let error as NSError {
                            self.mainContentViewController!.sheetForApplicationFailedToLaunch(name: proposedTargetURL.lastPathComponent, error: error)
                            self.updateTargetPopUpButtonTitle()
                            return
                        }
                        
                        if self.mainContentViewController!.launchingApplicationTarget!.activationPolicy == NSApplication.ActivationPolicy.regular {
                            
                            // Unregister to observe the NSWorkspace runningApplications property because the proposed target is a regular application whose isFinishedLaunching property can be observed.
                            // KVO removes observers automatically when they are deinited in Swift 4.
                            self.mainContentViewController!.runningApplicationsObservation = nil
                            
                            // Register to observe the NSRunningApplication isFinishedLaunching property.
                            self.mainContentViewController!.isFinishedLaunchingObservation = self.mainContentViewController!.launchingApplicationTarget!.observe(\.isFinishedLaunching) { (launchingApplicationTarget, change) in
                                
                                // MARK: KVO observer for NSRunningApplication isFinishedLaunching key path
                                // This closure fires when the user chooses a non-running target from the Open panel, it launched successfully, and it has now finished launching.
                                // This closure will fire when the non-running application the user chose in the Open panel, which launched successfully, finishes launching.
                                
                                // Update UI Browser for the proposed target if it passes validation; specifically, if it makes accessibility features available to assistive applications.
                                
                                /// The `NSRunningApplication` object of the application chosen in the Open panel, which successfully launched and finished launching.
                                let proposedTarget = launchingApplicationTarget
                                
                                // Unregister to observe the NSRunningApplication isFinishedLaunching property because the proposed target has been observed to finish launching and it is a regular application. If it is never observed to finish launching, it will be unregistered in MainViewController's deinit method when UI Browser terminates.
                                // KVO removes observers automatically when they are deinited in Swift 4.
                                self.mainContentViewController!.isFinishedLaunchingObservation = nil
                                
                                // Nullify the launchingApplicationTarget property to signal that it has finished launching and is no longer subject to KVO observation. However, it still requires validation and may require a repeating timer to accomplish that.
                                self.mainContentViewController!.launchingApplicationTarget = nil
                                
                                // Validate the proposed target.
                                /// The accessibility application element of the application chosen in the Open panel.
                                if let proposedTargetElement = self.validatedTargetElement(for: proposedTarget) {
                                    // The proposed target passed validation because accessibility is available, so update UI Browser's data and display. Most applications make accessibility features available by the time they finish launching, so a timer to allow more time is usually not needed.
                                    self.mainContentViewController!.updateApplication(forNewTarget: proposedTarget, usingTargetElement: proposedTargetElement)
                                } else {
                                    // The proposed target failed validation because accessibility is not yet available, so a timer to allow more time is needed.
                                    if timer == nil {
                                        timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.targetElementValidationTimer(_:)), userInfo: proposedTarget, repeats: true)                                  }
                                }
                            }
                        }
                    }
                    
                case NSApplication.ModalResponse.cancel:
                    // The user canceled, so restore the previous Target pop-up button title.
                    self.updateTargetPopUpButtonTitle()
                default:
                    preconditionFailure("An unrecognized button was pressed in the Target menu's Open panel.")
                }
            })
        }
    }
    
    /**
     Updates UI Browser's data and display when the user chooses an application from the Target menu's list of running applications.
     
     If the user chooses one of the listed running applications, this action method first validates it and, if it passes validation, updates UI Browser's data and display. If the application fails validation, the method aborts and leaves the current running application target unchanged. Validation tests whether the running application has made accessibility features available to assistive applications.
     
     When the user opened the Target menu, the `menuNeedsUpdate(_:)` `NSMenuDelegate` delegate method in `AppDelegate` or the TargetPopUpButtonWillPopUp(_:) notification method called the `updateTargetMenu(_:)` utility method to populate the Target menu in the main menu bar or the Target pop-up button's menu. The utility method programmatically connected this action method to each menu item in the menu representing a running application. It also set each menu item's represented object to a dictionary containing its `NSRunningApplication` object and other information.
     
     *See also:* `chooseNoTarget(_:)`, chooseSystemWideTarget(_:) and `chooseAnyTarget(_:)`.
     
     - note: The equivalent UI Browser 2 methods are \-\[PFBrowserController chooseApplicationMenuBarItemAction:\] and \-\[PFBrowserController chooseApplicationPopUpAction:\] (the last if-else else branch).
     
     - parameter sender: The menu item that sent the action.
     */
    @objc func chooseRunningTarget(_ sender: NSMenuItem) {

        // Get the proposed target and its name from the menu item's represented object, which is a dictionary in the form [RUNNING_APPLICATION_KEY: NSRunningApplication, RUNNING_APPLICATION_DISPLAY_NAME_KEY: String?].
        /// The menu item's represented object.
        guard let infoDict = sender.representedObject as? RunningApplicationInfo,
            let proposedTarget = infoDict[RUNNING_APPLICATION_KEY] as? NSRunningApplication,
            proposedTarget != mainContentViewController!.runningApplicationTarget else {return}
        
        // Unregister MainContentViewController as a KVO observer of the isFinishedLaunching key path for any previous launchingApplicationTarget that has not yet finished launching or that does not post NSApplicationDidFinishLaunchingNotification notifications.
        if mainContentViewController!.launchingApplicationTarget != nil {
            // KVO removes observers automatically when they are deinited in Swift 4.
            mainContentViewController!.isFinishedLaunchingObservation = nil
            mainContentViewController!.launchingApplicationTarget = nil
        }
        
        /// The accessibility application element for the application chosen in the Open panel.
        if let proposedTargetElement = validatedTargetElement(for: proposedTarget) {
            // Update UI Browser for the proposed target because it passed validation.
            mainContentViewController!.updateApplication(forNewTarget: proposedTarget, usingTargetElement: proposedTargetElement)
        }
    }
    
    // MARK: - UTILITY METHODS
    
    // TODO:  Document that updateTargetMenu ...
    // ... is also called from the displayElementInNewApplication method
    /**
     Updates the Target menu programmatically when the user opens it to choose a target.
     
     This utility method is called by the `menuNeedsUpdate(_:)` `NSMenuDelegate` delegate method in `AppDelegate` or by the `targetButtonWillPopUp(_:) notification method in `TargetMenuExtension`, depending on whether the user is opening the Target menu in the main menu bar or in the Target pop-up button. It populates the menu programmatically, connecting the appropriate action method to each menu item and setting the represented object of each running application menu item to a dictionary containing its `NSRunningApplication` object and other information. The two menus are identical.
     
     The method first clears all previous menu items from the menu. It then adds four fixed menu items, No Target, SystemWide Target, ChooseTarget… and Activate Target, followed by menu items for currently running applications. Because the menu displays currently running applications, it cannot be populated in advance in the storyboard file. The running applications that are listed and the order in which they are listed is dictated by preferences settings.
     
     The method uses the `NSWorkspace` `runningApplications` property to obtain an array of all running applications. The array includes only User applications managed by NSRunningApplication, but this includes all kinds of User applications: whether Cocoa, Carbon or otherwise; whether bundled (composed of an application package) or not; whether having a process identifier (PID) or not; whether relying on NSApplication or not; and whether regular (appearing in the Dock), accessory (`LSUIElement = 1` in its `Info.plist` file) or prohibited (`LSBackgroundOnly = 1` in its *Info.plist* file). These distinctions have implications for how UI Browser is coded in various circumstances. For example, an application that is not bundled will not be included in the array returned by the `NSRunningApplication` `runningApplications(withBundleIdentifier:)` method. An application that does not rely on `NSApplication`, such as a Carbon application, does not post the `didFinishLaunchingNotification` notification and its `isFinishedLaunching` property therefore cannot be observed using Key-Value Observing (KVO). In addition, an application that does not have a process identifier (PID) cannot be initialized using the `NSRunningApplication` `init?(processIdentifier:)` convenience initializer. However, an application without a process identifier cannot support accessibility because Apple's accessibility API has only one function, AXUIElementCreateApplication(), that creates a new AXUIElement object from scratch, and it requires a process identifier in its parameter.
     
     While iterating over all running applications, this method creates a dictionary of type `[String: AnyObject]` (defined as typealias RunningApplicationInfo) for each application containing its `NSRunningApplication` object and display name in this form: `[RUNNING_APPLICATION_KEY: NSRunningApplication, RUNNING_APPLICATION_DISPLAY_NAME_KEY: String?]`. These dictionaries are collected in separate arrays for regular applications, accessory (`LSUIElement`) applications, prohibited (`LSBackgroundOnly`) applications, and all applications, depending on user defaults settings dictating how the Target menu is displayed. The `name` value is used to set the menu item's title and the `NSRunningApplication` object is set as the menu item's represented object. Saving the NSRunningApplication object as the menu item's represented object makes it easy for UI Browser to work with applications that do not have a bundle identifier or process identifier. Later, when the user chooses a target in the `chooseRunningTarget(_:)` action method, the selected menu item's represented object is used to set the `runningApplicationTarget` property. This saves having to iterate over all running applications again or to create `NSRunningApplication` objects every time it is needed.
     
     When user preferences are set to show regular, accessory and prohibited applications together, the Target menu can be quite long. Apple's Human Interface Guidelines once said this about that: "Note that in some menus, users might add enough items to make the menu very long. For example, the Safari History menu can grow very long, depending on how many websites users visit. In some cases, a long menu can become a scrolling menu, which displays a downward-pointing arrow at the bottom edge. Scrolling menus should exist only when users add a large number of items to a customizable menu or when the menu’s function causes it to have items added to it (such as an app’s Window menu). You should not intentionally design a scrolling menu."
     
     **complexity:** This method uses KVO observers and a repeating timer to wait for an application to launch and make accessibility features available.
     
     **Requirements:** This method must place the No Target menu item at index 0 with the `NO_TARGET_MENU_ITEM_TAG` tag, the SystemWide Target menu item at index 1 with the `SYSTEMWIDE_TARGET_MENU_ITEM_TAG` tag, and the Choose Target… menu item at index 3 following a separator.
     
     *See also:* `chooseNoTarget(_:)`, `chooseAnyTarget(_:)` and `chooseRunningTarget(_:)`.
     
     - note: Equivalent UI Browser 2 methods are \-\[PFBrowserController menuNeedsUpdate:\] and \-\[PFBrowserController updateApplicationPopUpMenu:\].
     
     - parameter menu: The menu to be updated. It must be the Target menu in the main menu bar or in the Target pop-up button.
     */
    func updateTargetMenu(_ menu: NSMenu) {
        
        /// Whether UI Browser is allowed to control the computer using accessibility features. The Target menu's menu items are disabled if accessibility is not allowed for UI Browser, except for the No Target menu item, which is the selected menu item whenever accessibility is not allowed. The Activate Target menu item is disable when no target application is currently chosen.
        let isTrusted = AccessibleElement.isProcessTrusted()
        
        // 1. Clear the menu.
        menu.removeAllItems()
        
        // 2. Set up fixed menu items that always appear at the top of the Target menu.
        
        /// The title of the `NO Target` menu item.
        let noTargetTitle = NSLocalizedString(NO_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to deselect target")
        
        /// The title of the `SystemWide Target` menu item.
        let systemwideTargetTitle = NSLocalizedString(SYSTEMWIDE_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to choose the SystemWide Target")
        
        /// The title of the `Choose Target…` menu item.
        let chooseTargetTitle = NSLocalizedString(CHOOSE_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to choose new target")
        
        /// The title of the `Activate Target` menu item.
        let activateTargetTitle = NSLocalizedString(ACTIVATE_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to activate the current target")
        
        // 3. Organize information about all applications that are currently running into arrays of RunningApplicationInfo dictionaries.
        
        /// An array of `Regular` applications that are running and eligible to appear in the Dock.
        var regularAppsArray: [RunningApplicationInfo] = [] // array of infoDict
        
        /// An array of `Accessory` or `LSUIElement` applications that are running.
        var accessoryAppsArray: [RunningApplicationInfo] = [] // array of infoDict
        
        /// An array of `Prohibited` or `LSBackgroundOnly` applications that are running.
        var prohibitedAppsArray: [RunningApplicationInfo] = [] // array of infoDict
        
        /// An array of all applications that are running.
        var allAppsArray: [RunningApplicationInfo] = [] // array of infoDict
        
        // Build the RunningApplicationInfo arrays
        NSWorkspace.shared.runningApplications.forEach {
            /// A running application's display name
            let name = mainContentViewController!.displayName(for: $0)  // may be an empty string if an error occurs
            /// A dictionary serving as the menu item's represented object.
            let infoDict = [RUNNING_APPLICATION_KEY: $0 as NSRunningApplication, RUNNING_APPLICATION_DISPLAY_NAME_KEY: name as AnyObject]
            switch $0.activationPolicy {
            case NSApplication.ActivationPolicy.regular:
                regularAppsArray.append(infoDict)
            case NSApplication.ActivationPolicy.accessory:
                accessoryAppsArray.append(infoDict)
            case NSApplication.ActivationPolicy.prohibited:
                prohibitedAppsArray.append(infoDict)
            @unknown default:
                preconditionFailure("Unexpectedly entered default case in switch statement")
            }
        }
        
        // 4. Configure the Target menu from top to bottom.
        // 4.a. Place the fixed menu items (No Target, SystemWide and Choose Target…) at the top of the menu.
        
        /// A fixed menu item at the top of the Target menu.
        var fixedMenuItem = menu.addItem(withTitle: noTargetTitle, action: #selector(chooseNoTarget(_:)), keyEquivalent: "") // must be inserted at index 0
        fixedMenuItem.tag = NO_TARGET_MENU_ITEM_TAG // leave the No Target menu item enabled even if access is not authorized.
        
        fixedMenuItem = menu.addItem(withTitle: systemwideTargetTitle, action: #selector(chooseSystemWideTarget(_:)), keyEquivalent: "") // must be inserted at index 1
        fixedMenuItem.tag = SYSTEMWIDE_TARGET_MENU_ITEM_TAG
        fixedMenuItem.isEnabled = isTrusted
        
        menu.addItem(NSMenuItem.separator())
        
        fixedMenuItem = menu.addItem(withTitle: chooseTargetTitle, action: #selector(chooseAnyTarget(_:)), keyEquivalent: "") // must be inserted at index 3
        fixedMenuItem.isEnabled = isTrusted
        
        menu.addItem(NSMenuItem.separator())
        
        fixedMenuItem = menu.addItem(withTitle: activateTargetTitle, action: #selector(activateTarget(_:)), keyEquivalent: "") // must be inserted at index 5
        fixedMenuItem.isEnabled = isTrusted && MainContentViewController.sharedInstance.runningApplicationTarget != nil
        
        menu.addItem(NSMenuItem.separator())
        
        // 4.b. Place running application menu items below the fixed menu items.
        
        /**
         Nested function adds menu items from an array of `RunningApplicationInfo` dictionaries.
         
         - parameter names: An array of `NSRunningApplicationInfo` dictionaries.
         */
        func addApplicationItems(for infoArray: [RunningApplicationInfo]) {
            infoArray.forEach {
                /// Name of running application to serve as title of menu item.
                let name = $0[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String
                /// Menu item for a running application.
                let menuItem: NSMenuItem? = menu.addItem(withTitle: name, action: #selector(chooseRunningTarget(_:)), keyEquivalent: "")
                if menuItem != nil {
                    menuItem!.representedObject = $0
                    menuItem!.isEnabled = isTrusted
                }
            }
        }
        
        if UserDefaults.standard.bool(forKey: DISPLAYS_BACKGROUND_APPLICATIONS_DEFAULTS_KEY) {
            if UserDefaults.standard.bool(forKey: DISPLAYS_BACKGROUND_APPLICATIONS_SEPARATELY_DEFAULTS_KEY) {
                
                // Add regular application menu items before background application menu items.
                
                regularAppsArray.sort {
                    return ($0[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased() < ($1[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased()
                }
                addApplicationItems(for: regularAppsArray)
                
                menu.addItem(NSMenuItem.separator())
                
                // Add accessory (LSUIElement) application menu items before prohibited (LSBackgroundOnly) application menu items.
                
                accessoryAppsArray.sort {
                    return ($0[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased() < ($1[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased()
                }
                addApplicationItems(for: accessoryAppsArray)
                
                menu.addItem(NSMenuItem.separator())
                
                prohibitedAppsArray.sort {
                    return ($0[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased() < ($1[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased()
                }
                addApplicationItems(for: prohibitedAppsArray)
                
            } else {
                
                // Place regular and background application menu items mixed together.
                allAppsArray = regularAppsArray + accessoryAppsArray + prohibitedAppsArray
                allAppsArray.sort {
                    return ($0[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased() < ($1[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased()
                }
                addApplicationItems(for: allAppsArray)
            }
            
        } else {
            
            // 4.c. Place the Dock and SystemUIServer background application menu items near top of menu and place regular application menu items below them, omitting background applications other than the Dock and SystemUIServer.
            
            /// An array of `NSRunningApplication` objects for the Dock application.
            let dockApplications = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
            if !dockApplications.isEmpty {
                /// An `NSRunningApplication` object for the Dock application.
                let dockApp = dockApplications[0] as NSRunningApplication
                /// Name of running application to serve as title of menu item.
                let name = mainContentViewController!.displayName(for: dockApp) // may be an empty string if an error occurs
                /// A dictionary serving as the menu item's represented object.
                let infoDict = [RUNNING_APPLICATION_KEY: dockApp as NSRunningApplication, RUNNING_APPLICATION_DISPLAY_NAME_KEY: name as AnyObject]
                /// Menu item for a running application.
                let menuItem: NSMenuItem? = menu.addItem(withTitle: name, action: #selector(chooseRunningTarget(_:)), keyEquivalent: "")
                if menuItem != nil {
                    menuItem!.representedObject = infoDict
                    menuItem!.isEnabled = isTrusted
                }
            }
            
            /// An array of `NSRunningApplication` objects for the SystemUIServer application handling menu extras.
            let systemUIServerApplications = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systemuiserver")
            if !systemUIServerApplications.isEmpty {
                /// An `NSRunningApplication` object fot the SystemUIServer application handling menu extras.
                let systemUIServerApp = systemUIServerApplications[0] as NSRunningApplication
                /// Name of running application to serve as title of menu item.
                let name = mainContentViewController!.displayName(for: systemUIServerApp) // may be an empty string if an error occurs
                /// A dictionary serving as the menu item's represented object.
                let infoDict = [RUNNING_APPLICATION_KEY: systemUIServerApp as NSRunningApplication, RUNNING_APPLICATION_DISPLAY_NAME_KEY: name as AnyObject]
                /// Menu item for a running application.
                let menuItem: NSMenuItem? = menu.addItem(withTitle: name, action: #selector(MainWindowController.chooseRunningTarget(_:)), keyEquivalent: "")
                if menuItem != nil {
                    menuItem!.representedObject = infoDict
                    menuItem!.isEnabled = isTrusted
                }
            }
            
            if menu.item(at: menu.numberOfItems - 1) != NSMenuItem.separator() {
                menu.addItem(NSMenuItem.separator())
            }
            
            regularAppsArray.sort {
                return ($0[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased() < ($1[RUNNING_APPLICATION_DISPLAY_NAME_KEY] as! String).lowercased()
            }
            addApplicationItems(for: regularAppsArray)
        }
    }
    
    /**
     Updates the Target pop-up button's title after the user chooses a target.
     
     This utility method sets the title of the Target pop-up button after the user chooses it and the menu closes. This is necessary in order to synchronize the pop-up button's title if the user chooses the target using the menu bar's Target menu or the Choose Target… menu item in either Target menu.
     
     *See also:* `chooseNoTarget(_:)`, `chooseAnyTarget(_:)`, `chooseRunningTarget(_:)` and `updateTargetMenu(_:)`.
     */
    func updateTargetPopUpButtonTitle() {
        
        if mainContentViewController!.runningApplicationTarget == nil {
            if mainContentViewController!.currentElementData == nil || mainContentViewController!.currentElementData!.isEmpty {
                targetPopUpButton.title = NO_TARGET_MENU_ITEM_TITLE
            } else {
                targetPopUpButton.title = SYSTEMWIDE_TARGET_MENU_ITEM_TITLE
            }
        } else {
            let itemName = mainContentViewController!.displayNameForTargetApplication() // may be empty if an error occurs
            targetPopUpButton.title = itemName
        }
    }

    /**
     Validates the application that the user chose in the Target menu to be the proposed target, and if successful returns its root application AccessibleElement object.
     
     This utility method is called in the `chooseAnyTarget(_:)` and `chooseRunningTarget(_:)` action methods. The proposed target is guaranteed to be running, but it may not yet have finished launching.
     
     The method validates the proposed target by testing whether it has made its accessibility features available and is therefore suitable for use as a UI Browser target. It does this by using the proposed target's process identifier (PID) to attempt to create an `AccessibleElement` object with an `AXRole` attribute of "AXApplication". It obtains the process identifier from the proposed target's `NSRunningApplication` object. If validation is successful, it returns the `AccessibleElement` object to allow UI Browser to use it to update its data and display. If unsuccessful, it returns nil and leaves UI Browser's data and display unchanged. An unstated assumption of the accessibility API is that every process supporting accessibility has a valid process identifier, and that a process without a process identifier cannot support accessibility. See the AccessibleElement.swift file in PFAssistiveFramework4 for more information.
     
     If the user chooses a proposed target that is not running and has to be launched by the `chooseAnyTarget(_:)` action method, a failure of validation here causes UI Browser to attempt validation again repeatedly at short intervals using a repeating timer for a short time. This is done to accommodate a small number of applications that make their accessibility features available some time after they finish launching. An example is Adobe Photoshop CS6. Some applications may validate successfully before they have opened all of their windows. An example is BBEdit 12. In accordance with its "snapshot" policy, UI Browser will leave those windows undisplayed until the user refreshes the application.
     
     *See also:* `chooseAnyTarget(_:)` and `chooseRunningTarget(_:)`.
     
     - parameter proposedTarget: The `NSRunningApplication` object chosen by the user, or `nil` if the user chose No Target.
     */
    func validatedTargetElement(for proposedTarget: NSRunningApplication) -> AccessibleElement? {
        // Determine whether the proposed target has made accessibility features available by attempting to create an AccessibleElement object with an AXRole attribute of "AXApplication".
        
        /// The accessibility application element for the application chosen in the Open panel.
        guard let proposedTargetElement = AccessibleElement.makeApplicationElement(processIdentifier: proposedTarget.processIdentifier) as? AccessibleElement,
            let role = proposedTargetElement.AXRole,
            role == NSAccessibility.Role.application.rawValue else {return nil}
        
        return proposedTargetElement
    }
    
    // MARK: - TIMER METHODS
    
    /**
     Repeatedly attempts to validate the proposed target chosen in the Target menu.
     
     This repeating timer method is called from both of the `chooseAnyApplication(_:)` action method's KVO completion handlers. The method is called only if the proposed target failed validation immediately after a KVO observer reported that a regular application had finished launching or a background application had been added to the `NSWorkspace` `runningApplications` property. The method gives the proposed target limited additional time to be validated. If validation succeeds before the timer is invalidated, the method updates UI Browser's data and display.
     
     - parameter timer: The `Timer` object that scheduled this timer method.
     */
    @objc func targetElementValidationTimer(_ timer: Timer) {
        // Timer method called in choseAnyTarget(_:).
        
        struct staticVar {
            // Turn this into a real local static variable when Swift allows it.
            /// The elapsed time since the application chosen in the Open panel finished launching.
            static var elapsedTime = 0.0
        }
        
        // Attempt validation repeatedly until successful or the allowed time expires.
        /// The `NSRunningApplication` object for the chosen application.
        let target = timer.userInfo as! NSRunningApplication
        /// The accessibility application element for the application chosen in the Open panel.
        if let proposedTargetElement = self.validatedTargetElement(for: target) {
            // Update UI Browser for the proposed target because it passed validation.
            timer.invalidate()
            mainContentViewController!.updateApplication(forNewTarget: mainContentViewController!.runningApplicationTarget, usingTargetElement: proposedTargetElement)
        } else {
            // The target failed validation again because accessibility is still not available.
            print("Waiting for the proposed target to make accessibility features available.")
            staticVar.elapsedTime += SELECT_ELEMENT_TIMER_INTERVAL
            if staticVar.elapsedTime >= SELECT_ELEMENT_TIMER_DURATION {
                // Time's up! Accessibility has not become available in the time allowed, so invalidate the timer, set launchingApplicationTarget to nil to flag that it is unregistered for KVO, restore the target pop-up button's title, and alert the user.
                timer.invalidate()
                self.updateTargetPopUpButtonTitle()
                mainContentViewController!.sheetForApplicationUIElementNotCreated()
            }
        }
        
    }
    
    // MARK: - NOTIFICATION METHODS
    
    /**
     Updates the Target pop-up button's menu when the user opens it.
     
     This notification method is called when the user clicks the Target pop-up button to open its menu and choose a target. It populates the Target menu before it opens by calling `updateTargetMenu(_:)`, just as the `AppDelegate` `menuNeedsUpdate(_:)` `NSMenuDelegate` delegate method does when the user clicks the Target menu in the main menu bar. This method then uses techniques designed specifically for pop-up buttons to ensure that the correct menu item shows a check mark and that it is positioned over the pop-up button when it opens. `MainContentViewController` is registered to observe the `willPopUpNotification` notification in `viewDidLoad()`.
     
     *See also:* `MainWindowController.updateWindowTitle()`.
     
     - parameter notification: The `NSPopUpButton.willPopUpNotification` notification.
     */
    @objc func targetPopUpButtonWillPopUp(_ notification: NSNotification) {
        
        guard let popUpButton = notification.object as? NSPopUpButton,
            let popUpMenu = popUpButton.menu else {
                assertionFailure("Target pop-up button may not be connected correctly")
                return
        }
        
        // Populate the Target menu.
        updateTargetMenu(popUpMenu)
        
        // Select the current running application target menu item, or the "No Target" or "SystemWide Target" menu item, in order to display a checkmark on it reflecting the current selection and to position it over the button.
        if mainContentViewController!.runningApplicationTarget == nil {
            if mainContentViewController!.currentElementData == nil || mainContentViewController!.currentElementData!.isEmpty {
                popUpButton.selectItem(withTag: NO_TARGET_MENU_ITEM_TAG)
            } else {
                popUpButton.selectItem(withTag: SYSTEMWIDE_TARGET_MENU_ITEM_TAG)
            }
        } else {
            /// The display name of target application, used as its menu item title.
            let itemTitle = mainContentViewController!.displayNameForTargetApplication() // may be empty if an error occurs
            if popUpButton.item(withTitle: itemTitle) != nil {
                popUpButton.selectItem(withTitle:itemTitle)
            } else {
                // The current running application target is not in the menu, so add it. This happens when UI Browser's preferences are set to show only regular applications in the Target menu, and the current running application target is a background application (other than the Dock or systemUIServer) chosen in the Target menu's Open panel.
                // This menu item does not need a represented object because the user is prevented from choosing the current running application target in the Target menu's list of running applications. An action method is connected only to cover the possibility that UI Browser might perform validation on running applications listed in the menu.
                popUpMenu.addItem(NSMenuItem.separator())
                popUpButton.addItem(withTitle: itemTitle)
                popUpButton.select(popUpButton.lastItem)
            }
        }
    }
    
    // MARK: - DELEGATE METHODS
    
    // MARK: NSMenuDelegate Protocol Support
    
    // TODO: Remove this and remove NSMenuDelegate conformance...
    // ... if decide to keep Target pop-up button disabled when accessibility is disabled.
    /**
     Presents the `AccessAuthorizer` Request Access alert when the Target menu is dismissed, if accessibility is disabled.
     
     This delegate method is triggered when the user dismisses any menu controlled by the main window controller, whether or not a menu item was chosen. The only such menu is the Target pop-up button's menu, and when access is disabled its only enabled menu item is No Target. The alert is presented to remind the user that UI Browser can do nothing, not even choose a target application, without enabling access.
     
     Note that this method is never called in the current version of UI Browser because the Target pop-up button is disabled when accessibility is disabled.
     
     *See also:* `AppDelegate.menuDidClose(_:)`.
     
     - parameter menu: The `NSMenu` object that triggered this delegate method.
     */
     func menuDidClose(_ menu: NSMenu) {
        // Called after the user dismisses any menu controlled by the main window controller, whether or not a menu item was chosen. The only such menu is the Target pop-up button's menu, and when access is disabled its only enabled menu item is No Target. The alert is presented to remind the user that UI Browser can do nothing, not even choose a target application, without enabling access.
        // MainWindowController is set as the delegate of the Target pop-up button's menu in windowDidLoad().
        // Presents the `AccessAuthorizer` Request Access alert when the Target menu is dismissed, if accessibility is disabled.
        
        if menu == targetPopUpButton.menu {
            let appDelegate = NSApp.delegate as! AppDelegate
            appDelegate.accessAuthorizer!.requestAccess()
        }
    }
    
}
