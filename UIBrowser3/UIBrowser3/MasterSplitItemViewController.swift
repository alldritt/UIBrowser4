//
//  MasterSplitItemViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// MasterSplitItemViewController receives one of the split items relationship segues triggered by MainSplitViewController in Main.storyboard; the master (top) pane of the master split view is always visible and is therefore instantiated at application launch. It automatically calls loadView() to instantiate and load the main split view's master tab view. MasterSplitItemViewController's view contains, along with other UI elements, a container view that initiates or triggers an embed segue connected to MasterTabViewController in Main.storyboard; the tab view replaces the container view at application launch. MasterSplitItemViewController also manages other UI elements that are located in the master pane view because they are relevant to the master pane as a whole rather than to the individual tab view items of the tab view.
// The masterTabViewSelector segmented control allows the user to choose a browser, outline or list view to display the current accessibility hierarchy. The segmented control is bound to NSTabViewController.selectedTabViewItemIndex in Main.storyboard, and it is set in the View > UI Elements > Show menu items' action method. The current value of selectedTabViewItemIndex is used here in updateView(), showView(), clearView() and refreshApplication() to call the associated method in whichever tab view controller is currently selected.

import Cocoa
import PFAssistiveFramework4

class MasterSplitItemViewController: NSViewController, UserControlValidations, NSMenuItemValidation {

    // MARK: - PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    /// A type property that gives access to this object from any other object by referencing MasterSplitItemViewController.sharedInstance.
    static private(set) var sharedInstance: MasterSplitItemViewController! // set to self in viewDidLoad(); it was created in Main.storyboard at launch
    
    /// An instance property that gives access to the masterTabViewController storyboard scene and its members from this object.
    @objc dynamic var masterTabViewController: MasterTabViewController! // set in prepare(for:sender:)

    // MARK: IBOutlets and other views and controls
    // The Master split item view's outlets are declared here, and their action methods and other code are implemented in several user control extensions on the Master split item view controller. Their outlets are declared here rather than in the user control extensions because extensions may not contain stored properties.
    
    //@IBOutlet weak var masterTabView: NSTabView!
    @IBOutlet weak var highlightButton: NSButton!
    @IBOutlet weak var followFocusButton: NSButton!
    @IBOutlet weak var screenReaderButton: NSButton!
    @IBOutlet weak var applescriptPullDownButton: NSPopUpButton!
    @IBOutlet weak var masterTabViewSelector: NSSegmentedControl!
    @IBOutlet weak var refreshApplicationButton: NSButton!
    @IBOutlet weak var reportButton: NSButton!
    @IBOutlet weak var keystrokesButton: NSButton!
    @IBOutlet weak var terminologyPopUpButton: NSPopUpButton!
    
    // MARK: - STORYBOARD SUPPORT
    
