//
//  MainContentViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-09.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

import Cocoa
import PFAssistiveFramework4
import PFAccessibilityAuthorizer2

/**
 `MainContentViewController` receives the `window content` relationship segue triggered by `MainWindowController` in *Main.storyboard* and is therefore instantiated when *Main.storyboard* is loaded at application launch. It automatically calls `loadView()` to instantiate and load the main window's content view. Its `view` outlet is connected to the content view in *Main.storyboard*. `MainContentViewController`'s view contains, along with other UI elements, a container view that initiates or triggers a viewDidLoad embed segue connected to `MainSplitViewController` in *Main.storyboard*; the split view replaces the container view at application launch. `MainContentViewController` also manages other UI elements that are located in the window's content view because they are relevant to the application globally rather than to the individual panes of the split view. Constraints in *Main.storyboard* establish a minimum width and height for the main window.

 The content view is one of two areas in the window, located below the toolbar area. The content view is filled by the main split view.
 
 MainContentViewController manages everything in the window's content view. The split view in the main content view in the window's bottom area contains two panes or split view items. The top pane functions as a master view in which the user selects a target's UI element of interest; a segmented control allows the user to format it as a browser, outline or list. The bottom pane functions as a detail view; a tab control allows the user to examine and manipulate attributes, actions and notifications of the selected UI element. If the user only wants to explore the UI element hierarchy of the target, the detail view can be collapsed.

 The settings that are controlled by the toolbar and its toolbar items impact UI elements in the window's content view. For this reason, MainWindowController, its extensions for individual toolbar items, and the subclasses of NSToolbarItem are limited to management of the toolbar items themselves, while their more general impacts are managed by MainContentViewController. MainContentViewController also manages the toolbar items in response to global changes.
 
 Validation of UI elements in the content view is handled by UI Browser's UserControlValidations protocol and its `ValidatedUserControlItem` subprotocol of the `NSValidatedUserInterfaceItem` formal protocol, both of which are declared in UserControlValidation.swift. Toolbar item validation is handled separately by overriding NSToolbarItem in ValidatedToolbarItem.swift, as described in <https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Toolbars/Tasks/ValidatingTBItems.html#//apple_ref/doc/uid/20000753-BAJGFHDD>.
 
 Validation of menu items in the menubar that have the same action as a user control is handled by the validateMenuItem(_:) NSMenuItemValidation formal protocol method implemented in the target of the action method, such as MasterSplitItemViewController.
 
See `MainSplitViewController` for additional information.
 */
class MainContentViewController: NSViewController {
    
    // MARK: - PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    /// A type property that gives access to this object from any other object by referencing `MainContentViewController.sharedInstance`. `NSApp.mainWindow!.contentViewController as! MainContentViewController` cannot be used because `mainWindow` might be `nil` when the application is inactive or hidden.
    static private(set) var sharedInstance: MainContentViewController! // set to self in viewDidLoad(); it was created in Main.storyboard at launch
    
    /// An instance property that gives access to the `MainSplitViewController` storyboard scene and its members from this object.
    @objc dynamic var mainSplitViewController: MainSplitViewController! // set in prepare(for:sender:)
    
    /// An instance property that gives access to the `detailSplitViewItem` in the `MainSplitViewController` storyboard scene from this object.
    @objc dynamic var detailSplitViewItem: NSSplitViewItem! // set in prepare(for:sender:)
    
    // See https://cocoa-dev.apple.narkive.com/u0relSKc/safe-cross-references-between-scenes-in-an-os-x-storyboard.
    /// An instance property that gives access to the `MainWindowController` from this object.
    lazy var mainWindowController: MainWindowController? = {
        view.window!.windowController as? MainWindowController
    }()
    
   // MARK: Target
    // A target's accessibility features are usually available to an assistive application like UI Browser by the time the target finishes launching, but a small number of applications have been shown to make accessibility features available shortly after they finish launching. An example is Adobe Photoshop CS6. Older versions of UI Browser therefore scheduled a repeating timer when a target was launched by the chooseAnyTarget(_:) action method to detect when it had made accessibility features available. UI Browser 3 instead relies on KVO of the target's isFinishedLaunching or runningApplications key path for greater efficiency and reliability in determining when the target has reached the point where it might make accessibility features available. It then tests whether the proposed target has made accessibility features available, and it schedules a repeating timer to continue testing for accessibility only if accessibility is not available at that time. The timer is fired only a few times. If accessibility is still not available, the timer expires and presents a "try again" alert. By the time the user opens the Target menu to try again, the application will almost certainly have made accessibility features available, and because it has finished launching the user will find it listed as a running application in the Target menu. Running applications that are listed in the Target menu are tested only once for accessibility and a repeating timer is not scheduled for them, on the assumption that lack of accessibility means the target will never make accessibility features available, due presumably to a bug in the target. UI Browser also uses KVO of a target's "isTerminated" key path to detect when the target is terminated.
    
