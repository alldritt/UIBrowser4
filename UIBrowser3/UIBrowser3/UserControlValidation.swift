//
//  UserControlValidation.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2019-04-15.
//  Copyright © 2019-2020 PFiddlesoft. All rights reserved.
//

import Foundation

/**
 UserControlValidation.swift declares UI Browser's `UserControlValidations' protocol, as well as its `ValidatedUserControlItem` subprotocol of the `NSValidatedUserInterfaceItem` formal protocol. It also implements subclasses of Cocoa user controls such as NSButton to conform them to these protocols.
 
 These protocols for the most part follow Bill Cheeseman, "Cocoa Recipes for Mac OS X: The Vermont Recipes" (Peachpit Press, 2nd Ed, 2010), Recipe 4, Step 4. The main difference is that UI Browser's validated subclasses register to observe the Notification Center's NSWindow.didUpdateNotification to trigger validation, as described in Erik M. Buck and Donald A. Yacktman, "Cocoa Design Patterns" (Addison Wesley 2010), pp. 228-29, instead of implementing the windowDidUpdate(_:) NSWindowDelegate method in MainWindowController to call the validate(_:) protocol method directly. See also Apple's "User Interface Validation" (2007) document; and the AppKit *NSUserInterfaceValidation.h* header file.
 
 Note that the validate() protocol method cannot have a default implementation in a protocol extension due to this 2017 decision by the Swift team: "@objc methods cannot be contained in protocol extensions," https://bugs.swift.org/browse/SR-3349?focusedCommentId=21826&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-21826.
 */

/**
 Declares UI Browser's `UserControlValidations` protocol. MasterSplitItemViewController conforms to this protocol.
 */
@objc protocol UserControlValidations {
    func validateUserControlItem(_ item: ValidatedUserControlItem) -> Bool
}

 /**
 Declares UI Browser's `ValidatedUserControlItem` subprotocol of the `NSValidatedUserInterfaceItem` formal protocol. The user controls implemented here conform to this protocol.
 
 In order to be validated, a UI Browser control such as a button must declare that it conforms to the `ValidatedUserControlItem` subprotocol. To conform, it must implement the `validate(_:)` method to call the `validateUserControlItem(_:)` method declared in the `UserControlValidations` protocol.
 
 A validated user control must also implement the `action` and `tag` properties declared in the parent `NSValidatedUserInterfaceItem` protocol from which the `ValidatedUserControlItem` subprotocol inherits. AppKit's `NSControl` already implements `action` and `tag` properties that are inherited by its subclasses. Apple's protocol documentation lists which subclasses of NSControl, such as NSButton, declare conformance to the `NSValidatedUserInterfaceItem` protocol.

 UI Browser's "validator" for most buttons in the main content view is `MainSplitItemViewController`. It declares that it conforms to the `UserControlValidations` formal protocol and implements the `validateUserControlItem(_:)` method declared in the protocol.
 */
 @objc protocol ValidatedUserControlItem: NSValidatedUserInterfaceItem {
    func validate(_ notification: Notification)
}

/**
 ValidatedButton is a subclass of NSButton that conforms to the `ValidatedUserControlItem` subprotocol of the `NSValidatedUserControlItem` formal protocol by implementing the subprotocol's `validate(_:)` method.
 
 To submit a button to user interface validation in order to enable or disable it automatically based on current conditions every time the main window is updated, set its class to ValidatedButton instead of NSButton in Main.storyboard.
 
 AppKit's `NSButton` class does not declare that it conforms to the parent `NSValidatedUserInterfaceItem` protocol, but it does implement the `action` and `tag` properties required by that protocol by inheriting them from `NSControl`. By omitting the declaration of conformance, `NSButton` gives subclasses the option to be validated or not. Any subclass of `NSButton` can choose to be a validated control by declaring that it conforms to the `NSValidatedUserInterfaceItem` protocol or to UI Browser's `ValidatedUserControlItem` subprotocol. It can conform to the latter by implementing the `validate(_:)` method declared in the subprotocol; the `action` and `tag` properties required by the parent `NSValidatedUserInterfaceItem` protocol are already implemented in `NSControl`.
 
 Declaring conformance to the `ValidatedUserControl` protocol and implementing the awakeFromNib() override method and the `validate(_:)` protocol method ensures that a `ValidatedUserControl` button will be validated. This means that its `validate(_:)` protocol method will be called when the NSWindow.didUpdateNotification notification is received every time the main window updates. Windows normally update once in every iteration of the event loop, which is normally sufficient. They can be forced to update at any other time by calling NSApp.updateWindows() or NSApp.setWindowsNeedUpdate(_:). UI Browser calls NSApp.setWindowsNeedUpdate(_:) in MainContentViewController didChangeAccessStatus(_:) notification method that is triggered whenever access is denied to UI Browser behind its back, for example, in System Preferences.
 
 `NSButton` does declare that it conforms to the `NSUserInterfaceValidations` protocol. This means, according to Apple's protocol documentation, that "an instance may be the target of a user interface element and need to conditionally enable or disable the element based on the current state of the instance." `NSControl` implements a writable `isEnabled` property, which the `validate(_:)` protocol method implemented here sets by calling the `validateUserControlItem(_:)` `UserControlValidations` protocol method.
 */
