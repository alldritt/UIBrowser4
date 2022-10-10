//
//  ListTabItemViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

import Cocoa

// MARK: Class ListTabItemViewController, subclass of NSViewController

/**
 `ListTabItemViewController` receives a `tab items` relationship segue triggered by `MasterTabViewController` in *Main.storyboard*. It is instantiated at launch only if the state restoration mechanism restores it because it was the selected master tab view item when UI Browser last quit; otherwise, it is instantiated if and when the user selects the List tab view item. It calls `loadView()` to instantiate and load the tab view item's view.
 
 UI Browser's master (top) split view pane displays the UI elements in the target's current accessibility hierarchy in one of three tab view items, each of which contains a different kind of view; namely, a browser view, an outline view, and a list view. `ListTabItemViewController` controls the list view, created in *Main.storyboard*. All three of these element views rely on a common shared repository or data source for the data they display, which is cached in the `ElementDataModel` singleton object that serves as UI Browser's model object in the Model-View-Controller (MVC) design pattern. The data model is updated lazily on the fly by `ListTabItemViewController` as the user chooses different targets and uses the mouse or keyboard to select various elements in the path control or the list view.
 
 UI Browser uses the NSListViewDataSource protocol's data source methods to manage the data model when it is displayed in the list view.
 
 The list view is empty after *Main.storyboard* is loaded at launch. Only when the user chooses a target does the list view display a single row, known in the accessibility world as the "root application UI element."
 
 UI Browser separates the data model from the data's display, and it implements the data source and delegate methods in this `ListTabItemViewController` to manage the model. The shared singleton `ElementDataModel` object is an opaque object modeling the current target's accessibility hierarchy. In response to the user's choosing a target or selecting an element with the mouse or keyboard, `ListTabItemViewController` uses its NSTableViewDataSource data source methods to modify the model's contents accordingly so that it can later retrieve them and tell the list view to display them. `ElementDataModel` adds objects to the data repository by calling accessibility API functions through our *PFAssistiveFramework4* framework. It constructs a variety of objects that are cached in the model object for use when the browser, outline or list view displays them. Getting all of these data model operations out of the way once before the user's selection is displayed greatly improves performance, because the operations do not have to be performed repeatedly thereafter while the user navigates the display. The data source retrieval and display methods do not use any accessibility API functions themselves, but instead use the data source methods to retrieve the precomputed information from the data model. This caching of precomputed data source information allows rapid scrolling and window resizing, rapid user switching among the three element tab item views, and other features such as the continued display of elements after they have been destroyed in the user interface and are no longer available to accessibility functions.
 
 The OutlineTabItemViewController and ListTabItemViewController classes are set up like BrowserTabItemViewController, but they conform to the NSOutlineViewDataSource and NSTableViewDataSource protocols. Those two protocols are separate from the NSOutlineViewDelegate and NSTableViewDelegate protocols, whereas the NSBrowserDelegate protocol contains both delegate and data source methods for browsers in a single protocol.
 
 The list view's primary navigation tool is a path control at the top of the list tab view item. See ElementPathControlManager.swift for details. The list view also supports navigation using the mouse and keyboard to select sibling UI elements in the currently displayed list, and a two-level contextual menu to select a child of any UI element in the currently displayed list in a manner similar to clicking a row in the outline view.
*/
class ListTabItemViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {
    
    // MARK: - PROPERTIES
    
    // MARK: Access to storyboard scenes.
    
    /// A type property that gives access to this object from any other object by referencing `ListTabItemViewController.sharedInstance`.
    static private(set) var sharedInstance: ListTabItemViewController! // set to self in viewDidLoad()
    
    // MARK: Path control
    
    // TODO: Add error handling or move into viewDidLoad().
    var elementPathControlManager: ElementPathControlManager = ElementPathControlManager()
    
    // MARK: Miscellaneous
    
    /// Flag signals whether the selection of a row was made manually by the mouse or keyboard, as opposed to programmatically. If the flag is true, the data model needs to be updated and displayed in the tableViewSelectionDidChange(_:) delegate method to reflect the manual selection. The flag is used to prevent redundant updates by the delegate method when selection is made and the data model is updated and displayed programmatically. It is initialized to false here. It is set to true when the user makes a new selection manually using the mouse or the up or down arrow key. All of these cases automatically trigger the tableViewSelectionDidChange(_:) delegate method. If the flag is true, the delegate method updates and displays the data model, first resetting the falg to false to prepare for subsequent programmatic selections; if the flag is false, the delegate method does nothing in order to prevent redundant updates.
    var isManualSelection = false
    
    /// Struct declaring NSUserInterfaceItemIdentifier objects used in the tableView(_:viewFor:row:) delegate method to populate the columns of the list view. They are set in the Main.storyboard List Tab Item Table View Scene to identify each column.
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
    @IBOutlet weak var listPathControl: NSPathControl!

