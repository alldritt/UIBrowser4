//
//  ElementPathControlManager.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2018-11-22.
//  Copyright © 2018-2020 PFiddlesoft. All rights reserved.
//
//  Version 3.0.0
//

import Cocoa

// TODO: Add previous and next buttons at the left end of the path control as in Xcode.
// TODO: Add a path control above the browser view.

/**
 The ElementPathControlManager.swift file implements the ElementPathControlManager class dedicated to managing the path control in UI Browser's Master tab item's browser, outline and list views. The path control in each view behaves identically. It allows the user to open an hierarchical pop-up menu on any tab item to select a UI element anywhere in the target application's accessibility hierarchy for display in the view.
 
 UI Browser's path control is modeled on Apple's Xcode jump bar, with one major difference. UI Browser's path control reflects the current accessibility hierarchy selection path of the target application, which may not extend all the way to a leaf element because the user may have selected a shallower UI element as the current element. UI Browser's individual path item pop-up menus are used to select any sibling or child element of the element represented by the clicked path item to any depth, while the Xcode jump bar menus only allow the user to choose the leaf element of any available path. This difference reflects the fact that every level of the UI Browser hierarchy contains a UI element with useful information, while only the leaf element represented by the Xcode jump bar is a code file containing useful information.
 
 When *Main.storyboard* is loaded at launch, the path control shows a single path item, the path control's placeholder, which is set to "No Target" in Main.storyboard, and the current element view is empty. When the user chooses a target, the path control replaces the placeholder and instead displays as the first path item what is known in the accessibility world as the "root application UI element" (or the sytem-wide element if that was the chosen target), and the element view displays the root application element (or the system-wide element). The path control's action method is popUpPathControlMenu(_:) implemented in each of the master tab items. If the target is a running application and the user clicks the first path item, the action method opens a pop-up menu on it showing the root application element and a submenu indicator triangle. When the user moves the mouse, the submenu opens with menu items representing all of the child elements. The user can choose one of the children in the popup menu, and the element view then displays all of the children with the chosen child selected; typically, these are the application's menu bar element and a window element for every open application window. If the user then clicks the second path item, the action method opens a new popup menu on it showing the children of the selected window or menu bar element. The menus are hierarchical, enabling the user to choose any UI element at any deeper level of the target application's accessibility hierarchy, and the path control extends to the full depth of the chosen element.
 
 The action method for every menu item in the pop-up menu is `selectElement(_:)` implemented in each of the master tab items. It is programatically connected as the action method for every menu item in the path control. It is called once initially when the user chooses a new target while the list view is selected. It is called repeatedly thereafter when the user selects an existing element in the path control. The action method updates UI Browser's display, adding the child elements of the selected element and other views, such as the tab view items showing actions, attributes and notifications of the selected element.
 
 The menu item for the clicked path item is positioned directly over the clicked path item. That menu item may have sibling menu items above and below it representing other UI elements at the same level of the accessibility hierarchy and, if it is not a leaf element, that menu item may have an associated submenu with one or more menu items representing child elements at the next level of the accessibility hiearchy. The pop-up menu is created, configured and opened in the popUpMenu(for:) method, which is called in each element view's popUpPathControlMenu(_:) action method, including an express call to the menuNeedsUpdate(_:) delegate method.

 The key architectural feature of the `selectElement(_:)` method is that it caches all elements of the selected element hierarchy and related information in the element data model when a new element is selected, thus making access to them later more efficient. Updating the data model also makes access possible even after the selected element is destroyed (for example, if a hot key is used to select a UI element in a palette that disappears when UI Browser is brought to the front). The update actually occurs piecemeal as the user highights menu items in the path control pop-up menu using the mouse or keyboard, in the menu(_:willHighlight:) delegate method. When the user lifts the mouse from the last highlighted menu item to finalize the selection, the data model is already updated.
*/

class ElementPathControlManager: NSObject, NSMenuDelegate {
    
    // MARK: - PROPERTIES
    
    // MARK: Path control
    
    /// The path item last clicked in the path control.
    var clickedPathItem: NSPathControlItem? // set in popUpPathControlMenu(_:) action method
    
    /// The index of the path item last clicked in the path control.
    var clickedPathItemIndex: Int = -1 // set in popUpPathControlMenu(_:) action method
    
    /// The data model's selected index path saved in the menuWillOpen(_:) delegate method when the user last clicked in the path control, to be restored in the menuDidClose(_:) delegate method if the user does not select a path item using the pop-up menu.
    var clickedPathControlIndexPath: NSIndexPath?
    
