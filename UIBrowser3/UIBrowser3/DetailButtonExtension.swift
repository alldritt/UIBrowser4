//
//  DetailButtonExtension.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-11-22.
//  Copyright © 2017-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

import Cocoa

/**
 The DetailButtonExtension.swift file implements an extension on MainWindowController dedicated to the window's Detail button, a disclosure button that expands and collapses the detail split item.
 */
extension MainWindowController {
    
    // MARK: - ACTION METHODS

    /**
     Expands and collapses the detail split item when the user clicks the Detail button, with animation.
     
     - note: There is no equivalent UI Browser 2 method.

     - parameter sender: The Detail button that sent the action.
     */

     @IBAction func toggleDetailSplitItem(_ sender: NSButton) {
        // Action method connected from the Detail button to First Responder in Main.storyboard.
        // The Detail button is a Disclosure Button, not a Disclosure Triangle. Per Apple's Human Interface Guidelines, "[t]he chevron points down when the functionality is hidden and up when the functionality is visible. Clicking the disclosure button toggles between these two states, and the parent view expands or collapses accordingly to accommodate the available content."
        
        // Uses an animation proxy.
        let splitViewItemAnimator = mainContentViewController!.detailSplitViewItem.animator()
        splitViewItemAnimator.isCollapsed = (sender.state == NSControl.StateValue.off) ? true : false
        
    }
    
    
    // MARK: - MISCELLANEOUS METHODS
    
    // TODO: Reimplement this if decide to use my custom Detail buttom images.
    // TODO: Update this for Mojave multiple colors.
    /*
    func setDetailButtonColor() {
        // Set the color of the Detail button to match the current system NSControlTint set in the System Preferences General pane's Appearance setting. See https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/DrawColor/Tasks/SystemTintAware.html. This method is called in the MainContentViewController.systemTintDidChange(_:) notification method after the user changes the system preference. The notification method is also called in the AppDelegate.applicationDidBecomeActive(_) and applicationDidResignActive(_) NSApplicationDelegate delegate methods because the button must be graphite when the application is inactive.
        // The Detail button uses custom images in Assets.xcassets named DetailToggleButtonBlueOn, DetailToggleButtonBlueOff, DetailToggleButtonGraphiteOn and DetailToggleButtonGraphiteOff. The color of the button images for NSBlueControllerTint are set to RGB 22, 103, 248, and for NSGraphiteController Tint to RGB 135, 135, 141, based on screen samples taken from Apple applications that use it. The images are PDF images to allow vector scaling, and their Assets.xcassets Attributes Inspector Image Set settings are Render As: Default, Resizing: Preserve Vector Data, Devices: Mac, and Scales: Single Scale.
        // If and when macOS is updated to support template images in conjunction with the system control tint as iOS does, this code will need to be revised.
         var imageName, alternateImageName: NSImage.Name
        if NSColor.currentControlTint == NSControlTint.graphiteControlTint || !NSApp.isActive {
            imageName = "DetailToggleButtonGraphiteOn"
            alternateImageName = "DetailToggleButtonGraphiteOff"
        } else {
            imageName = "DetailToggleButtonBlueOn"
            alternateImageName = "DetailToggleButtonBlueOff"
        }
//        if let detailButton = MainWindowController.sharedInstance.detailButton {
            // The detail button is in the toolbar.
            detailButton.image = NSImage(named: imageName)
            detailButton.alternateImage = NSImage(named: alternateImageName)
//        }
//        (detailButton.cell as? NSButtonCell)?.backgroundColor = NSColor.white
    }
 */
 
}
