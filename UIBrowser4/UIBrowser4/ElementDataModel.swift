//
//  ElementDataModel.swift
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-03-12.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 3.0.0
//

// NOTE on the implementation.
// ElementDataModel manages UI Browser's data as an array of subarrays of dictionary nodes mirroring the macOS accessibility hierarchy. UI Browser's view controllers use data source and delegate methods instead of bindings to access and manage the data model, and they therefore do not use NSTreeController. Apple's NSTreeController documentation: "The NSTreeController class provides selection and sort management. Its primary purpose is to act as the controller when binding NSOutlineView and NSBrowser instances to a hierarchical collection of objects."
// UI Browser was designed this way in part because of difficulties encountered in early attempts to use bindings and NSTreeController with NSBrowser. Similar difficulties were reportedly encountered by Mark Alldritt in writing his Script Debugger application. "You cannot easily use an NSBrowser delegate if you are also using bindings and an NSTreeController to drive the browser (at least on Mac OS X 10.6). For instance, you are prevented from using the -[NSBrowser:willDisplayCell:atRow:row column:column] delegate method to customize the cell presentation as you might do in an NSTableView or NSOutlineView." Mark Alldritt's Journal, January 5, 2011 <http://markalldritt.com/?p=413>.

import Cocoa
import PFAssistiveFramework4

// MARK: Defines

// Keys for entries in an element node dictionary. When building with Swift 4.2 or later, this automatically conforms to the Equatable and Hashable protocols. Apple's macOS Mojave 10.14 Hashable Protocol documentation: "To use your own custom type ... as the key type of a dictionary, add Hashable conformance to your type. The Hashable protocol inherits from the Equatable protocol, so you must also satisfy that protocol’s requirements. The compiler automatically synthesizes your custom type’s Hashable and requirements when you declare Hashable conformance in the type’s original declaration and your type meets these criteria: ... For an enum, all its associated values must conform to Hashable. (An enum without associated values has Hashable conformance even without the declaration.)"
enum ElementNodeKey {
    case elementKey
    case childCountKey
    case indexPathKey
    case briefElementDescriptionKey
    case fullElementDescriptionKey
    case mediumElementDescriptionKey
    case briefAppleScriptDescriptionKey
    case fullAppleScriptDescriptionKey
    case parentNodeKey
    case childNodeKey
}

/**
 The `ElementDataModel` class encapsulates UI Browser's model object in the *Model-View-Controller* (*MVC*) design pattern for the current target's accessibility UI element hierarchy. The implementation is private. The model's data is available outside this class only through its public access methods.
 
 A singleton `ElementDataModel` object is created lazily the first time the user chooses a target using the Target menu. This is done in `MainContentViewController.updateData(usingTargetElement:)` the first time the `ElementDataModel.sharedInstance` type property is referenced to make the public methods available to other classes. The model is updated in its entirey by calls to `MainContentViewController.updateApplication(forNewTarget:usingTargetElement:)` from the choose...Target action methods when the user chooses a new target or clears an existing target. The model is updated partially by various action and delegate methods when the user selects an element in an existing target's accessibility hierarchy.
 
 The private internal implementation is `elementNodeTree`, an array of subarrays of dictionaries, often referred to as a "tree". Each dictionary is referred to as a `node` or `elementNode`. Each `node` corresponds to the `item` in the data source methods described below. A `node` is of type `ElementNodeInfo`, containing the `AccessibleElement` object at the corresponding level and index of the target's accessibility hierarchy along with other information described below.
 
 The `elementNodeTree` model object contains every element in the target's selected accessibility hierarchy, from the root application element to the current selected element and any children it may have, and it includes all siblings of the element that is selected at each level. The display of the data in UI Browser's master (top) split item depends on which tab item is selected in the segmented control: the browser tab item is handled by `NSBrowserDelegate` data source and delegate methods implemented in `BrowserTabItemViewController`; the outline tab item view is handled by `NSOutlineViewDataSource` data source methods implemented in `OutlineTabItemViewController`; and the list tab item view is handled by `NSTableViewDataSource` data source methods implemented in `ListTabItemViewController`. All of the data source methods use `ElementDataModel` as their model object.
 
 The `ElementDataModel` public access methods are used to access the data efficently. `ElementDataModel` also implements public methods to update the data model by providing element descriptions and related information for display when UI Browser's selection path or terminology preference setting changes. These methods compute and cache information about the currently selected root application element and its child elements once when the user chooses a new target. Thereafter, when the user selects an element that is already displayed, it installs only that element's child UI elements, after removing all elements that are no longer in the selection path. It switches rapidly between browser, outline and list views without having to recompute the hierarchy on the fly every time. Computationally expensive information like AppleScript's GUI Scripting index is calculated once when `elementNodeTree` is updated, instead of being recalculated every time a data source delegate method is triggered by user scrolling in one of the three views. In addition, descriptive information about elements is cached in the data model using the current terminology preference, to avoid wasting time recomputing terminology descriptions that may never be displayed. When the user changes the terminology preference, all relevant data model descriptions are updated to the new terminology and visible views are reloaded. Caching the information also allows UI Browser to display elements that have been destroyed even though their `AccessibleElement` values are no longer valid, because the array keeps the hierarchy of destroyed elements intact until the user selects a new element or clicks the Refresh button. All of this is consistent with UI Browser's design, which is to provide a "snapshot" of the target's user interface at a point in time and to update the information only as elements are added or the data model is explicitly refreshed.
 
 Each `ElementNodeInfo` dictionary in `elementNodeTree` uses keys defined in the `ElementNodeKey` enumeration type. Each node contains an `AccessibleElement` object representing the Core Foundation `AXUIElement` accessibility object for the selected element (for key `.elementKey`), the element's child count (for key `.childCountKey`), the element's index path (for key `.indexPathKey`), the element's brief, medium and full descriptions (for keys `.briefElementDescriptionKey`, `.mediumElementDescriptionKey` and `.fullElementDescriptionKey`) based on the current terminology preference, and the element's brief and full AppleScript descriptions (for keys `.briefAppleScriptDescritionKey` and `.fullAppleScriptDescriptionKey`). When a target has been chosen, the first subarray contains a single dictionary, whose `.elementKey` value is an `AccessibleElement` representing the root application element at the first level of the hierarchy. Any other subarrays contain one or more similar dictionaries, each with an `.elementKey` value of type `AccessibleElement` representing elements at deeper levels of the hierarchy. If no target is currently chosen, 'elementNodeTree' is empty (except that it is `nil` if no target has been chosen since UI Browser was launched).
 
 Each `ElementNodeInfo` dictionary is passed to required data source methods in their `item` parameters when the user chooses a target or selects an element using the mouse or keyboard. UI Browser implements the `NSBrowserDelegate` protocol data source methods in `BrowserTabItemViewController`, in part because Cocoa declares the data source methods in the browser's `NSBrowserDelegate` protocol instead of implementing separate data source protocols. `BrowserTabItemViewController` is connected in `Main.storyboard` as the browser view's `delegate`, and it implements the `NSBrowserDelegate` required item-based data source methods introduced in Mac OS X 10.6 (Snow Leopard). UI Browser also implements the seperate `NSOutlineViewDataSource` and `NSTableViewDataSource` data source protocols in `OutlineTabItemViewController` and `ListTabItemViewController`, which are the delegates of UI Browser's outline view and list view controllers, even though these data source protocols are declared separately from the `NSOutlineViewDelegate` and `NSTableViewDelegate` delegate protocols. `ElementDataModel` is connected as the outline and list tab item views' data sources programmatically, while `OutlineTabItemViewController` and `ListTabItemViewController` are connected as those views' delegates in `Main.storyboard`.

 These methods use the terms "level" and "index" to identify the location of nodes in the data model. This reflects the accessibility hierarchy, where "level" is a zero-based index identifying the depth of a particular element in the hierarchy from the root application element at level 0 to the leaf element on the screen, and "index" is an arbitrary zero-based index uniquely identifying the element among all of the sibling elements at the same level of the hierarchy. The "level" is the index of the outer array in `elementNodeTree`, and the "index" is the index of the element's `elementNodeInfo` dictionary within the inner subarray of `elementNodeTree`. This terminology is used in order to abstract the geometric terminology of the three views used in UI Browser's master (top) split item view; namely, the browser view (where "level" corresponds to "column" and "index" corresponds to the "row" within a column) and the outline view (where "level" corresponds to "level" or "indentation level" and "index" corresponds to the "row" within an indentation level). UI Browser's list view uses the "level" to display the path control and "index" to display the "rows" in the table. Methods are provided to access information about elements in `ElementDataModel` using either the `level` and `index` values or an `NSIndexPath` object (an array of integers).
 */
final class ElementDataModel {
//final class ElementDataModel: NSObject {
    
    // MARK: - PROPERTIES
    // MARK: Public
    
    /// A type property that gives access to this object from any other object by referencing `ElementDataModel.sharedInstance`. It is created here to hold all of the `AccessibleElement` objects in the data model and related information.
    static let sharedInstance = ElementDataModel() // lazily creates an empty singleton object when first accessed
    
