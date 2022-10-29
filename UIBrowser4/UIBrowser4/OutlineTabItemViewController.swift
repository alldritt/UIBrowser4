//
//  OutlineTabItemViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

import Cocoa

/**
 `OutlineTabItemViewController` receives a `tab items` relationship segue triggered by `MasterTabViewController` in *Main.storyboard*. It is instantiated at launch only if the state restoration mechanism restores it because it was the selected master tab view item when UI Browser last quit; otherwise, it is instantiated if and when the user selects the Outline tab view item. It calls `loadView()` to instantiate and load the tab view item's view.
 
 UI Browser's master (top) split view pane displays the UI elements in the target's current accessibility hierarchy in one of three tab view items, each of which contains a different kind of view; namely, a browser view, an outline view, and a list view. `OutlineTabItemViewController` controls the outline view, created in *Main.storyboard*. All three of these element views rely on a common shared repository or data source for the data they display, which is cached in the `ElementDataModel` singleton object that serves as UI Browser's model object in the Model-View-Controller (MVC) design pattern. The data model is updated lazily on the fly by `OutlineTabItemViewController` as the user chooses different targets and uses the mouse or keyboard to select various elements in the path control or the outline view.
 
 UI Browser uses the NSOutlineViewDataSource protocol's data source methods to manage the data model when it is displayed in the outline view.
 
 The outline view is empty after *Main.storyboard* is loaded at launch. Only when the user chooses a target does the outline view display a single unindented row, known in the accessibility world as the "root application UI element." If the target is a running application and not the system-wide element, it also then shows the children of the root application element in rows at the second indentation level; typically, these are the application's menu bar element and a window element for every open application window.
 
 UI Browser separates the data model from the data's display, and it implements the data source and delegate methods in this `OutlineTabItemViewController` to manage the model. The shared singleton `ElementDataModel` object is an opaque object modeling the current target's accessibility hierarchy. In response to the user's choosing a target or selecting an element with the mouse or keyboard, `OutlineTabItemViewController` uses its NSOutlineViewDataSource data source methods to modify the model's contents accordingly so that it can later retrieve them and tell the outline view to display them. `ElementDataModel` adds objects to the data repository by calling accessibility API functions through our *PFAssistiveFramework4* framework. It constructs a variety of objects that are cached in the model object for use when the browser, outline or list view displays them. Getting all of these data model operations out of the way once before the user's selection is displayed greatly improves performance, because the operations do not have to be performed repeatedly thereafter while the user navigates the display. The data source retrieval and display methods do not use any accessibility API functions themselves, but instead use the data source methods to retrieve the precomputed information from the data model. This caching of precomputed data source information allows rapid scrolling and window resizing, rapid user switching among the three element tab item views, and other features such as the continued display of elements after they have been destroyed in the user interface and are no longer available to accessibility functions.

 The OutlineTabItemViewController and ListTabItemViewController classes are set up like BrowserTabItemViewController, but they conform to the NSOutlineViewDataSource and NSTableViewDataSource protocols. Those two protocols are separate from the NSOutlineViewDelegate and NSTableViewDelegate protocols, whereas the NSBrowserDelegate protocol contains both delegate and data source methods for browsers in a single protocol.

 The outline view's primary navigation tool is a path control at the top of the outline tab view item. See ElementPathControlManager.swift for details. The outline view also supports navigation using the mouse and keyboard to select parent, sibling and child UI elements at any level in the currently displayed outline. A contextual menu like that in the list view is not needed because an outline view already incorporates equivalent functionality.
 */
class OutlineTabItemViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    // MARK: - PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    /// A type property that gives access to this object from any other object by referencing `OutlineTabItemViewController.sharedInstance`.
    static private(set) var sharedInstance: OutlineTabItemViewController! // set to self in viewDidLoad()
    
    // MARK: Path control
    
    // TODO: Add error handling or move into viewDidLoad().
    var elementPathControlManager: ElementPathControlManager = ElementPathControlManager()
    
    // MARK: Miscellaneous
    
    /// Flag signals whether the selection of a row was made manually by the mouse or keyboard, as opposed to programmatically. If the flag is true, the data model needs to be updated and displayed in the outlineViewSelectionDidChange(_:) delegate method to reflect the manual selection. The flag is used to prevent redundant updates by the delegate method when selection is made programmatically and the data model is updated and displayed before the delegate method is triggered. It is initialized to false here. It is set to true when the user makes a new selection manually using the mouse or the up or down arrow key, in OutlineTabItemOutlineView mouseDown(with:), moveUp(_:) and moveDown(_:). All of these cases automatically trigger the outlineViewSelectionDidChange(_:) delegate method. If the flag is true, the delegate method updates and displays the data model, first resetting the falg to false to prepare for subsequent programmatic selections; if the flag is false, the delegate method does nothing in order to prevent redundant updates.
    var isManualSelection = false

    /// Struct declaring NSUserInterfaceItemIdentifier objects used in the outlineView(_:viewFor:row:) delegate method to populate the columns of the outline view. They are set in the Main.storyboard Outline Tab Item Outline View Scene to identify each column.
    struct TableColumnIdentifiers {
        static let role = NSUserInterfaceItemIdentifier("role")
        static let subrole = NSUserInterfaceItemIdentifier("subrole")
        static let index = NSUserInterfaceItemIdentifier("index")
        static let title = NSUserInterfaceItemIdentifier("title")
        static let type = NSUserInterfaceItemIdentifier("type")
        static let help = NSUserInterfaceItemIdentifier("help")
    }
    
    // MARK: OUTLETS
    
    /// An outlet connected to the path control.
    @IBOutlet weak var outlinePathControl: NSPathControl!
    
    /// An outlet connected to the element outline view.
    @IBOutlet weak var elementOutline: NSOutlineView!
    
    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the shared type property to self to give access to this object from any other object by referencing OutlineTabItemViewController.sharedInstance.
        OutlineTabItemViewController.sharedInstance = self
        
        // Set path control placeholder text attributes when no target is chosen. The text content is set in Main.storyboard.
        outlinePathControl.placeholderAttributedString = NSAttributedString(string: outlinePathControl.placeholderString ?? "", attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .ultraLight), .foregroundColor: NSColor.gray])

       // Apple's NSOutlineView documentation: "It is possible that your data source methods for populating the outline view may be called before awakeFromNib() if the data source is specified in Interface Builder. You should defend against this by having the data source’s outlineView(_:numberOfChildrenOfItem:) method return 0 for the number of items when the data source has not yet been configured. In awakeFromNib(), when the data source is initialized you should always call reloadData()."
        elementOutline.reloadData()
    }
    
    // MARK: Miscellaneous Methods
    
    /**
     Displays the root application UI element or the SystemWide element in the first row and an application element's children in the rows at the second level of the outline view when the user chooses a new target or refreshes the current target, and selects the root element.
     
     Called in the `MasterSplitItemViewController` `updateView()` method when the user selects a new target and the top tab view item is the outline tab view item. Also called when the user Shift-clicks the Refresh Application button to refresh the application to root.
     */
    func updateView() {
        // Display the data model's initial contents. Called in the MasterSplitItemViewController updateView() method when the user selects a new target.
        // The data model does not need to be updated because it was updated in updateApplication(forNewTarget:usingTargetElement:), and it will not need to be displayed in the outlineViewSelectionDidChange(_:) delegate method because it is displayed here. See outlineViewSelectionDidChange(_:) for more information.
        let dataSource = ElementDataModel.sharedInstance
        
        // Display the path control.
        elementPathControlManager.updateTargetSelection(for: outlinePathControl)
        
        // Display the element outline.
        let node = dataSource.nodeAt(level: 0, index: 0)
        elementOutline.reloadItem(node, reloadChildren: true)
        
        // The current element is the root application UI element or the SystemWide element, and it is automatically selected because the Selection Empty setting is deselected in Main.storyboard and there is only one UI element at the root application level of the accessibility hierarchy. The first row is expanded to display its children.
        elementOutline.expandItem(node)
        
        view.window?.makeFirstResponder(elementOutline)
        
        // TODO: The attributes drawer etc. should show the application info.
    }
    
    /**
     Displays the current UI element and its ancestors, siblings and children in the outline view, and selects the current element, after the data model is updated to reflect the current selected element path when the user switches from a different view or selects a new element using the outline path control.
     
     Called in `MasterSplitItemViewController` `showView()` when the user chooses the outline view in the Master tab view item segmented control or the View > UI Elements menu, and in the selectElement(_:) action method when the user selects a new element using the outline path control.
     */
    func showView() {
        // Display the data model's current contents. Displays the current selection path, collapsing all sibling rows that are not needed to display it and expanding those that are needed.
        
        // Select the current element and display its ancestors, siblings and children.
        let dataSource = ElementDataModel.sharedInstance
        if let currentElementIndexPath = dataSource.currentElementIndexPath {
            // The data model does not need to be updated because the outline view will display the same element path as the previous view, and it will not need to be displayed in the outlineViewSelectionDidChange(_:) delegate method because it is displayed here. See outlineViewSelectionDidChange(_:) for more information.
            
            // Display the path control.
            elementPathControlManager.displayPathControl(outlinePathControl)
            
            // Display the element outline. Triggers the outlineViewSelectionDidChange(_:) delegate method, but it does nothing because the isManualSelection flag is false.
            elementOutline.collapseItem(nil, collapseChildren: true) // collapse all rows
            elementOutline.reloadData()
            
            // Select the current element and display its ancestors, siblings and children.
            for level in 0..<currentElementIndexPath.length {
                let node = dataSource.nodeAt(level: level, index: currentElementIndexPath.index(atPosition: level))
                performIgnoringDelegate(#selector(NSOutlineView.expandItem(_:)), with: node)
            }
            let currentNode = dataSource.node(atIndexPath: currentElementIndexPath)
            let currentRow = elementOutline.row(forItem: currentNode)
            elementOutline.selectRowIndexes(IndexSet(integer: currentRow), byExtendingSelection:false)
            elementOutline.scrollRowToVisible(elementOutline.selectedRow)

            view.window?.makeFirstResponder(elementOutline)
        } else {
            // Current target is No Target.
            clearView()
        }
    }
    
    /**
     Displays the empty outline view when the user chooses No Target. Also clears the outline view in preparation for displaying new contents when the user chooses the SystemWide Target or an application target.
     
     Called in MasterSplitItemViewController's updateView() method when the user chooses No Target, SystemWide Target or an application target and the top tab view item is the outline tab view item.
     */
    func clearView() {
        // Display an empty data model having no contents. Called in the MasterSplitItemViewController updateView() method when the user chooses No Target and to clear the outline before displaying new contents when the user chooses the SystemWide Target or an application target.
        // The data model does not need to be updated because it was already updated in updateApplication(forNewTarget:usingTargetElement:), and it will not need to be displayed in the outlineViewSelectionDidChange(_:) delegate method because it is displayed here. See outlineViewSelectionDidChange(_:) for more information.
        
        // Clear the path control. This causes the path control to display its placeholder, which is set to "No Target" in Main.storyboard.
        elementPathControlManager.clearPathControl(outlinePathControl)
        
        // Clear the outline. Triggers the outlineViewSelectionDidChange(_:) delegate method, but it does nothing because the isManualSelection flag is false.
        elementOutline.reloadData()
    }
    
    // MARK: - ACTION METHODS
    // The outline view uses a path control as its primary navigation means, like the browser and list views. However, it does not use a contextual menu like the list view because the outline view itself is a more powerful version of the list view's contextual menu.
    
    @IBAction func popUpPathControlMenu(_ sender: NSPathControl) {
        // Action method connected to the sending outlinePathControl in Main.storyboard. It opens a pop-up menu positioned over the clicked path item to enable the user to select another UI Element for display in UI Browser's outline view. See ElementPathControlManager popUpMenu(for:) for more information.
        elementPathControlManager.popUpMenu(for: outlinePathControl)
    }
    
    /**
     Action method that updates the data model, the outline path control, the outline view and the rest of UI Browser's interface when the user chooses a UI element using the outline path control pop-up menu. Action methods with the same selectElement(_:) signature are implemented in the browser view, outline view and list view in the master (top) split item. It is connected programmatically to each menu item in the path control menu.
     
     This action method does not also update the outline view when the user selects an existing element using the mouse or keyboard, as in the browser view. Instead, mouse and keyboard selection in the outline view is handled by the outlineViewSelectionDidChange(_:) delegate method. See that method for details.

     - parameter sender: The outline path control pop-up menu item that sent the action.
     */
    // TODO: Update the rest of the UI Browser interface based on the selected element.
   @objc func selectElement(_ sender: NSMenuItem) {
        // Action method connected programmatically to the sending outline path control pop-up menu item in the ElementPathControlManager menuNeedsUpdate(_:) delegate method using MasterSplitItemViewController currentTabItemSelectElementAction(). The @objc attribute is required to use the #selector expression when connecting the action. Although it triggers the outlineViewSelectionDidChange(_:) delegate method, the delegate method does nothing because this method does it all.
        // This method collapses all rows before expanding the rows in the current selection path. This emulates the behavior of the browser view and avoids creating complex outlines that would distract the user from the current selection path.
        // The data model does not need to be updated or displayed in the outlineViewSelectionDidChange(_:) delegate method because it is updated and displayed here. See the outlineViewSelectionDidChange(_:) delegate method for details.

        let dataSource = ElementDataModel.sharedInstance

        // The current selection index path was temporarily saved in the element model's savedCurrentElementIndexPath private property in the elementPathControlManager menuWillOpen(_:) delegate method when the user opened the path control pop-up menu. It is reset to nil here because the user did choose a menu item instead of dismissing the menu without a selection, and the saved index path therefore does not need to be restored.
        dataSource.unsaveCurrentElementIndexPath()
        
        // Get information about the UI element selected by the user, including its index path, level and index, from the chosen menu item's represented object. The represented object is a node in the data model with the opaque type ElementNodeInfo, with public properties and methods to access information about it. It was added to the menu item in the elementPathControlManager menuNeedsUpdate(_:) delegate method when the menu item was created and configured.
        if let selectedNode = sender.representedObject as? ElementDataModel.ElementNodeInfo {
            let selectedIndexPath = dataSource.indexPath(ofNode: selectedNode)
            let selectedLevel = selectedIndexPath.length - 1
            let selectedIndex = selectedIndexPath.index(atPosition: selectedLevel)
            
            // Update the data model for the selected UI element. This is necessary here because updates during menu navigation are limited to new menu items and do not cover leftward mouse moves to a shallower level.
            dataSource.updateDataModelForCurrentElementAt(level: selectedLevel, index: selectedIndex)
            
            showView()
        }
    }
    
    // MARK: - DELEGATE, DATA SOURCE AND HELPER METHODS
    // All of the data source and delegate methods that access UI Browser's accessibility element information use the opague ElementDataModel object, and the information it caches is available to other UI Browser classes only through ElementDataModel public methods. The object was created and cached in ElementDataModel's updateDataModel(forApplicationElement:) or updateDataModelForCurrentElementAt(level:index:) method when the user chose a target application or selected another UI element.
    // UI Browser's outline view displays the data model in an NSOutlineView object. Navigation of the UI element hierarchy is handled by a path control or by selecting a row at any level of the outline using the mouse or keyboard. Path control navigation is handled in the ElementPathControlManager class for all of the master tab view tab items. Outline view navigation is handled here using NSOutlineView delegate methods.
    
    // NOTE about UI Browser's implementation of the NSOutlineViewDataSource and NSOutlineViewDelegate protocols.
    // While UI Browser's browser view uses data source methods that are part of the NSBrowserDelegate protocol, UI Browser's outline and list views take advantage of the separate data source methods in the NSOutlineViewDataSource and NSTableViewDataSource protocols as well as required NSOutlineViewDelegate and NSTableViewDelegate protocol methods.
    // UI Browser's model object in the MVC design pattern is an opaque object created and maintained in the ElementDataModel class. Its data is made available through the ElementDataModel.sharedInstance type property and public methods declared in ElementDataModel. The data model is constructed or updated using accessibility API functions made available through the PFAsssistiveFramework4 framework when the user chooses a target application or selects another UI element in the browser, outline or list view.
    // After the data model is updated, the NSOutlineViewDataSource and NSOutlineViewDelegate methods retrieve data for display in response to user actions based on the current contents of the data model rather than calling accessibility API methods directly. Caching the data in this way allows time-consuming accessibility operations to be performed once before the view is displayed instead of repeatedly in multiple calls to the framework methods.
    // To implement this workflow when the user chooses a target application using the Target menu, MainContentViewController's choose...Target(_:) action methods (in the TargetMenuExtension.swift file) call MainContentViewController's updateApplication(forNewTarget:usingTargetElement:) method. That method in turn calls MainContentViewController's updateData(usingTargetElement:) method, which calls ElementDataModel's updateDataModel(forApplicationElement:) to update the data source with the new target application. If successful, MainContentViewController's updateApplication(forNewTarget:usingTargetElement:) method then calls MainContentViewController's updateView(_:) method, which in turn calls MasterSplitItemViewController's updateView(_:) method, which then calls OutlineTabItemViewController's updateView() method if the outline view is currently selected. The outline view's updateView() method calls NSOutlineView's reloadData(forRowIndexes:columnIndexes:) to load the root application UI element from the data model and display it.
    // To implement this workflow when the user selects an existing element in the outline path control, OutlineTabItemViewController implements the selectElement(_:) action method. The path control pop-up menu's NSMenuDelegate delegate methods call ElementDataModel's updateDataModelForCurrentElementAt(level:index:) to update the data source with the new selection path. The action method then calls NSOutlineView's reloadData() method to load the new selection path and display it.
    // To implement this workflow when the user selects an existing element in the outline view with the mouse or keyboard, OutlineTabItemViewController implements the appropriate NSOutlineViewDelegate delegate methods. The delegate methods call ElementDataModel's updateDataModelForCurrentElementAt(level:index:) to update the data source with the new selection path. They also update the path control to display the new selection.
    
    // TODO: look for ways to make this faster....
    // ... For levels with large number of siblings, display a temporary "Loading..." item in the column if necessary then reload the column with valid entries. Or load it in chunks, with the first chunk big enough to display all, and subsequent chunks loaded in the background while the user reads the first chunk
    
    // MARK: NSOutlineViewDataSource
    // UI Browser uses a view-based NSOutlineView. Apple's NSOutlineViewDataSource documentation: "If you are using conventional data sources for content you must implement the basic methods that provide the outline view with data: outlineView(_:child:ofItem:), outlineView(_:isItemExpandable:), outlineView(_:numberOfChildrenOfItem:), and outlineView(_:objectValueFor:byItem:)." UI Browser does not use bindings to provide data to the outline view. It does not use target/action for editing, but instead uses delegate methods so rows can be selected using the keyboard arrow keys as well as mouse clicks.
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // Optional but mandatory data source method per the NSOutlineViewDataSource formal protocol. Returns the node representing the child UI element at index of the element represented by the specified node in the data source. Apple's NSOutlineViewDataSource documentation: "When these methods are invoked by the outline view, nil as the item refers to the 'root' item."
        let dataSource = ElementDataModel.sharedInstance
        if let node = item as? ElementDataModel.ElementNodeInfo {
            return dataSource.childNode(ofNode: node, atIndex: index)
        }
        // In UI Browser, the "root" item always has one child UI element, the root application or system-wide UI element.
        return dataSource.nodeAt(level: 0, index: 0)
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any)  -> Bool {
        // Optional but mandatory data source method per the NSOutlineViewDataSource formal protocol. Returns whether the UI element represented by the specified node in the data source has child elements.
        let dataSource = ElementDataModel.sharedInstance
        if let node = item as? ElementDataModel.ElementNodeInfo {
            return dataSource.childCount(ofNode: node) > 0
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int{
        // Optional but mandatory data source method per the NSOutlineViewDataSource formal protocol. Returns the number of child elements of the UI element represented by the specified node in the data source. Apple's NSOutlineViewDataSource documentation: "When these methods are invoked by the outline view, nil as the item refers to the 'root' item."
        let dataSource = ElementDataModel.sharedInstance
        
        // Apple's NSOutlineView documentation: "It is possible that your data source methods for populating the outline view may be called before awakeFromNib() if the data source is specified in Interface Builder. You should defend against this by having the data source’s outlineView(_:numberOfChildrenOfItem:) method return 0 for the number of items when the data source has not yet been configured. In awakeFromNib(), when the data source is initialized you should always call reloadData()."
        guard !dataSource.isEmpty else { return 0 }
        
        if let node = item as? ElementDataModel.ElementNodeInfo {
            return dataSource.childCount(ofNode: node)
        }
        
        // In UI Browser, the "root" item always has 1 child UI element, the root application or system-wide UI element.
        return 1
    }
    
    /* This method is no longer required.
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        // Optional but formerly mandatory data source method per the NSOutlineViewDataSource formal protocol. Returns the node representing the UI element represented by the specified node in the data source. Apple's NSOutlineViewDataSource documentation: "When these methods are invoked by the outline view, nil as the item refers to the 'root' item."
     // See comments in the ListTabItemViewController listView(_:objectValueFor: Row:) datasource method for information about why this method is no longer required.

     return nil
    }
    */
    
    // MARK: NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        // Optional but mandatory delegate method for view-based outline views per the NSOutlineViewDelegate formal protocol. Apple's NSOutlineViewDelegate documentation: "This method is required if you wish to use NSView objects instead of NSCell objects for the cells within an outline view. Cells and views cannot be mixed within the same outline view." Returns the view to be displayed in the outline's cell view in the specified column for the specified item.
        // This method is not called if no target application has been chosen. It is called once for every visible cell in the outline when the cell view is displayed and again when the column is scrolled or resized.
        // The base string value to be displayed for item can be created and returned in the view here. It can then be modified or replaced in outlineView(_:willDisplayCell:for:item:), if desired.
        if outlineView == elementOutline {
            
            if let node = item as? ElementDataModel.ElementNodeInfo {
                let dataSource = ElementDataModel.sharedInstance
                let element = dataSource.element(ofNode: node)

                let placeholder = "–"
                var cellText: String = ""
                switch tableColumn?.identifier {
                case TableColumnIdentifiers.role:
                    cellText = element.AXRole ?? placeholder
                case TableColumnIdentifiers.subrole:
                    cellText = element.AXSubrole ?? placeholder
                case TableColumnIdentifiers.index:
                    let path = dataSource.indexPath(ofNode: node)
                    cellText = String(path.index(atPosition: path.length - 1))
                case TableColumnIdentifiers.title:
                    let text = element.AXTitle ?? placeholder
                    cellText = text == placeholder ? text : "\"\(text)\""
                case TableColumnIdentifiers.type:
                    cellText = element.AXRoleDescription ?? placeholder
                case TableColumnIdentifiers.help:
                    cellText = element.AXHelp ?? placeholder
                default:
                    preconditionFailure("Unexpectedly entered default case in switch statement")
                }

                let cellView = elementOutline.makeView(withIdentifier: (tableColumn?.identifier)!, owner: self) as? NSTableCellView
                cellView?.textField?.stringValue = cellText
                return cellView
            }
        }
        return nil
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        // Optional delegate method per the NSOutlineViewDelegate formal protocol. Changes to the outline view's selection are handled by this delegate method instead of an action method connected to the outline view, although either approach is possible. One reason to prefer the delegate approach is that this delegate method responds to keyboard arrow key presses as well as mouse clicks, while an action method ignores the arrow keys. However, the delegate method responds to programmatic selections as well as manual selections, which may require special handling, as UI Browser does with the isManualSelection flag here to avoid redundant data model updates for programmatic selections.
        // UI Browser's outline view is designed to display only one expanded path at a time, the current element selection path, similar to the browser view. When the user selects a new row, UI Browser collapses the previous selection path back to the shortest path shared with the new selection path. Selecting a row automatically expands it, and expanding a row automatically selects it.
        // This delegate method is triggered in several different ways, depending on whether the user changed the UI element selection using the Target menu, the segmented control, the path control pop-up menu, or the mouse or keyboard. The isManualSelection flag is used to track the data model and outline view update and display process in the two different directions in which they occur, (a) programmatic selections that cause or use a data model update which then requires display in the outline view and (b) manual selections that change the list view display which then requires a data model update. In the first group, (a), the outline view's' row selection has not yet been displayed when a menu or the segmented control triggers this method programmatically (1) when the user chooses a target application in the menu bar's Target menu or the Target popup button's menu while the outline view is showing, (2) when the user uses the segmented control or View > UI Elements menu to switch into the outline view from another view, or (3) when the user selects an element using the outline path control pop-up menu. (The outline view does not use a contextual menu, as the list view does.) UI Browser is designed so that all three of the cases in the first group display the data model update immediately, before this delegate method is triggered, and the isManualSelection flag has already been set to false to prevent this delegate method from reduntantly updating and displaying the data model again. In the second group, (b), the data model has not yet been updated when the mouse or keyboard triggers this method manually (4) when the user selects an element by clicking the mouse or pressing an arrow key in the outline view and the selection is immediately displayed. UI Browser sets the isManualSelection flag to true to signal this delegate method that it needs to update the data model and display the update in affected views, such as the outline path control.
        // (a)(1) When the user selects a new target application or the system-wide target, the appropriate choose...Target action method in MainContentViewController (in TargetMenuExtension.swift) calls updateApplication(forNewTarget:usingTargetElement:), which calls updateData(usingTargetElement:) to update the data model. It also calls clearView() and updateView() to display the root application UI element or the SystemWide Target. The clearView() and updateView() methods call NSOutlineView reloadData() to update the display. That also unavoidably triggers this delegate method, but the isManualSelection property was already set to false to avoid updating the data model here because the data model was already updated. The isManualSelection property is reset to false here because this is the end of the cycle.
        // (2) When the user uses the segmented control or View > UI Elements menu to switch into the outline view from another view, the data model is used as is without updating. The segmented control or menubar menu item action methods result in a call to showView() to display the element that had previously been selected in the switched out view. The showView() method calls NSOutlineView reloadData() to update the display. That also unavoidably triggers this delegate method, the isManualSelection property was already set to false to avoid updating the data model here because the data model was already up to date. The isManualSelection property is reset to false here because this is the end of the cycle.
        // (3) When the user selects a new element using the outline path control pop-up menu, menu navigation is handled by ElementPathControlManager as its NSMenuDelegate. The user's navigation in the pop-up menu repeatedly updates the data model with calls to updateDataModelForCurrentElementAt(level:index:). The chosen pop-up menu item sends the selectElement(_:) action method, which calls NSTableView reloadData() to update the display. That also unavoidably triggers this delegate method, but the isManualSelection property was already set to false to avoid updating the data model because the data model was already updated. The isManualSelection property is reset to false because this is the end of the cycle.
        // (b)(4) When the user selects a new element with the mouse or keyboard, it automatically triggers this delegate method to update the display without using an action method. The data model has not yet been updated to reflect the new selection, so this delegate method must update it. The isManualSelection property was set to true when an OutlineTabItemTableView override of the NSResponder mouseDown(_:) or keyDown(_:) method was triggered by the user's mouse click or press of the up or down arrow. The isManualSelection property is tested here and, since it is true, the data model is updated and displayed; and it is then reset to false here because this is the end of the cycle.
        // The outline view is empty only when no target application is chosen. When it is not empty, it always has a selected row.
        
        let dataSource = ElementDataModel.sharedInstance
        if isManualSelection {
            // Update and display the data model in this delegate method only if it was not already updated and displayed. All selections that are made programmatically update and display the data model themselves and, because isManualSelection is false, this delegate method does nothing. Manual selections using the mouse or keyboard are updated and displayed here in this delegate method because the isManualSelection flag was set to true in ListTabItemTableView mouseDown(with:), moveUp(_:) and moveDown(_:). The flag is reset to false here to prepare for subsequent programmatic selections.
            isManualSelection = false

            guard let outline = notification.object as? NSOutlineView,
                outline.selectedRow >= 0
                else { return }
            // A selectedRow value of -1 indicates that the user clicked in the outline view when it is empty because there is no current running application target. (When the user clicks in an empty area of a non-empty outline, the selected row remains as it was before the click and this action method therefore simply redisplays that selection.)
            
            // Get information about the UI element selected by the user, including its index path, level and index, from the data model. The data model index path was saved when the current element was selected to show the current outline view, but it has not yet been updated to reflect the user's selection of a sibling. It needs to be updated here to reflect the user's selection of a row in the outline view at any level.
            let selectedLevel = elementOutline.level(forRow: elementOutline.selectedRow)
            let selectedIndex = elementOutline.childIndex(forItem: elementOutline.item(atRow: elementOutline.selectedRow)!)
            let selectedNode = dataSource.nodeAt(level: selectedLevel, index: selectedIndex)
            let selectedPath = dataSource.indexPath(ofNode: selectedNode)
            
            // Collapse the current selection path back to the shortest path shared with the new selection path.
            let expandedIndexPath = selectedPath as IndexPath
            var currentPath = dataSource.currentElementIndexPath! as IndexPath
            while !expandedIndexPath.starts(with: currentPath) {
                elementOutline.collapseItem(dataSource.node(atIndexPath:currentPath as NSIndexPath))
                currentPath.removeLast()
            }
            
            // Update the data model for the selected element and its children.
            ElementDataModel.sharedInstance.updateDataModelForCurrentElementAt(level: selectedLevel, index: selectedIndex)
            
            // Expand the selected element.
            elementOutline.expandItem(selectedNode)
            
            // Display the path control.
            elementPathControlManager.displayPathControl(outlinePathControl)
            
            // TODO: scroll the selected list item into view if necessary
        }
    }
    
    func outlineViewItemWillExpand(_ notification: Notification) {
        // Optional delegate method per the NSOutlineViewDelegate formal protocol.
        // UI Browser's outline view is designed to display only one expanded path at a time, the current selection path, similar to the browser view. When the user expands a node, UI Browser selects it and collapses the previous selection path back to the shortest path shared with the new selection path.
        // The outline view is empty only when no target application is chosen. When it is not empty, it always has a selected row.
        // UI Browser triggers this method only when the user expands a node using the mouse or keyboard. When a node is expanded programmatically in showView() and selectElement(_:), the delegate is temporarily disconnected because those methods handle the expansion themselves.
        
        let dataSource = ElementDataModel.sharedInstance
        
        // Get information about the UI element expanded by the user, including its index path, level and index, from the data model.
        if let expandedNode = notification.userInfo?["NSObject"] as? ElementDataModel.ElementNodeInfo {
            let expandedPath = dataSource.indexPath(ofNode: expandedNode)
            let expandedLevel = expandedPath.length - 1
            let expandedIndex = expandedPath.index(atPosition: expandedLevel)
            
            // Collapse the current selection path back to the shortest path shared with the new selection path.
            let expandedIndexPath = expandedPath as IndexPath
            var currentPath = dataSource.currentElementIndexPath! as IndexPath
            while !expandedIndexPath.starts(with: currentPath) {
                elementOutline.collapseItem(dataSource.node(atIndexPath:currentPath as NSIndexPath))
                currentPath.removeLast()
            }
            
            // Select the expanded element.
            let selectedRow = elementOutline.row(forItem: expandedNode)
            elementOutline.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection:false)
            elementOutline.scrollRowToVisible(elementOutline.selectedRow)

            // Update the data model for the selected element and its children.
            dataSource.updateDataModelForCurrentElementAt(level: expandedLevel, index: expandedIndex)
            
            // Display the path control.
            elementPathControlManager.displayPathControl(outlinePathControl)
            
            // TODO: scroll the selected list item into view if necessary
        }
    }
    
    func performIgnoringDelegate(_ aSelector: Selector, with anArgument: Any) {
        // Perform a selector without triggering the receiver's delegate. Called to perform the expandItem(_:) method in showView() and selectElement(_:).
        let savedDelegate = elementOutline.delegate
        elementOutline.delegate = nil
        elementOutline.perform(aSelector, with: anArgument)
        elementOutline.delegate = savedDelegate
    }
    
}