    /// An outlet connected to the element list view.
    @IBOutlet weak var elementList: NSTableView!
    
    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the shared type property to self to give access to this object from any other object by referencing ListTabItemViewController.sharedInstance.
        ListTabItemViewController.sharedInstance = self
        
        // Set path control placeholder text attributes when no target is chosen. The text content is set in Main.storyboard.
        listPathControl.placeholderAttributedString = NSAttributedString(string: listPathControl.placeholderString ?? "", attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .ultraLight), .foregroundColor: NSColor.gray])

        // Apple's NSTableView documentation: "It’s possible that your data source methods for populating the table view may be called before awakeFromNib() is called if the data source is specified in Interface Builder. You should defend against this by having the data source’s numberOfRows(in:) method return 0 for the number of rows when the data source has not yet been configured. In awakeFromNib(), when the data source is initialized you should always call reloadData on the table view."
        elementList.reloadData()
    }
    
    // MARK: Miscellaneous Methods
    
    /**
     Displays the root application UI element or the SystemWide element in the first row of the list view when the user chooses a new target or refreshes the current target, with the root element automatically selected.
     
     Called in the `MasterSplitItemViewController` `updateView()` method when the user selects a new target and the top tab view item is the list tab view item. Also called when the user Shift-clicks the Refresh Application button to refresh the application to root.
     */
    func updateView() {
        // Display the data model's initial contents. Called in the MasterSplitItemViewController updateView() method when the user selects a new target.
        // The data model does not need to be updated because it was updated in updateApplication(forNewTarget:usingTargetElement:), and it will not need to be displayed in the tableViewSelectionDidChange(_:) delegate method because it is displayed here. See tableViewSelectionDidChange(_:) for more information.
        
        // Display the path control.
        elementPathControlManager.updateTargetSelection(for: listPathControl)

        // Display the element list.
        elementList.reloadData()
        
        // The current element is the root application UI element or the SystemWide element, and it is automatically selected because the Selection Empty setting is deselected in Main.storyboard and there is only one UI element at the root application level of the accessibility hierarchy.
        view.window?.makeFirstResponder(elementList)

        // TODO: The attributes drawer etc. should show the application info.
    }
    
    /**
     Displays the current UI element and its siblings in the list view, and selects the current element, after the data model is updated to reflect the current selected element path when the user switches from a different view or selects a new element using the list path control or the list view's contextual menu.
     
     Called in `MasterSplitItemViewController` `showView()` when the user chooses the list view in the Master tab view item segmented control or the View > UI Elements menu and in the selectElement(_:) and selectElementWithContextMenu(_:) action methods when the user selects a new element using the list path control or the list view's contextual menu.
     */
    func showView() {
        // Display the data model's current contents. Called in the showMasterTabItem(_:) action method when the user chooses the list view in the masterTabViewSelector segmented control or the View > UI Elements menu.
        
        // Select the current element and display its siblings.
        let dataSource = ElementDataModel.sharedInstance
        if let currentElementIndexPath = dataSource.currentElementIndexPath {
            // The data model does not need to be updated because the list view will display the same element path as the previous view, and it will not need to be displayed in the tableViewSelectionDidChange(_:) delegate method because it is displayed here. See tableViewSelectionDidChange(_:) for more information.
            
            // Display the path control.
            elementPathControlManager.displayPathControl(listPathControl)

            // Display the element list. Triggers the tableViewSelectionDidChange(_:) delegate method, but it does nothing because the isManualSelection flag is false.
            elementList.reloadData()
        
            // Select the current element and display its siblings.
            let selectedIndex = currentElementIndexPath.index(atPosition: currentElementIndexPath.length - 1)
            elementList.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection:false)
            elementList.scrollRowToVisible(selectedIndex)
            
            view.window?.makeFirstResponder(elementList)
        } else {
            // Current target is No Target.
            clearView()
        }
    }
    
    /**
     Displays the empty list view when the user chooses No Target. Also clears the list view in preparation for displaying new contents when the user chooses the SystemWide Target or an application target.
     
     Called in MasterSplitItemViewController's updateView() method when the user chooses No Target, SystemWide Target or an application target and the top tab view item is the list tab view item.
     */
    func clearView() {
        // Display an empty data model having no contents. Called in the MasterSplitItemViewController updateView() method when the user chooses No Target and to clear the list before displaying new contents when the user chooses the SystemWide Target or an application target.
        // The data model does not need to be updated because it was already updated in updateApplication(forNewTarget:usingTargetElement:), and it will not need to be displayed in the tableViewSelectionDidChange(_:) delegate method because it is displayed here. See tableViewSelectionDidChange(_:) for more information.

        // Clear the path control. This causes the path control to display its placeholder, which is set to "No Target" in Main.storyboard.
        elementPathControlManager.clearPathControl(listPathControl)
        
        // Clear the list. Triggers the tableViewSelectionDidChange(_:) delegate method, but it does nothing because the isManualSelection flag is false.
        elementList.reloadData()
    }
    
    // MARK: - ACTION METHODS
    // The list view uses a path control as its primary navigation means, like the browser and outline views. It also uses a contextual menu as a secondary navigation means, emulating the built-in behavior of the browser and outline views.
    
    @IBAction func popUpPathControlMenu(_ sender: NSPathControl) {
        // Action method connected to the sending listPathControl in Main.storyboard. It opens a pop-up menu positioned over the clicked path item to enable the user to select another UI Element for display in UI Browser's list view. See ElementPathControlManager popUpMenu(for:) for more information.
        elementPathControlManager.popUpMenu(for: listPathControl)
    }

    /**
     Action method that updates the data model, the list path control, the list view and the rest of UI Browser's interface when the user selects a UI element using the list path control pop-up menu. Action methods with the same selectElement(_:) signature are implemented in the browser view, outline view and list view in the master (top) split item. It is connected programmatically to each menu item in the path control menu.
     
     This action method does not also update the list view when the user selects an existing element using the mouse or keyboard, as in the browser view. Instead, mouse and keyboard selection in the list view is handled by the tableViewSelectionDidChange(_:) delegate method. See that method for details.
     
     - parameter sender: The list path control pop-up menu item that sent the action.
     */
    // TODO: Update the rest of the UI Browser interface based on the selected element.
    @objc func selectElement(_ sender: NSMenuItem) {
        // Action method connected programmatically to the sending list path control pop-up menu item in the ElementPathControlManager menuNeedsUpdate(_:) delegate method using MasterSplitItemViewController currentTabItemSelectElementAction(). The @objc attribute is required to use the #selector expression when connecting the action. Although it triggers the tableViewSelectionDidChange(_:) delegate method, the delegate method does nothing because this method does it all.
        // The data model does not need to be updated or displayed in the tableViewSelectionDidChange(_:) delegate method because it is updated and displayed here. See the tableViewSelectionDidChange(_:) delegate method for details.

        let dataSource = ElementDataModel.sharedInstance

        // The current selection index path was temporarily saved in the element model's savedCurrentElementIndexPath variable in the elementPathControlManager menuWillOpen(_:) delegate method when the user opened the path control pop-up menu. It is reset to nil here because the user did choose a menu item instead of dismissing the menu without a selection, and the saved index path therefore does not need to be restored.
        dataSource.unsaveCurrentElementIndexPath()

        // Get information about the sibling or child UI element selected by the user, including its index path, level and index, from the chosen menu item's represented object. The represented object is a node in the data model with the opaque type ElementNodeInfo, with public properties and methods to access information about it. It was added to the menu item in the elementPathControlManager menuNeedsUpdate(_:) delegate method when the menu item was created and configured.
        if let selectedNode = sender.representedObject as? ElementDataModel.ElementNodeInfo {
            let selectedIndexPath = dataSource.indexPath(ofNode: selectedNode)
            let selectedLevel = selectedIndexPath.length - 1
            let selectedIndex = selectedIndexPath.index(atPosition: selectedLevel)
            
            // Update the data model for the selected UI element. This is necessary here because updates during menu navigation are limited to new menu items and do not cover leftward mouse moves to a shallower level.
            dataSource.updateDataModelForCurrentElementAt(level: selectedLevel, index: selectedIndex)
            
            showView()
            
        /* Update the rest of UI Browser's interface. May be best to do this in tableViewSelectionDidChange(_:)?
         // TODO: the following comments relate to future additions:
         
         /// The list view that sent the action method.
         //let list = sender as! NSTableView
         
         //guard list.selectedColumn >= 0 else {return}
         // A selectedColumn value of -1 indicates that no column was selected, so the user must have clicked in an empty list column or on a row separator. The list may have been empty because there is no current running application target.
         
         //  In table and outline views, a click automatically triggers a ...DidSelect delegate method unless the row is already selected, unlike a browser view, which requires explicit code to trigger the delegate's selection behavior.
         ///
         // This action method would not be needed in tableview if children were selected by clicking an element in a column of the list view, because it could all be done in the tableViewSelectionDidChange(_:) delegate method if I don't need to take action when an already-selected row is selected, and besides children are not displayed in the list view. However, we are using a path control to select elements, so this selectAction method will be triggered by a selection in a path control popup menu, instead.
         // Trigger the ListTabItemViewController.tableView(_:viewFor:row:) delegate method to update the list in response to the user's selection of an element in the path control using the mouse or keyboard. [[[A click in a browser column's empty space below its last filled row (clickedRow == -1) selects the element in the selection path for the previous column, or the root application UI element.]]]
         //        elementList.selectRowIndexes(elementList.selectedRowIndexes, byExtendingSelection: false)
         //        print("currentElementPath: \(ElementDataModel.sharedInstance.currentElementPath)")
         //browser.scrollColumnToVisible(browser.lastColumn) // scroll new selected element and its children into view, if necessary
         ///
         
         // Implement this somewhere when write detail split item code.
         ///
         // Update other UI.
         // The updateDetailSplitItemForElement(_:) method caches information about attributes, actions or notifications of the selected element in their respective data sources, depending on which view is selected in detail (bottom) split item view, before displaying them.
         if let selectedElement = ElementDataModel.shared.currentElement {
         DetailSplitItemViewController.controller.updateDetailSplitItemForElement(selectedElement)
         validateControls()
         }
         ///
         //        }
         */
        }
    }
    
    // TODO: Update the rest of the UI Browser interface based on the selected element.
    @objc func selectElementWithContextMenu(_ sender: NSMenuItem) {
        // Action method connected to the sending contextual menu item programmatically in the ListTabItemViewController menuNeedsUpdate(_:) delegate method. This method is not called in any other way. It triggers the tableViewSelectionDidChange(_:) delegate method.
        // The data model does not need to be updated or displayed in the tableViewSelectionDidChange(_:) delegate method because it is updated and displayed here. See the tableViewSelectionDidChange(_:) delegate method for details.

        // The current selection index path was temporarily saved in the element model's savedCurrentElementIndexPath variable in the menuWillOpen(_:) delegate method when the user opened the path control pop-up menu. It is reset to nil here because the user did choose a menu item instead of dismissing the menu without a selection, and the saved index path therefore does not need to be restored.
        let dataSource = ElementDataModel.sharedInstance
        dataSource.unsaveCurrentElementIndexPath()

       // Get information about the child element selected by the user, including the child's index path, level and index, from the chosen menu item's represented object. The represented object is a node in the data model with the opaque type ElementNodeInfo, with public properties and methods to access information about it. It was added to the menu item in the menuNeedsUpdate(_:) delegate method when the menu item was created and configured.
        let selectedNode = sender.representedObject as! ElementDataModel.ElementNodeInfo
        let selectedIndexPath = dataSource.indexPath(ofNode: selectedNode)
        let selectedLevel = selectedIndexPath.length - 1
        let selectedIndex = selectedIndexPath.index(atPosition: selectedLevel)
        
        // Update the data model for the selected UI element. This is necessary here because updates during menu navigation are limited to new menu items and do not cover leftward mouse moves to a shallower level. In addition, a different parent element may be selected here.
        dataSource.updateDataModelForCurrentElementAt(level: selectedLevel, index: selectedIndex)

        showView()
    }

    // MARK: - DELEGATE, DATA SOURCE AND HELPER METHODS
    // All of the data source and delegate methods that access UI Browser's accessibility element information use the opague ElementDataModel object, and the information it caches is available to other UI Browser classes only through ElementDataModel public methods. The object was created and cached in ElementDataModel's updateDataModel(forApplicationElement:) or updateDataModelForCurrentElementAt(level:index:) method when the user chose a target application or selected another UI element.
    // UI Browser's list view displays the data model in an NSTableView object. Navigation of the UI element hierarchy is handled by a path control, by a contextual menu, or by selecting a row in the list using the mouse or keyboard. Path control navigation is handled in the ElementPathControlManager class for all of the master tab view tab items. List view navigation is handled here using NSTableView delegate methods.
    
    // NOTE about UI Browser's implementation of the NSTableViewDataSource and NSTableViewDelegate protocols.
    // While UI Browser's browser view uses data source methods that are part of the NSBrowserDelegate protocol, UI Browser's outline and list views take advantage of the separate data source methods in the NSOutlineViewDataSource and NSTableViewDataSource protocols as well as required NSOutlineViewDelegate and NSTableViewDelegate protocol methods.
    // UI Browser's model object in the MVC design pattern is an opaque object created and maintained in the ElementDataModel class. Its data is made available through the ElementDataModel.sharedInstance type property and public methods declared in ElementDataModel. The data model is constructed or updated using accessibility API functions made available through the PFAsssistiveFramework4 framework when the user chooses a target application or selects another UI element in the browser, outline or list view.
    // After the data model is updated, the NSTableViewDataSource and NSTableViewDelegate methods retrieve data for display in response to user actions based on the current contents of the data model rather than calling accessibility API methods directly. Caching the data in this way allows time-consuming accessibility operations to be performed once before the view is displayed instead of repeatedly in multiple calls to the framework methods.
    // To implement this workflow when the user chooses a target application using the Target menu, MainContentViewController's choose...Target(_:) action methods (in the TargetMenuExtension.swift file) call MainContentViewController's updateApplication(forNewTarget:usingTargetElement:) method. That method in turn calls MainContentViewController's updateData(usingTargetElement:) method, which calls ElementDataModel's updateDataModel(forApplicationElement:) to update the data source with the new target application. If successful, MainContentViewController's updateApplication(forNewTarget:usingTargetElement:) method then calls MainContentViewController's updateView(_:) method, which in turn calls MasterSplitItemViewController's updateView(_:) method, which then calls ListTabItemViewController's updateView() method if the list view is currently selected. The list view's updateView() method calls NSTableView's reloadData(forRowIndexes:columnIndexes:) to load the root application UI element from the data model and display it.
    // To implement this workflow when the user selects an existing element in the list path control, ListTabItemViewController implements the selectElement(_:) action method. The path control pop-up menu's NSMenuDelegate delegate methods call ElementDataModel's updateDataModelForCurrentElementAt(level:index:) to update the data source with the new selection path. The action method then calls NSTableView's reloadData() method to load the new selection path and display it.
    // To implement this workflow when the user selects an existing element in the list view with the mouse or keyboard, ListTabItemViewController implements the appropriate NSTableViewDelegate delegate methods. The delegate methods call ElementDataModel's updateDataModelForCurrentElementAt(level:index:) to update the data source with the new selection path. They also update the path control to display the new selection.
    
    // TODO: look for ways to make this faster....
    // ... For levels with large number of siblings, display a temporary "Loading..." item in the column if necessary then reload the column with valid entries. Or load it in chunks, with the first chunk big enough to display all, and subsequent chunks loaded in the background while the user reads the first chunk
    
    // MARK: NSTableViewDataSource
    // UI Browser uses a view-based NSTableView. Apple's NSTableViewDataSource documentation: "View-based table views must not use the tableView(_:setObjectValue:for:row:) method for setting values. Instead the views must explicitly set the values for the fields, or use Cocoa bindings.... See Table View Programming Guide for Mac for more information on populating view-based and cell-based table views." UI Browser does not use bindings to provide data to the list view. It does not use target/action for editing, but instead uses delegate methods so rows can be selected using the keyboard arrow keys as well as mouse clicks.
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        // Optional but mandatory data source method per the NSTableViewDataSource formal protocol. Returns the number of rows in the list view required to display all of the UI elements at the currently selected level of the accessibility hierarchy.
        // Apple's NSTableViewDataSource documentation says this method is required if not using Cocoa bindings to provide data to the table view.
        let dataSource = ElementDataModel.sharedInstance
        
        // Apple's NSTableView documentation: "It’s possible that your data source methods for populating the table view may be called before awakeFromNib() is called if the data source is specified in Interface Builder. You should defend against this by having the data source’s numberOfRows(in:) method return 0 for the number of rows when the data source has not yet been configured. In awakeFromNib(), when the data source is initialized you should always call reloadData on the table view."
        guard !dataSource.isEmpty else { return 0 }

        // If the data model has one or more levels, the list view displays the elements at the level currently selected in the path control.
        return dataSource.nodeCount(atLevel: dataSource.currentElementIndexPath!.length - 1)
    }
    
    /* This method is no longer required.
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        // Optional but formerly mandatory data source method per the NSTableViewDataSource formal protocol. Returns the item in the data source in the specified table column and row.
        // Apple's NSTableViewDataSource documentation says the tableView(_:setObjectValue:for:row:) datasource method must not be used in view-based table views.
        // Apple's NSTableViewDataSource documentation says this tableView(_:objectValueFor:row:) datasource method is required and mandatory if not using Cocoa bindings to provide data to the table view. However, UI Browser's list view works correctly without it, and the WWDC 2011 session "View Based NSTableView Basic to Advanced" says it was previously required for cell-based table views but is now optional. See https://stackoverflow.com/questions/41708427/purpose-of-tableview-objectvalueforrow.
        
        return nil
    }
    */
    
   // MARK: NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // Optional but mandatory delegate method for view-based table views per the NSTableViewDelegate formal protocol. Apple's NSTableViewDelegate documentation: "This method is required if you want to use NSView objects instead of NSCell objects for the cells within a table view." Returns the view to be displayed in the list's cell view in the specified column and row.
        // This method is not called if no target application has been chosen. It is called once for every visible cell in the list when the cell view is displayed and again when the column is scrolled or resized.
        // The base string value to be displayed for each item can be created and returned here. It can then be modified or replaced in tableView(_:willDisplayCell:for:row:), if desired.
        if tableView == elementList {
            
            let dataSource = ElementDataModel.sharedInstance
            let node = dataSource.nodeAt(level: dataSource.currentElementIndexPath!.length - 1, index: row)
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
            
            let cellView = elementList.makeView(withIdentifier: (tableColumn?.identifier)!, owner: self) as? NSTableCellView
            cellView?.textField?.stringValue = cellText
            return cellView
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        // Optional delegate method per the NSTableViewDelegate formal protocol. In Cocoa tradition, changes to an NSTableView's selection are usually handled by delegate methods such as this instead of an action method connected to the table view, although either approach is possible. One reason to prefer the delegate approach is that this delegate method responds to keyboard arrow key presses as well as mouse clicks, while an action method ignores the arrow keys. However, the delegate method responds to programmatic selections as well as manual selections, which may require special handling, as UI Browser does with the isManualSelection flag here to avoid redundant data model updates for programmatic selections.
        // This delegate method is triggered in several different ways, depending on whether the user changed the UI element selection using the Target menu, the segmented control, the path control pop-up menu, the list view contextual menu, or the mouse or keyboard. The isManualSelection flag is used to track the data model and list view update and display process in the two different directions in which it occurs, (a) programmatic selections that cause or use a data model update which then requires display in the list view, and (b) manual selections that change the list view display which then require a data model update. In the first group, (a), the list view's' row selection has not yet been displayed when a menu or the segmented control triggers this method programmatically (1) when the user chooses a target application in the menu bar's Target menu or the Target popup button's menu while the list view is showing, (2) when the user uses the segmented control or View > UI Elements menu to switch into the list view from another view, (3) when the user selects an element using the list path control pop-up menu, or (4) when the user selects an element using the list view contextual menu to choose a sibling UI element and child element. UI Browser is designed so that all four of the cases in the first group display the data model update immediately, before this delegate method is triggered, and the isManualSelection flag is already set to false to prevent this delegate method from reduntantly updating and displaying the data model again. In the second group, (b), the data model has not yet been updated when the mouse or keyboard triggers this method manually (5) when the user selects an element by clicking the mouse or pressing an arrow key in the list view and the selection is immediately displayed. UI Browser sets the isManualSelection flag to true to signal this delegate method that it needs to update the data model and display the update in affected views, such as the list path control.
        // (a)(1) When the user selects a new target application or the system-wide target, the appropriate choose...Target action method in MainContentViewController (in TargetMenuExtension.swift) calls updateApplication(forNewTarget:usingTargetElement:), which calls updateData(usingTargetElement:) to update the data model. It also calls clearView() and updateView() to display the root application UI element or the SystemWide Target. The clearView() and updateView() methods call NSTableView reloadData() to update the display. That also unavoidably triggers this delegate method, but the isManualSelection property was already set to false to avoid updating the data model here because the data model was already updated. The isManualSelection property is reset to false here because this is the end of the cycle.
        // (2) When the user uses the segmented control or View > UI Elements menu to switch into the list view from another view, the data model is used as is without updating. The segmented control or menubar menu item action methods result in a call to showView() to display the element that had previously been selected in the switched out view. The showView() method calls NSTableView reloadData() to update the display. That also unavoidably triggers this delegate method, but the isManualSelection property was already set to false to avoid updating the data model here because the data model was already up to date. The isManualSelection property is reset to false here because this is the end of the cycle.
        // (3) When the user selects a new element using the list path control pop-up menu, menu navigation is handled by ElementPathControlManager as its NSMenuDelegate. The user's navigation in the pop-up menu repeatedly updates the data model with calls to updateDataModelForCurrentElementAt(level:index:). The chosen pop-up menu item sends the selectElement(_:) action method, which calls NSTableView reloadData() to update the display. That also unavoidably triggers this delegate method, but the isManualSelection property was already set to false to avoid updating the data model because the data model was already updated. The isManualSelection property is reset to false here because this is the end of the cycle.
        // (4) When the user selects a new element using the list view contextual menu, menu navigation is handled here in its NSMenuDelegate. The user's navigation in the contextual menu repeatedly updates the data model with calls to updateDataModelForCurrentElementAt(level:index:). The chosen contextual menu item sends the selectElementWithContextMenu(_:) action method, which calls NSTableView reloadData() to update the display. That also unavoidably triggers this delegate method, but the isManualSelection property was already set to false to avoid updating the data model because the data model was already updated. The isManualSelection property is reset to false here because this is the end of the cycle.
        // (b)(5) When the user selects a new element with the mouse or keyboard, it automatically triggers this delegate method to update the display without using an action method. The data model has not yet been updated to reflect the new selection, so this delegate method must update it. The isManualSelection property was set to true when a ListTabItemTableView override of the NSResponder mouseDown(_:) or keyDown(_:) method was triggered by the user's mouse click or press of the up or down arrow. The isManualSelection property is tested here and, since it is true, the data model is updated and displayed; and it is then reset to false here because this is the end of the cycle.
        // The list view is empty only when no target application is chosen. When it is not empty, it always has a selected row.

        let dataSource = ElementDataModel.sharedInstance
        if isManualSelection {
            // Update and display the data model in this delegate method only if it was not already updated and displayed. All selections that are made programmatically update and display the data model themselves and, because isManualSelection is false, this delegate method does nothing. Manual selections using the mouse or keyboard are updated and displayed here in this delegate method because the isManualSelection flag was set to true in ListTabItemTableView mouseDown(with:), moveUp(_:) and moveDown(_:). The flag is reset to false here to prepare for subsequent programmatic selections.
            isManualSelection = false
            
            guard let list = notification.object as? NSTableView,
                list.selectedRow >= 0
                else { return }
            // A selectedRow value of -1 indicates that the user clicked in the list view when it is empty because there is no current running application target. (When the user clicks in an empty area of a non-empty list, the selected row remains as it was before the click and this action method therefore simply redisplays that selection.)
            
            // Get information about the sibling UI element selected by the user, including its index path, level and index, from the data model. The data model index path was saved when the current element was selected to show the current list view, but it has not yet been updated to reflect the user's selection of a sibling. It needs to be updated here only to reflect the user's selection of a row in the list view at the current level, because the mouse or keyboard cannot be used to change the level in the list view.
            let currentIndexPath = dataSource.currentElementIndexPath!
            let selectedLevel = currentIndexPath.length - 1
            let selectedIndex = list.selectedRow
            
            // Update the data model for the selected element and its children.
            ElementDataModel.sharedInstance.updateDataModelForCurrentElementAt(level: selectedLevel, index: selectedIndex)
            
            // Update the path control.
            elementPathControlManager.displayPathControl(listPathControl)
        }
    }
    
    // MARK: NSMenuDelegate
    // UI Browser's primary means to navigate the data model in the list view is the list path control. The path control's multi-level pop-up hierarchical menu enables the user to select any UI element at any level of the data model. The delegate methods for the path control's pop-up menu are implemented in ElementPathControlManager.
    // UI Browser's list view uses a contextual menu as a secondary means to navigate the data model. When the user Control-clicks or right clicks any row in the list view, the system automatically calls the ListTabItemTableView override of the NSView menu(for:) method to create the contextual menu, and to create its single root level menu item corresponding to the clicked row. Instead of returning the contextual menu and leaving it to the system to pop it up automatically wherever the user clicked, as the default menu(for:) method does, the override method pops it up programmatically positioned over the clicked row and returns nil to prevent the system from popping it up again. It is a simple two-level hierarchical menu enabling the user to quickly select a child UI element of the element represented by the clicked row, much like clicking an expandable row in an outline view. The NSMenuDelegate methods for the contextual menu are implemented here.
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        // Optional delegate method per the NSMenuDelegate formal protocol. It is triggered by the NSView menu(for:) override method when it pop's the menu up in response to the user's right click or Control-click in a row. If the UI element represented by the clicked row has children, it is triggered a second time by the menu(_:willHighlight: delegate method when it sets the submenu. Apple's NSMenuDelegate documentation: "Using this method, the delegate can change the menu by adding, removing, or modifying menu items.... Menu item validation occurs after this method is called." The NSMenuDelegate clickedRow property is valid here, as explained in the ListTabItemTableView menu(for:) override method's comments.
        // This delegate method is called before the menuWillOpen(_:) delegate method.
        
     // Get the affected level of the data model based on the current list path control. The affected level for the root level of the menu is the level of the sibling UI elements currently displayed in the list view (the level of the last path control item), and the affected level for the child menu is the next deeper level (not yet displayed in the path control).
       let affectedLevel = menu.supermenu == nil ? listPathControl.pathItems.count - 1 : listPathControl.pathItems.count
        
        // Configure the first and second levels of the menu. The single menu item for the root level of the menu was created and configured in the ListTabItemTableView override of the NSTableView menu(for:) method. The only thing it needs in the first if branch is to have its submenu created and associated with it so its submenu indicator triangle will be displayed. The menu items for the second level will be displayed when the user highlights the first-level menu's menu item by moving the mouse over it, triggering the menu(_:willHighlight:) delegate method. That delegate method will actually set the submenu and thereby trigger this menuNeedsUpdate(_:) delegate method a second time to add the child menu items to it in the second if branch.
        let dataSource = ElementDataModel.sharedInstance
        if let nodes = dataSource.nodesAt(level: affectedLevel) {
            if menu.supermenu == nil {
                // Menu is the root menu. If its menu item represents a UI element that has children, create its submenu and associate it with the menu item. The associated submenu will give it a submenu indicator triangle. Its menu item will be displayed immediately. The child menu items will be displayed when the menu(_:willHighlight:) delegate method is triggered. That delegate method's call to the NSMenu setSubmenu(_:for:) method will trigger this menuNeedsUpdate(_:) delegate method again, which will add the child menu items to the submenu.
                let thisNode = nodes[elementList.clickedRow]
                if dataSource.childCount(ofNode: thisNode) > 0 {
                    menu.items[0].submenu = NSMenu(title: menu.title) // does not trigger a delegate method
                }
            } else {
                // Menu is the submenu. This delegate method was triggered a second time because the clicked row has child UI elements needing menu items.
                var menuItem: NSMenuItem
                var menuItemTitle: String
                let menuItemAction = #selector(selectElementWithContextMenu)
                for thisNode in nodes {
                    // The target will be determined at runtime based on the responder chain.
                    menuItemTitle = dataSource.mediumDescription(ofNode: thisNode)
                    menuItem = NSMenuItem(title: menuItemTitle, action: menuItemAction, keyEquivalent: "")
                    menuItem.representedObject = thisNode
                    menu.addItem(menuItem)
                }
            }
        }
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        // Optional delegate method per the NSMenuDelegate formal protocol. If the UI element represented by the clicked row has children, this method is triggered when the menu item is highlighted. It calls setSubmenu(_:for:) to set the submenu that was created and associated with the menu item in the menuNeedsUpdate(_:) delegate method as the menu item's submenu. This triggers the menuNeedsUpdate(_:) delegate method for the second time, which configures the submenu, adding menu items enabling the user to choose child elements. The contextual menu does not go deeper than the second level.
        
        // Proceed if a menu item is being highlighted. Apple's NSMenuDelegate documentation: "If item is nil, it means that all items in the menu are about to be unhighlighted."
        guard item != nil else { return }
        
        if menu.supermenu == nil {
            // Menu is the root menu.
            
            // Update the data model if the user clicked a row that was not already selected. This must be done because the menu item will be titled using information in the data model. The data model will be restored if the user dismisses the contextual menu without selecting a child UI element.
            let affectedLevel = listPathControl.pathItems.count - 1
            let affectedIndex = elementList.clickedRow
            if affectedIndex != elementList.selectedRow {
                ElementDataModel.sharedInstance.updateDataModelForCurrentElementAt(level: affectedLevel, index: affectedIndex)
            }
            
            // Set the root menu's submenu. It was created and associated with the menu item in the menuNeedsUpdate(_:) delegate method to display the submenu indicator triangle. Setting the submenu here triggers the submenu's menuNeedsUpdate(_:) delegate method a second time, passing the submenu as the new menu, which has the root level menu as its supermenu. Menu items for the child UI elements of the UI element represented by the clicked row will be added in the menuNeedsUpdate(_:) delegate method's second if branch.
            if let submenu = item!.submenu {
                submenu.delegate = self
                menu.setSubmenu(submenu, for: item!)
            }
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        // Optional delegate method per the NSMenuDelegate formal protocol. It is triggered after the menuNeedsUpdate(_:) delegate method. Apple's NSMenuDelegate documentation: "Don’t modify the structure of the menu or the menu items during this method."
        // This delegate method is triggered once before the root level of the contextual menu will open and once again before the submenu will open. When the root level will open, the menuNeedsUpdate(_:) delegate method has not yet been triggered to update the data model for the clicked row. This is therefore an appropriate place to save the current element index path of the data model. The data model will be restored in the menuDidClose(_:) delegate method using the saved index path if the user dismisses the menu without choosing a menu item. The current element index path is saved here. It will be set to nil in the selectElementWithContextMenu(_:) action method connected to each menu item in the menu if the user does choose a menu item, or in the menuDidClose(_:) delegate method if the user dismisses the menu without selecting a new UI element and the data model is therefore restored from the cache.
        
        if menu.supermenu == nil {
            // Menu is the root menu. Save the current element index path in case the user does not choose a menu item in the contextual menu and the data model therefore will have to be restored to its previous contents. The current element index path is saved here but will be reset to nil if the user does select an element.
            let dataSource = ElementDataModel.sharedInstance
            dataSource.saveCurrentElementIndexPath()
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // Optional delegate method per the NSMenuDelegate formal protocol. Apple's NSMenuDelegate documentation: "Don’t modify the structure of the menu or the menu items during this method." Clearing the menu here nevertheless does not cause a problem. This method clears the default menu of all menu items so it can be reused.
        // After the root menu closes, the data model will be restored using the saved current element index path if the user dismissed the menu without choosing a menu item. The current element index path was saved in the menuWillOpen(_:) delegate method. It will be set to nil in the selectElementWithContextMenu(_:) action method connected to each menu item in the contextual menu if the user does choose a menu item, or here if the user dismissed the contextual menu, thus requiring the data model to be restored.
        // Time travel is the only way to determine whether the user chose a menu item in the contextual menu or instead dismissed it. This is because, if the user selected a UI element by choosing a menu item, the selectElementWithContextMenu(_:) action method connected to the menu item will be called only after the menu closes and this delegate method is triggered. Furthermore, there is no Cocoa method disclosing whether the user dismissed a menu without choosing a menu item, and by the nature of reality the absence of a call to the action method cannot be reported by the action method itself. This delegate method therefore calls NSObject perform(_:with:afterDelay:) to call the menuWasDismissed() @objc helper method in a future iteration of the run loop, after a call to selectElementWithContextMenu(_:) -- if there will be such a call -- will have had time to execute and reset the saved current element index path to nil.

        if menu.supermenu == nil {
            // Menu is the root menu.
            
            // Clear the menu for reuse
            menu.items = []
            
            // Restore the data model.
            let currentElementView = MasterSplitItemViewController.sharedInstance.currentElementView()
            currentElementView.window?.makeFirstResponder(currentElementView)
            perform(#selector(menuWasDismissed), with: nil, afterDelay: 0.0) // 0.0 delays to the next iteration of the run loop
        }
    }
    
    @objc func menuWasDismissed() {
        // Performed by the menuDidClose(_:) delegate method after delaying to the next iteration of the run loop to give the selectElementWithContextMenu(_:) action method time to set the saved current element index path to nil if the user chose a menu item. If the user instead dismissed the contextual menu, the saved current element index path will be used by this method to restore the data model as it existed before the user clicked a row in the list view to open the contextual menu.
        let dataSource = ElementDataModel.sharedInstance
        // Restore the data model using the saved current element index path if the user did not choose a menu item in the contextual menu.
        dataSource.restoreCurrentElementIndexPath()
    }
    
}
