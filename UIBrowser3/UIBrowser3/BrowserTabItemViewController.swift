//
//  BrowserTabItemViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//


import Cocoa
import PFAssistiveFramework4

/**
 `BrowserTabItemViewController` receives a `tab items` relationship segue triggered by `MasterTabViewController` in *Main.storyboard*. Because it is designated as the Selected or default master tab view item in *Main.storyboard* and the master split pane is visible by default at first application launch, it is always instantiated at launch. It calls `loadView()` to instantiate and load the tab view item's view.
 
 UI Browser's master (top) split view pane displays the UI elements in the target's current accessibility hierarchy in one of three tab view items, each of which contains a different kind of view; namely, a browser view, an outline view, and a list view. `BrowserTabItemViewController` controls the browser view, created in *Main.storyboard*. All three of these element views rely on a common shared repository or data source for the data they display, which is cached in the `ElementDataModel` singleton object that serves as UI Browser's model object in the Model-View-Controller (MVC) design pattern. The data model is updated lazily on the fly by `BrowserTabItemViewController` as the user chooses different targets and uses the mouse or keyboard to select various elements in the path control or the browser view.
 
 UI Browser uses the NSBrowserDelegate's item-based data source delegate methods introduced in Mac OS X 10.6 (Snow Leopard) to manage the data model when it is displayed in the browser view. The matrix-based delegate methods were deprecated in OS X Yosemite 10.10. As noted in the AppKit Release Notes for Snow Leopard: "NSBrowser no longer caches the contents of each column. Instead it depends on the data source to provide speedy results." Per the AppKit Release Notes for OS X Yosemite 10.10, "Matrix-based NSBrowsers are ... deprecated in favor of the item-based interface" as part of the general trend to deprecate cells.
 
 The browser view is empty after *Main.storyboard* is loaded at launch. Only when the user chooses a target does the browser view display a single item in the first column, known in the accessibility world as the "root application UI element." If the target is a running application and not the system-wide element, it also then shows the children of the root application element in the second column; typically, these are the application's menu bar element and a window element for every open application window. The root application element is not to be confused with NSBrowser's "root item", a support object that is used as a starting point to manage any NSBrowser view. UI Browser's behavior in this regard differs from Apple's item-based NSBrowser examples *SimpleCocoaBrowser*, *ComplexBrowser* and *AnimatedTableView*. Those examples display the browser's root item in a header, and they display the root item's children in the first column when the browser's nib file is loaded, with none of them selected and nothing displayed in the second column. The *Main.storyboard* Attribute inspector's `Browser Selection Empty` setting must be turned off to avoid problems when there is no current target.
 
 In accordance with Apple's reliance on the data source for "speedy results" in an item-based browser, as noted above, UI Browser separates the data model from the data's display and implements the data source methods in this `BrowserTabItemViewController` to manage the model. The shared singleton `ElementDataModel` object is an opaque object modeling the current target's accessibility hierarchy. In response to the user choosing a target or selecting an element with the mouse or keyboard, `BrowserTabItemViewController` uses its NSBrowserDelegate data source methods to modify the model's contents accordingly so that it can later retrieve them and tell the browser view to display them. `ElementDataModel` adds objects to the data repository by calling accessibility API functions through our *PFAssistiveFramework4* framework. It constructs a variety of objects that are cached in the model object for use when the browser view displays them. Getting all of these data model operations out of the way once before the user's selection is displayed greatly improves performance, because the operations do not have to be performed repeatedly thereafter while the user navigates the display. The data source retrieval and display methods do not use any accessibility API functions themselves, but instead use the data source methods to retrieve the precomputed information from the data model. This caching of precomputed data source information allows rapid scrolling and window resizing, rapid user switching among the three element tab item views, and other features such as the continued display of elements after they have been destroyed in the user interface and are no longer available to accessibility functions.
 
 // TODO: Review this after conforming browser view to outline and list view and adding path control.
 [[[The browser view's action method is `selectElement(_:)`. It is called explicitly once when the user chooses a new target while the browser view is selected, to select the target in the browser view. It is called repeatedly thereafter when the user selects an existing element in the browser view with the mouse or keyboard, because the `selectElement(_:)` action method is connected to `BrowserTabItemViewController`'s `First Responder` in *Main.storyboard*. It is called after the data source methods have updated the data model. The action method updates UI Browser's display, adding the child elements of the selected element and other views, such as the tab view items showing actions, attributes and notifications of the selected element.???]]]
 
 The OutlineTabItemViewController and ListTabItemViewController classes are set up like BrowserTabItemViewController, but they conform to the NSOutlineViewDataSource and NSTableViewDataSource protocols. Those two protocols are separate from the NSOutlineViewDelegate and NSTableViewDelegate protocols, whereas the NSBrowserDelegate protocol contains both delegate and data source methods for browsers in a single protocol.
 
 The browser view's primary navigation tool is a path control at the top of the browser tab view item. See ElementPathControlManager.swift for details. The browser view also supports navigation using the mouse and keyboard to select parent, sibling and child UI elements at any level in the currently displayed outline. A contextual menu like that in the list view is not needed because a browser view already incorporates equivalent functionality.
 */
class BrowserTabItemViewController: NSViewController, NSBrowserDelegate {

    // MARK: - PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    /// A type property that gives access to this object from any other object by referencing `BrowserTabItemViewController.sharedInstance`.
    static private(set) var sharedInstance: BrowserTabItemViewController! // set to self in viewDidLoad(); it was created in Main.storyboard at launch
    
    // MARK: Path control
    
    // TODO: Add error handling or move into viewDidLoad().
    var elementPathControlManager: ElementPathControlManager = ElementPathControlManager()
    
    // MARK: OUTLETS
    
    /// An outlet connected to the path control.
    @IBOutlet weak var browserPathControl: NSPathControl!
    
    /// An outlet connected to the element browser view.
    @IBOutlet weak var elementBrowser: NSBrowser!
    
    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
       super.viewDidLoad()
        
        // Set the shared type property to self to give access to this object from any other object by referencing BrowserTabItemViewController.sharedInstance. It was created in Main.storyboard at launch.
        BrowserTabItemViewController.sharedInstance = self
        
