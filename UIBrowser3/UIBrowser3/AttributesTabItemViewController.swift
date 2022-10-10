//
//  AttributesTabItemViewController.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-10.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// AttributesTabItemViewController receives a tab items relationship segue triggered by DetailTabViewController in Main.storyboard. Because the detail (bottom) split item is revealed by default at first launch and the attributes tab item is its default tab item, the attributes tab item view controller is instantiated at first launch. At subsequent launches, it is only instantiated if the state restoration mechanism restores it; otherwise, it is instantiated when the user selects the Attributes tab item. The controller calls loadView() to instantiate and load the tab item's view.
// The attributes of the selected UI element are displayed in attributeTable. This controller is connected in Main.storyboard's Attributes Scene as the delegate of the attributeTable. The attributeTable's data source is AttributeDataSource, set programmatically here in viewDidLoad().
// The attributes tab item view in Main.storyboard includes a container view to the right of the attributeTable to hold a tabless settings tab view with numerous settings tab items. Each of the settings tab items contains controls to view or set the values or parameters of attributes of a particular type, such as "string" and "number". At runtime, the settings tab view is substituted for the container view via an embed segue. The user's selection of an attribute in the attributeTable selects a settings tab item of the appropriate type. The settings tab view's tab view controller is AttributeSettingsTabViewController. Each of its settings tab items has its own view controller, such as StringTabItemViewController and NumberTabItemViewController.
// In the Main.storyboard Attributes inspector for the Attribute, Type and Value column's table view cells in the Attributes table view, the Control Tooltips "Allows Expansion Tooltips" checkbox is selected.

import Cocoa

class AttributesTabItemViewController: NSViewController {

    // MARK: - VIEW MANAGEMENT
    
    // MARK: NSViewController Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