    /// An `NSRunningApplication` object representing the application that the user last chose using the Choose Target… menu item or an application name menu item in UI Browser's Target menu. It is set when the user chooses the target, if it is running, or, if it is not running, when it finishes launching or is added to NSWorkspace's list of running applications. It is reset to `nil` when the user chooses No Target or SystemWide Target, or when the target is terminated. UI Browser allows targeting only one application at a time. Its name is shown as the Target pop-up button's title and in the main window's title. This global instance property is used throughout UI Browser to refer to the current running application target.
    var runningApplicationTarget: NSRunningApplication?
    // KVO of launchingApplicationTarget's "isTerminated" key path: The runningApplicationTarget NSRunningApplication object is created when the user chooses a new application target using the chooseAnyTarget(_:) or chooseRunningTarget(_:) action method or, if it wasn't already running, when the user chooses it in chooseAnyTarget(_:) and it finishes launching. It is set to nil every time the user chooses No Target in chooseNoTarget(_:) or when the launchingApplicationTarget's KVO observer observes that the target has terminated. When a new runningApplicationTarget is created, it is registered as a KVO observer of launchingApplicationTarget's "isTerminated" key path in the validatedTargetElement(for:) utility method called in the chooseAnyTarget(_:) and chooseRunningTarget(_:) action methods. It is reset to nil when a new runningApplicationTarget is created or when the user chooses No Target or SystemWide Target. It is a global property to prevent it from being deallocated before the observer is unregistered.
    
    /// An `NSRunningApplication` object representing an application that was not running when the user chose it using the `chooseAnyTarget(_:)` action method. It is set when UI Browser launches the chosen target. It is reset to `nil` as soon as the chosen target finishes launching or is added to NSWorkspace's list of running applications, to flag that it is no longer in the process of launching. See TargetMenuExtension's `chooseAnyTarget(_:)` action method for more information.
    var launchingApplicationTarget: NSRunningApplication?
    // KVO of launchingApplicationTarget's "isFinishedLaunching" key path: The launchingApplicationTarget NSRunningApplication object is created only if and when the user chooses a new target in the Open panel presented by the chooseAnyTarget(_:) action method and UI Browser launches it because it is not already running. It is a global property to prevent it from being deallocated before it is unregistered. It is set to nil when launchingApplicationTarget has finished launching. In case the target never finishes launching or is an application that does not rely on NSApplication and therefore does not post an NSApplicationDidFinishLaunchingNotification notification, it is also set to nil in the chooseAnyTarget(_:) or chooseRunningTarget(_:) action method when a new target is chosen or in deinit when UI Browser is terminated.
    
    // The runningApplicationTarget is nil whenever UI Browser is not targeting a running application represented by an NSRunningApplication object. This happens not only when the user chooses No Target in the Target menu but also, for example, when the user attempts to launch a new proposed target and it fails to launch or never finishes launching, and when a runningApplicationTarget that was running is terminated. It is also set to nil when the user chooses SystemWide Target in the Target menu, because the Systemwide accessibility element does not represent a running application. Note that a nil runningApplicationTarget property does not by itself mean that no target is chosen; to make that determination, it is necessary to test whether the currentElementData contains an AccessibleElement object with an NSAccessibilityRole of 'AXSystemWide'.
    
    // MARK: Data Source
    
    // TODO: This is currently used only to distinguish between no target and system-wide target...
    // ... It isn't currently used at all or even set for a running application target...
    // So is there a simpler way? Or will it be needed when I add attribute display, etc.?
    /// Holds the accessibility element hierarchy for the selected `runningApplicationTarget` and the selected element.
    var currentElementData: ElementDataModel?
    
    // MARK: KVO observers
    
    /// A key-value observer of all running applications.
    var runningApplicationsObservation: NSKeyValueObservation?
    
    /// A key-value observer of launchingApplicationTarget's "isTerminated" key path.
    var isTerminatedObservation: NSKeyValueObservation?
    
    /// A key-value observer of `launchingApplicationTarget`'s "isFinishedLaunching" key path.
    var isFinishedLaunchingObservation: NSKeyValueObservation?
    
    // MARK: Miscellaneous constants
    
    /// The text color of destroyed UI elements.
    let destroyedElementColor = NSColor.orange
    
    // MARK: - INITIALIZATION
    