    /// A `Boolean` value indicating whether the data model is empty because no target is currently chosen.
    var isEmpty: Bool {
        // Whenever the data model is not empty, a single element node is selected.
        return elementNodeTree.isEmpty
    }
    
    /// The `AccessibleElement` contained in the currently selected element node, or `nil` if no target is currently chosen and therefore no node is selected.
    var currentElement: AccessibleElement? {
        // A single element node is always selected whenever the data model is not empty, and this property returns the AccessibleElement object that it contains.
        guard !currentElementNode.isEmpty else {return nil}
        return currentElementNode[.elementKey] as? AccessibleElement
    }
    
    /// An array containing the AccessibleElement objects in the currently selected UI element path. This does not include any siblings at any level.
    var currentElementPath: [AccessibleElement] {
        return currentElementNodePath.map {($0[.elementKey] as! AccessibleElement)}
    }
    
    /// The `NSIndexPath` of the `currentElement`, or `nil` if no target is currently chosen; use it as required to access information about the current element using public methods of the data model that require an index path.
    var currentElementIndexPath: NSIndexPath? {
        guard !currentElementNode.isEmpty else {return nil}
        return currentElementNode[.indexPathKey] as? NSIndexPath
    }
    
    // MARK: Private
    
    /// The type of each element node in the data model caching an individual `AccessibleElement` object and information about it.
    typealias ElementNodeInfo = [ElementNodeKey: Any]
    // Each node is a dictionary using keys defined in the ElementNodeKey enumeration and values as follows: [.elementKey: AccessibleElement, .childCountKey: Int, .indexPathKey: NSIndexPath, .briefElementDescriptionKey: string, .mediumElementDescriptionKey: string .fullElementDescriptionKey: NSAttributedString, .briefAppleScriptDescriptionKey: String, .fullAppleScriptDescriptionKey: NSAttributedString, .parentNodeKey: ElementNodeInfo, .childNodeKey: ElementNodeInfo].

    /// An array holding all of the subarrays containing element nodes in the currently selected UI element hierarchy. This includes all siblings of each element in the element path.
    private var elementNodeTree: [[ElementNodeInfo]] // an array of subarrays of ElementNodeInfo dictionaries

    /// The currently selected element node, of type `ElementNodeInfo`, or `nil` if no target is currently chosen and therefore no node is selected.
    private var currentElementNode: ElementNodeInfo // set in updateDataModelForCurrentElementAt(level:index:)
    
    /// An array containing element nodes in the currently selected UI element path. This does not include any siblings at any level.
    private var currentElementNodePath: [ElementNodeInfo] // an array of ElementNodeInfo dictionaries
    
    /// A saved copy of the index path of the currently selected element node as it existed before a menu was opened to select a new node. Saved in saveCurrentElementIndexPath(_:), called in the ElementPathControlManager or ListTabItemViewController menuWillOpen(_:) delegate method when the user opens the path control pop-up menu or the list view context menu. The data model is updated repeatedly as the user navigates either menu, and it is restored in restoreCurrentElementIndexPath(_:) called in the ElementPathControlManager or ListTabItemViewController menuWasDismissed() delegate method if the user dismisses the pop-up menu or the context menu without selecting a new UI element. It is set to nil again when the user selects a new element in the browser, outline or list view, by calling unsaveCurrentElementIndexPath(_:).
    private var savedCurrentElementIndexPath: NSIndexPath?
    
    private lazy var appleScriptClassNames: NSDictionary? = {
        // Lazily loads the AppleScriptRoles.plist file equating raw (or "AX") accessibility roles with AppleScript class names from the System Events application's AppleScript terminology dictionary.
        guard let url = Bundle.main.url(forResource: "AppleScriptRoles", withExtension: "plist"),
            let names = NSDictionary(contentsOf: url) else {
                sheetForRolesAppleScriptFileFailedToLoad()
                return nil
        }
        return names
    }()
    
    // TODO: Figure this out, and fix AnyObject?
    private var stringAttributes: Dictionary<NSAttributedString.Key, AnyObject> // style attributes for NSAttributedString; set in init()
    
    
    // MARK: - INITIALIZATION
    
    init() {
//   override init() {
        elementNodeTree = []
        currentElementNodePath = []
        currentElementNode = ElementNodeInfo()
        
        // Set up NSAttributedString attributes to use the small system font.
        stringAttributes = [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): NSFont.controlContentFont(ofSize: NSFont.smallSystemFontSize)]
        