    // MARK: NSSeguePerforming Protocol Support
    // NSViewController conforms to the NSSeguePerforming protocol, so it would be redundant to declare conformance here.

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        // NSSequePerforming protocol method. Called when a presentation or embed segue (but not a containment or relationship segue) is about to be performed. Used to obtain information about the controllers that initiated or received the segue.
        switch segue.identifier! {
        case "MasterSplitItemViewControllerSegueIdentifier":
            masterTabViewController = segue.destinationController as? MasterTabViewController
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the shared type property to self to give access to this object from any other object by referencing MasterSplitItemViewController.sharedInstance.
        MasterSplitItemViewController.sharedInstance = self
   }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Validate user controls in the main content view that conform to UI Browser's ValidatedUserControlItem subprotocol of the NSValidatedUserInterfaceItem formal protocol, or to the formal protocol itself.
//        MainContentViewController.sharedInstance.validateUserControls()
    }
    
   func currentTabItemSelectElementAction() -> Selector {
        // Return the path control pop-up menu's menu item action method selector for the tab item currently selected in the masterTabViewSelector segmented control. The selector is used in ElementPathControlManager menuNeedsUpdate() to attach the action to every path control menu item.
        let selectedIndex = masterTabViewController.selectedTabViewItemIndex
        switch selectedIndex {
        // TODO: complete these cases when implement action methods for browser and outline view.
        case MasterTabViewItemIndex.Browser.rawValue:
            // Return the element browser view.
            return #selector(BrowserTabItemViewController.sharedInstance!.selectElement)
//            return BrowserTabItemViewController.sharedInstance!.selectElement
        case MasterTabViewItemIndex.Outline.rawValue:
            // Return the element outline view selectAction(_:) selector.
            return #selector(OutlineTabItemViewController.sharedInstance!.selectElement)
        case MasterTabViewItemIndex.List.rawValue:
            // Return the element table view selectAction(_:) selector.
            return #selector(ListTabItemViewController.sharedInstance!.selectElement)
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // TODO: use this elsewhere here to shorten other methods.
    func currentTabItemViewController() -> NSViewController {
        // Return the tab item view controller for the tab item currently selected in the masterTabViewSelector segmented control.
        let selectedIndex = masterTabViewController.selectedTabViewItemIndex
        switch selectedIndex {
        case MasterTabViewItemIndex.Browser.rawValue:
            // Return the element browser view.
            return BrowserTabItemViewController.sharedInstance
        case MasterTabViewItemIndex.Outline.rawValue:
            // Return the element outline view.
            return OutlineTabItemViewController.sharedInstance
        case MasterTabViewItemIndex.List.rawValue:
            // Return the element table view.
            return ListTabItemViewController.sharedInstance
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // TODO: use this elsewhere here to shorten other methods.
    func currentElementView() -> NSView {
        // Return the elementview for the tab item currently selected in the masterTabViewSelector segmented control. It is used in the ElementPathControlManager menuDidClose(_:) delegate method to make the current tab item's element view first responder so arrow keys can be used to select different UI elements.
        let selectedIndex = masterTabViewController.selectedTabViewItemIndex
        switch selectedIndex {
        case MasterTabViewItemIndex.Browser.rawValue:
            // Return the element browser view.
            return BrowserTabItemViewController.sharedInstance.elementBrowser
        case MasterTabViewItemIndex.Outline.rawValue:
            // Return the element outline view.
            return OutlineTabItemViewController.sharedInstance.elementOutline
        case MasterTabViewItemIndex.List.rawValue:
            // Return the element table view.
            return ListTabItemViewController.sharedInstance.elementList
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // TODO: Consider replacing the case statement calls with a protocol?
    func updateView() {
        // Update the selected tab view item in the master tab view to display its initial contents. Called in the MainContentViewController updateView() method when the user selects a new target. To display the modified contents when switching to this tab item from another tab item, call showView().
        let selectedIndex = masterTabViewController.selectedTabViewItemIndex
        switch selectedIndex {
        case MasterTabViewItemIndex.Browser.rawValue:
            // Update element browser view.
            BrowserTabItemViewController.sharedInstance.updateView()
        case MasterTabViewItemIndex.Outline.rawValue:
            // Update element outline view.
            OutlineTabItemViewController.sharedInstance.updateView()
        case MasterTabViewItemIndex.List.rawValue:
            // Update element table view.
            ListTabItemViewController.sharedInstance.updateView()
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // TODO: Consider replacing the case statement calls with a protocol?
    func showView() {
        // Update the selected tab view item in the master tab view to display its current contents. Called in the showMasterTabItem(_:) action method when the user chooses a new tab item in the masterTabViewSelector segmented control or a View > UI Elements > Show menu item when switching from another tab view item. To display the initial contents when choosing a new target, call updateView().
        let selectedIndex = masterTabViewController.selectedTabViewItemIndex
        switch selectedIndex {
        case MasterTabViewItemIndex.Browser.rawValue:
            // Show element browser view.
            BrowserTabItemViewController.sharedInstance.showView()
        case MasterTabViewItemIndex.Outline.rawValue:
            // Show element outline view.
            OutlineTabItemViewController.sharedInstance.showView()
        case MasterTabViewItemIndex.List.rawValue:
            // Show element table view.
            ListTabItemViewController.sharedInstance.showView()
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // TODO: Consider replacing the case statement calls with a protocol?
    // TODO: Write an action method for the segmented control to call this when user chooses different master tab item? ...
    // ... as it is, this is called only when a new target is chosen
    func clearView() {
        // Clear the selected tab view item in the master tab view to display its current empty contents. Called in the MainContentViewController ClearView() method when the user chooses No Target, SystemWide Target or an application target.
        let selectedIndex = masterTabViewController.selectedTabViewItemIndex
        switch selectedIndex {
        case MasterTabViewItemIndex.Browser.rawValue:
            // Clear element browser view.
            BrowserTabItemViewController.sharedInstance.clearView()
        case MasterTabViewItemIndex.Outline.rawValue:
            // Clear element outline view.
            OutlineTabItemViewController.sharedInstance.clearView()
        case MasterTabViewItemIndex.List.rawValue:
            // Clear element table view.
            ListTabItemViewController.sharedInstance.clearView()
        default:
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // TODO: Generalize this like updateView() and clearView(), and move this specific code to BrowserTabItemViewController.
    func refreshApplication() {
        // update the browser view to add UI elements created and remove UI elements destroyed since the last snapshot. Called by the refreshApplication(_:) action method.
        let datasource = ElementDataModel.sharedInstance
        if let controller = BrowserTabItemViewController.sharedInstance,
            let browser = controller.elementBrowser {
            let currentElementPath = datasource.currentElementPath
            updateView()
            datasource.clearDataModel()
            var parentElement: AccessibleElement?
            columnLoop: for (thisColumn, selectedElement) in currentElementPath.enumerated() {
                if thisColumn == 0 {
                    datasource.updateDataModel(forApplicationElement: selectedElement)
                    datasource.updateDataModelForCurrentElementAt(level: thisColumn, index: 0)
                    parentElement = selectedElement
                    browser.selectRowIndexes(IndexSet(integer: 0), inColumn: 0)
                } else {
                    let children = parentElement!.AXChildren
                    rowLoop: for (thisRow, thisElement) in children!.enumerated() {
                        if thisElement.isEqual(to: selectedElement) {
                            datasource.updateDataModelForCurrentElementAt(level: thisColumn, index: thisRow)
                            browser.selectRowIndexes(IndexSet(integer: thisRow), inColumn: thisColumn)
                            parentElement = selectedElement
                            browser.selectRowIndexes(IndexSet(integer: thisRow), inColumn: thisColumn)
                            continue columnLoop
                        }
                    }
                    // If we get here, the old selection index path is now invalid from this column on.
                    return
                }
            }
        }
    }
    
    // TODO: fix this so it works with other master tab view items, too.
    func refreshApplicationToRoot(_ sender: Any) {
        // Clear back to the root application level. Called by the refreshApplication(_:) action method if the Shift key is down
/*
    // Clear all tables and validate associated user controls
    [self setCachedActionArray:nil];
    [self setCachedAttributeArray:nil];
    [self setCachedNotificationArray:nil];
    [self updateElementPathView:nil];
    [self updateDrawers:nil];
    
    [self closeAuxiliaryWindows];
*/
        // Update the current tab item in the master split item.
        updateView()
    }
    
    // MARK: ACTION METHODS

    /* MOVED to ShowMasterTabItemSelectorExtension
    @IBAction func showMasterTabItem(_ sender: AnyObject) {
        // Action method connected to masterTabViewSelector segmented control and View > UI Elements > Show menu items in Main.storyboard. The segmented control items and menu items are tagged in Main.storyboard (0 for browser view, 1 for outline view and 3 for list view), but the segment tags are not needed here.
        if sender is NSSegmentedControl {
            masterTabViewController.selectedTabViewItemIndex = sender.selectedSegment
        } else { // if sender is NSMenuItem
            // The segmented control selection does not need to be set because it is bound to selectedTabViewItemIndex in Main.storyboard.
            masterTabViewController.selectedTabViewItemIndex = sender.tag
        }
        showView()
    }
*/
    
/* MOVED to RefreshApplicationButtonExtension.
     // TODO: Figure out why this is not called when UI Browser was just launched and no target was yet chosen.
    @IBAction func refreshApplication(_ sender: NSButton) {
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
 */
    
    // MARK: - PROTOCOL SUPPORT
    
    // MARK: UserControlValidations protocol
    
     @objc func validateUserControlItem(_ item: ValidatedUserControlItem) -> Bool {
        // Protocol method per UI Browser's UserControlValidations protocol.
        // The return value of this method reports whether conditions require the user control to be enabled or disabled. It is called only by a user control that conforms to UI Browser's ValidatedUserControlItem subprotocol of the NSValidatedUserInterfaceItem formal protocol by implementing a validate(_:) method, and that targets this controller, either directly or through the responder chain, with an action method implemented in this controller. See UserControlValidation.swift for details. The return value determines whether the user control is enabled or disabled, and the state, title and other properties of some controls may be set, as well.
        // The following user controls are always enabled, even when access is disabled, because the user should always be able to set up a working session in anticipation of enabling access: Highlight button, Follow Focus button, Screen Reader button, Generate AppleScript button (some menu items will be disabled), Show Master Tab Item Selector, and Choose Terminology button.
        let isTrusted = AccessibleElement.isProcessTrusted()
        switch item.action! {
        case #selector(highlightElement(_:)): // Highlight checkbox
            return true
 //           return isTrusted
        case #selector(followFocus(_:)): // FollowFocus checkbox
            return true
 //           return isTrusted
        case #selector(showScreenReader(_:)): // Screen Reader button
            return true
 //           return isTrusted
        case #selector(generateAppleScript(_:)): // Generate AppleScript pull-down button
            return true
 //           return isTrusted
        case #selector(showMasterTabItem(_:)): // Master Tab View Selector segmented control
            return true
 //           return isTrusted
        case #selector(refreshApplication(_:)): // Refresh Application button
            return isTrusted && MainContentViewController.sharedInstance.runningApplicationTarget != nil
        case #selector(showReport(_:)): // Report button
            return isTrusted && MainContentViewController.sharedInstance.runningApplicationTarget != nil
        case #selector(showKeystrokes(_:)): // Keystrokes button
            return isTrusted && MainContentViewController.sharedInstance.runningApplicationTarget != nil
        case #selector(chooseTerminology(_:)): // Terminology pop-up button
            return true
 //           return isTrusted
        default:
//           return true
            preconditionFailure("Unexpectedly entered default case in switch statement")
        }
    }
    
    // MARK: NSMenuItemValidation protocol
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Protocol method per the NSMenuItemValidation formal protocol to enable or disable menu items.
        
        // Most menu items are disabled if accessibility is not authorized.
        switch menuItem.action {
        case #selector(showMasterTabItem):
            menuItem.state = (menuItem.tag == masterTabViewController.selectedTabViewItemIndex) ? .on : .off
            return AXIsProcessTrusted()
        default:
            return true
        }
    }
        
}