    // TODO: Confirm that deinit is called in appropriate circumstances
    deinit {
        // KVO removes observers automatically when they are deinitialized in Swift 4.
        self.runningApplicationsObservation = nil
        isFinishedLaunchingObservation = nil
        isTerminatedObservation = nil
    }
    
    // MARK: - STORYBOARD SUPPORT
    
    // MARK: NSSeguePerforming Protocol Support
    // NSViewController conforms to the NSSeguePerforming protocol, so it would be redundant to declare conformance here.
    // A Detail button to collapse and reveal the detail split view item is placed in the main window's toolbar. The button's action method is implemented in the DetailButtonExtension on MainWindowController (in DetailButtonExtension.swift) and connected to FirstResponder in Main.storyboard. It toggles the detail split view item's isCollapsed property to collapse and reveal the detail split view item. It uses an animator proxy to cause the collapse and reveal to be animated.
    // By using NSSplitViewController and NSSplitViewItem, the collapsed or revealed state of the bottom split view item is controlled and signaled solely through the split view item's isCollapsed property. Older techniques that relied on a variety of inconsistent tricks, such as hiding the bottom split view or setting its height to 0.0, can be ignored. (However, if delegate methods are used, it would be prudent to remain alert to the possibility that these values are changed and the possible need to counteract them by resetting these values at appropriate times.)
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        // Called when a presentation or embed segue (but not a containment or relationship segue) is about to be performed. Used to obtain information about the controllers that initiated or received the segue.
        