        /*
         //  It is not necessary to set NSMutableParagraphStyle to NSLineBreakMode.ByTruncatingTail because Main.storyboard browser and table view settings truncate the tail automatically and provide expansion tooltips when the mouse hovers over the truncated string. This is how truncation could be done, but the expansion tooltips would be lost:
         let tableParagraphStyle = NSMutableParagraphStyle()
         tableParagraphStyle.lineBreakMode = NSLineBreakMode.ByTruncatingTail
         stringAttributes = [NSFontAttributeName: NSFont.controlContentFontOfSize(NSFont.smallSystemFontSize()), NSParagraphStyleAttributeName: tableParagraphStyle]
         */
    }
    
    // MARK: - DATA MODEL ACCESS METHODS
    // These access methods provide fast public access to information in the data model. When calling the methods that take an element node of type 'ElementNodeInfo' as a parameter, the node can be obtained using nodeAt(level:index:), nodesAt(level:), node(atIndexPath:) or childNode(ofNode:atIndex:). When doing so, treat the node as an opague object; only use the public methods to extract data from the data model.
    
    /**
     Returns the element node at `level` and `index` in the data model.
     
     Use the return value with any method that takes an object of type `ElementNodeInfo` as a parameter. `ElementNodeInfo` is an opaque type; use public methods of this class to extract a node's information.
     
     - parameter level: The zero-based level of the node and its siblings in the selected accessibility hierarchy
     
     - parameter index: The zero-based index of the node among its siblings within its level of the selected accessibility hierarchy
     
     - returns: The `ElementNodeInfo` object
     */
    func nodeAt(level: Int, index: Int) -> ElementNodeInfo {
        return elementNodeTree[level][index]
    }
    
    /**
     Returns an array of all element nodes at `level` in the data model.
     
     - parameter level: The zero-based level of the node and its siblings in the selected accessibility hierarchy
     
     - returns: An array of `ElementNodeInfo` objects
     */
    // TODO: review the guard statement here and one other place added in build 49 to prevent range errors
    func nodesAt(level: Int) -> [ElementNodeInfo]? {
        guard level < elementNodeTree.count else { return nil }
        return elementNodeTree[level]
    }
    
    /**
     Returns the element node at `indexPath` in the data model.
     
     Use the return value with any method that takes an object of type `ElementNodeInfo` as a parameter. `ElementNodeInfo` is an opaque type; use public methods of this class to extract a node's information.
     
     - parameter path: The index path of the node in the selected accessibility hierarchy
     
     - returns the `ElementNodeInfo` object
     */
    func node(atIndexPath path: NSIndexPath) -> ElementNodeInfo {
        return elementNodeTree[path.length - 1][path.index(atPosition: path.length - 1)]
    }
    
    // TODO: add similar tests to other methods that return a node.
    // TODO: should childNode(ofNode:atIndex:) return nil instead of [:]?
    /**
     Returns the element node at `index` among the parent node's child elements in the data model, or an empty node if the parent node's child elements have not yet been added to the data model.
     
     Use the return value with any method that takes an object of type `ElementNodeInfo` as a paremeter. `ElementNodeInfo` is an opaque type; use public methods of this class to extract a node's information.
     
     If the parent node parameter value is passed in as `nil`, the returned child node at index 0 is the root application element or the system-wide element currently chosen as UI Browser's target.
     
     - parameter node: The parent node in the selected accessibility hierarchy
     
     - parameter index: The zero-based index of the child node among its siblings in the selected accessibility hierarchy
     
     - returns: The `elementNodeInfo` object
     */
    func childNode(ofNode node: ElementNodeInfo?, atIndex index: Int) -> ElementNodeInfo { //[String: Any] {
        // Called in the BrowserTabItemViewController browser(_:child:ofItem:) item-based data source method, which asserted that it is of the correct type.
        if node == nil { // represents the parent, or root, of the element tree itself
            return elementNodeTree[0][0]
        } else {
            let path = node![.indexPathKey] as! NSIndexPath
            //print("parent node is at level: \(path.length - 1), index: \(path.index(atPosition: path.length - 1))")
            guard elementNodeTree.count > path.length,
                index >= 0,
                index < childCount(ofNode: node!)
                else { return [:] }
            //           let path = node![.indexPathKey] as! NSIndexPath
            //print("child node is at level: \(path.length), index: \(index)")
            return elementNodeTree[path.length][index] // path.length is the level of node's children, one level deeper than the parent node's level
        }
    }

    /**
     Returns the number of element nodes at 'level' in the data model.
     
     - parameter level: A zero-based level in the selected accessibility hierarchy
     
     - returns: The number of nodes as an Int
     */
    func nodeCount(atLevel level: Int) -> Int {
        // Called in BrowserTabItemViewController updateTerminology(), in ListTabItemViewController numberOfRows(inTableView:), and....
        if elementNodeTree.endIndex <= level {
            return 0
        }
        return elementNodeTree[level].count
    }
    
    /**
     Returns the element in the accessibility hierarchy represented by a node in the data model.
     
     - parameter node: A node in the data model.
     
     - returns: The `AccessibleElement` object cached in the node
     */
    func element(ofNode node: ElementNodeInfo) -> AccessibleElement {
        return node[.elementKey] as! AccessibleElement
    }
    
    // TODO: Fix this to work with change of NodesAt(level) to return optional result ...
    // ... maybe this should return optional result, too; what about others?
    func elements(atLevel level: Int) -> [AccessibleElement] {
        if let x = nodesAt(level: level) {
            return x.map {($0[.elementKey] as! AccessibleElement)}
//        return nodesAt(level: level).map {($0[.elementKey] as! AccessibleElement)}
        } else {
            return []
        }
    }
    
    /**
     Returns the number of child elements of the element in the accessibility hierarchy represented by a node in the data model.
     
     - parameter node: A node in the data model.
     
     - returns: The number of the element's child elements cached in the node as an Int
     */
   func childCount(ofNode node: ElementNodeInfo) -> Int {
        // Called in several methods of BrowserTabItemViewController.
        return node[.childCountKey] as! Int
    }
    
    /**
     Returns the index path of the element in the accessibility hierarchy represented by a node in the data model.
     
     - parameter node: A node in the data model.
     
     - returns: The element's index path cached in the node as an `NSIndexPath`
     */
   func indexPath(ofNode node: ElementNodeInfo) -> NSIndexPath {
        // Returns the index path of the specified node. Called in BrowserTabItemViewController updateTerminology() and MasterSplitItemViewController refreshApplication().
        return node[.indexPathKey] as! NSIndexPath
    }
    
    /**
     Returns a brief description of the element in the accessibility hierarchy represented by a node in the data model.
     
     - parameter node: A node in the data model.
     
     - returns: The element's brief description cached in the node as a String
     */
    func briefDescription(ofNode node: ElementNodeInfo) -> String { // brief descriptions are used as column titles
        // Called in BrowserTabItemViewController browser(_:titleOfColumn:) and updateTerminology().
        return node[.briefElementDescriptionKey] as! String
    }
    
    /**
     Returns a medium description of the element in the accessibility hierarchy represented by a node in the data model.
     
     - parameter node: A node in the data model.
     
     - returns: The element's medium description cached in the node as a String
     */
    func mediumDescription(ofNode node: ElementNodeInfo) -> String { // medium descriptions are used as menu item titles
        // Called in BrowserTabItemViewController browser(_:titleOfColumn:) and updateTerminology().
        return node[.mediumElementDescriptionKey] as! String
    }
    
    /**
     Returns a full description of the element in the accessibility hierarchy represented by a node in the data model.
     
     - parameter node: A node in the data model.
     
     - returns: The element's full description cached in the node as an NSAttributedString
     */
    func fullDescription(ofNode node: ElementNodeInfo) -> NSAttributedString { // full descriptions are used as cell view content
        // Called in AttributeDataSource descriptionOfAttributeArrayObject(_:) and BrowserTabItemViewController browser(_:objectValueForItem:).
        return node[.fullElementDescriptionKey] as! NSAttributedString
    }
    
    // MARK: - DATA MODEL MANAGEMENT
    
    /**
     Clears the data model and updates it by appending a node for the system-wide accessibility element at level 0.
     
     Call this method when the user chooses SystemWide Target in the Target menu. When this method completes, the data model contains a single subarray containing a single `ElementNodeInfo` dictionary representing the system-wide `AccessibleElement` object.
     
     The system-wide element has no children.
     
     - parameter element: A system-wide accessibility element created when the user chose SystemWide Target in the Target menu
     */
    func updateDataModel(forSystemWideElement element: AccessibleElement) {
        // Called by MainContentViewController updateData(usingTargetElement:) via updateApplication(forNewTarget:usingTargetElement:), testing for AXRole of "AXSystemWide".
        assert(element.AXRole == kAXSystemWideRole, "called ElementDataModel.updateDataModel(forSystemWideElement:) with an element parameter value whose AXRole attribute is not \"AXSystemWide\"")

        func appleScriptDescriptions(forElement element: AccessibleElement) -> (String, NSAttributedString) {
            // Composes the system-wide element's AppleScript descriptions. The system-wide element is not supported in GUI Scripting.
            
            // Compose the brief AppleScript reference as a string.
            let briefAppleScriptDescription = NSLocalizedString("<no AppleScript support>", comment: "")
            
            // Compose the full AppleScript reference as an NSAttributedString.
            let fullAppleScriptDescription = NSAttributedString(string: briefAppleScriptDescription, attributes: stringAttributes)
            
            return (briefAppleScriptDescription, fullAppleScriptDescription)
        }
        
        // Compose descriptions of the element.
        var briefElementDescription: String = briefDescription(ofElement: element)
        let mediumElementDescription: String = mediumDescription(ofElement: element, atIndexPath: NSIndexPath(index: 0))
        var fullElementDescription: NSAttributedString = fullDescription(ofElement: element, atIndexPath: NSIndexPath(index: 0))
        
        // Compose AppleScript references to the element.
        var briefAppleScriptDescription: String
        var fullAppleScriptDescription: NSAttributedString
        (briefAppleScriptDescription, fullAppleScriptDescription) = appleScriptDescriptions(forElement: element)
        
        //  Replace descriptions for briefElementDescription and fullElementDescription that were set above if the current terminology preference is AppleScript.
        if UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY) == Terminology.appleScript.rawValue {
            briefElementDescription = briefAppleScriptDescription
            fullElementDescription = fullAppleScriptDescription
        }
        
        // Create an ElementNodeInfo dictionary for the chosen system-wide element.
        let node: ElementNodeInfo = [
            .elementKey: element,
            .childCountKey: element.childCount(),
            .indexPathKey: NSIndexPath(index: 0),
            .briefElementDescriptionKey: briefElementDescription,
            .mediumElementDescriptionKey: mediumElementDescription,
            .fullElementDescriptionKey: fullElementDescription,
            .briefAppleScriptDescriptionKey: briefAppleScriptDescription,
            .fullAppleScriptDescriptionKey: fullAppleScriptDescription,
            .parentNodeKey: [:],
            .childNodeKey: [:]
        ]

        // Update the data model by removing all subarrays and replacing them with a single subarray containing a single ElementNodeInfo dictionary representing the system-wide target.
        elementNodeTree.removeAll()
        elementNodeTree.append([node])
        
        // Update the currentElementNodePath by removing all nodes and replacing them with the current node.
        currentElementNodePath.removeAll()
        currentElementNodePath.append(node)
        
        currentElementNode = node
        
        
        // TODO: Make sure adding this here to solve the path control problem does not result in duplicate calls later.
        updateDataModelForCurrentElementAt(level: 0, index: 0)
    }
    
    /**
     Clears the data model and updates it by appending a node for an application accessibility element at level 0.
     
     Call this method when the user chooses a new application in the Target menu. When this method completes, the data model contains a single subarray containing a single `ElementNodeInfo` dictionary representing the target's application `AccessibleElement` object.
     
     The `updateDataModelForCurrentElementAt(level:index:)` method should be called immediately afterward to select the application element and append the current target's child elements at level 1 of the data model.
     
     - parameter element: An application accessibility element created when the user chose an application in the Target menu
     */
    func updateDataModel(forApplicationElement element: AccessibleElement) {
        // Called by MainContentViewController updateApplication(forNewTarget:usingTargetElement:) and updateTargetWithTimer(_:).
        assert(element.AXRole == kAXApplicationRole, "called ElementDataModel.updateDataModel(forApplicationElement:) with an element parameter value whose AXRole attribute is not \"AXApplication\"")

        func appleScriptDescriptions(forElement element: AccessibleElement) -> (String, NSAttributedString) {
            // Composes the target application element's AppleScript descriptions. They are composed here instead of in dedicated description methods and cached separately from the briefElementDescription and fullElementDescription to facilitate efficient terminology updates to AppleScript. While AppleScript application references do not have an index, all other AppleScript UI element references do have an index and composing and caching them once here and in updateDataModelForCurrentElementAt(level:index:) is more efficient than recalculating them. These AppleScript descriptions replace the empty descriptions for briefElementDescription and fullElementDescription that were set above if the current terminology preference is ApppleScript.
            
            guard appleScriptClassNames != nil else {
                // appleScriptClassNames is a private lazy ElementDataModel property of type NSDictionary loaded from the AppleScriptRoles.plist file when ElementDataModel is initialized. Any error is presented at initialization.
                return ("", NSAttributedString(string: "", attributes: stringAttributes))
            }
            
            // Get the AppleScript role name.
            let role = element.AXRole!
            let appleScriptName = appleScriptClassNames![role] as? String
            
            // Get the AppleScript title.
            let title = element.AXTitle
            
            // Compose the brief AppleScript reference as a string.
            let briefAppleScriptDescription = "\(appleScriptName!) \"\(title!)\""
            
            // Compose the full AppleScript reference as an NSAttributedString.
            let fullAppleScriptDescription = NSAttributedString(string: briefAppleScriptDescription, attributes: stringAttributes)
            
            return (briefAppleScriptDescription, fullAppleScriptDescription)
        }
        
        // Compose descriptions of the element.
        // TODO: make AppleScript changes to mediumElementDescription like brief... and full...
        var briefElementDescription: String = briefDescription(ofElement: element)
        let mediumElementDescription: String = mediumDescription(ofElement: element, atIndexPath: NSIndexPath(index: 0))
        var fullElementDescription: NSAttributedString = fullDescription(ofElement: element, atIndexPath: NSIndexPath(index: 0))
        
        // TODO: Add mediumAppleScriptDescription here and elsewhere.
        // Compose AppleScript references to the element.
        var briefAppleScriptDescription: String
        var fullAppleScriptDescription: NSAttributedString
        (briefAppleScriptDescription, fullAppleScriptDescription) = appleScriptDescriptions(forElement: element)
        
        //  Replace descriptions for briefElementDescription and fullElementDescription that were set above if the current terminology preference is ApppleScript.
        if UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY) == Terminology.appleScript.rawValue {
            briefElementDescription = briefAppleScriptDescription
            fullElementDescription = fullAppleScriptDescription
        }
        
        // Create an ElementNodeInfo dictionary for the chosen application element.
        let node: ElementNodeInfo = [
            .elementKey: element,
            .childCountKey: element.childCount(),
            .indexPathKey: NSIndexPath(index: 0),
            .briefElementDescriptionKey: briefElementDescription,
            .mediumElementDescriptionKey: mediumElementDescription,
            .fullElementDescriptionKey: fullElementDescription,
            .briefAppleScriptDescriptionKey: briefAppleScriptDescription,
            .fullAppleScriptDescriptionKey: fullAppleScriptDescription,
            .parentNodeKey: [:],
            .childNodeKey: [:]
        ]

        // Update the data model by removing all levels and replacing them with a single array containing a single ElementNodeInfo dictionary representing the target application. It will be selected and its child nodes will be appended in updateDataModelForCurrentElementAt(level:index:).
        elementNodeTree.removeAll()
        elementNodeTree.append([node])

        // Update the selected currentElementNodePath by removing all nodes. The ElementNodeInfo dictionary representing the target application will be appended to the empty selected currentElementNodePath in updateDataModelForCurrentElementAt(level:index:).
        currentElementNodePath.removeAll()

        currentElementNode = node
        
        // TODO: Make sure adding this here to solve the path control problem does not result in duplicate calls later.
        updateDataModelForCurrentElementAt(level: 0, index: 0)
    }
    
    /**
     Clears the data model from the level of the current element, and appends nodes for the current element's child accessibility elements at the next level, if any.
     
     Call this method when the user sets the current element by selecting an existing accessibility element in the browser or list tab item view. Also call it to append the application element's child elements, if any, after calling `updateDataModel(forApplicationElement:)` when the user chooses a new application target in the Target menu no matter which tab item view is currently displayed. When this method completes, the current element is selected and, if the current element is not in a leaf node, the data model contains an additional subarray containing `ElementNodeInfo` dictionaries representing all of the child AccessibleElement objects of the current element.
     
     - parameter level: The zero-based level of the current element in the selected accessibility hierarchy
     
     - parameter index: The zero-based index of the current element among its siblings within its level of the current accessibility hierarchy
     */
    func updateDataModelForCurrentElementAt(level: Int, index: Int) {
        // Called by the BrowserTabItemViewController browser(_:selectRow:inColumn:) delegate method, ListTabItemViewController selectElement(_:), and several other methods.
        
        func appleScriptDescriptions(forElement element: AccessibleElement, elementIndex: Int, roleIndex: inout [String: Int]) -> (String, NSAttributedString) {
            // Composes a child element's AppleScript descriptions and, as part of the task, calculates the child element's one-based AppleScript index. The index is calculated here in order to do it once, while already iterating over the current element's children. It is then cached in the ElementNodeInfo dictionary for reuse, to facilitate efficient updates to AppleScript terminology. It would be much less efficient to instead calculate the index separately in a dedicated description method called whenever the Terminology preference is set to AppleScript terminology.
            
            guard appleScriptClassNames != nil else {
                // appleScriptClassNames is a private lazy ElementDataModel property of type NSDictionary loaded from the AppleScriptRoles.plist file when ElementDataModel is initialized. Any error is reported at initialization.
                return ("", NSAttributedString(string: "", attributes: stringAttributes))
            }
            
            // Get AppleScript role name.
            let role = element.AXRole!
            var appleScriptName = appleScriptClassNames![role] as? String
            if appleScriptName == nil {
                // If role is not listed as a key in AppleScriptRoles.plist...
                if role.hasPrefix("AX") {
                    // ... but it has Apple's "AX" accessibility prefix, use "UI element".
                    appleScriptName = "UI element"
                } else {
                    // ... otherwise use its raw role string.
                    appleScriptName = role
                }
            }
            
            // Get AppleScript index.
            var appleScriptIndex: Int
            if element.isRole(NSAccessibility.Role.unknown.rawValue) || appleScriptName!.hasPrefix("AX") {
                // The GUI Scripting index of a UI Element whose role is unknown is its one-based index within all elements of all roles in the array.
                appleScriptIndex = elementIndex + 1; // AppleScript indexes are one-based
            } else {
                // The GUI Scripting index of a UI Element whose role is known is its one-based index within all elements of the same role in the array. Computing the AppleScriptIndex in the main loop by storing each role's last index in a dictionary is dramatically faster than counting elements with the same role repeatedly in an inner loop.
                if var lastRoleIndex = roleIndex[role] {
                    // This is not the first element with this role at this level of elementNodeTree.
                    lastRoleIndex += 1
                    roleIndex[role] = lastRoleIndex
                    appleScriptIndex = lastRoleIndex
                } else {
                    // This is the first element with this role at this level of elementNodeTree.
                    roleIndex[role] = 1
                    appleScriptIndex = 1
                }
            }
            
            // Compose the brief AppleScript reference as a string.
            let briefAppleScriptDescription = "\(appleScriptName!) \(appleScriptIndex)"
            
            // Compose the full AppleScript reference as an NSAttributedString.
            var description = briefAppleScriptDescription
            let title = element.AXTitle
            if title != nil && !title!.isEmpty {
                description += " (\"\(title!)\")"
            }
            let fullAppleScriptDescription = NSAttributedString(string: description, attributes: stringAttributes)
            
            return (briefAppleScriptDescription, fullAppleScriptDescription)
        }
        
        // TODO: is there a better way to protect against selecting a path component without children?
        guard level < elementNodeTree.count else {return}
//        guard index >= 0 else {return}
        
        // Set the currentElementNode private variable. If the user chose a new target, the target's root application UI element has already been selected and its element information has already been set at data model level 0, index 0 in updateDataModel(forApplicationElement:). Otherwise, if the user selected a UI element that is visible in the master (top) split item (including the application element) or from the path control pop-up menu, then its element information was already in the data model at the specified level and index as the result of a previous user selection. In either case, the selected element's information is already available in the data model so that currentElementNode can be updated now from the data model. The information in the data model is from the last "snapshot" of the target.
//        currentElementNode = elementNodeTree[level][0]
       currentElementNode = elementNodeTree[level][index]
/*
        // Set the current node to be its parent node's child node.
        if level > 0 {
            var parentNode = currentElementNode[ElementNodeKey.parentNodeKey] as! ElementDataModel.ElementNodeInfo
            parentNode.updateValue(currentElementNode, forKey: .childNodeKey)
        }
*/
        /// A temporary array of `AccessibleElement` objects containing the child elements of the current element, if any.
        //guard let childElements = (currentElementNode[.elementKey] as! AccessibleElement).AXChildren,
        //    childElements.count > 0 else {return}
        if let childElements = (currentElementNode[.elementKey] as! AccessibleElement).AXChildren,
            childElements.count > 0 {
            // Declare entries in an ElementNodeInfo dictionary for each child element.
            var childNodes: [ElementNodeInfo] = [] // array of ElementNodeInfo dictionaries representing the child elements of the parent element
            var element: AccessibleElement
            var childCount: Int
            var indexPath: IndexPath
            var briefElementDescription: String
            var mediumElementDescription: String
            var fullElementDescription: NSAttributedString
            var briefAppleScriptDescription: String// = ""
            var fullAppleScriptDescription: NSAttributedString// = NSAttributedString(string: "", attributes: stringAttributes)
            var parentNode: ElementNodeInfo
            var childNode: ElementNodeInfo
            
            // Loop through every child element in the childElements array, creating an ElementNodeInfo dictionary for each and appending it to the new childNodes array. The childNodes array will then be appended to the elementNodeTree array.
            var appleScriptRoleIndex: [String: Int] = [:] // create a temporary dictionary for use by the appleScriptDescriptions(forElement:elementIndex:roleIndex:) nested method to accumulate an array of AppleScript indexes for specific roles
            // TODO: change the for..in terms to fix destroyed problem; is it ok?
            for idx in 0..<childElements.count {
            //for idx in 0..<(currentElementNode[.childCountKey] as! Int) {
                element = childElements[idx]
                
                // Set element's delegate, if any.
                element.delegate = MainContentViewController.sharedInstance
                
                // Compose descriptions of the element.
                childCount = element.childCount()
                indexPath = (currentElementNode[.indexPathKey] as! NSIndexPath).adding(idx)
                
                briefElementDescription = briefDescription(ofElement: element)
                mediumElementDescription = mediumDescription(ofElement: element, atIndexPath: indexPath as NSIndexPath)
                fullElementDescription = fullDescription(ofElement: element, atIndexPath: indexPath as NSIndexPath)
                
                // Compose AppleScript references to the element.
                (briefAppleScriptDescription, fullAppleScriptDescription) = appleScriptDescriptions(forElement: element, elementIndex: idx, roleIndex: &appleScriptRoleIndex)
                
                //  Replace descriptions for briefElementDescription and fullElementDescription that were set above if the current terminology preference is ApppleScript.
                if UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY) == Terminology.appleScript.rawValue {
                    briefElementDescription = briefAppleScriptDescription
                    fullElementDescription = fullAppleScriptDescription
                }
                
                // Compose parent and child nodes.
                parentNode = currentElementNode
                childNode = [:]
                
                // Set the element's indexPath property.
                element.indexPath = indexPath
                
                // Create an ElementNodeInfo dictionary for the chosen application element.
                let node: ElementNodeInfo = [
                    .elementKey: element,
                    .childCountKey: childCount,
                    .indexPathKey: indexPath,
                    .briefElementDescriptionKey: briefElementDescription,
                    .mediumElementDescriptionKey: mediumElementDescription,
                    .fullElementDescriptionKey: fullElementDescription,
                    .briefAppleScriptDescriptionKey: briefAppleScriptDescription,
                    .fullAppleScriptDescriptionKey: fullAppleScriptDescription,
                    .parentNodeKey: parentNode,
                    .childNodeKey: childNode
                ]
                
                // Append this ElementNodeInfo dictionary to childNodes.
                childNodes.append(node)
            }
            
            // Update the data model by removing any and all levels following the current level and replacing them with the childNodes array. If the selected element is the root application UI element in level 0 of the data source, it was already appended in updateDataModel(forApplicationElement:).
            elementNodeTree.removeSubrange((level + 1)..<elementNodeTree.count)
            elementNodeTree.append(childNodes)
 //           elementNodeTree.insert(childNodes, at: level + 1)
            // TODO: next line works only if level + 1 exists
 //           elementNodeTree[level + 1].append(contentsOf: childNodes)
        }
        
        // Update the selected currentElementNodePath by removing any and all nodes at and following the current level and appending the current node.
        if currentElementNodePath.count > level {
            // The user selected a different row in the currently selected column.
            currentElementNodePath.removeSubrange(level..<currentElementNodePath.count)
        }
        currentElementNodePath.append(currentElementNode)
    }
    
    /*
    /**
     Clears the data model from the level of the current element, and appends nodes for the current element's child accessibility elements at the next level, if any. This method behaves like updateDataModelForCurrentElementAt(level:index:), but it is designed especially for use in the outline tab item view.
     
     Call this method when the user sets the current element by selecting or expanding an existing accessibility element in the outline tab item view. When this method completes, the current element is selected and expanded and, if the current element is not in a leaf node, the data model contains an additional subarray containing `ElementNodeInfo` dictionaries representing all of the child AccessibleElement objects of the current element. Any elements outside of the current element path that were previously expanded are collapsed. This behavior matches the behavior of UI Browser's browser tab item view. It is unlike the usual behavior of a macOS outline view in that selecting a row in the outline automatically expands it, expanding a row automatically selects it, and selecting or expanding a row automatically collapses any expanded rows that are outside the current selection path. To support this behavior, the data model need only be an array of arrays; a full tree is not required.
     
     - parameter level: The zero-based level of the current element in the accessibility hierarchy
     
     - parameter index: The zero-based index of the current element among its siblings within its level of the current accessibility hierarchy
     */
    func updateDataModelForExpandedElementAt(level: Int, index: Int) {
        // Called by the OutlineTabItemViewController outlineViewItemWillExpand(_:) delegate method.
        
        func appleScriptDescriptions(forElement element: AccessibleElement, elementIndex: Int, roleIndex: inout [String: Int]) -> (String, NSAttributedString) {
            // Composes a child element's AppleScript descriptions and, as part of the task, calculates the child element's one-based AppleScript index. The index is calculated here in order to do it once, while already iterating over the current element's children. It is then cached in the ElementNodeInfo dictionary for reuse, to facilitate efficient updates to AppleScript terminology. It would be much less efficient to instead calculate the index separately in a dedicated description method called whenever the Terminology preference is set to AppleScript terminology.
            
            guard appleScriptClassNames != nil else {
                // appleScriptClassNames is a private lazy ElementDataModel property of type NSDictionary loaded from the AppleScriptRoles.plist file when ElementDataModel is initialized. Any error is reported at initialization.
                return ("", NSAttributedString(string: "", attributes: stringAttributes))
            }
            
            // Get AppleScript role name.
            let role = element.AXRole!
            var appleScriptName = appleScriptClassNames![role] as? String
            if appleScriptName == nil {
                // If role is not listed as a key in AppleScriptRoles.plist...
                if role.hasPrefix("AX") {
                    // ... but it has Apple's "AX" accessibility prefix, use "UI element".
                    appleScriptName = "UI element"
                } else {
                    // ... otherwise use its raw role string.
                    appleScriptName = role
                }
            }
            
            // Get AppleScript index.
            var appleScriptIndex: Int
            if element.isRole(NSAccessibility.Role.unknown.rawValue) || appleScriptName!.hasPrefix("AX") {
                // The GUI Scripting index of a UI Element whose role is unknown is its one-based index within all elements of all roles in the array.
                appleScriptIndex = elementIndex + 1; // AppleScript indexes are one-based
            } else {
                // The GUI Scripting index of a UI Element whose role is known is its one-based index within all elements of the same role in the array. Computing the AppleScriptIndex in the main loop by storing each role's last index in a dictionary is dramatically faster than counting elements with the same role repeatedly in an inner loop.
                if var lastRoleIndex = roleIndex[role] {
                    // This is not the first element with this role at this level of elementNodeTree.
                    lastRoleIndex += 1
                    roleIndex[role] = lastRoleIndex
                    appleScriptIndex = lastRoleIndex
                } else {
                    // This is the first element with this role at this level of elementNodeTree.
                    roleIndex[role] = 1
                    appleScriptIndex = 1
                }
            }
            
            // Compose the brief AppleScript reference as a string.
            let briefAppleScriptDescription = "\(appleScriptName!) \(appleScriptIndex)"
            
            // Compose the full AppleScript reference as an NSAttributedString.
            var description = briefAppleScriptDescription
            let title = element.AXTitle
            if title != nil && !title!.isEmpty {
                description += " (\"\(title!)\")"
            }
            let fullAppleScriptDescription = NSAttributedString(string: description, attributes: stringAttributes)
            
            return (briefAppleScriptDescription, fullAppleScriptDescription)
        }
        
        // TODO: is there a better way to protect against selecting a path component without children?
        guard level < elementNodeTree.count else {return}
        //        guard index >= 0 else {return}
        
        // Set the currentElementNode private variable. If the user chose a new target, the target's root application UI element has already been selected and its element information has already been set at data model level 0, index 0 in updateDataModel(forApplicationElement:). Otherwise, if the user selected a UI element that is visible in the master (top) split item (including the application element) or from the path control pop-up menu, then its element information was already in the data model at the specified level and index as the result of a previous user selection. In either case, the selected element's information is already available in the data model so that currentElementNode can be updated now from the data model. The information in the data model is from the last "snapshot" of the target.
        //        currentElementNode = elementNodeTree[level][0]
        // currentElementNode = elementNodeTree[level][index]
        currentElementNode = elementNodeTree[level][index]
        /*
         // Set the current node to be its parent node's child node.
         if level > 0 {
         var parentNode = currentElementNode[ElementNodeKey.parentNodeKey] as! ElementDataModel.ElementNodeInfo
         parentNode.updateValue(currentElementNode, forKey: .childNodeKey)
         }
         */
        /// A temporary array of `AccessibleElement` objects containing the child elements of the current element, if any.
        //guard let childElements = (currentElementNode[.elementKey] as! AccessibleElement).AXChildren,
        //    childElements.count > 0 else {return}
        if let childElements = (currentElementNode[.elementKey] as! AccessibleElement).AXChildren,
            childElements.count > 0 {
            // Declare entries in an ElementNodeInfo dictionary for each child element.
            var childNodes: [ElementNodeInfo] = [] // array of ElementNodeInfo dictionaries representing the child elements of the parent element
            var element: AccessibleElement
            var childCount: Int
            var indexPath: IndexPath
            var briefElementDescription: String
            var mediumElementDescription: String
            var fullElementDescription: NSAttributedString
            var briefAppleScriptDescription: String// = ""
            var fullAppleScriptDescription: NSAttributedString// = NSAttributedString(string: "", attributes: stringAttributes)
            var parentNode: ElementNodeInfo
            var childNode: ElementNodeInfo
            
            // Loop through every child element in the childElements array, creating an ElementNodeInfo dictionary for each and appending it to the new childNodes array. The childNodes array will then be appended to the elementNodeTree array.
            var appleScriptRoleIndex: [String: Int] = [:] // create a temporary dictionary for use by the appleScriptDescriptions(forElement:elementIndex:roleIndex:) nested method to accumulate an array of AppleScript indexes for specific roles
            // TODO: change the for..in terms to fix destroyed problem; is it ok?
            for idx in 0..<childElements.count {
                //for idx in 0..<(currentElementNode[.childCountKey] as! Int) {
                element = childElements[idx]
                
                // Set element's delegate, if any.
                element.delegate = MainContentViewController.sharedInstance
                
                // Compose descriptions of the element.
                childCount = element.childCount()
                indexPath = (currentElementNode[.indexPathKey] as! NSIndexPath).adding(idx)
                
                briefElementDescription = briefDescription(ofElement: element)
                mediumElementDescription = mediumDescription(ofElement: element, atIndexPath: indexPath as NSIndexPath)
                fullElementDescription = fullDescription(ofElement: element, atIndexPath: indexPath as NSIndexPath)
                
                // Compose AppleScript references to the element.
                (briefAppleScriptDescription, fullAppleScriptDescription) = appleScriptDescriptions(forElement: element, elementIndex: idx, roleIndex: &appleScriptRoleIndex)
                
                //  Replace descriptions for briefElementDescription and fullElementDescription that were set above if the current terminology preference is ApppleScript.
                if UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY) == Terminology.appleScript.rawValue {
                    briefElementDescription = briefAppleScriptDescription
                    fullElementDescription = fullAppleScriptDescription
                }
                
                // Compose parent and child nodes.
                parentNode = currentElementNode
                childNode = [:]
                
                // Set the element's indexPath property.
                element.indexPath = indexPath
                
                // Create an ElementNodeInfo dictionary for the chosen application element.
                let node: ElementNodeInfo = [
                    .elementKey: element,
                    .childCountKey: childCount,
                    .indexPathKey: indexPath,
                    .briefElementDescriptionKey: briefElementDescription,
                    .mediumElementDescriptionKey: mediumElementDescription,
                    .fullElementDescriptionKey: fullElementDescription,
                    .briefAppleScriptDescriptionKey: briefAppleScriptDescription,
                    .fullAppleScriptDescriptionKey: fullAppleScriptDescription,
                    .parentNodeKey: parentNode,
                    .childNodeKey: childNode
                ]
                
                // Append this ElementNodeInfo dictionary to childNodes.
                childNodes.append(node)
            }
            
            // Update the data model by removing any and all levels following the current level and replacing them with the childNodes array. If the selected element is the root application UI element in level 0 of the data source, it was already appended in updateDataModel(forApplicationElement:).
            elementNodeTree.removeSubrange((level + 1)..<elementNodeTree.count)
            elementNodeTree.append(childNodes)
            //           elementNodeTree.insert(childNodes, at: level + 1)
            // TODO: test whether child level exists; if not, create it; then in any case do this:
            /*
            if level + 1 >= elementNodeTree.count {
                // The level of the child elements to be revealed is greater than the deepest level of the data model, so a new level must be appended to the data model.
                elementNodeTree.append(childNodes)
            }
            elementNodeTree[level + 1].append(contentsOf: childNodes)
             */
        }

        // Update the selected currentElementNodePath by removing any and all nodes at and following the current level and appending the current node.
        if currentElementNodePath.count > level {
            // The user selected a different row in the currently selected level.
            currentElementNodePath.removeSubrange(level..<currentElementNodePath.count)
        }
        currentElementNodePath.append(currentElementNode)
    }