        // Set the size to small programmatically. The size cannot be set in Interface Builder because it has for many years automatically switched back to Regular when attempting to set Size to Small or Mini. The NSBrowser+PFSmallBrowserAdditions Objective-C category used in older versions of UI Browser 2 can no longer be used because Apple announced in 2018 that it would block all use of private instance variables in a future release of macOS, and access was blocked in macOS Catalina 10.15; see my bug report 41209462 2018-06-18, now closed. Apple fixed setting the size programmatically effective in macOS Catalina 10.15 and later, but the fix does not work in macOS Mojave 10.14 or earlier.
        elementBrowser.controlSize = .small
        
        // Disable taking column titles from the previous column, because column titles are provided by the browser(_:titleOfColumn:) optional delegate method.
        elementBrowser.takesTitleFromPreviousColumn = false // default is true
        
        // Set path control placeholder text attributes when no target is chosen. The text content is set in Main.storyboard.
        browserPathControl.placeholderAttributedString = NSAttributedString(string: browserPathControl.placeholderString ?? "", attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .ultraLight), .foregroundColor: NSColor.gray])
        
        // Set path control border. This is not needed in the outline and list views.
        browserPathControl.wantsLayer = true
        browserPathControl.layer?.borderWidth = 0.5
        browserPathControl.layer?.borderColor = NSColor.lightGray.cgColor
        
       // Set the background color of the view behind the browser column title area lighter to differentiate it from the path control above.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        
        // TODO: Set up doubleAction here and in outline and list views to highlight selected element in target application.
        // elementBrowser.doubleAction = Selector("highlightDoubleClickAction:")
     }
    
    // MARK: Miscellaneous Methods
    
    /**
     Displays the root application element or the SystemWide element in the first column and an application element's children in the second column of the browser view when the user chooses a new target or refreshes the current target, and selects the root element.
     
     Called in the `MasterSplitItemViewController`'s `updateView()` method when the user chooses a new target and the top tab view item is the browser tab view item. Also called when the user Shift-clicks the Refresh Application button to refresh the application to root.
     */
    func updateView() {
        // Display the data model's initial contents. Called in the MasterSplitItemViewController updateView() method when the user selects a new target.

        // Display the path control.
        elementPathControlManager.updateTargetSelection(for: browserPathControl)
        
        // Display the element browser.
        elementBrowser.loadColumnZero() // load root application UI element
        elementBrowser.selectRow(0, inColumn: 0) // trigger browser(_:selectRow:inColumn:) delegate method, which selects the root application UI element and updates the data source with its children and displays them
        elementBrowser.scrollColumnToVisible(elementBrowser.lastColumn) // scroll new selected element and its children into view, if necessary

        view.window?.makeFirstResponder(elementBrowser)
        
        // TODO: The attributes drawer etc. should show the application info.
  }
    
    /**
     Displays the current UI element and its ancestors, siblings and children in the browser view, and selects the current element, after the data model is updated to reflect the current selected element path when the user switches from a different view or selects a new element using the browser path control.
     
     Called in `MasterSplitItemViewController` `showView()` when the user chooses the browser view in the Master tab view item segmented control or the View > UI Elements menu, and in the selectElement(_:) action method when the user selects a new element using the browser path control.
     */
    func showView() {
        // Display the data model's current contents. Displays the current selection path.
        
        elementBrowser.loadColumnZero()
        
        // Select the current element and display its ancestors, siblings and children.
        let dataSource = ElementDataModel.sharedInstance
        if let currentElementIndexPath = dataSource.currentElementIndexPath {
            
            // Display the path control.
            elementPathControlManager.displayPathControl(browserPathControl)
            
            // Display the element browser.
            for column in 1..<currentElementIndexPath.length {
                elementBrowser.reloadColumn(column)
            }
            
            // Select the current element and display its ancestors, siblings and children.
            elementBrowser.selectionIndexPath = currentElementIndexPath as IndexPath
            let selectedColumn = currentElementIndexPath.length - 1
            let selectedRow = currentElementIndexPath.index(atPosition: selectedColumn)
            elementBrowser.scrollColumnToVisible(elementBrowser.lastColumn) // scroll new selected element and its children into view, if necessary
            elementBrowser.scrollRowToVisible(selectedRow, inColumn: selectedColumn)

            view.window?.makeFirstResponder(elementBrowser)
        } else {
            // Current target is No Target
            clearView()
        }
    }
    