    // MARK: - VIEW MANAGEMENT
    
    func displayPathControl(_ control: NSPathControl) {
        // Configure the path control to display the current UI element path when the user switches to a different element view.
        let dataSource = ElementDataModel.sharedInstance
        if let currentElementIndexPath = dataSource.currentElementIndexPath {
            //print("OUTLINE ENTERING displayPathControl currentElementIndexPath: \(currentElementIndexPath)")
            var pathItems: [NSPathControlItem] = []
            for level in 0..<currentElementIndexPath.length {
                let index = currentElementIndexPath.index(atPosition: level)
                let newItem = NSPathControlItem()
                let stringAttributes = [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)]
                newItem.attributedTitle = NSAttributedString(string: dataSource.mediumDescription(ofNode: dataSource.nodeAt(level: level, index: index)), attributes: stringAttributes)
                pathItems.append(newItem)
            }
            control.pathItems = pathItems
        }
    }
    
    func clearPathControl(_ control: NSPathControl) {
        // Clear the path control when the user chooses No Target. This causes the path control to display its placeholder, which is set to "No Target" in Main.storyboard.
        control.pathItems = []
    }
    
    func updateTargetSelection(for pathControl: NSPathControl) {
        // Configure the path control to display the root application UI element or the SystemWide element when the user chooses a new target or refreshes the current target. Sets the first path item to the root application UI element, replacing the path control's placeholder, which is set to "No Target" in Main.storyboard. The clearView() method simply empties the path items array in order to display "No Target" again if the user chooses No Target.
        let dataSource = ElementDataModel.sharedInstance
        let rootItem = NSPathControlItem()
        let stringAttributes = [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)]
        rootItem.attributedTitle = NSAttributedString(string: dataSource.mediumDescription(ofNode: dataSource.nodeAt(level: 0, index: 0)), attributes: stringAttributes) // briefDescription(ofNode:index:) returns an NSString
        pathControl.pathItems = [rootItem]
    }
    
    func updatePopUpMenuSelection(for pathControl: NSPathControl, with selectedNode: ElementDataModel.ElementNodeInfo) {
        // Configure the path control to display the current UI element path when the user selects a UI element in the path control's pop-up menu. Get information about the sibling or child UI element selected by the user, including its index path, level and index, from the chosen menu item's represented object. The represented object is a node in the data model with the opaque type ElementNodeInfo, with public properties and methods to access information about it. It was added to the menu item in the menuNeedsUpdate(_:) delegate method when the menu item was created and configured.
        let dataSource = ElementDataModel.sharedInstance
        let selectedIndexPath = dataSource.indexPath(ofNode: selectedNode)
        let selectedLevel = selectedIndexPath.length - 1
        
        // Update the path control by reusing the levels of the existing path control from the root application path item through the parent of the clicked path item and appending new path items corresponding to the selection path of the pop-up menu.
        var pathItems = Array(pathControl.pathItems.prefix(through: clickedPathItemIndex - 1))
        for level in clickedPathItemIndex...selectedLevel {
            let index = selectedIndexPath.index(atPosition: level)
            let newItem = NSPathControlItem()
            let stringAttributes = [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)]
            newItem.attributedTitle = NSAttributedString(string: dataSource.mediumDescription(ofNode: dataSource.nodeAt(level: level, index: index)), attributes: stringAttributes)
            pathItems.append(newItem)
        }
        pathControl.pathItems = pathItems
    }
    
    func updateContextMenuSelection(for pathControl: NSPathControl, atChild childIndex: Int, parent parentIndex: Int) {
        // Configure the path control to display the new UI element path after the user selects a sibling UI element and one of its child elements in the list view using the contextual menu. Get information about the sibling and child elements selected by the user, including the child element's index path, level and index, from the data model. The data model has already been updated, in the selectElementWithContextMenu(_:) action method, to reflect the user's selection of a sibling and child in the list view. The path control needs to be updated here only to reflect the user's selection of a sibling and child row in the list view at the new level.
        let dataSource = ElementDataModel.sharedInstance
        let currentIndexPath = dataSource.currentElementIndexPath!
        let selectedLevel = currentIndexPath.length - 1
        
        // Update the path control by reusing the existing path control, replacing the sibling path item with the selected parent element, and appending a new path item corresponding to the selected child element.
        var pathItems = pathControl.pathItems
        let stringAttributes = [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)]
        let parentItem = pathItems[selectedLevel - 1]
        parentItem.attributedTitle = NSAttributedString(string: dataSource.mediumDescription(ofNode: dataSource.nodeAt(level: selectedLevel - 1, index: parentIndex)), attributes: stringAttributes)
        let newItem = NSPathControlItem()
        newItem.attributedTitle = NSAttributedString(string: dataSource.mediumDescription(ofNode: dataSource.nodeAt(level: selectedLevel, index: childIndex)), attributes: stringAttributes)
        pathItems[selectedLevel - 1] = parentItem
        pathItems.append(newItem)
        pathControl.pathItems = pathItems
    }
        
    // MARK: - ACTION METHODS AND SUPPORT
    
    func popUpMenu(for pathControl: NSPathControl) {
        // Opens a pop-up menu positioned over the clicked path item to enable the user to select another UI Element for display in UI Browser's current element view. The pop-up menu is hierarchical and enables the user to select any UI element at any level of the target application's accessibility hierarchy starting at the level of the clicked path item.
        // This method first sets the clickedPathItem and clickedPathItemIndex instance properties using the NSPathControl clickedPathItem computed property. It then creates the pop-up menu and makes an express call to the menuNeedsUpdate(_:) delegate method to configure it, adding menu items representing the UI elements in the level of the element data model represented by the clicked path item. These menu items enable the user to select siblings of the UI element represented by the clicked path item, using the saved clickedPathItemIndex value to associate the level of the clicked path item and the chosen menu item with the level of the accessibility hierarchy in the data model. It then gets the current position of the clicked path item within the bounds of the path control and calls the NSMenu popUp(positioning:at:in:) method to pop the menu up and position the menu item representing the clicked path item directly over the clicked path item. Popping the menu up triggers the menuNeedsUpdate(_:) delegate method, but it is designed to do nothing at this point because the top-level menu was already configured in the express call. When the user moves the mouse over any of the menu items, it triggers the menu(_:willHighlight:) delegate method, which, if the menu item represents a UI element having children, associates a submenu created in the menuNeedsUpdate(_:) delegate method with the menu item. Setting the submenu triggers the menuNeedsUpdate(_:) delegate method again, which then adds the submenu's child menu items to the submenu. The menu(_:willHighlight:) and menuNeedsUpdate(_:) delegate methods fire again every time the user moves the mouse over another menu item representing a UI element having children, creating a hierarchical menu of any depth to navigate the accessibility hierarchy starting at the level of the clicked path item. When the user eventually releases the mouse button over a menu item to choose it, the selectElement(_:) action method implemented in each of the master tab items is sent to update the element view and the window.
        
        // Access the NSPathControl clickedPathItem property and save the clicked path item and its index as instance properties for use by the delegate methods. According to the NSPathControl header file, "[b]oth an action and doubleAction can be set for the control. To find out what path item was clicked upon in the action, you can access the 'clickedPathItem'.... The 'clickedPathItem' is only valid when the action is being sent. It will also be valid when the keyboard is used to invoke the action." According to the header comment for the clickedPathItem property: it "is generally only valid while the action or doubleAction is being sent."
        guard let clickedItem = pathControl.clickedPathItem else { return }
        clickedPathItem = clickedItem
        clickedPathItemIndex = pathControl.pathItems.firstIndex(where: { $0.attributedTitle.string == clickedItem.attributedTitle.string }) ?? -1
 
        // Create and configure the pop-up menu and expressly call the menuNeedsUpdate(_:) delegate method to add menu items for all of the UI elements in the data model at the level of the clicked path item, including the UI element represented by the clicked path item. Adding the menu items cannot be delayed until the menuNeedsUpdate(_:) delegate method is triggered automatically, because the menu items are needed here to position the appropriate menu item before the menu is popped up. The delegate method is designed to recognize that the menu has already been configured when it is triggered again automatically.
        let menu = NSMenu(title: "")
        menu.font = NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)
        menu.allowsContextMenuPlugIns = false
        // menu.showsStateColumn = false // if uncommented, this line would suppress the checkmark
        menu.delegate = self
        menuNeedsUpdate(menu) // expressly call delegate method
        
        // Position the appropriate menu item over the clicked path item. The state of the menu item representing the clicked path item was set to On when it was created in the express call to the menuNeedsUpdate(_:) delegate method, as a marker identifying it as the menu item to be positioned over the clicked path item when the menu is popped up.
        guard
            let index = menu.items.firstIndex(where: { $0.state == .on }),
            let menuItem = menu.item(at: index),
            let pathCell = pathControl.cell as? NSPathCell
            else { return }
        let pathComponentCell = pathCell.pathComponentCells[clickedPathItemIndex]
        let rect = pathCell.rect(of: pathComponentCell, withFrame: pathControl.bounds, in: pathControl)
        let position = NSMakePoint(NSMinX(rect) - 17, NSMinY(rect) + 2)
        
        // Pop the menu up. This triggers the menu's menuNeedsUpdate(_:) delegate method, but it is designed to do nothing when the menu is popped up because it was already configured by the express call, above. The delegate method will be triggered again later to configure submenus after they are added in the menu(_:willHighlight) delegate method.
        menu.popUp(positioning: menuItem, at: position, in: pathControl) // ignore return value
    }
    
    // MARK: - DELEGATE METHODS
    
    // MARK: NSMenuDelegate
    // UI Browser's list view uses the list path control and its pop-up menu as the primary means to navigate the data model. These NSMenuDelegate methods for the pop-up menu update the data model, the path control, the list view and the UI Browser user interface as the user highlights menu items using the mouse or the keyboard before choosing one. See the popUpPathControlMenu(_:) action method for an overview.
    // After the user clicks a path item at any level of the list path control and the pop-up menu is opened, the user may choose a sibling menu item at that level or a child menu item at any deeper level of the hierarchy. If the user chooses a sibling menu item, the clicked path item and any path items following it are removed, and a new path item representing the newly selected sibling UI element is appended. If the user chooses a child menu item at any deeper level of the accessibility hierarchy, the clicked path item and any path items following it are removed, a new path item representing the new sibling UI element is appended, and new path items representing the path to the selected child element are appended. The list view is then populated with the selected element and its siblings, and the selected element in the list is highlighted.

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Optional delegate method per the NSMenuDelegate formal protocol. Apple's NSMenuDelegate documentation: "Using this method, the delegate can change the menu by adding, removing, or modifying menu items.... Menu item validation occurs after this method is called."
        // This delegate method is initially called expressly in the list path control's popUpPathControlMenu(_:) action method when the user clicks a path item, before the action method calls NSMenu popUp(positioning:at:in:) to pop the menu up. It configures the top-level or root menu, adding menu items enabling the user to choose sibling elements. It is designed to do nothing the next time it is called, when the root menu pops up and triggers it automatically, because the menu is no longer empty. Thereafter, every time the user moves the mouse over a menu item, the menu(_:willHighlight:) delegate method is triggered. If that menu item represents a UI element having children, that delegate method creates a submenu and calls NSMenu setSubmenu(_:for:) to set it as the menu item's submenu, which triggers this menuNeedsUpdate(_:) delegate method again. This method then configures the submenu, adding menu items representing UI elements at the correpsonding level of the datasource, enabling the user to choose child elements.
        // This delegate method is called before the menuWillOpen(_:) delegate method.
        
        // The root menu is configured in an express call to this delegate method in the popUpPathControlMenu(_:) action method, and the root menu does not need to be reconfigured a second time when the action method calls the NSMenu popUp(positioning:at:in:) method to pop up the root menu. Submenus, on the other hand, are always empty at this point and are therefore always configured.
        guard menu.items.isEmpty else { return }
        
        // Get the affected level of the data model based on the current list path control and the pop-up menu. The affected level is the level represented by the path item that the user clicked adjusted by the level of the menu item the user just highlighted using the mouse or keyboard. See the menu(_:willHighlight:) delegate method for more information.
        // The level property of the menu is an extension on NSMenu implemented below. The level is 0 for the top-level menu.
        let affectedLevel = clickedPathItemIndex + menu.level
        
        // Add menu items to the current menu for all UI elements at the affected level. These menu items will not be displayed until later, when the user highlights the menu item using the mouse or keyboard, triggering the menu(_:willHighlight:) delegate method.
        let dataSource = ElementDataModel.sharedInstance
        var menuItem: NSMenuItem
        var menuItemTitle: String
        let menuItemAction = MasterSplitItemViewController.sharedInstance.currentTabItemSelectElementAction()
        if let nodes = dataSource.nodesAt(level: affectedLevel) {
            for i in nodes.indices {
                // No target is specified for the menu item's action, so the target is determined at runtime based on the responder chain.
                let thisNode = nodes[i]
                menuItemTitle = dataSource.mediumDescription(ofNode: thisNode)
                menuItem = NSMenuItem(title: menuItemTitle, action: menuItemAction, keyEquivalent: "")
                menuItem.representedObject = thisNode
                
                if dataSource.childCount(ofNode: thisNode) > 0 {
                    // Create a submenu and associate it with this menu item, if this menu item represents a UI element that has children. The existence of an associated submenu will cause this menu item to show a submenu indicator triangle when it is displayed, even though the new submenu's menu items have not yet been added to it.
                    // This menu item will be displayed with its indicator triangle as soon as this call to the menuNeedsUpdate(_:) delegate method completes, either as a result of the earlier call to the NSMenu popUp(positioning:at:in:) method in the popUpPathControlMenu(_:) action method, or as a result of the earlier call to the NSMenu setSubmenu(_:for:) method in the menu(_:willHighlight:) delegate method, one of which triggered this delegate method before displaying the menu item. The child menu items to be associated with this menu item's new submenu will be displayed only later, when the user highlights this menu item using the mouse or the keyboard, triggering the menu(_:willHighlight:) delegate method. That delegate method's call to the NSMenu setSubmenu(_:for:) method will trigger this menuNeedsUpdate(_:) delegate method again, which this time will add the child menu items to the submenu. The child menu items will be displayed as soon as this delegate method completes, as a result of the earlier call to the NSMenu setSubmenu(_:for:) method in the menu(_:willHighlight:) delegate method. This process will repeat as long as the user highlights new menu items with children at deeper levels of the accessibility hierarchy, until the user chooses on of the highlighted menu items.
                    menuItem.submenu = NSMenu(title: menuItemTitle) // does not trigger a delegate method
                }
                if menuItemTitle == clickedPathItem!.title {
                    // Set the state of the menu item representing the clicked path item to On. This will be used as a marker in the popUpPathControlMenu(_:) action method to identify the menu item to be positioned over the clicked path item.
                    menuItem.state = NSControl.StateValue.on
                }
                menu.addItem(menuItem)
            }
        }
    }
    
    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        // Optional delegate method per the NSMenuDelegate formal protocol. It is triggered every time the user opens the root pop-up menu by clicking the list path control or moves the mouse over a menu item at any level of the menu hierarchy, highlighting the menu item. If the menu item represents a UI element having children, this method calls setSubmenu(_:for:) to add the submenu that was created in the menuNeedsUpdate(_:) delegate method to the menu item. This triggers the menuNeedsUpdate(_:) delegate method, which configures the submenu, adding menu items enabling the user to choose child elements. For submenu levels deeper than the clicked path item, the data model is updated to add information that is needed to configure the submenu.
        
        // Proceed if a menu item is being highlighted. Apple's NSMenuDelegate documentation: "If item is nil, it means that all items in the menu are about to be unhighlighted."
        guard item != nil else { return }
        
        // Update the data model to correspond to the path to be displayed in the path control and its pop-up menu. This must be done every time a new menu is popped up or a new submenu is created, because their menu items will be titled using information in the data model. The root application level of the data model can always be reused because the pop-up menu cannot change it; it can only be changed using the Target menu. Deeper levels of the data model may also be reused because the pop-up menu cannot change levels above that represented by the clicked path item. This method therefore updates the data model at the affected level. The affected level is the level represented by the path item that the user clicked adjusted to include the level of the menu item just highlighted as the user navigated the menu, and any deeper levels already in the data model are cleared. The data model will be restored if the user dismisses the contextual menu without selecting a child UI element.
        // The level property of the menu item is an extension on NSMenuItem implemented below. The level is 0 for the root menu item.
        let dataSource = ElementDataModel.sharedInstance
        let affectedLevel = clickedPathItemIndex + item!.level
        let affectedIndex = (menu.index(of: item!))
        dataSource.updateDataModelForCurrentElementAt(level: affectedLevel, index: affectedIndex)
        
        if dataSource.childCount(ofNode: item!.representedObject as! ElementDataModel.ElementNodeInfo) > 0 {
            // If the highlighted menu item represents a UI element that has children, set it as a submenu.
            
            // Set the submenu. It was created and associated with the menu item in the menuNeedsUpdate(_:) delegate method to display the submenu indicator triangle. Setting the submenu here triggers the submenu's menuNeedsUpdate(_:) delegate method again, passing the submenu as the new menu. Menu items for all child UI elements of the UI element represented by the highlighted menu item will be added in the menuNeedsUpdate(_:) delegate method.
            if let submenu = item!.submenu {
                submenu.delegate = self
                menu.setSubmenu(submenu, for: item!)
            }
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        // Optional delegate method per the NSMenuDelegate formal protocol. It is triggered after the menuNeedsUpdate(_:) delegate method. Apple's NSMenuDelegate documentation: "Don’t modify the structure of the menu or the menu items during this method."
        // This delegate method is triggered once before the root level of the path control pop-up menu will open and once again before each submenu in its menu hierarchy will open. When the root level will open, the menuNeedsUpdate(_:) delegate method has already been triggered once to configure the menu for the clicked path item, but the menu(_:willHighlight:) delegate method has not yet been triggered to update the data model for the clicked path item. This is therefore an appropriate place to cache the current index path of the data model here. The data model will be restored in the menuDidClose(_:) delegate method using the cached index path if the user dismisses the menu without choosing a menu item. The current element index path is saved here. It will be set to nil in the selectElement(_:) action method connected to each menu item in the pop-up menu if the user does choose a menu item, or in the menuDidClose(_:) delegate method if the user dismisses the pop-up menu without selecting a new UI element and the data model is therefore restored.
        
        if menu.supermenu == nil {
            // Menu is the root menu. Save the current element index path in case the user does not choose a menu item in the path control pop-up menu and the data model therefore will have to be restored to its previous contents. The current element index path is saved here but will be reset to nil if the user does select an element.
            let dataSource = ElementDataModel.sharedInstance
            dataSource.saveCurrentElementIndexPath()
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // Optional delegate method per the NSMenuDelegate formal protocol. Apple's NSMenuDelegate documentation: "Don’t modify the structure of the menu or the menu items during this method."
        // This delegate method is triggered once after each submenu in the path control pop-up menu hierarchy closes and once again after the root level menu closes. After the root menu closes, the data model will be restored using the saved current element index path if the user dismissed the menu without choosing a menu item. The saved current element index path was saved in the menuWillOpen(_:) delegate method. It will be set to nil in the selectElement(_:) action method connected to each menu item in the pop-up menu if the user does choose a menu item, or here if the user dismissed the pop-up menu, thus requiring the data model to be restored.
        // Time travel is the only way to determine whether the user chose a menu item in the pop-up menu or instead dismissed it. This is because, if the user selected a UI element by choosing a menu item, the selectElement(_:) action method connected to the menu item will be called only after the pop-up menu closes and this delegate method is triggered. Furthermore, there is no Cocoa method disclosing whether the user dismissed a menu without choosing a menu item, and by the nature of reality the absence of a call to the action method cannot be reported by the action method itself. This delegate method therefore calls NSObject perform(_:with:afterDelay:) to call the menuWasDismissed() @objc helper method in a future iteration of the run loop, after a call to selectElement(_:) -- if there will be such a call -- will have had time to execute and reset the saved current element index path to nil.
        
        if menu.supermenu == nil {
            // Menu is the root menu.
            let currentElementView = MasterSplitItemViewController.sharedInstance.currentElementView()
            currentElementView.window?.makeFirstResponder(currentElementView)
            perform(#selector(menuWasDismissed), with: nil, afterDelay: 0.0) // 0.0 delays to the next iteration of the run loop
        }
    }
    
    @objc func menuWasDismissed() {
        // Performed by the menuDidClose(_:) delegate method after delaying to the next iteration of the run loop to give the selectElement(_:) action method time to set the saved current element index path to nil if the user chose a menu item. If the user instead dismissed the pop-up menu, the saved current element index path will be used to restore the data model as it existed before the user clicked the path control to open the pop-up menu.
        let dataSource = ElementDataModel.sharedInstance
        // Restore the data model using the saved current element index path if the user did not choose a menu item in the path control pop-up menu.
        dataSource.restoreCurrentElementIndexPath()
    }
    
}

// MARK: - Extensions on NSMenu and NSMenuItem

extension NSMenu {
    // The level property returns the depth of this menu in the linked list of menus in an hierarchical menu. According to Apple's documentation for the NSMenu supermenu property, the supermenu is "the parent menu that contains the menu as a submenu. If the menu has no parent menu, then the value of this property is nil." Note that the root menu is untitled in a pop-up menu.
    public var level: Int {
        var menu = self
        var level = 0
        while let parent = menu.supermenu {
            menu = parent
            level += 1
        }
        return level
    }
}

extension NSMenuItem {
    // The level property returns the depth of this menu item in the linked list of menu items in an hierarchical menu. According to Apple's documentation for the NSMenuItem parent property, the parent is the "menu item whose submenu contains the receiver."
    public var level: Int {
        var menuItem = self
        var level = 0
        while let parent = menuItem.parent {
            menuItem = parent
            level += 1
        }
        return level
    }
}
