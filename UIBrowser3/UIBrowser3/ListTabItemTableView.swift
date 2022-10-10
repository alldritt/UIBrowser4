//
//  ListTabItemTableView.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2018-11-23.
//  Copyright © 2018-2020 PFiddlesoft. All rights reserved.
//
//  Version 3.0.0
//

import Cocoa

class ListTabItemTableView: NSTableView {
    
    override class var defaultMenu: NSMenu? {
        // Override type property per NSView creates the list view's contextual menu. Apple's NSView technical reference: this override should "return the default pop-up menu for instances of the receiving class." Apple's Application Menu and Pop-up List Programming Topics: "Override the defaultMenu class method of NSView to create and return a menu that’s common to all instances of your subclass. This default menu is also accessible via the NSResponder menu method unless some other NSMenu object has been associated with the view." Note that defaultMenu and menu are now properties, not methods.
        // When the user Control-clicks or right-clicks a row in the list view, UI Browser's override of NSView menu(for:) obtains the contextual menu by calling super.menu(for:) before popping it up. The first time the contextual menu is popped up, the NSResponder menu property has not yet been set, and the call to super therefore accesses the NSView defaultMenu property. The defaultMenu property is accessed only once while UI Browser is running; thereafter, the menu created in defaultMenu is reused repeatedly in successive calls to menu(for:) because the list view does not reset the menu property. As a result, each time the menu pops up it would normally display the same menu items in the same state as when it was last dismissed. This would be appropriate behavior for a typical contextual menu, but UI Browser uses the contextual menu only to navigate the clicked row. The menu must therefore be cleared in the menuDidClose(_:) delegate method before UI Browser reuses it for a new contextual menu to navigate another row.
        return NSMenu()
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        // Override method per NSView pops up a contextual menu when the user Control-clicks or right-clicks a row in the list view. It is limited here to popping the menu up only if the click was on a row, because UI Browser has nothing useful to do if the user clicks in an empty part of the table. It disallows menu plug-ins because it is used solely to navigate the table. It calls super.menu(for:), which returns the NSResponder menu property, creating the menu on the first call by accessing the override of the NSView defaultMenu property; it then creates a single menu item and adds it as the contextual menu's only submenu; and it finally programmatically pops the menu up positioned over the clicked row. It obtains the click location used to position the menu from the event parameter. It displays an emphasis border around the clicked row, but the table's current selection is not changed unless and until the user chooses a new child element using the contextual menu. It then returns nil because it has already popped the menu up programmatically. The nil return value prevents the system from popping the menu up again.
        // Before it pops up, the contextual menu is further configured and displayed using NSTableViewDelegate methods implemented in the list view's delegate, ListTabItemViewController. The NSTableView clickedRow property will be valid when used in the delegate methods. See Michael Tsai's comment at https://stackoverflow.com/questions/12494489/nstableview-right-clicked-row-index: "According to the 10.5 release notes (developer.apple.com/library/content/releasenotes/AppKit/…): “The key thing to note is that clickedRow and clickedColumn will now both be valid when a contextual menu is popped up. … The clickedRow and clickedColumn properties will still be valid when the action is sent from the NSMenuItem.”. I found that this does work if the table’s menu outlet is set and if you override -menuForEvent: you have to call super. – Michael Tsai Jul 4 '17 at 15:20." It is therefore no longer necessary to obtain the clickedRow value by popping up the contextual menu using the list view's action method -- using the action method is undesirable because a contextual menu should pop up on a mouse down event, as here, but the action method is not sent until mouse up.
        
        // Proceed only if the user clicked a row in the table and the table's defaultMenu property successfully created the menu.
        let clickedRow = row(at: convert(event.locationInWindow, from: nil))
        guard clickedRow >= 0,
            let menu = super.menu(for: event)
            else { return nil }
        
        // Display an emphasis border around the clicked row.
        rowView(atRow: clickedRow, makeIfNecessary: false)?.isEmphasized = true
        
        // Configure the menu.
        menu.font = NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)
        menu.allowsContextMenuPlugIns = false
        menu.delegate = ListTabItemViewController.sharedInstance
        
        // Add the single root level menu item representing the clicked row. This must be done here because the menu will be popped up programmatically before this method returns.
        guard let title = (view(atColumn: 0, row: clickedRow, makeIfNecessary: false)?.subviews.last as? NSTextField)?.stringValue else { return nil }
        let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menu.addItem(menuItem)
        
        // Pop the menu up positioned over the clicked row. This triggers the menu's menuNeedsUpdate(_:) delegate method.
        let rowRect = rect(ofRow: clickedRow)
        let position = NSMakePoint(NSMinX(rowRect) - 17, NSMinY(rowRect) + 2)
        menu.popUp(positioning: menu.item(at: 0), at: position, in: self) // ignore return value
        
        // Prevent the system from popping the menu up a second time.
        return nil
    }
    
    // NSResponder override methods
    
    override func mouseDown(with event: NSEvent) {
        // NSResponder override method. This method performs its function only if the user clicks the mouse to select a new row; it does nothing if the click is not on a row or is on an already selected row and the click therefore does not select a new row. The NSTableViewDelegate formal protocol tableViewSelectionDidChange(_:) delegate method is triggered by the click immediately afterward under identical circumstances. This method sets the ListTabItemViewController isManualSelection flag to true before the tableViewSelectionDidChange(_:) delegate method is triggered, to signal the delegate method to update and display the user's selection of a new row using a mouse click.
        let clickedRow = row(at: convert(event.locationInWindow, from: nil))
        guard clickedRow >= 0, selectedRow >= 0 else { return }
        if clickedRow != selectedRow {
            ListTabItemViewController.sharedInstance.isManualSelection = true
        }
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        // NSResponder override method. It calls NSResponder interpretKeyEvents(_:) to cause the input manager to call the doCommand(by:) NSStandardKeyBindingResponding protocol method to send commands to the list view depending on which NSStandardKeyBindingResponding protocol methods are overridden here; namely, moveUp(_:) and moveDown(_:).
        interpretKeyEvents([event])
        super.keyDown(with: event)
    }
    
    // NSStandardKeyBindingResponding protocol methods

    override func moveUp(_ sender: Any?) {
        // NSStandardKeyBindingResponding protocol method is triggered by the user's press of the up arrow key in the list table view. Sender is nil. This method is triggered only if the arrow key press selects a new row; it is not triggered if the top row is already selected and the arrow key therefore does not select a new row. The NSTableViewDelegate formal protocol tableViewSelectionDidChange(_:) delegate method is triggered by the arrow key immediately afterward under identical circumstances. This method sets the ListTabItemViewController isManualSelection flag to true before the tableViewSelectionDidChange(_:) delegate method is triggered, to signal the delegate method to update and display the user's selection of a new row using an up arrow key press.
        ListTabItemViewController.sharedInstance.isManualSelection = true
    }
    
    override func moveDown(_ sender: Any?) {
        // NSStandardKeyBindingResponding protocol method is triggered by the user's press of the down arrow key in the list table view. Sender is nil. This method is triggered only if the arrow key press selects a new row; it is not triggered if the bottom row is already selected and the arrow key therefore does not select a new row. The NSTableViewDelegate formal protocol tableViewSelectionDidChange(_:) delegate method is triggered immediately afterward by the arrow key under identical circumstances. This method sets the ListTabItemViewController isManualSelection flag to true before the tableViewSelectionDidChange(_:) delegate method is triggered, to signal the delegate method to update and display the user's selection of a new row using a down arrow key press.
        ListTabItemViewController.sharedInstance.isManualSelection = true
    }
    
}