/*
    func updateTerminology() {
        // Called from MainContentViewController updateTerminology() when the user chooses a new terminology preference.
        
        ElementDataModel.shared.updateTerminology()
        
        var indexSet: NSIndexSet
        for columnIndex in 0...elementBrowser.lastColumn {
     indexSet = NSIndexSet(indexesInRange: NSMakeRange(0, ElementDataModel.shared.nodeCount(atLevel: columnIndex)))
            elementBrowser.reloadDataForRowIndexes(indexSet, inColumn: columnIndex)
            
            if columnIndex > 0 {
                let parentItem: Dictionary<String, AnyObject> = elementBrowser.parentForItemsInColumn(columnIndex) as! Dictionary
     let parentIndexPath = ElementDataModel.sharedInstance.indexPath(ofNode: parentItem)
     let updatedParentItem = ElementDataModel.sharedInstance.node(atIndexPath: parentIndexPath)
     var columnTitle = ElementDataModel.sharedInstance.briefDescription(ofNode: updatedParentItem)
                
                // Add number of rows in column in parentheses.
                let childrenCount = ElementDataModel.sharedInstance.childCount(ofNode parentItem)
                if childrenCount > 0 {
                    columnTitle = "\(columnTitle) (\(childrenCount))"
                }
                
                elementBrowser.setTitle(columnTitle, ofColumn: columnIndex)
            }
        }
    }
     */

    /**
     Displays the empty browser view when the user chooses No Target. Also clears the browser view in preparation for displaying new contents when the user chooses SystemWide Target or an application target.
     
     Called in MasterSplitItemViewController's updateView() method when the user chooses No Target, SystemWide Target or an application target and the top tab view item is the browser tab view item.
     */
    func clearView() {
        // Display an empty data model having no contents. Called in the MasterSplitItemViewController updateView() method when the user chooses No Target and to clear the outline before displaying new contents when the user chooses the SystemWide Target or an application target.
        
        // FIXME: test need for this bug fix
/* THIS WAS DONE ONLY AS A BUG FIX, but the bug seems to be fixed in Mojave.
        // TODO: Move this block into its own utility method as a bug fix and call it here, and in updateView() ...
        // ... and the equivalent method for SystemWide Target, and ...
        // ... fix MainContentViewController's updateView() so it calls clearView() only for No Target?
        // Clear all column titles except the first. This is needed to work around a longstanding NSBrowser bug that causes column titles that are no longer needed to remain visible until the window is resized. If it were not for this bug, this method would only have to be called when the user chooses No Target.
        /// A column of the browser view.
        var column = elementBrowser.lastColumn
        while column > 0 {
            elementBrowser.setTitle("", ofColumn: column)
            column -= 1
        }
*/
        
        // Clear the path control. This causes the path control to display its placeholder, which is set to "No Target" in Main.storyboard.
        elementPathControlManager.clearPathControl(browserPathControl)
        
        // Clear the browser.
        elementBrowser.loadColumnZero() // unload element browser
        elementBrowser.scrollColumnToVisible(elementBrowser.lastColumn) // scroll new selected element and its children into view, if necessary
    }
 
    // MARK: - ACTION METHODS
    // The browser view uses a path control as its primary navigation means, like the outline and list views. However, it does not use a contextual menu like the list view because the browser view itself is a more powerful version of the list view's contextual menu.

    @IBAction func popUpPathControlMenu(_ sender: NSPathControl) {
        // Action method connected to the sending browserPathControl in Main.storyboard. It opens a pop-up menu positioned over the clicked path item to enable the user to select another UI Element for display in UI Browser's browser view. See ElementPathControlManager popUpMenu(for:) for more information.
        elementPathControlManager.popUpMenu(for: browserPathControl)
    }
    
    /**
     Action method that updates the data model, the browser path control, the browser view and the rest of UI Browser's interface when the user chooses a UI element using the browser path control pop-up menu. Action methods with the same selectElement(_:) signature are implemented in the browser view, outline view and list view in the master (top) split item. It is connected programmatically to each menu item in the path control menu.

     This action method also updates the browser view when the user selects an existing element using the mouse or keyboard in the browser view. It is connected to First Responder in the Main.storyboard Browser Tab Item View Controller Scene. The browser view uses an action method for mouse and keyboard selection of elements because NSBrowser is designed to be used this way, even for mouse and keyboard selection; NSBrowserDelegate has no delegate method analogous to the outlineViewSelectionDidChange(_:) or tableViewSelectionDidChange(_:) delegate methods in NSOutlineViewDelegate and NSTableViewDelegate that are used for mouse and keyboard selection in UI Browser's outline and list views. The selectElement(_:) action method could be used in the outline and list views, too, but there the action method would not respond to mouse or keyboard selection; only the outlineViewSelectionDidChange(_:) and tableViewSelectionDidChange(_:) delegate methods respond to mouse and keyboard selection in those two views.
     
     The mouse or keyboard branch of this method uses `NSBrowser`'s `selectRow(_:inColumn:)` method to trigger the delegate methods that refresh the browser view, to allow the user to select an element using the keyboard's arrow keys as well as mouse clicks. The *Main.storyboard*'s Attribute inspector setting for `Browser Navigation "Arrows Send Action"` is turned on.
     
     - parameter sender: The browser view or menu item view that sent the action.
 */
    // TODO: Update the rest of the UI Browser interface based on the selected element, using stuff from old version as appropriate.
    @IBAction func selectElement(_ sender: Any) {
        // Action method connected programmatically to the sending browser path control pop-up menu item in the ElementPathControlManager menuNeedsUpdate(_:) delegate method using MasterSplitItemViewController currentTabItemSelectElementAction(). The @objc attribute is implied by @IBAction and is required to use the #selector expression when connecting the action. This action method is also connected to First Responder in the Main.storyboard Browser Tab Item View Controller Scene to handle mouse and keyboard selection.
        
        // NOTE about NSBrowser's clickedRow and clickedColumn properties:
        // The following statement in Apple's NSTableView documentation about a table view's clickedRow and clickedColumn properties applies also to NSBrowser's clickedRow and clickedColumn properties: "The value of this property is meaningful in the target object’s implementation of the action and double-action methods." UI Browser uses selectedColumn() and selectedRow(inColumn:) instead, but this note is valuable anyway.
        // The NSBrowser documentation incorrectly suggests that, unlike a table view, the browser's clickedRow and clickedColumn properties return the clicked row and column numbers only if the user right-clicked or Control-clicked a browser cell to present a contextual menu. For example, the NSBrowser reference document correctly states that clickedRow returns "The row number of the cell that the user clicked to display a context menu" and that clickedColumn returns "The column number of the cell that the user clicked to display a context menu." However, it incorrectly adds in the Discussion sections that this is true only if the clickedRow or clickedColumn property is called after the click presents a contextual menu and while the contextual menu is open: "The value of this property is -1 if no context menu is active." The NSBrowser.h header file comments for both also correctly state that each of them "Returns the column and row clicked on to display a context menu," but they add, incorrectly, that "These methods will return -1 when no menu is active."
        // The Mac OS X 10.6 (Snow Leopard) AppKit Release Notes, when these methods were introduced, are more accurate but imply the same limitation to contextual menus: "While the contextual menu is displayed, you may call -[NSBrowser clickedRow] and -[NSBrowser clickedColumn] to determine which cell was underneath the mouse when the context menu was displayed. The return value of both these functions will be -1 if no cell was clicked."
        // Testing demonstrates that these methods actually return the clicked row and column numbers generally for any user click in a browser cell, not just a right-click or Control-click to display a contextual menu, and that they do not in fact return -1 when no context menu is active but only when no cell was clicked. The description of the equivalent NSTableView properties in its reference document in fact applies to NSBrowser, as well. For example, as to clickedColumn, Apple's NSTableView documentation states: "The value is -1 when the user clicks in an area of the table view that is not occupied by columns or when the user clicks a row that is a group separator. The value of this property is meaningful in the target object’s implementation of the action and double-action methods. You can also use the value to determine which contextual menu to display when the user Control-clicks in a table. Note that the clickedColumn value remains valid when the menu item sends the action message."
        // It appears that the NSBrowser documentation was not meant to suggest that these properties can only be used in connection with contextual menus, but instead to emphasize that, in addition to their normal usage, the properties had added to NSBrowser the ability to present cell-specific context menus, an ability that NSBrowser did not have before Snow Leopard.
        
        if sender is NSMenuItem {
            // Handle element selection in the browser path control.
            
            /// The menu item that sent the action method.
            let menuItem = sender as! NSMenuItem
            
            // The current selection index path was temporarily saved in the element model's savedCurrentElementIndexPath private property in the elementPathControlManager menuWillOpen(_:) delegate method when the user opened the path control pop-up menu. It is reset to nil here because the user did choose a menu item instead of dismissing the menu without a selection, and the saved index path therefore does not need to be restored.
            let dataSource = ElementDataModel.sharedInstance
            dataSource.unsaveCurrentElementIndexPath()
            
            // Get information about the UI element selected by the user, including its index path, level and index, from the chosen menu item's represented object. The represented object is a node in the data model with the opaque type ElementNodeInfo, with public properties and methods to access information about it. It was added to the menu item in the elementPathControlManager menuNeedsUpdate(_:) delegate method when the menu item was created and configured.
            if let selectedNode = menuItem.representedObject as? ElementDataModel.ElementNodeInfo {
                let selectedIndexPath = dataSource.indexPath(ofNode: selectedNode)
                let selectedLevel = selectedIndexPath.length - 1
                let selectedIndex = selectedIndexPath.index(atPosition: selectedLevel)
                
                // Update the data model for the selected UI element.
                dataSource.updateDataModelForCurrentElementAt(level: selectedLevel, index: selectedIndex)
                
                showView()
            }
        } else if sender is NSBrowser {
            // Handle element selection using the mouse or keyboard.
            
            /// The browser view that sent the action method.
            let browser = sender as! NSBrowser
            
            guard browser.selectedColumn >= 0 else { return }
            // A selectedColumn value of -1 indicates that no column was selected, so the user must have clicked in an empty browser column or on a row or column separator. The browser may have been empty because there is no current running application target.
            
            // Call the BrowserTabItemViewController.browser(_:selectRow:inColumn:) delegate method programatically to update the browser in response to the user's selection of a browser cell using the mouse or keyboard. Unlike table and outline views, where a click automatically triggers a ...DidSelect delegate method unless the row is already selected, a browser view requires explicit code to trigger the delegate's selection behavior. A click in a browser column's empty space below its last filled row (clickedRow == -1) selects the element in the selection path for the previous column, or the root application UI element.
            browser.selectRow(browser.selectedRow(inColumn: browser.selectedColumn), inColumn: browser.selectedColumn)
            browser.scrollColumnToVisible(browser.lastColumn) // scroll new selected element and its children into view, if necessary
            
            // Update the data model for the selected element and its children.
            ElementDataModel.sharedInstance.updateDataModelForCurrentElementAt(level: browser.selectedColumn, index: browser.selectedRow(inColumn: browser.selectedColumn))
            
            // Update the path control.
            elementPathControlManager.displayPathControl(browserPathControl)

            
            // TODO: Implement this somewhere when write detail split item code.
            /*
             // Update other UI.
             // The updateDetailSplitItemForElement(_:) method caches information about attributes, actions or notifications of the selected element in their respective data sources, depending on which view is selected in detail (bottom) split item view, before displaying them.
             if let selectedElement = ElementDataModel.shared.currentElement {
             DetailSplitItemViewController.controller.updateDetailSplitItemForElement(selectedElement)
             validateControls()
             }
             */
        }
    }
    
    // MARK: - DELEGATE, DATA SOURCE AND HELPER METHODS
    // All of the data source and delegate methods that access UI Browser's accessibility element information use the opague ElementDataModel object, and the information it caches is available to other UI Browser classes only through ElementDataModel public methods. The object was created and cached in ElementDataModel's updateDataModel(forApplicationElement:) or updateDataModelForCurrentElementAt(level:index:) method when the user chose a target application or selected another UI element.
    // UI Browser's browser view displays the data model in an NSBrowser object. Navigation of the UI element hierarchy is handled by a path control or by selecting a row in any column of the browser using the mouse or keyboard. Path control navigation is handled in the ElementPathControlManager class for all of the master tab view tab items. Outline view navigation is handled here using NSOutlineView delegate methods.

    // NOTE about UI Browser's implementaton of the NSBrowserDelegate protocol data source methods.
    // UI Browser's browser view implements the NSBrowserDelegate required item-based data source methods introduced in Mac OS X 10.6 (Snow Leopard). See the NSBrowser.h header file comments for a description of the item-based data source methods. NSBrowserDelegate mixes data source and delegate methods in one combined delegate class, so we implement them all here in BrowserTabItemViewController, which is connected in Main.storyboard as the browser view's delegate. This architecture differs from that for UI Browser's outline and list views, which take advantage of the separate data source protocols in NSOutlineViewDataSource and NSTableViewDataSource.
    // The browser view's "root item" is UI Browser's model object in the MVC design pattern. The model object is a private object created and maintained in ElementDataModel. Its data is made available through the ElementDataModel.shared type property and public methods declared in ElementDataModel. The data model is constructed or updated using accessibility API functions made available through the PFAsssistiveFramework4 framework when the user chooses a target application or selects an existing element in the browser view with the mouse or keyboard. After the data model is updated, the NSBrowserDelegate data source methods then retrieve data based on the current state of the data model and information stored in it, rather than calling accessibility API methods. This allows time-consuming accessibility operations to be performed once before the browser view is displayed instead of repeatedly in multiple calls to the framework methods.
    // To implement this workflow when the user chooses a target application from the Target menu, MainContentViewController's choose...Target(_:) action methods (in the TargetMenuExtension.swift file) call the data model's updateApplication(forNewTarget:usingTargetElement:) method. The updateApplication(forNewTarget:usingTargetElement:) method in turn calls updateData(usingTargetElement:), which calls ElementDataModel's updateDataModel(forApplicationElement:) to update the data source with the new target application. If successful, the updateApplication(forNewTarget:usingTargetElement:) method then calls updateView(_:) to call BrowserTabItemViewController's updateView() method. The updateView() method calls NSBrowser's loadColumnZero() to load the root application UI element from the data model, and it calls selectRow(_:inColumn) to programmatically trigger the browser(_:selectRow:inColumn:) optional delegate method and the required NSBrowserDelegate data source delegate methods to display the chosen target's root application UI element. The browser(_:selectRow:inColumn:) optional delegate method then calls ElementDataModel's updateDataModelForCurrentElementAt(level:index:) to add the root application UI element's children to the display.
    // To implement this workflow when the user selects an existing element in the browser view with the mouse or keyboard, BrowserTabItemViewController implements the browser(_:selectRow:inColumn:) delegate method and the selectElement(_:) action method.
    
    // TODO: look for ways to make this faster....
    // ... For columns with large number of siblings, display a temporary "Loading..." item in the column if necessary then reload the column with valid entries. Or load it in chunks, with the first chunk big enough to display all, and subsequent chunks loaded in the background while the user reads the first chunk
    
    // MARK: NSBrowserDelegate
    
    // MARK: required item-based data source delegate methods
    // All of the required item-based data source delegate methods are passed an object in the item parameter containing information about a UI element to be displayed. The type of the object is private to ElementDataModel, and the information it caches is available to other UI Browser classes only through ElementDataModel public methods. The object was created and cached in ElementDataModel's updateDataModel(forApplicationElement:) or updateDataModelForCurrentElementAt(level:index:) method when the user chose a target application or selected an existing element. The object is introduced into each round of data source delegate method calls by the browser(_:child:ofItem:) delegate method.
    
   func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {
        // Required item-based data source delegate method per the NSBrowserDelegate formal protocol. The incoming item parameter value is nil if no target application has been chosen or NSBrowser wants the number of children of the browser view's root item. Returns the number of child items of item or of the root item.
    let dataSource = ElementDataModel.sharedInstance

        // if browser == elementBrowser { // no need to test browser because only one exists
    
    // A nil item parameter value normally signals that NSBrowser wants the number of children of the browser's root item when, as in UI Browser, the rootItemForBrowser(_:) method is not implemented, per the NSBrowser.h header comments ("The item parameter passed to each of these methods will be nil if the browser is querying about the root of the tree, unless -rootItemForBrowser: is implemented"). The root item is typically either an array of arrays representing a tree structure or the root item of a tree structure. A positive number is therefore normally returned by this delegate method when item is nil, to tell the browser view to display the first level of the tree, which can be thought of as the root item's child or children. UI Browser displays a single root application UI element in the browser view's first column when a target application has been chosen. UI Browser therefore returns 1 when item is nil because applications always have a single root application UI element.
    // However, UI Browser displays the browser view even when no target application has been chosen and the root item has no content, and the item parameter value is also nil in that case. UI Browser returns 0 when item is nil and the root item is empty, which suppresses all further calls to the data source delegate methods. As a result, the browser view remains empty until the browser is reloaded by an explicit call to loadColumnZero() in updateView().
    guard !dataSource.isEmpty else { return 0 }
    
    if let node = item as? ElementDataModel.ElementNodeInfo {
        return dataSource.childCount(ofNode: node)
    }
    
    // In UI Browser, the "root" item always has 1 child UI element, the root application or system-wide UI element.
    return 1

    /* OLD VERSION:
        if item == nil {
            // A nil item parameter value normally signals that NSBrowser wants the number of children of the browser's root item when, as in UI Browser, the rootItemForBrowser(_:) method is not implemented, per the NSBrowser.h header comments ("The item parameter passed to each of these methods will be nil if the browser is querying about the root of the tree, unless -rootItemForBrowser: is implemented"). The root item is typically either an array of arrays representing a tree structure or the root item of a tree structure. A positive number is therefore normally returned by this delegate method when item is nil, to tell the browser view to display the first level of the tree, which can be thought of as the root item's child or children. UI Browser displays a single root application UI element in the browser view's first column when a target application has been chosen. UI Browser therefore returns 1 when item is nil because applications always have a single root application UI element.
            // However, UI Browser displays the browser view even when no target application has been chosen and the root item has no content, and the item parameter value is also nil in that case. UI Browser returns 0 when item is nil and the root item is empty, which suppresses all further calls to the data source delegate methods. As a result, the browser view remains empty until the browser is reloaded by an explicit call to loadColumnZero() in updateView().

            if ElementDataModel.sharedInstance.isEmpty {
                // If the data model is empty, a nil item indicates no target is chosen; the browser view will display nothing.
                return 0
            } else {
                // If the data model is not empty, a nil item represents the browser view's root item; the browser view will display the root application UI element.
                return 1
            }
        } else {
            // The item parameter represents an existing UI element; the browser view will display its children in the next column
            assert(item is ElementDataModel.ElementNodeInfo, "Failed to get the child count because the parent is not of type ElementNodeInfo")

            return ElementDataModel.sharedInstance.childCount(ofNode: item as! ElementDataModel.ElementNodeInfo)
        }
    */
        // }
    }
    
    func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
        // Required item-based data source delegate method per the NSBrowserDelegate formal protocol. The incoming item parameter value is nil if NSBrowser wants a child of the browser's root item. This method is not called if no target application has been chosen. Returns the indexth child of item or of the root item.
        // This method may be called multiple times for every visible row in a browser column, so it must be efficient.
        // The index parameter value is guaranteed never to be greater than or equal to the number of children as reported by browser(_:, numberOfChildrenOfItem:), per the NSBrowser.h header comments ("You may expect that index is never equal to or greater to [sic] the number of children of item as reported by -browser:numberOfChildrenOfItem:"). This implies that this method is never called on a leaf item; if it were, the index parameter value would have to be -1.
        // NOTE: Main.storyboard must not allow empty selection in the browser; otherwise, this method will be called prematurely when the user chooses a target application and ElementDataModel does not yet contain the target application's children.
 
        let dataSource = ElementDataModel.sharedInstance

        // if browser == elementBrowser { // no need to test browser because only one exists
        
        if let node = item as? ElementDataModel.ElementNodeInfo {
            return dataSource.childNode(ofNode: node, atIndex: index)
        }
        
        // In UI Browser, the "root" item always has one child UI element, the root application or system-wide UI element.
        return dataSource.nodeAt(level: 0, index: 0)

        /* OLD VERSION:
        if item == nil {
            // Item represents root item; will display application UI element as its only "child".
            // A nil item parameter value signals that NSBrowser wants the child of the browser view's root item when, as in UI Browser, the rootItemForBrowser(_:) method is not implemented. This method is not called when no target application has been chosen and the root item has no content to be displayed, because browser(_:, numberOfChildrenOfItem:) returned 0 in that case.

            return ElementDataModel.sharedInstance.childNode(ofNode: nil, atIndex: 0)
        } else {
            // Item represents an existing UI element; will display its children.
            assert(item is ElementDataModel.ElementNodeInfo, "Failed to get the child item because the parent is not of type ElementNodeInfo")
            
            return ElementDataModel.sharedInstance.childNode(ofNode: item as? ElementDataModel.ElementNodeInfo, atIndex: index)
        }
        */
        
        // }
    }
    
    func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {
        // Required item-based data source delegate method per the NSBrowserDelegate formal protocol. The incoming item parameter value is never nil. Returns true if item should be shown as a leaf item, that is, an item that has no children and therefore displays no expansion triangle because it cannot be expanded. The item's child count is needed here to decide whether to display the expansion triangle, but the actual children do not need to be available in the data source yet because this item has not yet been selected.
        // This method is not called if no target application has been chosen. Returning false does not prevent returning 0 from browser(_:numberOfChildrenOfItem:), per the NSBrowser.h header comments ("Returning NO does not prevent you from returning 0 from -browser:numberOfChildrenOfItem:").
        let dataSource = ElementDataModel.sharedInstance

        // if browser == elementBrowser { // no need to test browser because only one exists
        
        if let node = item as? ElementDataModel.ElementNodeInfo {
            return node.isEmpty || dataSource.childCount(ofNode: node) == 0
        }
        
        // In UI Browser, the "root" item always has one child UI element, the root application or system-wide UI element.
        return true

        /* OLD VERSION:
        assert(item is ElementDataModel.ElementNodeInfo, "Failed to determine whether the item is a leaf item because the item is not of type ElementNodeInfo")

        return ElementDataModel.sharedInstance.childCount(ofNode: item as! ElementDataModel.ElementNodeInfo) == 0
        */
        
        // }
    }
    
    func browser(_ browser: NSBrowser, objectValueForItem item: Any?) -> Any? {
        // Required item-based data source delegate method per the NSBrowserDelegate formal protocol. The incoming item parameter value is never nil. Returns the NSString or NSAttributedString object to be displayed in the browser.
        // This method is not called if no target application has been chosen. It is called once for every visible cell in the browser when the cell is displayed and again when the column is scrolled or resized.
        // The base string value to be displayed for item can be created and returned here. It can then be modified or replaced in browser(_:willDisplayCell:atRow:column:), if desired.
        // The equivalent NSOutlineViewDataSource and NSListViewDataSource methods are not used in OutlineTabItemViewController and ListTabItemViewController, in favor of their outlineView(_:viewFor:item:) and tableView(_:viewFor:row:) delegate methods. NSBrowserDelegate does not have an equivalent method delegate method.
        let dataSource = ElementDataModel.sharedInstance

        // if sender == elementBrowser { // no need to test browser because only one exists
        
        // Get the element's description as an attributed string.
        // The terminology of the description is based on the user defaults setting for the key TERMINOLOGY_DEFAULTS_KEY. The key and its available Terminology enumeration values are declared in Defines.swift. The user defaults setting is initialized to Natural at first launch in the [[[initialize() class method.]]]
        if let node = item as? ElementDataModel.ElementNodeInfo {
            return dataSource.fullDescription(ofNode: node)
        }
        
        let placeholder = "–"
        return placeholder

        /* OLD VERSION:
        assert(item is ElementDataModel.ElementNodeInfo, "Failed to get the item's object value because the item is not of type ElementNodeInfo")

        return ElementDataModel.sharedInstance.fullDescription(ofNode: item as! ElementDataModel.ElementNodeInfo)
        */
        
        // }
    }
    
    // MARK: optional delegate methods
    
    // TODO: implement browser(_:willDisplayCell:atRow:column:) delegate method?
