//
//  Defines.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-11.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

import Foundation

// MARK: - PROPERTIES

// MARK: General Constants

// MARK: Target menu
// for main menu bar and Target pop-up button

// Target menu titles and tags
let TARGET_MENU_TITLE = "Target"
let TARGET_MENU_TAG = 4 // for main menu bar's Target menu only
let NO_TARGET_MENU_ITEM_TITLE = "No Target"
let NO_TARGET_MENU_ITEM_TAG = 1000
let SYSTEMWIDE_TARGET_MENU_ITEM_TITLE = "SystemWide Target"
let SYSTEMWIDE_TARGET_MENU_ITEM_TAG = 1001
let CHOOSE_TARGET_MENU_ITEM_TITLE = "Choose Target…"
let ACTIVATE_TARGET_MENU_ITEM_TITLE = "Activate Target"

// Target menu notifications
let DID_CHOOSE_TARGET_NOTIFICATION_NAME = "did choose target notification" // posted in MainContentViewController's chooseRunningTarget(_:) action method and anywhere the target menu title is changed to "No Target"; observed by auxiliary windows to update their titles with a new target name
let TARGET_NAME_KEY = "target name"

// Target menu representedObject dictionary keys associating NSRunningApplication objects with their display names
let RUNNING_APPLICATION_KEY = "running application"
let RUNNING_APPLICATION_DISPLAY_NAME_KEY = "running application display name"

// Repeating timer interval and duration to detect delayed availability of access after target is finished launching, used in MainContentViewController.
let SELECT_ELEMENT_TIMER_INTERVAL = 0.1
let SELECT_ELEMENT_TIMER_DURATION = 3.0

// MARK: User Defaults constants

// Display of Target menu in menu bar and Target pop-up button
let DISPLAYS_BACKGROUND_APPLICATIONS_DEFAULTS_KEY = "Target menu displays background applications"
let DISPLAYS_BACKGROUND_APPLICATIONS_SEPARATELY_DEFAULTS_KEY = "Target menu displays background applications separately"

// Effect of Target menu in menu bar and Target pop-up button
let CHOOSING_TARGET_ACTIVATES_APPLICATION_DEFAULTS_KEY = "choosing target activates application"

// For master (top) tab views in main window
let MASTER_TAB_VIEW_ITEM_DEFAULTS_KEY = "master tab view item"
enum MasterTabViewItemIndex: Int {
    // The Main.storyboard masterTabViewSelector segmented control indexes correspond to the raw values and are used by NSTabViewController.
    case Browser = 0, Outline, List
}

// TODO: Change this enum ...
// ... to pure Swift enum, if can store values in user defaults.
let TERMINOLOGY_DEFAULTS_KEY = "terminology"
enum Terminology: Int {
    // The Main.storyboard terminologyPopUpButton menu item tags correspond to the raw values.
    case natural = 0, raw, accessibility, appleScript, javaScript, objectiveC
}
