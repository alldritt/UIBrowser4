//
//  MainSplitViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// MainSplitViewController receives the embed segue triggered by MainContentViewController in Main.storyboard and is therefore instantiated at application launch. It automatically calls loadView() to instantiate and load the main window content view's main split view. MainSplitViewController triggers two split items relationship segues, connected to MasterSplitItemViewController (the top pane) and DetailSplitItemViewController (the collapsible bottom pane), respectively, in Main.storyboard. The default holding priority for split view items is NSLayoutPriorityDefaultLow (250.0), but the master (top) split view item priority is set lower, to 249.0, in Main.storyboard, so that resizing the window causes the master pane to resize in preference to the detail (bottom) pane. The height constraints of the container views for both split view items are set to greater-than-or-equal-to 125.0 using constraints in Main.storyboard, which, in combination with other constraints, gives a minimum height to the main window. The User Can Collapse setting of the detail split view item is set in Main.storyboard, so that dragging the divider to half of the minimum height causes it to collapse.

// Apple's documentation for NSSplitView and related classes is inadequate. The header file comments and the OS X Yosemite 10.10 and OS X El Capitan 10.11 release notes are the best sources of information about usage.
// NSSplitViewController is a container view controller designed to manage almost all standard behaviors of a split view automatically, and Apple warns developers not to change most of its properties, such as delegate and holding priorities. Exceptions include the vertical, autosaveName and divider properties of NSSplitView. Use of Auto Layout is required to control the layout of the child views and the animations of collapses and reveals, and animation can be handled by a proxy animator. Special behaviors for sidebars (source lists) and content lists can be achieved simply by setting an NSSplitViewItem behavior property. Several of the split view controller's split view properties can be set in Interface Builder, as can some properties of each of its split view items.
// NSSplitViewController creates its split view object automatically and its child views lazily. A custom split view object can be provided only by setting the splitView property before self.viewLoaded is true.
// Standard behavior for a split view (other than a source list or content list) is to collapse a split view item by setting its isCollapsed property directly; for example, by using a button. If the split view item's canCollapse property is set, as it is here in Main.storyboard, dragging the divider to an edge or to the value set for minimumThickness also collapses it and sets its isCollapsed property accordingly. Double-clicking the divider does not collapse a split view item in macOS El Capitan 10.11 or later, contrary to the documentation. A button can be bound to the isCollapsed property to collapse and reveal a split view, and a suitable bound detail button's state can change automatically when the split view is collapsed and revealed by dragging.
// NSSplitViewController declares its conformance to the NSSplitViewDelegate protocol and automatically serves as the delegate of its managed NSSplitView object, so declaring conformance here or in Main.storyboard would be redundant. In fact, the macOS High Sierra 10.13 AppKit Release Notes specifically state with respect to a "NSWindow, NSTabView, or NSSplitView managed by a NSWindowController, NSTabViewController, or NSSplitViewController respectively": "When building using Xcode 9 or later, Xcode will now automatically set the delegate outlet on these objects to their owning controllers." NSSplitViewDelegate is declared in NSSplitView.h. NSSplitViewController itself implements five of the NSDelegateProtocol delegate methods. It is not necessary to implement or override any of the delegate methods to achieve standard behavior, and built-in NSSplitViewController and NSplitViewItem properties and methods should be used in preference to similar delegate methods where possible. Some delegate methods must not be used because they conflict with and invalidate Auto Layout. Do not call NSSplitView methods on the delegate property; use the splitView property instead. The view property does not necessarily refer to the same object as the splitView property, so always use the splitView property.
//  See MasterSplitItemViewController and DetailSplitItemViewController for additional information.

import Cocoa

class MainSplitViewController: NSSplitViewController {

    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK: - DELEGATE METHODS AND HELPERS
    
    // MARK: NSSplitViewDelegate Protocol Support
    // NSSplitViewController conforms to the NSSplitViewDelegate protocol and its split view connects its delegate outlet, so it would be redundant to declare conformance or connect the delegate in the MainSplitViewController scene of Main.storyboard.
    
    override func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
        // Delegate method per NSSplitViewDelegate formal protocol. Makes the effective rect of the divider extend 5.0 points above and below its position to show the drag cursor even if the pointer is not positioned directly over the divider. This helps the user to grab the default thin divider in order to drag it, and it is necessary to enable the user to drag a collapsed thin divider from the edge of the split view. This assumes a horizontal split view with two subviews, top and bottom, and a single divider.
        if dividerIndex == 0 {
            return NSMakeRect(0.0, splitView.subviews[0].bounds.size.height - 5.0, splitView.bounds.size.width, 10.0)
        } else {
            return super.splitView(splitView, additionalEffectiveRectOfDividerAt: dividerIndex)
        }
    }
    
/* This method is not needed because the detail split view item's User Can Collapse setting is set in Main.storyboard's Main Split View Controller Scene.
    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        // Delegate method per NSSplitViewDelegate formal protocol.
        return subview == splitView.subviews[1]
    }
*/
    
/**
     Collapses the detail split view item when the user double-clicks the divider in OS X Yosemite 10.10 or earlier.
     
     This NSSplitViewDelegate delegate method is not called in macOS El Capitan 10.11 or later. This is not documented by Apple, but it is widely reported on developer forums and mailing lists.
 */
    override func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        // Delegate method per NSSplitViewDelegate formal protocol.
        return subview == splitView.subviews[1]
    }

}