/* Don't seem to need this. Use it only for modifying or formatting the object value
    func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
        // Optional item-based delegate method per NSBrowserDelegate Protocol. Use this method to modify or format the string in the cell before the cell is displayed, including any operations that require the row index as well as the column index. The class of cell is NSTextFieldCell. The item displayed in cell is available by calling [sender itemAtRow:row inColumn:column].
        // This method is not called if no target is chosen.
        // The browser cell's basic string value was set to an empty string in the -browser:objectValueForItem: delegate method. The basic text is composed here based on the element and on the row index as well as the column index. A prefix for any parent-child mismatch may be added here. The NSString object in the incoming cell, as modified here, is also converted to an NSAttributedString object here, and it is formatted with ansiWarningColor if the element or an ancestor is destroyed.
//        print("ENTERING -browser:willDisplayCell:atRow:column:")
        (cell as! NSCell).attributedStringValue = modifiedObjectValueForCell(cell as! NSCell, atRow: row, column: column)
        // TODO: make the color show up....
        // ... needsDisplay doesn't help.
        // ... when I select another window in browser, destoryed one goes blank.
//        view.needsDisplay = true

        /*
        if let node = sender.item(atRow: row, inColumn: column) {
            // NSBrowser does not support tooltips for item-based browsers. The following code is from the pre-Snow Leopard matrix-based browser:
             // Attach tooltip to cell to report its value, if any.
             if (element) {
             NSString *toolTipText = [self descriptionOfAttributeValue:[element AXValue] ofType:[element typeForAttribute:NSAccessibilityValueAttribute] element:element];
             if ([toolTipText length] > 0) {
             toolTipText = [NSString stringWithFormat:NSLocalizedString(@"Value: %@", @"Prefix to tooltip for value of UI Element"), toolTipText];
             if ([toolTipText length] > 256) toolTipText = [NSString stringWithFormat:@"%@%C", [toolTipText substringToIndex:255], (unichar)0x2026]; // 0x2026 is Unicode ellipsis
             NSMatrix *matrix = [browser matrixInColumn:column];
             [matrix setToolTip:toolTipText forCell:cell];
             }
             }
        }
             */