*/
    
    /**
     Clears the data model and its current node property.
     
     Call this method when the user chooses No Target in the Target menu.
     */
    func clearDataModel() {
        // Called from MainWindowController.clearTarget().
        elementNodeTree.removeAll()
        currentElementNodePath.removeAll()
        currentElementNode.removeAll(keepingCapacity: true)
    }
    
    func clearDataModelBeyondLevel(_ level: Int) {
        // Called from ____.
        let keepTree: [[ElementNodeInfo]] = Array(elementNodeTree[...level])// as? [[ElementNodeInfo]]
        let keepPath: [ElementNodeInfo] = Array(currentElementNodePath[...level])// as? [ElementNodeInfo]
        clearDataModel()
        elementNodeTree = keepTree
        currentElementNodePath = keepPath
        currentElementNode = keepPath.last!
        currentElementNode[.childCountKey] = (currentElementNode[.elementKey] as! AccessibleElement).AXChildren!.count
        currentElementNode.updateValue(currentElementNode, forKey: .childNodeKey)
    }
    
    func removeNodeAt(level: Int, index: Int) {
        elementNodeTree[level].remove(at: index)
        // TODO: update affected fields of surrounding nodes; e.g. index path.
    }
    
    /**
     Caches the index path of the current node, for later restoration of the data model in restoreCurrentElementIndexPath().
     
     Call this method to cache the index path before the user changes the data model temporarily. There are situations where it is useful to change the data model speculatively in order to obtain information about alternative accessibility hierarchies. To be able to restore the data model afterward, the application need only cache the initial hierarchy's index path using this method, for restoration of the data model using the restoreCurrentElementIndexPath() method shortly later. The data model should normally be restored a very short time after it was changed, before permanent intended or unintended changes occur.
     
     For example, an existing hierarchy's index path might be cached immediately before the user opens a pop-up menu in a path control to select a new hierarchy. The data model is updated repeatedly while the user moves the pointer over different menu items and submenus while the menu is open, in order to provide UI element information for use in the menu regarding a possible new selection hierarchy, and it is updated finally when the user chooses a menu item. However, the user might decide to dismiss the menu without making a choice. That decision requires the initial selection hierarchy to be restored.

     For convenience when initially caching it, the saved index path always contains the complete hierarchy from the root application UI element to the current selected element. When the data model is restored, the hierarchy is restored beyond the root application UI element even if only part of it was changed by the user.
     */
    func saveCurrentElementIndexPath() {
        // Called in the ElementPathControlManager or ListTabItemViewController menuWillOpen(_:) delegate method when the user opens the menu.
        savedCurrentElementIndexPath = indexPath(ofNode: currentElementNode)
    }
    
    func unsaveCurrentElementIndexPath() {
        // Called in OutlineTabItemViewController selectElement() when the data model is updated after the user selects a new UI element in the outline view, in several methods in ListTabItemViewController and elementPathControlManager.
        savedCurrentElementIndexPath = nil
    }
    
    /**
     Restores the data model for the current application from the index path saved in saveCurrentElementIndexPath().
     
     Call this method to restore the data model from the index path that was saved before the user changed the data model temporarily. There are situations where it is useful to change the data model speculatively in order to obtain information about alternative accessibility hierarchies. To be able to restore the data model afterward, the application need only save the initial hierarchy's index path using the saveCurrentElementIndexPath() method, for restoration of the data model using this method shortly later. The data model should normally be restored a very short time after it was changed, before permanent intended or unintended changes occur.
     
     For example, an existing hierarchy's index path might be cached immediately before the user opens a pop-up menu in a path control to select a new hierarchy. The data model is updated repeatedly while the user moves the pointer over different menu items and submenus while the menu is open, in order to provide UI element information for use in the menu regarding a possible new selection hierarchy, and it is updated finally when the user chooses a menu item. However, the user might decide to dismiss the menu without making a choice. That decision requires the initial selection hierarchy to be restored.
     
     For convenience when initially caching it, the saved index path always contains the complete hierarchy from the root application UI element to the current selected element. When the data model is restored, the hierarchy is restored beyond the root application UI element even if only part of it was changed by the user.
     */
    func restoreCurrentElementIndexPath() {
        // Called in the ElementPathControlManager or ListTabItemViewController menuWasDismissed() delegate method when the user closes the menu without selecting a menu item.
        if let savedPath = savedCurrentElementIndexPath {
            for level in 1..<savedPath.length {
                updateDataModelForCurrentElementAt(level: level, index: savedPath.index(atPosition: level))
            }
        }
        savedCurrentElementIndexPath = nil
    }
    
    // MARK: - TERMINOLOGY UPDATE UTILITIES

    /**
     Updates the terminology used in description entries in the data model.
     
     The data model's description entries are initially created using several `ElementDataModel` terminology utilities, which are called by `updateDataModel(forSystemWideElement:)`, `updateDataModel(forApplicationElement:)` and `updateDataModelForCurrentElementAt(level:index:)` to compose descriptions to be cached in the data model based on the current `TERMINOLOGY_DEFAULTS_KEY` preference setting. The `TERMINOLOGY_DEFAULTS_KEY` key and its available `Terminology` enumeration values are declared in `Defines.swift`. These terminology utilities call accessibility functions through the `PFAssistiveFramework4` framework to obtain relevant information from the target application, and they are then cached in the data model for efficient access. The user defaults setting is initialized to Natural Language at first launch, and the description utilities are called thereafter in this method only when the `Terminology` setting is changed and the cache needs to be updated. Other classes should obtain the descriptions from the accessor methods for the data model node for maximum efficiency.
     
     The Natural Language description is the element's `AXRoleDescription` attribute (or, if it has none, its `AXRole:AXSubrole` attribute), extended to include the `AXTitle` attribute, if one exists, and its zero-based row and column in the form (r/c). Most elements have an `AXRoleDescription` attribute, which typically describes the element's mandatory `AXRole` attribute and any optional `AXSubrole` attribute using natural language.
     
     The Raw (or "AX") description is the element's `AXRole:AXSubrole` attribute, extended to include the `AXTitle` attribute, if one exists, and its zero-based row and column in the form (r/c). All elements should have a required `AXRole` attribute and many elements have an optional `AXSubrole` attribute.
     
     The Accessibility Protocol description is also the element's Raw (or "AX") description, because the Accessibility Protocol applies only to attributes and actions.
     
     The AppleScript description is the element's AppleScript name, title and index, or the name and index if it has no title, or the name and title if the element is the root application UI element. The AppleScript index is calculated within the group of siblings having the same role, except that elements of unknown type are indexed by their position in all siblings no matter what type, consistently with Apple's implementation of GUI Scripting in the System Events application. Indexes are one-based for AppleScript. This method is intended only for display of the AppleScript reference; an AppleScript reference suitable for use when generating scripts is available from `descriptionForAppleScriptOfElement(_:atDepth:)`.
     
     Call this method when the user chooses a new terminology preference.
     */
    func updateTerminology() {
        // Called from BrowserTabItemViewController [and later others] updateTerminology() when the user chooses a new terminology preference, followed immediately by calls to reloadDataForRowIndexes(_:inColumn:).
        
        var node: ElementNodeInfo
        for columnIndex in 0..<elementNodeTree.count {
            for rowIndex in 0..<elementNodeTree[columnIndex].count {
                node = elementNodeTree[columnIndex][rowIndex]
                let element = node[.elementKey] as! AccessibleElement
                let indexPath = node[.indexPathKey] as! NSIndexPath
                if UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY) == Terminology.appleScript.rawValue {
                    // AppleScript descriptions were already composed and cached in updateDataModel(forApplicationElement:) and updateDataModelForCurrentElementAt(level:index:).
                    node[.briefElementDescriptionKey] = node[.briefAppleScriptDescriptionKey]
                    node[.fullElementDescriptionKey] = node[.fullAppleScriptDescriptionKey]
                } else {
                    node[.briefElementDescriptionKey] = briefDescription(ofElement: element)
                    node[.mediumElementDescriptionKey] = mediumDescription(ofElement: element, atIndexPath: indexPath)
                    node[.fullElementDescriptionKey] = fullDescription(ofElement: element, atIndexPath: indexPath)
                }
                elementNodeTree[columnIndex][rowIndex] = node
            }
        }
    }
    
    /**
     Composes and returns a brief description of an accessibility element, suitable for display in a header cell of the element column in any tab item in the main (top) split item.
     
     This method is called in the `updateDataModel…` methods to update the data model's cached description entries according to the current Terminology preference setting. It calls the specific description method corresponding to the Terminology setting.
     
     *See also:* `updateTerminology()`, `fullDescription(ofElement:)`, `briefNaturalDescription(ofElement:)`, `fullNaturalDescription(ofElement:)`, `briefRawDescription(ofElement:)` and `fullRawDescription(ofElement:)`.

     - parameter element: An `AccessibiltyElement` object
     
     - returns: A brief description of the element as a String
     */
    private func briefDescription(ofElement element: AccessibleElement) -> String {
        let terminology = UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY)
        switch terminology {
        case Terminology.natural.rawValue:
            return briefNaturalDescription(ofElement: element)
        case Terminology.raw.rawValue, Terminology.accessibility.rawValue:
            return briefRawDescription(ofElement: element)
        default:
            // Terminology.AppleScript.rawValue is handled in updateDataModel(forApplicationElement:) and updateDataModelForCurrentElementAt(level:index:).
            return ""
        }
    }
    
    /**
     Composes and returns a medium description of an accessibility element, suitable for display in a menu item in the path control pop-up menu in any tab item in the main (top) split item.
     
     This method is called in the `updateDataModel…` methods to update the data model's cached description entries according to the current Terminology preference setting. It calls the specific description method corresponding to the Terminology setting.
     
     *See also:* `updateTerminology()`, `fullDescription(ofElement:)`, `briefNaturalDescription(ofElement:)`, `fullNaturalDescription(ofElement:)`, `briefRawDescription(ofElement:)` and `fullRawDescription(ofElement:)`.
     
     - parameter element: An `AccessibiltyElement` object
     
     - returns: A medium description of the element as a String
     */
    private func mediumDescription(ofElement element: AccessibleElement, atIndexPath path: NSIndexPath) -> String {
        let terminology = UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY)
        switch terminology {
        case Terminology.natural.rawValue:
            return mediumNaturalDescription(ofElement: element, atIndexPath: path)
        case Terminology.raw.rawValue, Terminology.accessibility.rawValue:
            return mediumRawDescription(ofElement: element, atIndexPath: path)
        default:
            // Terminology.AppleScript.rawValue is handled in updateDataModel(forApplicationElement:) and updateDataModelForCurrentElementAt(level:index:).
            return ""
        }
    }
    
    /**
     Composes and returns a full description of an accessibility element, suitable for display in a cell of the element column in any tab item in the main (top) split item, or in a cell of the value column of the attribute table in the detail (bottom) split item.
     
     This method is called in the `updateDataModel…` methods to update the data model's cached description entries according to the current Terminology preference setting. It calls the specific description method corresponding to the Terminology setting.
     
     This method is public because the `AttributeDataSource` also needs to compute on the fly descriptions of some UI elements that are outside of the `ElementDataModel` `elementNodeTree`.
     
     *See also:* `updateTerminology()`, `briefDescription(ofElement:)`, `briefNaturalDescription(ofElement:)`, `fullNaturalDescription(ofElement:)`, `briefRawDescription(ofElement:)` and `fullRawDescription(ofElement:)`.
     
     - parameter element: An `AccessibiltyElement` object
     
     - parameter path: The index path of the element in the selected accessibility hierarchy
     
     - returns: A full description of the element as an NSAttributedString
     */
    func fullDescription(ofElement element: AccessibleElement, atIndexPath path: NSIndexPath) -> NSAttributedString {
        // Called by AttributeDataSource descriptionOfAttributeValue(_:ofType:element:).
        
        let terminology = UserDefaults.standard.integer(forKey: TERMINOLOGY_DEFAULTS_KEY)
        switch terminology {
        case Terminology.natural.rawValue:
            return fullNaturalDescription(ofElement: element, atIndexPath: path)
        case Terminology.raw.rawValue, Terminology.accessibility.rawValue:
            return fullRawDescription(ofElement: element, atIndexPath: path)
        default:
            // Terminology.AppleScript.rawValue is handled in updateDataModel(forApplicationElement:) and updateDataModelForCurrentElementAt(level:index:).
            return NSAttributedString.init(string: "")
        }
    }
    
    /**
     Composes and returns a brief natural language description of an accessibility element.
     
     The returned description is the element's `AXRoleDescription` attribute or, if it doesn't have one, its `AXRole` attribute or, if it has one, its `AXSubrole` attribute.
     
     *See also:* `updateTerminology()`, `briefDescription(ofElement:)`, `fullDescription(ofElement:)`, `fullNaturalDescription(ofElement:)`, `briefRawDescription(ofElement:)` and `fullRawDescription(ofElement:)`.
     
     - parameter element: An `AccessibiltyElement` object
     
     - returns: A brief natural language description of the element as a String
     */
    private func briefNaturalDescription(ofElement element: AccessibleElement) -> String {
        if let description: String = element.AXRoleDescription { // natural language; nil for elements that do not have an AXRoleDescription attribute
            return description
        } else {
            return briefRawDescription(ofElement: element)
        }
    }
    
    /**
     Composes and returns a medium natural language description of an accessibility element.
     
     The returned description is the element's `AXRoleDescription` attribute or, if it doesn't have one, its `AXRole` attribute or, if it has one, its `AXSubrole` attribute, extended to include the `AXTitle` attribute, if one exists, or its zero-based row.

     *See also:* `updateTerminology()`, `briefDescription(ofElement:)`, `fullDescription(ofElement:)`, `fullNaturalDescription(ofElement:)`, `briefRawDescription(ofElement:)` and `fullRawDescription(ofElement:)`.
     
     - parameter element: An `AccessibiltyElement` object
     
     - parameter path: The index path of the element in the selected accessibility hierarchy
     
     - returns: A medium natural language description of the element as a String
     */
    private func mediumNaturalDescription(ofElement element: AccessibleElement, atIndexPath path: NSIndexPath) -> String {
        var description = briefNaturalDescription(ofElement: element)
        if let title: String = element.AXTitle {
            description = "\(description) \"\(title)\""
        } else {
            description = "\(description) \(path.index(atPosition: path.length - 1)))"
        }
        return description
    }
    
    /**
     Composes and returns a full natural language description of an accessibility element.
     
     The returned description is the element's `AXRoleDescription` attribute or, if it has none, its `AXRole` attribute and any `AXSubrole` attribute in the form `AXRole:AXSubrole`, extended to include the `AXTitle` attribute, if one exists, and its zero-based row and column in the form (r/c).
     
     *See also:* `updateTerminology()`, `briefDescription(ofElement:)`, `fullDescription(ofElement:)`, `briefNaturalDescription(ofElement:)`, `briefRawDescription(ofElement:)` and `fullRawDescription(ofElement:)`.
     
     - parameter element: An `AccessibiltyElement` object
     
     - parameter path: The index path of the element in the selected accessibility hierarchy
     
     - returns: A brief natural language description of the element as an NSAttributedString
     */
    private func fullNaturalDescription(ofElement element: AccessibleElement, atIndexPath path: NSIndexPath) -> NSAttributedString {
        // Returns the element's AXRoleDescription attribute or, if it has none, its AXRole attribute and any AXSubrole attribute in the form AXRole:AXSubrole, extended to include the AXTitle attribute, if one exists, and its zero-based row and column in the form (r/c). Most elements have an AXRoleDescription attribute, which typically describes the element's mandatory AXRole attribute and any optional AXSubrole attribute using natural language. Called by fullDescriptionOfElement(_:atIndexPath:).
        
        var description = briefNaturalDescription(ofElement: element)
        if let title: String = element.AXTitle {
            description = "\(description) \"\(title)\""
        }
        description = "\(description) (\(path.index(atPosition: path.length - 1)))"
//        description = "\(description) (\(path.index(atPosition: path.length - 1))/\(path.length - 1))"
        return NSAttributedString(string:description, attributes: stringAttributes)
    }
    
    /**
     Composes and returns a brief raw description of an accessibility element.
     
     The returned description is the element's `AXRole` attribute or any `AXSubrole` attribute.
     
     *See also:* `updateTerminology()`, `briefDescription(ofElement:)`, `fullDescription(ofElement:)`, `briefNaturalDescription(ofElement:)` and `fullRawDescription(ofElement:)`.
     
     - parameter element: An `AccessibiltyElement` object
     
     - returns: A brief raw description of the element as a String
     */
    private func briefRawDescription(ofElement element: AccessibleElement) -> String {
        guard var description: String = element.AXRole else {return "<ERROR: missing AXRole attribute>"} // never nil or empty in a properly designed accessible application
        
        if let subrole: String = element.AXSubrole { // nil for elements that do not have an AXSubrole attribute
            description = subrole
        }
        return description
    }
    
    /**
     Composes and returns a medium raw description of an accessibility element.
     
     The returned description is the element's `AXRole` attribute or any `AXSubrole` attribute, extended to include the `AXTitle` attribute, if one exists, or its zero-based row.
     
     *See also:* `updateTerminology()`, `briefDescription(ofElement:)`, `fullDescription(ofElement:)`, `briefNaturalDescription(ofElement:)` and `fullRawDescription(ofElement:)`.
     
     - parameter element: An `AccessibiltyElement` object
     
     - parameter path: The index path of the element in the selected accessibility hierarchy
     
     - returns: A medium raw description of the element as a String
     */
    private func mediumRawDescription(ofElement element: AccessibleElement, atIndexPath path: NSIndexPath) -> String {

        var description = briefRawDescription(ofElement: element)
        if !description.hasPrefix("<ERROR") {
            if let title: String = element.AXTitle {
                description = "\(description) \"\(title)\""
            } else {
                description = "\(description) \(path.index(atPosition: path.length - 1))"
            }
        }
        return description
    }
    
    /**
     Composes and returns a full raw description of an accessibility element.
     
     The returned description is the element's `AXRole` attribute and any `AXSubrole` attribute in the form `AXRole:AXSubrole`, extended to include the `AXTitle` attribute, if one exists, and its zero-based row and column in the form (r/c).
     
     *See also:* `updateTerminology()`, `briefDescription(ofElement:)`, `fullDescription(ofElement:)`, `briefNaturalDescription(ofElement:)` and `briefRawDescription(ofElement:)`.

     - parameter element: An `AccessibiltyElement` object
     
     - parameter path: The index path of the element in the selected accessibility hierarchy
     
     - returns: A brief raw description of the element as an NSAttributedString
     */
    private func fullRawDescription(ofElement element: AccessibleElement, atIndexPath path: NSIndexPath) -> NSAttributedString {
        // All elements should have an AXRole attribute and many elements have an optional AXSubrole attribute. Called by fullDescriptionOfElement(_:atIndexPath:).
        
        guard var description: String = element.AXRole else {return NSAttributedString(string: "<ERROR: missing AXRole attribute>")} // never nil or empty in a properly designed accessible application
        
        if let subrole: String = element.AXSubrole { // nil for elements that do not have an AXSubrole attribute
            description = description + ":" + subrole
        }
        
        if let title: String = element.AXTitle {
            description = "\(description) \"\(title)\""
        }
        description = "\(description) (\(path.index(atPosition: path.length - 1)))"
//        description = "\(description) (\(path.index(atPosition: path.length - 1))/\(path.length - 1))"
        return NSAttributedString(string:description, attributes: stringAttributes)
    }
    
    /**
     Composes and returns a full AppleScript description of an accessibility element.
     
     This method calculates the element's AppleScript index for display in the detail (bottom) split item's attributes tab item for attributes that return a `UIElement` type. It is relatively inefficient because it must iterate over multiple siblings of the element in order to count elements of the same type separately, but there are relatively few such attributes for any given element. The elementNodeTree object cannot be used to retrieve elements displayed in the attributes tab item because they often are outside of the current accessibility selection path.
     
     *See also:* ....
     
     - parameter element: An `AccessibiltyElement` object
     
     - parameter path: The index path of the element in the selected accessibility hierarchy
     
     - returns: A full AppleScript description of the element as an `NSAttributedString`
     */
    func fullAppleScriptDescription(ofElement element: AccessibleElement) -> NSAttributedString {
        // Called by AttributeDataSource descriptionOfAttributeValue(_:ofType:element:).
        
            guard appleScriptClassNames != nil else {
                // appleScriptClassNames is a private lazy ElementDataModel property of type NSDictionary loaded from the AppleScriptRoles.plist file when ElementDataModel is initialized. Any error is reported at initialization.
                return NSAttributedString(string: "", attributes: stringAttributes)
        }
        
        // Get AppleScript role name.
        let role = element.AXRole!
        var appleScriptName = appleScriptClassNames![role] as? String
        if appleScriptName == nil {
            // If role is not listed as a key in AppleScriptRoles.plist...
            if role.hasPrefix("AX") {
                // ... but it has Apple's "AX" accessibility prefix, use "UI element".
                appleScriptName = "UI element"
            } else {
                // ... otherwise use its raw role string.
                appleScriptName = role
            }
        }
        var description = "\(appleScriptName!)"
        
        // Get AppleScript title.
        let title = element.AXTitle
        
        if role == "AXApplication" {
            // Compose full AppleScript reference as an NSAttributedString.
            description += " \(title!)" // AppleScript application references do not have an index
        } else {
            // Get AppleScript index.
            let siblingArray = element.AXParent!.AXChildren
            var sibling: AccessibleElement
            var appleScriptIndex = 0
            let countAll = element.isRole(NSAccessibility.Role.unknown.rawValue) || appleScriptName!.hasPrefix("AX")
            for index in 0..<siblingArray!.count {
                sibling = siblingArray![index] 
                if countAll {
                    // The GUI Scripting index of a UI Element whose role is unknown is its one-based index within all elements of all roles in the array.
                    appleScriptIndex += 1; // AppleScript indexes are one-based
                } else if sibling.AXRole == role {
                    // The GUI Scripting index of a UI Element whose role is known is its one-based index within all elements of the same role in the array.
                    appleScriptIndex += 1 // AppleScript indexes are one-based
                }
                if sibling.isEqual(to: element) {
                    break
                }
            }
            
            // Compose full AppleScript reference as an NSAttributedString.
            description += " \(appleScriptIndex)"
            if title != nil && !title!.isEmpty {
                description += " (\"\(title!)\")"
            }
        }
        
        return NSAttributedString(string: description, attributes: stringAttributes)
    }
    
    // MARK: - ALERTS
    
    func sheetForRolesAppleScriptFileFailedToLoad() {
        // Presents sheet to handle the failure of the RolesAppleScript.strings file to load. Called in the appleScriptClassNames variable.
        
        let alert = NSAlert();
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = NSLocalizedString("Failed to load AppleScript names", comment: "Alert message text for failed to load AppleScript names")
        alert.informativeText = NSLocalizedString("UI Browser will be unable to display AppleScript terminology. Change the Terminology setting in order to continue using UI Browser.", comment: "Alert informative text for failed to load AppleScript names")
        alert.showsHelp = true
        alert.helpAnchor = "UIBr020using0011choosetarget"
        // alert.delegate = self // needed only if the delegate overrides standard help-anchor lookup behavior, per the NSAlertDelegate reference document
        alert.beginSheetModal(for: MainWindowController.sharedInstance.window!, completionHandler: nil)
    }
    
}