        switch segue.identifier! {
        case "MainContentViewControllerSegueIdentifier":
            mainSplitViewController = segue.destinationController as? MainSplitViewController
            detailSplitViewItem = mainSplitViewController.splitViewItems[1]
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the shared type property to self to give access to this object from any other object by referencing MainContentViewController.sharedInstance.
        MainContentViewController.sharedInstance = self
        
        // Register as an observer of the AccessAuthorizer.didChangeAccessStatusNotification notification in order to select No Target in the Target menu when the user disables accessibility for the client application, which disables most UI Browser controls, and change the state of the Accessibility checkbox.
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccessStatus(_:)), name: AccessAuthorizer.didChangeAccessStatusNotification, object: nil)
        
        // Register as an observer of the AccessibleElement.elementWasDestroyedNotification notification in order to ....
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.elementWasDestroyed(_:)), name: AccessibleElement.elementWasDestroyedNotification, object: nil)
        
        // Register as an observer of the NSApplication.currentControlTintDidChangeNotification notification in order to display the appropriate color for any custom buttons when the user changes the system control tint in the System Preferences General pane's Appearance setting. See https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/DrawColor/Tasks/SystemTintAware.html. The notification method is also called in the AppDelegate.applicationDidBecomeActive(_:) and applicationDidResignActive(_:) NSApplicationDelegate delegate methods because the button must appear graphite while the application is inactive. The call in AppDelegate.applicationDidBecomeActive(_:) also sets the appropriate color when the application is launched.
        NotificationCenter.default.addObserver(self, selector: #selector(systemTintDidChange), name: NSColor.currentControlTintDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
    }
    
    // TODO: Is this needed?...
    // ... see https://developer.apple.com/library/archive/qa/qa1871/_index.html
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // MARK: - APPLICATION MANAGEMENT
    
    /**
     Returns the display name or path of a running application.
     
     The display name is the localized name of the application or a new name the user gave to the application in the Finder. The display name is preferred for user display per Apple Technical Q&A QA1544 because it displays any name change the user might have made in the Finder.
     
     *See also:* `displayNameForTargetApplication()`.
     
     - parameter runningApplication: An NSRunningApplication object for a running application.
     
     - returns: The display name or path of the running application, or an empty string if an error occurs.
     */
    func displayName(for runningApplication: NSRunningApplication) -> String {
        
        if let bundlePath = runningApplication.bundleURL?.path {
            return FileManager.default.displayName(atPath: bundlePath)
        } else if let executablePath = runningApplication.executableURL?.path {
            return FileManager.default.displayName(atPath: executablePath)
        } else {
            // Should never get here even though bundleURL and executableURL both return optionals.
            assertionFailure("Failed to obtain bundle URL or executable URL of running application to set its display name")
            return ""
        }
    }
    
    /**
     Returns the display name or path of the running application that is UI Browser's current target.
     
     This method should be called only if a current target has been chosen.
     
     The display name is the localized name of the application, or a new name the user gave to the application in the Finder. It is used in the title of UI Browser's main window and to populate the Target menu with the display names or paths of running applications. The display name is preferred for user display over the localized name and names derived from the appplication's URL or path per Apple Technical Q&A QA1544 because it displays any name change the user might have made in the Finder.
     
     *See also:* `displayName(for:)`.
     
     - returns: The display name or path of the running application, or an empty string if an error occurs.
     */
    func displayNameForTargetApplication() -> String {
        // Returns the display name or path of the current running application target, or an empty string if an error occurs. This method should be called only if there is a current running application target. The display name is the localized name of the application, or a new name the user gave to the application in the Finder. It is used in the title of UI Browser's main window and to populate the Target menu with the display names or paths of running applications. The display name is preferred for user display over the localized name and names derived from the appplication's URL or path per Apple Technical Q&A QA1544 because it displays any name change the user might have made in the Finder.
        assert(runningApplicationTarget != nil, "Called MainContentViewController.displayNameForTargetApplication() when runningApplicationTarget is nil")
        
        return displayName(for: runningApplicationTarget!)
    }
    
    // TODO: Consider moving this to AppDelegate.
    // TODO: Consider possible role for applicationWillUpdate NSApp delegate method.
    /**
     Updates UI Browser's data and display to reflect a new target after the target was successfully validated in validatedTargetElement(for:), or clears the data and display if the target is nil because the user chose No Target or SystemWide Target. Both parameters are optional, and the second parameter defaults to nil so that it can be omitted when the user chooses No Target or SystemWide Target from the Target menu.
     The method clears the old current target's KVO observers; sets the new current running application target to the proposed target; updates the Target pop-up button's title and the main window's title; unhides and activates the new current running application target as needed and sets up a KVO observer for its isTerminated key path; updates UI Browser's data source and the display of its main window with calls to updateData(usingTargetElement:) and updateView(); and posts a DID_CHOOSE_TARGET_NOTIFICATION_NAME notification so auxiliary windows can update their views. It is called only if the target is a running application that has made accessibility features available to assistive applications, or nil because the user chose No Target.
     Called when the user chooses a new target in the Target menu, by MainContentViewController's chooseNoTarget(_:) and chooseRunningTarget(_:) action methods, by its chooseAnyTarget(_:) action method if the application was already running, and by the KVO observer if the application had to be launched by the chooseAnyTarget(_:) action method because it was not already running (all in TargetMenuExtension.swift). Also called from [[[displayElementInNewApplication(???)]]] triggered by the system-wide hot key, the follow focus handler, and the Screen Reader's Find in Browser button, all of which may choose a new target; and from [[[didSwitchFrontApplication(???)]]] when the user activates another application while in Follow Focus mode.
     If this method is called to set up a newly chosen running application target, it is always preceded by a call to validatedTargetElement(for:), which creates and returns the validated AccessibleElement object passed into this method as the element value. If validatedTargetElement(forTarget:withElement:) returns nil, validation failed and this method is not called.
     The equivalent UI Browser 2 method is -[PFBrowserController setBrowserForPath:withTimer:].
     
     - parameter target: An NSRunningApplication object for a running application, or nil for No Target or SystemWide Target.
     
     - parameter element: A root application AccessibleElement object for a running application or the system-wide AccessibleElement object for SystemWide Target, or nil for No Target.

     */
    func updateApplication(forNewTarget target: NSRunningApplication?, usingTargetElement element: AccessibleElement? = nil) {
        // TODO: Does element need a delegate?...
        // ... What if it's application or system-wide?
        
        // Clean up the old running application target, if any.
        if runningApplicationTarget != nil {
            // KVO removes observers automatically when they are deinited in Swift 4.
            isTerminatedObservation = nil
            isFinishedLaunchingObservation = nil
        }
        // TODO: [self unhighlightAction:sender];
        // TODO: ditto follow focus mode?
        
        // Set the new running application target to the proposed target. From this point forward, methods that do not take a target parameter rely on the new running application target property's value, and UI Browser cannot recover from errors in setting up the new target by preserving or restoring the old target but must instead deal with errors affecting the new target.
        runningApplicationTarget = target
        
        currentElementData = nil
        if runningApplicationTarget == nil {
            // Prepare the new system-wide target, if any.
            if element?.AXRole == "AXSystemWide" {
                currentElementData = ElementDataModel.sharedInstance
            }
        } else {
        
        // Prepare the new running application target, if any.
//        if runningApplicationTarget != nil {
            // Register the new runningApplicationTarget for KVO of isTerminated.
            // In Swift 4, KVO observes changes using this closure. KVO removes observers automatically when they are deinited in Swift 4.
            self.isTerminatedObservation = self.runningApplicationTarget!.observe(\.isTerminated) { (runningApplicationTarget, change) in
                
                // This KVO observer closure fires when the target terminates. It sets runningApplicationTarget to nil and updates UI Browser's data and display.
                self.isTerminatedObservation = nil
                self.runningApplicationTarget = nil
                self.updateApplication(forNewTarget: nil)
            }
            
            // Unhide the new target if it is hidden.
            if runningApplicationTarget!.isHidden {
                runningApplicationTarget!.unhide()
            }
            
            // Activate the new target if the CHOOSING_TARGET_ACTIVATES_APPLICATION_DEFAULTS_KEY preference is set.
            if runningApplicationTarget!.isActive && (UserDefaults.standard.bool(forKey: CHOOSING_TARGET_ACTIVATES_APPLICATION_DEFAULTS_KEY)) {
                runningApplicationTarget!.activate(options: .activateIgnoringOtherApps)
            }
        }
        
        // Update UI Browser's data and, if successful, update the main window's content view for the new running application target or system-wide target.
        if updateData(usingTargetElement: element) {
            updateView()
            
            // Update UI Browser's interface to display the new target; or better to move this to udpateView()
            // TODO: [self validateControls];
            // Update the Target pop-up button's title and the window title.
            mainWindowController!.updateTargetPopUpButtonTitle()
            mainWindowController!.updateWindowTitle()

            
            // Notify observers that the new target has been chosen so they can update their views.
            if runningApplicationTarget != nil {
                let displayName = displayNameForTargetApplication()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: DID_CHOOSE_TARGET_NOTIFICATION_NAME), object: self, userInfo: [TARGET_NAME_KEY: displayName])
            } else {
                // TODO: Handle notification of No Target or SystemWide Target
            }
        }
    }
    
    /**
     Updates UI Browser's data source representing the accessibility hierarchy for a new target using the validated root application UI element or the system-wide element.
     Called by updateApplication(forNewTarget:usingTargetElement:). For a new target application, the caller has already set the global current running application target property.
     The equivalent UI Browser 2 method is -[PFBrowserController setBrowserForPath:withTimer:].
     */
    func updateData(usingTargetElement element: AccessibleElement?) -> Bool {
        let datasource = ElementDataModel.sharedInstance
        if element == nil {
            // The user chose No Target, so clear the data source.
            datasource.clearDataModel()
        } else {
            // The user chose SystemWide Target or an application, so use the targetElement parameter value to update the data source.
            if element!.isRole(NSAccessibility.Role.systemWide.rawValue) {
                // The system-wide element has no children.
                datasource.updateDataModel(forSystemWideElement: element!)
            } else {
                datasource.updateDataModel(forApplicationElement: element!)
            }
        }
        
        return true
    }
    
    /*
     func clearTarget() {
     // The equivalent UI Browser 2 method is -[PFBrowserController clearBrowser].
     // Clears global target info and the user interface when the user chooses No Target in the main menu bar's Target menu or the Target pop-up button's menu.
     // Clear global target info.
     runningApplicationTarget = nil
     ElementDataModel.shared.clearDataModel()
     
     // Clear the user interface.
     clearTargetDisplay()
     
     // Post DID_CHOOSE_TARGET_NOTIFICATION_NAME notification so other windows can update.
     let displayName = NSLocalizedString(NO_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to deselect target")
     NSNotificationCenter.defaultCenter().postNotificationName(DID_CHOOSE_TARGET_NOTIFICATION_NAME, object: self, userInfo: [CHOSEN_TARGET_APP_NAME_KEY: displayName])
     }
     */
    
    func updateView() {
        // Updates the main content view when a new target is chosen to show its initial contents. This updates the accessibility hierarchy element view in the browser, outline or list view in the master split view pane, and updates the attributes, actions or notifications view in the detail split view pane. Views in auxiliary windows update in response to the DID_CHOOSE_TARGET_NOTIFICATION_NAME notification posted in updateApplication(forNewTarget:usingTargetElement:).
        // Called by updateApplication(forNewTarget:usingTargetElement:). The caller has already set global target information for the new target and set the Target pop-up button's menu title, and the data model has already been updated.
        // The equivalent UI Browser 2 method is -[PFBrowserController setBrowserForPath:withTimer:].
        
        // Clear the master split item view. This is necessary when the user chooses No Target. For the browser view, it is also necessary when the user chooses SystemWide Target or an application target to work around a bug in NSBrowser that fails to clear the previous column titles for columns not loaded by the new target.
        MasterSplitItemViewController.sharedInstance.clearView()
        
        if !ElementDataModel.sharedInstance.isEmpty {
            // The current target is the system-wide element or a running application.
            
            // Update the selected tab view item of the master tab view.
            MasterSplitItemViewController.sharedInstance.updateView()
            
            // Update the selected tab view item of the bottom tab view.
            //        DetailSplitItemViewController.controller.updateDetailSplitItemForElement(targetElement!)
        }
        /*
         let bottomIdentifier = accessTabView.selectedTabViewItem!.identifier as? String
         switch bottomIdentifier! {
         case ATTRIBUTES_IDENTIFIER:
         // Update attributes view.
         // TODO: Only a few attributes are supported by the system-wide element: ...
         // ... kAXFocusedApplicationAttribute is the key attribute ...
         // ... but there are a total of 5: AXRole, AXRoleDescription, AXFocusedUIElment, AXFocusedApplication, and AXIdentifier.
         attributesViewController.sharedAttributeDataSource.updateDataModelForSelectedElement(selectedElement)
         attributesViewController.updateAttributeView()
         case ACTIONS_IDENTIFIER:
         // Update actions view.
         // TODO: write this
         NSBeep()
         case KEYSTROKES_IDENTIFIER:
         // Update keystrokes view.
         // TODO: write this
         NSBeep()
         case NOTIFICATIONS_IDENTIFIER:
         // Update notifications view.
         // TODO: write this
         NSBeep()
         default:
         preconditionFailure("Unexpectedly entered default case in switch statement")
         }
         */
        // Validate all controls.
        //       validateWindowControls()
    }
    
    /*
     func clearTargetDisplay() {
     // Clears all information displayed about the old target when it is being abandoned, whether by choosing No Target or a new target. This does not clear the Target pop-up button's title because it is used to display the user's new choice. If the Target pop-up button's title needs to be cleared, as in didToggleAccess, clear it explicitly. Called by clearTarget() and observeValueForKeyPath(_:ofObject:change:context:).
     // Set the window title and the menu bar Window menu's window menu item title to No Target, and disable a pop-up menu showing the target's path when the title bar is Command- or Control-clicked.
     let displayName = NSLocalizedString(NO_TARGET_MENU_ITEM_TITLE, comment: "Title of menu item to deselect target")
     MainWindowController.sharedInstance.updateWindowTitleWithTargetName(displayName)
     view.window!.representedURL = nil
     
     // Set the Target pop-up button to No Target in case the user used the menu bar's Target menu (which does not set the Target pop-up button's title).
     clearTargetPopUpButton()
     // TODO: change that call to updateTargetPopUpButtonTitle(nil)
     
     // Clear the selected tab view item of the master tab view.
     let selectedIndex = MasterTabViewController.controller.selectedTabViewItemIndex
     switch selectedIndex {
     case MasterTabViewItemIndex.Browser.rawValue:
     // Clear element browser view.
     BrowserTabItemViewController.controller.clearView()
     case MasterTabViewItemIndex.Outline.rawValue:
     // Clear element outline view.
     // TODO: write this
     NSBeep()
     case MasterTabViewItemIndex.List.rawValue:
     // Clear update element table view.
     // TODO: write this
     NSBeep()
     default:
     preconditionFailure("Unexpectedly entered default case in switch statement")
     }
     
     /*
     // Clear the selected tab view item of the top tab view.
     let topTabViewItemIndex = NSUserDefaults.standardUserDefaults().integerForKey(MASTER_TAB_VIEW_ITEM_DEFAULTS_KEY)
     switch topTabViewItemIndex {
     case TopTabViewItem.Browser.rawValue:
     // Clear element browser view.
     BrowserTabItemViewController.controller.clearView()
     case TopTabViewItem.Outline.rawValue:
     // Clear element outline view.
     // TODO: write this
     NSBeep()
     case TopTabViewItem.List.rawValue:
     // Clear update element table view.
     // TODO: write this
     NSBeep()
     default:
     preconditionFailure("Unexpectedly entered default case in switch statement")
     }
     
     // Clear the selected tab view item of the bottom tab view.
     let bottomIdentifier = accessTabView.selectedTabViewItem!.identifier as? String
     switch bottomIdentifier! {
     case ATTRIBUTES_IDENTIFIER:
     // Clear attributes view.
     // TODO: write this
     NSBeep()
     case ACTIONS_IDENTIFIER:
     // Clear actions view.
     // TODO: write this
     NSBeep()
     case KEYSTROKES_IDENTIFIER:
     // Clear keystrokes view.
     // TODO: write this
     NSBeep()
     case NOTIFICATIONS_IDENTIFIER:
     // Clear notifications view.
     // TODO: write this
     NSBeep()
     default:
     preconditionFailure("Unexpectedly entered default case in switch statement")
     }
     
     // Validate all controls.
     validateWindowControls()
     */
     // TODO: add more from -[PFBrowserController clearBrowser]?
     }
     */
    
    // MARK: - ACTION METHODS AND SUPPORT
    // Action methods for individual controls are declared in their extensions in separate files.
    
    // TODO: Write this later
    /*
     @IBAction func chooseTerminology(sender: AnyObject) {
     // Action method for the Terminology submenu in the View > Terminology menu and the terminology popup button in the master (top) split item. Connected from the individual View > Terminology submenu's menu items and from the terminology popup button to First Responder in Main.storyboard. Main.storyboard also connects a selected tag value binding between the popup button and the user defaults "terminology" key path so that the selected item in the popup menu will change automatically when the terminology preference is changed from the View > Terminology menu. The menu items' tags are set from 0 to 5 corresponding to the Terminology enum's rawValues in Defines.h. Sets the user defaults setting for the key TERMINOLOGY_DEFAULTS_KEY, and then calls updateTerminology() to change the terminology of all views that display accessibility terms based on the new user defaults setting. The key and its available values are declared in Defines.swift. The user defaults setting is initialized to Natural Language at first launch in the initialize() class method.
     if sender is NSPopUpButton { // the Terminology popup button
     NSUserDefaults.standardUserDefaults().setInteger(sender.selectedItem!!.tag, forKey: TERMINOLOGY_DEFAULTS_KEY)
     } else if sender is NSMenuItem { // in the View > Terminology menu item in the menu bar
     NSUserDefaults.standardUserDefaults().setInteger(sender.tag, forKey: TERMINOLOGY_DEFAULTS_KEY)
     }
     updateTerminology()
     }
     */

    // MARK: - NOTIFICATION METHODS
    
    /**
     Clears the application and sets the title of the Target pop-up button to No Target when access is disabled.
     
     This notification method is called when UI Browser's access status is changed in the *Accessibility* list in the *Privacy* tab of the *Security & Privacy* pane in *System Preferences*. `MainContentViewController` is registered to observe the `didChangeAccessStatusNotification` notification in `viewDidLoad()`.
     
     - parameter notification: The `AccessAuthorizer.didChangeAccessStatusNotification` notification.
     */
    @objc func didChangeAccessStatus(_ notification: NSNotification) {
        if let targetPopUpButton = mainWindowController!.targetPopUpButton {
            if !(notification.userInfo![AccessAuthorizer.accessStatusKey] as! Bool) {
                // Update UI Browser for no target. This passes nil to both optional parameters.
                updateApplication(forNewTarget: nil)
                targetPopUpButton.title = NO_TARGET_MENU_ITEM_TITLE
            }
        }
        
        // Trigger validation of user controls that conform to the ValidatedUserControlItem protocol and observe NSWindow.didUpdateNotification. Apple's method documentation: "This method is especially useful for making sure menus are updated to reflect changes not initiated by user actions, such as messages received from remote objects."
        NSApp.setWindowsNeedUpdate(true)
    }
    
    @objc func systemTintDidChange(_ notification: Notification) {
        // Notification method triggered by the NSApplication.currentControlTintDidChangeNotification notification in order to display the appropriate color for any custom buttons when the user changes the system control tint in the System Preferences General pane's Appearance setting. See https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/DrawColor/Tasks/SystemTintAware.html. The notification method is also called in the AppDelegate.applicationDidBecomeActive(_) and applicationDidResignActive(_) NSApplicationDelegate delegate methods because the button must appear graphite while the application is inactive.
        
        // TODO: Reimplement this if decide to use my custom Detail buttom images.
        // mainWindowController!.setDetailButtonColor()
    }

    // MARK: - ALERTS
    
    func sheetForApplicationFailedToLaunch(name: String, error: NSError) {
        // Presents sheet to handle the failure of an application to launch. Called in the chooseAnyTarget(_:) action method.
        
        let alert = NSAlert();
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = NSLocalizedString("Couldn't launch the application", comment: "Alert message text for failed to launch the application")
        let description = error.localizedDescription
        let failureReason = error.localizedFailureReason != nil ? error.localizedFailureReason!: ""
        alert.informativeText = description + " " + failureReason + "\n\n" + NSLocalizedString("Try again or choose another application.", comment: "Alert informative text for failed to launch the application")
        alert.showsHelp = true
        alert.helpAnchor = "UIBr020using0011choosetarget"
        // alert.delegate = self // needed only if the delegate overrides standard help-anchor lookup behavior, per the NSAlertDelegate reference document
        alert.beginSheetModal(for: mainWindowController!.window!, completionHandler: nil)
    }
    
    func sheetForApplicationUIElementNotCreated() {
        //    func sheetForApplicationUIElementNotCreated(name: String) {
        // Presents sheet to handle the failure of a target to make accessibility features available to assistive applications. The application may have crashed or may not support the accessibility API at all, or it may simply have failed to create the application UI element before it finished launching or within a short time afterward. Called in the repeating timer created in a isFinishedLaunching or runningApplications KVO observer in the chooseAnyTarget:(_") action method.
        
        let alert = NSAlert();
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = NSLocalizedString("Can't access the target", comment: "Alert message text for cannot access the target");
        alert.informativeText = NSLocalizedString("The chosen application may need more time to make accessibility features available. Click Continue to try again.", comment: "Alert informative text for cannot access the target")
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: "Name of Continue button"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Name of Cancel button"))
        alert.showsHelp = true
        alert.helpAnchor = "UIBr020using0018getsetattributes"
        // alert.delegate = self // needed only if the delegate overrides standard help-anchor lookup behavior, per NSAlertDelegate reference document
        alert.beginSheetModal(for: mainWindowController!.window!) {responseCode in
            if responseCode == NSApplication.ModalResponse.alertFirstButtonReturn { // Continue
                // TODO: This crashes because runningApplicationTarget is not set.
                //self.updateApplication(forNewTarget: self.runningApplicationTarget! usingNewTarget: WHAT???) // try again
            } else { // Cancel
                // Unregister MainWindowController as a KVO observer of targetApplication's "isTerminated" key path.
                if self.runningApplicationTarget != nil {
                    // KVO removes observers automatically when they are deinited in Swift 4.
                    self.isTerminatedObservation = nil
                    self.runningApplicationTarget = nil
                }
                
                // TODO: put something here in place of clearTarget
                //  self.clearTarget()
            }
        }
    }
    
    // MARK: - PROTOCOL SUPPORT
    
    // MARK: NSMenuItemValidation protocol
    
    // TODO: Remove this because menu item validation is handled in MasterSplitItemViewController and other targets of action methods.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Protocol method per the NSMenuValidation formal protocol to enable or disable menu items, except that menu items in the main menu bar's Target menu and the Target popup button's menu are enabled or disabled in AppDelegate's updateTargetMenu(_:) utility method.

        /*
        // All Terminology popup button and AppleScript popdown button menu items are disabled if accessibility is not authorized, except for the selected or title menu item of each.
         switch menuItem.action {
         case #selector(showMasterTabItem):
            return AXIsProcessTrusted()
         case Selector("terminologyPopUpButtonAction:"):
         // This action is connected to the Terminology popup button itself and is therefore the action method for each of its menu items.
         if menuItem.state == NSOnState {
         // Leave the selected menu item enabled even if accessibility is not allowed.
         return isProcessTrusted
         }
         return isProcessTrusted
         case Selector("generateAppleScriptPullDownButtonAction:"):
         // This action is connected to the AppleScript popup button itself and is therefore the action method for each of its menu items.
         if menuItem.state == NSOnState {
         // Leave the selected menu item enabled even if accessibility is not allowed.
         return isProcessTrusted
         }
         return isProcessTrusted
         default:
            return true
//         return super.validateMenuItem(menuItem)
         }
             */
        return true // remove this line when finish writing this method?
    }
    
}

// MARK: AccessibleElementDelegate formal protocol

extension MainContentViewController: AccessibleElementDelegate {
    
    // TODO: Figure out why this is called twice....
    // It logs that there are 2 "cheeseb" windows with different memory addresses! Why?
    @objc func elementWasDestroyed(_ notification: Notification) {
        print("TRIGGERED DESTRUCTION DELEGATE METHOD!")
        let element = notification.object as! AccessibleElement
        print("element is \(String(describing: notification.object))")
        let destroyed: Bool = element.isDestroyed
        print("isDestroyed property value is \(destroyed)")
        let cachedAttributes = notification.userInfo
        print("cached attributes are \(String(describing: cachedAttributes))")
        
        //        BrowserTabItemViewController.shared.elementBrowser.validateVisibleColumns()
        print("destroyedRowIndex is \(element.indexPath![element.indexPath!.count - 1])")
        let destroyedRowIndexes = IndexSet(integer: element.indexPath![element.indexPath!.count - 1])
        let destroyedColumn = element.indexPath!.count - 1
        print("destroyedColumn is \(destroyedColumn)")
        BrowserTabItemViewController.sharedInstance.elementBrowser.reloadData(forRowIndexes: destroyedRowIndexes, inColumn: destroyedColumn)
    }
}