//        print("value is \((cell as! NSCell).attributedStringValue)")
//        print("LEAVING -browser:willDisplayCell:atRow:column:")
    }
*/
    
    func browser(_ sender: NSBrowser, selectRow row: Int, inColumn column: Int) -> Bool {
        // Optional delegate method per the NSBrowserDelegate formal protocol. Called programmatically when the user chooses a new target application in the menu bar's Target menu or the Target popup button's menu, or triggered automatically when the user selects a new existing element with the mouse or keyboard. When the user chooses a new target application, one of the choose...Target action methods results in a call to updateView(), which calls NSBrowser loadColumnZero() to trigger the browser's data source methods to display the root application UI element, and it then calls NSBrowser selectRow(_:inColumn:) to trigger this delegate method to add the application element's children. When the user selects a new existing element with the mouse or keyboard, it sends the selectElement(_:) action method, which calls selectRow(_:inColumn:) to trigger this delegate method to add the selected element's children.
        // IMPORTANT NOTE: UI Browser does not implement the browser(_:selectionIndexesForProposedSelection:inColumn:) delegate method because it is not triggered by user clicks in the browser's current selection path. The NSBrowserDelegate reference document says that it "Asks the delegate for a set of indexes to select when the user changes the selection in the browser with the keyboard or mouse." As a result, the browser would not be updated when the user selects an element that is already in the selection path. This is efficient in the general case from NSBrowser's point of view, because descendant elements in the browser are presumed to remain valid and it would be a waste of time to remove them. However, UI Browser needs to display information specific to the newly selected element in the detail (bottom) split item view even if it is in the selection path.
        
        // Handle user's choosing target application from menu.
        if row == 0 && column == 0 { // for root application UI element
            if sender.selectionIndexPaths.count == 0 { // nothing is selected in the browser
                // Set selection to root application element and give the browser focus programmatically because user chose target application from menu instead of clicking it in browser.
                sender.selectionIndexPath = NSIndexPath(index: 0) as IndexPath
                sender.window!.makeFirstResponder(sender) // required to highlight selection
            }
        }

        // Update the selected element and its children.
        ElementDataModel.sharedInstance.updateDataModelForCurrentElementAt(level: column, index: row)

        return true
    }
    
    func browser(_ sender: NSBrowser, titleOfColumn column: Int) -> String? {
        // Optional delegate method per the NSBrowserDelegate formal protocol. Returns the title to display above the specified column. In Main.storyboard, the Titled setting must be selected, and the browser's Top Space to Superview and the browserVew's Top Space to Browser constraints must be set to default values to leave room for the column titles to display. ViewDidLoad() must set the browser's takesTitleFromPreviousColumn title to false because it defaults to true.
        
        // if sender == elementBrowser { // no need to test browser because only one exists
        
        // Get title for first column as a string.
        if (column == 0) {
            return "root";
        }
        
        // Get title for subsequent columns as a string.
        // The terminology of the title is based on the user defaults setting for the key TERMINOLOGY_DEFAULTS_KEY. The key and its available Terminology enumeration values are declared in Defines.swift. The user defaults setting is initialized to Natural at first launch.
        /// The item selected in the previous column.
        let parentItem = elementBrowser.parentForItems(inColumn: column) as! ElementDataModel.ElementNodeInfo
        
        /// A brief description of the item selected in the previous column.
        var columnTitle = ElementDataModel.sharedInstance.briefDescription(ofNode: parentItem)
        
        // Add number of rows in column in parentheses.
        /// The number of items in this column.
        let childCount = ElementDataModel.sharedInstance.childCount(ofNode: parentItem)
        if childCount > 0 {
            columnTitle = "\(columnTitle)—\(childCount) children"
        }
        
        return columnTitle;
        // }
    }

    // FIXME: test need for this bug fix
