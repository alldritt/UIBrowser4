//
//  OutlineTabItemOutlineView.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2018-12-12.
//  Copyright © 2018-2020 PFiddlesoft. All rights reserved.
//
//  Version 3.0.0
//

import Cocoa

class OutlineTabItemOutlineView: NSOutlineView {
    
    // NSOutlineView override methods
    
/*
    override func row(forItem item: Any?) -> Int {
        // Without this override or the alternative technique described next, the NSOutlineView version would always return -1 because of a bug reported at https://openradar.appspot.com/38734802. See https://stackoverflow.com/questions/41056547/using-a-swift-struct-in-an-nsoutlineview.
     // UI Browser uses the other way to fix this issue, without requiring an override method; namely, to build UI Browser under macOS Mojave 10.14 or later and make all Info items conform to the Equatable and Hashable protocols. See the NSOutlineView discussion under "API Changes" in https://developer.apple.com/documentation/appkit/appkit_release_notes_for_macos_10_14. Apple's macOS Mojave 10.14 AppKit Release Notes: "Swift value types provided as items to an NSOutlineView instance using methods such as insertItems(at:inParent:withAnimation:) need to be made both Equatable and Hashable. For more information, see Adopting Common Protocols. These conformances let NSOutlineView correctly compare items so that performance is optimal and methods like row(forItem:) can correctly find the stored item internally."
        if let itemNode = item as? ElementDataModel.ElementNodeInfo {
            let itemElement = ElementDataModel.sharedInstance.element(ofNode: itemNode)
            print("itemElement: \(itemElement.AXRole!) and \(String(describing: itemElement.AXTitle))")
            for thisRow in 0..<numberOfRows {
                print("ROW \(thisRow)")
                if let thisNode = self.item(atRow: thisRow) as? ElementDataModel.ElementNodeInfo {
                    let thisElement = ElementDataModel.sharedInstance.element(ofNode: thisNode)
                    print("thisElement: \(thisElement.AXRole!) and \(String(describing: thisElement.AXTitle))")
                    if thisElement.isEqual(to: itemElement) {
                        print("THISROW: \(thisRow)")
                        return thisRow
                    }
                }
            }
        }
        print("ABOUT TO RETURN -1")
        return -1
    }
*/
    
    // NSResponder override methods
    
    override func mouseDown(with event: NSEvent) {
        // NSResponder override method. This method is designed to perform its function only if the user clicks the mouse to select a new row; it does nothing if the click is not on a row or is on an already selected row and the click therefore does not select a new row. The NSOutlineViewDelegate formal protocol outlineViewSelectionDidChange(_:) delegate method is triggered by the click immediately afterward under identical circumstances. This method sets the OutlineTabItemViewController isManualSelection flag to true before the outlineViewSelectionDidChange(_:) delegate method is triggered, to signal the delegate method to update and display the user's selection of a new row using a mouse click. Note that a click on a row's expansion button does not trigger this method.
        let clickedRow = row(at: convert(event.locationInWindow, from: nil))
        guard clickedRow >= 0, selectedRow >= 0 else { return }
        if clickedRow != selectedRow {
            OutlineTabItemViewController.sharedInstance.isManualSelection = true
        }
        super.mouseDown(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        // NSResponder override method. It calls NSResponder interpretKeyEvents(_:) to cause the input manager to call the doCommand(by:) NSStandardKeyBindingResponding protocol method to send commands to the outline view depending on which NSStandardKeyBindingResponding protocol methods are overridden here; namely, moveUp(_:) and moveDown(_:).
        interpretKeyEvents([event])
        super.keyDown(with: event)
    }
    
    // NSStandardKeyBindingResponding protocol methods
    
    override func moveUp(_ sender: Any?) {
        // NSStandardKeyBindingResponding protocol method is triggered by the user's press of the up arrow key in the outline view. Sender is nil. This method is triggered only if the arrow key press selects a new row; it is not triggered if the top row is already selected and the arrow key therefore does not select a new row. The NSOutlineViewDelegate formal protocol outlineViewSelectionDidChange(_:) delegate method is triggered by the arrow key immediately afterward under identical circumstances. This method sets the OutlineTabItemViewController isManualSelection flag to true before the outlineViewSelectionDidChange(_:) delegate method is triggered, to signal the delegate method to update and display the user's selection of a new row using an up arrow key press.
        OutlineTabItemViewController.sharedInstance.isManualSelection = true
    }
    
    override func moveDown(_ sender: Any?) {
        // NSStandardKeyBindingResponding protocol method is triggered by the user's press of the down arrow key in the outline view. Sender is nil. This method is triggered only if the arrow key press selects a new row; it is not triggered if the bottom row is already selected and the arrow key therefore does not select a new row. The NSOutlineViewDelegate formal protocol outlineViewSelectionDidChange(_:) delegate method is triggered immediately afterward by the arrow key under identical circumstances. This method sets the OutlineTabItemViewController isManualSelection flag to true before the outlineViewSelectionDidChange(_:) delegate method is triggered, to signal the delegate method to update and display the user's selection of a new row using a down arrow key press.
        OutlineTabItemViewController.sharedInstance.isManualSelection = true
    }
    
}