class ValidatedButton: NSButton, ValidatedUserControlItem {
    // For the master split item view's Highlight checkbox, Follow Focus checkbox, Screen Reader button, Refresh button, Report button and Keystrokes button.
    
    /// Register to observe NSWindow.didUpdateNotification
    override open func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(validate(_:)), name: NSWindow.didUpdateNotification, object: self.window)
    }
    
    /// Implementation of the validate(_:) protocol method declared by UI Browser's `ValidatedUserControlItem` protocol.
    @objc func validate(_ notification: Notification) {
        // Protocol method per UI Brower's ValidatedUserControlItem subprotocol of the NSValidatedUserInterfaceItem formal protocol.
        
        // The user control's `action`.
        guard let action = action else {
            assertionFailure("The user control being validated requires an action method implemented in MasterSplitItemViewController and connected in Main.storyboard.")
            return
        }
        
        // The user control's `target`.
        let proposedTarget = MasterSplitItemViewController.sharedInstance
        let validator = NSApp.target(forAction: action, to: proposedTarget, from: self) as AnyObject

        // Validate the control, enabling or disabling it.
        if validator is UserControlValidations {
            isEnabled = validator.validateUserControlItem(self)
        } else {
            // Enable the control unless other code disables it.
            isEnabled = true
        }
    }
    
}

/**
 A subclass of NSPopUpButton that conforms to the `ValidatedUserControlItem` subprotocol of the `ValidatedUserControlItem` formal protocol by implementing the subprotocol's `validate(_:)` method.
 
 To submit a pop-up button to user interface validation in order to enable or disable it automatically based on current conditions every time the main window is updated, set its class to ValidatedPopUpButton instead of NSPopUpButton in Main.storyboard.
 
 See the ValidatedButton class implementation for more information.
 
 */
class ValidatedPopUpButton: NSPopUpButton, ValidatedUserControlItem {
    // For the master split item view's Generate AppleScript pull-down button and Terminology pop-up button.
    
    /// Register to observe NSWindow.didUpdateNotification
    override open func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(validate(_:)), name: NSWindow.didUpdateNotification, object: self.window)
    }
    
    /// Implementation of the validate(_:) protocol method declared by UI Browser's `ValidatedUserControlItem` protocol.
    @objc func validate(_ notification: Notification) {
        // Protocol method per UI Brower's ValidatedUserControlItem subprotocol of the NSValidatedUserInterfaceItem formal protocol.
        
        /// The user control's action.
        guard let action = action else {
            assertionFailure("The user control being validated requires an action method implemented in MasterSplitItemViewController and connected in Main.storyboard.")
            return
        }
        
        // The user control's `target`.
        let proposedTarget = MasterSplitItemViewController.sharedInstance
        let validator = NSApp.target(forAction: action, to: proposedTarget, from: self) as AnyObject
        
        // Validate the control, enabling or disabling it.
        if validator is UserControlValidations {
            isEnabled = validator.validateUserControlItem(self)
        } else {
            // Enable the control unless other code disables it.
            isEnabled = true
        }
    }
    
}
    
/**
 A subclass of NSSegmented Control that conforms to the `ValidatedUserControlItem` subprotocol of the `ValidatedUserControlItem` formal protocol by implementing the subprotocol's `validate(_:)` method.
     
 To submit a segmented control to user interface validation in order to enable or disable it automatically based on current conditions every time the main window is updated, set its class to ValidatedSegmentedControl instead of NSSegmentedControl in Main.storyboard.
     
 `NSSegmentedControl` does not declare that it conforms to the `NSUserInterfaceValidations` protocol.
 
 See the ValidatedButton class implementation for more information.
     
 */
class ValidatedSegmentedControl: NSSegmentedControl, ValidatedUserControlItem {
    // For the master split item view's Master Tab View Selector segmented control.
    
    /// Register to observe NSWindow.didUpdateNotification
    override open func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(validate(_:)), name: NSWindow.didUpdateNotification, object: self.window)
    }
    
    /// Implementation of the validate(_:) protocol method declared by UI Browser's `ValidatedUserControlItem` protocol.
    @objc func validate(_ notification: Notification) {
        // Protocol method per UI Brower's ValidatedUserControlItem subprotocol of the NSValidatedUserInterfaceItem formal protocol.
        
        /// The user control's action connected in Main.storyboard.
        guard let action = action else {
            assertionFailure("The user control being validated requires an action method implemented in MasterSplitItemViewController and connected in Main.storyboard.")
            return
        }
        
        // The user control's `target`.
        let proposedTarget = MasterSplitItemViewController.sharedInstance
        let validator = NSApp.target(forAction: action, to: proposedTarget, from: self) as AnyObject
        
        // Validate the control, enabling or disabling it.
        if validator is UserControlValidations {
            isEnabled = validator.validateUserControlItem(self)
        } else {
            // Enable the control unless other code disables it.
            isEnabled = true
        }
    }
    
}