/* THIS WAS DONE ONLY AS A BUG FIX, but the bug seems to be fixed in Mojave.
    // FIXME: Crash here repeatably...
    // ... "Can't form Range with upperBound < lowerBound" when switching from outline view to browserview with 31st row selected in Mail/AXApplication/AXStandardWindow "Inbox"/AXSplitGroup/AXScrollArea/AXOutline/AXOutlineRow. Only crashes when switching from another view that has a deep selection requiring scrolling here.
    func browserWillScroll(_ sender: NSBrowser) {
        // Optional delegate method per the NSBrowserDelegate formal protocol. Works around an Apple bug that leaves a browser column title undisplayed when a hidden column scrolls into view.
        // Due to a longstanding Apple bug, an NSBrowser column title fails to display when the browser scrolls horizontally and a hidden column becomes visible. In very early versions of macOS, the bug affected columns scrolled into view from the right, and UI Browser worked around it by implementing the -browserDidScroll: delegate method and calling -setNeedsDisplayInRect: on the title frame of the last column. That workaround failed in Mac OS X 10.7 (Lion), but UI Browser was then surprisingly able to work around the bug simply by selecting the Titled checkbox in Interface Builder instead of calling -setTitled: in -awakeFromNib. See my posts to Apple's cocoa-dev mailing list at https://lists.apple.com/archives/cocoa-dev/2011/Sep/msg00136.html. That workaround failed in macOS Mojave 10.14, and the bug now affects columns scrolled into view from the left. Testing reveals that a hidden column does in fact have a title, but it may be significant that the browser(_:titleOfColumn:) delegate method is not called when the column scrolls into view. UI Browser now works around the bug by implementing the browserWillScroll(_:) delegate method and calling setTitle(_:ofColumn:) on each visible column. Because the column already has a title supplied by a previous call to the browser(_:titleOfColumn:) delegate method, this workaround is able to get the title directly by calling title(ofColumn:) instead of calling the delegate method again. The key step in the workaround is the call to setTitle(_:ofColumn:), which has the side effect of displaying the title.
        for column in sender.firstVisibleColumn...sender.lastVisibleColumn {
            if let title = sender.title(ofColumn: column) {
                sender.setTitle(title, ofColumn: column)
            }
        }
    }
*/
    // TODO: Implement the browser:willdisplaycell delegate method to call this...
    // ... then write this to be moved to maincontentviewcontroller or, better, top split item view to do the work...
    // ... so it can be reused for table and outline views.
     // TODO: Call this after bare-bones string is displayed in browser.
     // Either delay automatically after initial display, or by clicking a button.
    /* Don't seem to need this. I wrote this myself; it is not a Cocoa method.
    func modifiedObjectValueForCell(_ cell: Any, atRow row: Int, column: Int) -> NSAttributedString {
        // Utility method called from browser(willDisplayCell, atRow, column) delegate method.
        
        let element = ElementDataModel.sharedInstance.element(ofNode: ElementDataModel.sharedInstance.nodeAt(level: column, index: row))
        let cellString = (cell as! NSCell).stringValue
        
        /*
         // Modify cellString by adding description of element with AppleScript title and index.
         var tempString = cellString.stringByAppendingString(ElementDataModel.sharedInstance.descriptionWithTitleAndOSAReferenceOfElement(element, inRow: row, atColumn: column))
         
         // Modify cellString by prepending a "MISMATCH" legend if a parent-child mismatch is found by looking back at the parent in the browser while traversing the accessibility children tree.
         if !element.isRole(NSAccessibilityApplicationRole) { // root application element has no parent
         let browserParent = browser.parentForItemsInColumn(column)!.objectForKey(.elementKey) as! PFUIElement
         //            let browserParent = browser.parentForItemsInColumn(column) as! PFUIElement
         if element.exists() && (element.AXParent == nil) {
         tempString = NSLocalizedString("[MISMATCH-no parent in screen reader] ", comment: "Warning string for no parent mismatch in target application's UI element hierarchy for browser").stringByAppendingString(tempString)
         NSLog("The browser found an accessibility MISMATCH in process \"\(processNameForPid(element.pid()))\" while examining the descendants of the root application UI element. In the browser the \(element.AXRoleDescription) UI element's parent is the \(browserParent.AXRoleDescription) UI element when looking \"down\" the children tree toward the leaf element on the screen, but in the screen reader it has no parent when looking \"up\" the parent tree toward the root application UI Element. Assistive applications may malfunction if the hierarchy is not identical in both directions.\nParent element in browser when looking down:\n\(browserParent.description())\nParent element in screen reader when looking up:\n\(element.AXParent.description).")
         } else if element.exists() && !element.AXParent.isEqualToElement(browserParent) {
         tempString = NSLocalizedString("[MISMATCH-different parent in screen reader] ", comment: "Warning string for different parent mismatch in target application's UI element hierarchy for browser").stringByAppendingString(tempString)
         NSLog("The browser found an accessibility hierarchy MISMATCH in process \"\(processNameForPid(element.pid()))\" while examining the descendants of the root application UI element. In the browser the \(element.AXRoleDescription) UI element's parent is the \(browserParent.AXRoleDescription) UI element when looking \"down\" the children tree toward the leaf element on the screen, but in the screen reader its parent is the \(element.AXParent.AXRoleDescription) UI element when looking \"up\" the parent tree toward the root application UI Element. Assistive applications may malfunction if the hierarchy is not identical in both directions.\nParent element in browser when looking down:\n\(browserParent.description())\nParent element in screen reader when looking up:\n\(element.AXParent.description)")
         }
         }
         */
        
        // TODO, check if ancestor is destroyed, too.
        // Create attributed string.
        var foregroundColor: NSColor
        if element.isDestroyed {
            foregroundColor = MainContentViewController.sharedInstance.destroyedElementColor
        } else {
            foregroundColor = NSColor.controlTextColor
        }
        let attributes = [
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.font: NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)
            ] as [NSAttributedString.Key : Any]
        let returnString = NSAttributedString(string: cellString, attributes: attributes)
        return returnString
    }
*/
    
    // MARK: - PROTOCOL METHODS
    
    // MARK: NSToolTipOwner informal protocol
    // The use of this technique to implement custom tooltips in an item-based NSBrowser object was suggested by Ken Thomases in a mailing list post on May 5, 2014: "you can use -[NSView addToolTipRect:owner:userData:] to add a tooltip rect covering the whole browser view (and update it when its bounds change). Set the owner to an object which implements the NSToolTipOwner informal protocol – i.e. the -view:stringForToolTip:point:userData: method. In that method, you can translate from the point to a row and column and return an appropriate string."
    // An alternative "is browser:shouldShowCellExpansionForRow:column: which does not allow for a custom tooltip, only the display of the entire cell contents if the cell contents doesn't fit in the column." UI Browser currently does this by setting Allows Expansion Tooltips in the Interface Builder nib file.
    // This code was used in UI Browser when it used the now deprecated matrix-based NSBrowser delegate methods:
    /* NSBrowser does not support tooltips for item-based browsers. The following code is from the pre-Snow Leopard matrix-based browser:
     // Attach tooltip to cell to report its value, if any.
     if (element) {
     NSString *toolTipText = [self descriptionOfAttributeValue:[element AXValue] ofType:[element typeForAttribute:NSAccessibilityValueAttribute] element:element];
     if ([toolTipText length] > 0) {
     toolTipText = [NSString stringWithFormat:NSLocalizedString(@"Value: %@", @"Prefix to tooltip for value of UI Element"), toolTipText];
     if ([toolTipText length] > 256) toolTipText = [NSString stringWithFormat:@"%@%C", [toolTipText substringToIndex:255], (unichar)0x2026]; // 0x2026 is Unicode ellipsis
     NSMatrix *matrix = [browser matrixInColumn:column];
     [matrix setToolTip:toolTipText forCell:cell];
     }
     }
     */
    
    // MARK: - APPLESCRIPT GENERATION
    // TODO: Move this to a separate class, or remove it
    
    // TODO: Test this with Adobe Photoshop CS6 which has different file, process and UI element names.
    func processNameForPid(PID: pid_t) -> String {
        // Returns the running process name as recognized by System Events. In some applications (e.g., Adobe Photoshop CS6) this differs from the application or display name. AppleScript, via System Events, used the old GetProcessInformation function instead of the more modern CopyProcessName function in the Process Manager, although this may have changed. CopyProcessName is documented to work with multilingual names, unlike GetProcessInformation. Called from -tellBlockWrapperShortScript and -tellBlockWrapperSafeScript, and from -descriptionForAppleScriptOfElement:atDepth: to get the name of the application reference while constructing a reference to a UI element. Also called from the modifiedObjectValueForCell method for NSLog entries.
        let runningApplication = NSRunningApplication(processIdentifier: PID)
        return runningApplication!.localizedName!
    }
    
}
