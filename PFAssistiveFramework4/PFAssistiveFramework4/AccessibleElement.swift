//
//  AccessibleElement.swift
//  PFAssistiveFramework4
//
//  Created by Bill Cheeseman on 2017-03-09.
//  Copyright © 2003-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 4.0.0
//

import Cocoa
import ApplicationServices

// NOTE about the AccessibleElementDelegate formal protocol and notifications.

// Designing a framework to use a delegate protocol is useful, because a client only has to adopt the protocol by implementing its declared method to take advantage of it. The client does not have to register to observe a Notification Center notification and implement the notification method, which is a slightly busier coding task and may take up additional system resources. A limitation of using a delegate protocol, however, is that the framework can have only one delegate, while notifications can be observed by multiple objects using different classes.
// If a framework supports both a delegate protocol and notifications, the client has the best of both worlds. It can make one of its classes the delegate simply by adopting the protocol and implementing the delegate method in that class. In addition, it can register any number of other classes to observe and respond to the notification. To enable the client to use both techniques without duplicating code, a single method can act both as the delegate method and as the notification method. To do this, the method must take the notification as its parameter.
// To support a delegate protocol, the framework must create an appropriate notification object and pass it as a parameter when it calls the delegate method declared in the protocol and implemented in the delegate. To support notifications as well, the framework must separately post the notification that the client registered to observe.
// A framework that supports a delegate protocol must have a reference to the delegate. A framework whose classes support a relatively small number of long-lived objects can set its public delegate property in several ways. (1) If the object is a responder such as a view or control, its delegate property can be declared as an IBOutlet and connected in Interface Builder at build time. (2) In any case, the delegate property can be set by the client using a delegate parameter in the class's initializer at run time when an instance of the class is first created. (3) The delegate property can be set programmatically by the client after the instance is created, by directly setting the delegate property.
// None of these techniques is so easy if a framework instead supports a class that will be used to create a large number of objects of the same type very frequently. That is the case with the AccessibleElement class in the PFAssistive4 Framework. Instances of AccessibleElement must potentially be created for every user interface element in the accessibility hierarchy of the application targeted by the client application. The tree of elements can grow quite large as elements deeper in the accessibility hierarchy are accessed. Many of them may be removed from the tree, as well, every time the user narrows the path at any level of the tree.
// The PFAssistive4 Framework must track the destruction of AccessibleElement objects in the user interface as windows and menus are closed and other views and controls are hidden or removed. It does this both with a delegate protocol and Notification Center notifications, to support clients that use either or both techniques. The delegate method, elementWasDestroyed(_), also serves as the notification method. The notification object is the AccessibleElement instance that called the delegate method or posted the notification when the accessibility API AXUIElement object that it wraps was destroyed. The notification's userInfo parameter passes the AccessibleElement's cachedAttributes property (the element's role, role description, subrole, help and title), because the client can no longer obtain this information directly from the element that has been destroyed. The cached information can be used to display descriptive information about any destroyed element.
// When one of the elements is destroyed in the user interface, it and its children at all levels of the tree must respond. If the elements are configured to use delegates adopting the delegate protocol, there is only one usable way to set the framework's delegate property. The first two techniques described above are either impossible or too complicated.
// (1) An AccessibleElement's delegate property cannot be connected in Interface Builder at compile time. Its delegate property can be declared as an IBOutlet, but there is no place to create the needed instances of AccessibleElement in Main.storyboard to make their delegate outlets available for connection to the client's view controller. An AccessibleElement is not a responder such as a view or control, and new ones are created constantly.
// (2) Passing the delegate in an AccessibleElement's initializer when it is created by a client object at run time would be feasible in some scenarios; for example, when an individual AccessibleElement is needed for some temporary purpose. However, it is not feasible in the context of building up an accessibility hierarchy. The AccessibleElement class has many methods that create multiple AccessibleElement objects, such as AXChildren(). They call intermediate methods such as elementArrayAttributeValue(for:), which repeatedly calls the AccessibleElement initializer. Declaring a delegate parameter in each of these methods so that the client object and these element methods can pass it along to each element in the hierarchy would complicate the framework. In any event, it is uncommon to include the delegate as a parameter in class initializers.
// (3) That leaves setting each element's delegate property after it is created, but no later than the earliest time when it might be destroyed. A client application will normally need to monitor the destruction of user interface elements as soon as they are displayed. For a client application that displays a target's elements in a table view, an outline view or a browser view, for example, the client application's data source is the appropriate place to set up the delegate property. The data source is where the client handles the data displayed by the view's controller. UI Browser, for example, uses each of these view types to display its target's current accessibility hierarchy. The AccessibleElement objects in the hierarchy are the views' data, and they are managed by the ElementDataModel data source. The views display this data after obtaining it from the data source, and the view controllers monitor which AccessibilityElements in the data source are destroyed so they can alter their views accordingly. The view controllers are the delegates that adopt the delegate protocol by implementing the delegate method to respond to the destruction of the AccessibleElements in the data source.
// In the third scenario, it is relatively easy for the data source to set each AccessibleElement's delegate property at the same time it adds the element to the accessibility hierarchy. Unlike the AccessibleElement class, which is in an independent framework bearing no inherent relationship to the client, the data source is a custom, application-specific class designed as part of the application. The data source is intimately connected with the view controller, so the necessary information is readily available to the data source.
// In the case of UI Browser, this is done in the ElementDataModel class's updateDataModelForCurrentElementAt(level:index:) method. This data source method has access to the element currently selected by the user, known as the current element, because the element is by definition already in the data source from earlier operations, such as creating the target's root application AccessibleElement instance when a new target was chosen. This data source method creates all of the current element's child AccessibleElements by calling the appropriate PFAssistive4 Framework method; namely, AXChildren(). Immediately afterward, the data source method sets each child's delegate property, and the circle is closed.
// The PFAssistive4 Framework could have implemented all appropriate methods to take a delegate parameter, as discussed above, and the data source could have used that parameter instead of setting the delegate property directly after each element was created. However, writing a delegate parameter into every framework method that creates AccessibleElement objects would add unneeded complexity to the framework. It would also be inconsistent with the basic design idea that the framework leaves it up to its client to decide whether to use the delegate protocol or instead to register to observe notifications.
// Another approach would be to write the PFAssistive4 Framework's methods so that all of them set their delegate properties within the framework by getting the delegate from the root application AccessibleElement object, and to leave it to clients to worry only about setting the delegate property of the root application element when it is created. Each AccessibleElement instance already has a reference to its root application element.  Again, however, this would be inconsistent with the basic design idea that the framework is neutral as to whether clients should use the delegate protocol or register to observe notifications. Also, the destruction observer mechanism is not implemented by application or system-wide AccessibleElement instances, as opposed to interface instances, so focusing on setting up the delegate protocol in the root application element would be somewhat incongruous.
// The remaining question is how to tell the AccessibleElement whether it should register to observe the accessibility API's destruction notification so as to post its own destruction notification and call its delegate method. Observing an element's destruction involves some expense, so clients should be allowed to create AccessibleElement instances for purposes other than display that do not waste time dealing with their own destruction. The Objective-C way to do this would be to implement separate initializers. For Swift, we can use optional parameters.
// The AccessibleElement's designated initializer declares an optional Boolean parameter, observesDestruction, that defaults to true: init?(axElement: AXUIElement, observesDestruction: Bool = true). Because of this, the most common and complex use of AccessibleElement objects, in a data source used to display the accessibility hierarchy, requires the simplest calls to the framework. Initialize each new element by calling AccessibleElement(axElement) and set its delegate property, and by default the element will observe the destruction of the AXUIElement object it wraps, post its elementWasDestroyedNotification to the Notification Center when it is destroyed in case anybody is observing it, and, if the element property has been set by the client, call the client's elementWasDestroyed delegate method and pass the notification object to it. When a client wants to create a single, temporary AccessibleElement object, instead, without the expense of observing its destruction, the client can call the initializer with an explicit observesDestruction parameter set to false: AccessibleElement(axElement, observesDestruction: false).

// NOTE about Core Foundation types.
// Accessibility is a Core Foundation API, and it uses CFTypeRef types such as AXUIElement (formerly AXUIElementRef). AnyObject is the Swift form of Core Foundation's CFTypeRef base type, a generic object reference type used as a placeholder for Core Foundation objects. From Apple's "Using Swift with Cocoa and Objective-C (Swift 4)": "When Swift imports Core Foundation types, the compiler remaps the names of these types. The compiler removes Ref from the end of each type name because all Swift classes are reference types, therefore the suffix is redundant. The Core Foundation CFTypeRef type completely remaps to the AnyObject type. Wherever you would use CFTypeRef, you should now use AnyObject in your code."
// Accessibility API constants of type CFString (formerly CFStringRef) are typed in Swift as String. These constants must therefore be cast to type CFString when calling accessibility API functions directly and cast to type String when using the constants in Swift code such as switch statements.

// NOTE about accessibility and the process identifier (PID).
// The AccessibleElement class declared here assumes that every application and other process supporting accessibility has a valid PID and that a process without a valid PID cannot support accessibility. For this reason, AccessibleElement's init?(axElement:observesDestruction:) designated initializer fails if the provided AXUIElement object has a PID value that is nil or negative, and it always tests the result of AXUIElementGetPid(_:_:) function calls for errors and for an invalid nil or negative result. These precaustions are implemented because Apple's documentation leaves open the possibility that there may be applications or other processes that have no PID or a negative PID.
// Apple's accessibility API has only one function, AXUIElementCreateApplication(_:), that creates a new AXUIElement from scratch; that is, without deriving it from an existing AXUIElement that already has a reference to its application's PID. According to its reference documentation, the AXUIElementCreateApplication(_:) function requires "the process ID of an application" as its only parameter, and it returns the AXUIElement "representing the top-level accessibility object for the application with the specified process ID." This suggests that an AXUIElement without a PID cannot be created by an assistive application.
// The documentation for the accessibility API's AXUIElementGetPid() function similarly states without qualification that it indirectly returns "the process ID associated with the specified accessibility object." The only errors it is specifically documented to return are for illegal or invalid parameters. There is no mention of a negative indirect return value of the PID. This, too, suggests that a valid AXUIElement always has a valid PID.
// Nevertheless, the reference documentation for NSRunningApplication notes with respect to its convenience initializer, init?(processIdentifier:), that "Applications that do not have PIDs cannot be returned from this method." NSRunningApplication inherits from NSObject, so NSRunningApplication objects can also be initialized without a PID using NSObject's init() method, which according to its documentation never returns nil. All of this suggests that there may be running applications that do not have a PID. The NSRunningApplication documentation makes this explicit when it notes with respect to its processIdentifier property that "Not all applications have a pid." The processIdentifier property documentation goes on to state, "Applications without a pid return a value of -1."
// Online commentary suggests that the warnings in the NSRunningApplication documentation about applications without a PID might have been a hedge against rare or unknown situations, and we have never seen a process that has no PID or a negative PID listed in the Activity Monitor application. The AccessibleElement class nevertheless checks for an invalid nil or negative PID in case a client attempts to use a negative PID returned by the NSRunningApplication processIdentifier property.

/**
 A user interface element that can be explored, monitored and controlled by an assistive application or other accessibility client.
 
 The `AccessibleElement` class wraps a Core Foundation `AXUIElement` object. It allows an assistive application or other accessibility client to exercise all of the powers made available by Apple's accessibility API using standard Swift code. In addition, it enhances the power of the accessibility API and increases its ease of use by making familiar techniques like delegate methods and notifications readily available. These support the ability to observe the destruction of an element in the user interface.
 */
open class AccessibleElement: NSObject {
    
    // MARK: - PROPERTIES
    
    /// The Core Foundation accessibility API `AXUIElement` object represented by the `AccessibleElement`. An `AccessibleElement` with an `axElement` that has been destroyed or invalidated is considered invalid.
    public var axElement: AXUIElement
    
    /// An object that conforms to the `AccessibleElementDelegate` protocol, allowing clients to use delegate methods declared in `AccessibleElement` instead of or in addition to registering to observe notifications in order to handle the destruction of `axElement` in the user interface.
    weak public var delegate: AccessibleElementDelegate?

    // TODO: set isValid to false when axElement is invalidated.
    /// Whether the `AccessibleElement` has a valid `axElement`. Returns `true` until the `axElement` is destroyed or invalidated.
    public private(set) var isValid: Bool = false
    
    // TODO: This will have to be publicly settable, if I start setting children of destroyed elements to destroyed.
    /// Whether the `AccessibleElement` has been destroyed in the user interface, such as when a window or menu closes. Returns `true` after the destruction observer posts `kAXUIElementDestroyedNotification`.
    public private(set) var isDestroyed: Bool = false
    
    /// The `indexPath` of the `AccessibleElement` in the accessibility hierarchy. This should be set by the client when the element is added to the data source. Any user action that would change the `indexPath` should force the `AccessibleElement` to be removed and readded, so it should always be up to date.
    public var indexPath: IndexPath?
    
    /// Attributes used to describe an `AccessibleElement` after it has been destroyed. It is an array of dictionaries using accessibility API attribute constants as keys for the `AccessibleElement`'s `role` attribute and, if they exist, its `roleDescription`, `subrole`, `help` and `title` attributes.
    public var cachedAttributes: [String: String]?

    /// Required to support `isEqual(_:)`.
    override open var hash: Int {
        return Int(CFHash(self.axElement))
    }

    // MARK: - INITIALIZATION
    
    /**
     Initializes a new instance of a system-wide, application or interface AccessibleElement.
        
     A valid Core Foundation accessibility API `AXUIElement` object must be provided to enable the `AccessibleElement` to explore, monitor and control the element using Apple's accessibility API. An `AccessibleElement` with an `axElement` that has been destroyed or invalidated is considered invalid.
         
     The initializer fails if the `axElement`'s `role` attribute cannot be obtained, without regard to the nature of the error, because every `AXUIElement` must have a role attribute. This prevents creation of a new instance after an element has been destroyed. From Apple's *Application Services* reference documentation for `kAXRoleAttribute`: "All accessibility objects must include this attribute."
     
     The optional `observesDestruction` parameter defaults to `true` and may be omitted. By using the initializer with the default parameter value, the client can handle the element's destruction by implementing an `elementWasDestroyed(_:)` delegate method or registering to observe an `elementWasDestroyedNotification`. The `observesDestruction` parameter can be passed explicitly as `false` to create a temporary `AccessibleElement` for special purposes that does not observe the element's destruction; for example, to compare it with other `AccessibleElements` obtained from the user interface.
     
     Clients typically do not create new instances of `AccessibleElement` by using the designated initializer. Instead, they might create an `AccessibleElement` representing a leaf element existing in the user interface by reading the screen using a utility method such as [[[+[PFUIElement elementAtPoint:withDelegate:error:]???]]]. Alternatively, they might create a root application `AccessibleElement` using the `applicationElement(forProcessIdentifier)` class method or a system-wide `AccessibleElement` using the `systemWideElement()` class method, and then use properties such as `AXParent` or `AXChildren` to traverse the accessibility hierarchy to create `AccessibleElements` representing existing user interface elements. See PFiddlesoft's *Assistive Application Programming Guide* for more information.
         
     A client can create as many instances of `AccessibleElement` as desired, as often as desired, even if they refer to the same element. All instances that refer to the same element in the user interface are considered equal.
         
     For application elements only, the initializer sets up a class registration mechanism for possible use by subclasses.
        
     For interface elements only, the initializer creates a `cachedAttributes` array containing the `AccessibleElement`'s `role` attribute and, if they exist, its `roleDescription`, `subrole`, `help` and `title` attributes keyed to accessibility API attribute constants. The cached attributes can be used to describe a user interface element after it is destroyed. An application or system-wide element does not create a `cachedAttributes` dictionary.
     
     For interface elements only, if the `observesDestruction` parameter value is `true`, the initializer creates and installs a private accessibility API `AXObserver` object in order to be notified when the element is destroyed; for example, when a window or menu is closed. When the destruction observer callback closure declared here is triggered, it calls the `handleDestruction()` method to set the `isDestroyed` and `isValid` properties to true; it posts an `elementWasDestroyedNotification` to the Notification Center so clients can observe it; and if a delegate conforming to the `AccessibleElementDelegate` protocol has been set, it calls the delegate's `elementWasDestroyed(_:) delegate method. The `elementWasDestroyedNotification` is declared in an extension on Notification.Name at the end of this file. Application and system-wide instances do not participate in the destruction observer mechanism. The delegate parameter is optional; if omitted, it is nil.
         
     The initializer's `required` modifier is necessary because `AccessibleElement` conforms to the `NSCopying` protocol.
     
     - parameter axElement: `AXUIElement` object represented by an `AccessibleElement`.
     
     - parameter observesDestruction: `Bool` value controlling whether an `AccessibleElement` observes the destruction of the `axElement` in the user interface.
      */
    required public init?(axElement: AXUIElement, observesDestruction: Bool = true) { // designated initializer
        
        // Set the axElement property.
        self.axElement = axElement
        
        /// The element's `AXRole` attribute value.
        var role: AnyObject?
        
        // Fail if axElement has no role attribute.
        let err = AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &role)
        guard err == AXError.success else {return nil}
        
        super.init()
        
        // Handle features that differ as between system-wide, application and interface elements.
        switch role as! String {
        case kAXSystemWideRole:
            // There is only one system-wide element. It is created directly by the systemWideElement(withDelegate:) class method. A system-wide element is useful for things like finding the frontmost application or the focused accessibility element regardless of which application is currently active.
            // A system-wide elemnt's attributes are not cached because it cannot be destroyed and therefore does not participate in the destruction observer mechanism.
            
            break
            
        case kAXApplicationRole:
            // An application element may have been obtained from a property such as AXParent or AXChildren or created directly by the applicationElement(forProcessIdentifier:withDelegate:) class method.
            // An application element's attributes are not cached because it is not destroyed but just stops running and therefore does not participate in the destruction observer mechanism. Its termination can be observed using NSWorkspace and NSRunningApplication key paths).
            
            // Register an application element's class. Only application elements participate in the class registration mechanism.
            // TODO: Add class registration code, rootIndex and maybe pidNumber.
            // TODO: Remove this example code after implementing the class registry mechanism '''
            // ''' It shows how to access and use an instance's class.
            /*
             let myClass: AnyClass = type(of: self)
             print("Type of self is \(String(describing: myClass))")
             let selfIsAccessibilityElement: Bool = (myClass == AccessibleElement.self)
             print("Self is of type AccessibleElement: \(selfIsAccessibilityElement ? "YES": "NO")")
             */
            
            break
            
        default:
            // Self is an interface element. Its role is any interface element role, such as kAXButtonRole.
            
            // The cachedAttributes array contains dictionaries of type [String: String]. The cache contains the element's role attribute and, if they exist, its role description, subrole, help and title attributes keyed to accessibility API attribute constants. Any attribute that cannot be copied for any reason is omitted from the cache.
            // The optional value object indirectly returned by the AXUIElementCopyAttributeValue(_:_:_:) function is of type CFTypeRef?. All of the attribute values cached here are CFString (formerly CFStringRef) objects, but they are cast to Swift String objects to make it possible for clients to use the cache without casting.
            
            /// The element's AXRoleDescription, AXSubrole, AXHelp and AXTitle attribute values.
            var roleDescription, subrole, help, title: AnyObject? // The role attribute is declared and copied above
            
            // Cache the attributes used to describe a user interface element so they can be used after it is destroyed.
           cachedAttributes = [kAXRoleAttribute: role as! String]
            if AXUIElementCopyAttributeValue(axElement, kAXRoleDescriptionAttribute as CFString, &roleDescription) == AXError.success {
                cachedAttributes![kAXRoleDescriptionAttribute] = (roleDescription as! String)
            }
            if AXUIElementCopyAttributeValue(axElement, kAXSubroleAttribute as CFString, &subrole) == AXError.success {
                // TODO: AXUIElementCopyAttributeValue() fails randomly on kAXSubroleAttribute for unknown reasons ...
                // ... without producing an error value and without posting any information. During development, watch for this error to try to pin down the circumstances. The only impact of this issue is that the subrole attribute might not be cached.
                cachedAttributes![kAXSubroleAttribute] = (subrole as! String)
            }
            if AXUIElementCopyAttributeValue(axElement, kAXHelpAttribute as CFString, &help) == AXError.success {
                cachedAttributes![kAXHelpAttribute] = (help as! String)
            }
            if AXUIElementCopyAttributeValue(axElement, kAXTitleAttribute as CFString, &title) == AXError.success {
                cachedAttributes![kAXTitleAttribute] = (title as! String)
            }

            // TODO: Finish destruction observer code ...
            // * bring all the UIB 2.7.0 comments over
            // * Implement the refreshApplication() action method.
            // * set up ANSI Warning color in UIB when elements are destroyed, based on UIB 2.7.0 code, and make it impossible to select them (or present their cached info).
            
            if observesDestruction { // optional parameter defaults to true
                // Create and install an accessibility API AXObserver object to observe the destruction of AccessibleElement's axElement in the user interface. Application and system-wide elements do not participate in the destruction observer mechanism.
                // In Swift 3 or later, the AXObserverCreate(_:_:_:) function and the AXObserverCallback typealias it uses for the callback parameter require that the callback take the form of the closure implemented here rather than an external callback function. The observer is created using the Swift 3 or later unsafe pointer management mechanisms. This allows the callback to obtain external context; specifically, the reference to self (accessibleElement) that is passed in through the closure's refcon parameter and used to enable the closure to call back out to self's handleDestruction() method. That method has full access to the context of self because it is a member of self, and it uses it to set the AccessibleElement's isDestroyed variable, to post elementWasDestroyedNotification for client notification observers, and to call the elementWasDestroyed(_:) delegate method if implemented by the client.
                
                /// The process identifier (PID) of `axElement`'s application. Even a destroyed element has a PID.
                var pid: pid_t = 0
                var err = AXUIElementGetPid(axElement, &pid)
                
                if err == .success {
                    // The PID was successfully copied, so use it to create and install an accessibility AXObserver object.
                    
                    /// The observer's `AXObserverCallback` closure.
                    let callback: AXObserverCallback = { (observer: AXObserver, element: AXUIElement, notificationName: CFString, refcon: UnsafeMutableRawPointer?) -> Void in
                        
                        /// The `AccessibleElement` (`self`), extracted from the callback closure's `refcon` parameter. It was passed to the callback when the `axObserver` object was registered to observe `kAXUIElementDestroyedNotification`, below.
                        let accessibleElement = Unmanaged<AccessibleElement>.fromOpaque(refcon!).takeRetainedValue()
                        
                        // Tell the AccessibleElement (self) to handle the destruction of its axElement member.
                        accessibleElement.handleDestruction()
                        
                        // Invalidate the AXObserver object.
                        CFRunLoopSourceInvalidate(AXObserverGetRunLoopSource(observer))
                        }
                    
                    // Memory for the AXObserver pointer is allocated here, and it is used when the AXObserverCreate(_:_:_:) function creates the AXObserver object, next. Deallocation of the memory is deferred to the end of the initializer, after the observer has been added to the run loop.
                    /// A pointer to the `AXObserver` object.
                    let axObserverPtr = UnsafeMutablePointer<AXObserver?>.allocate(capacity: 1)
                    defer{axObserverPtr.deallocate()}
                    
                   // Create the observer.
                    err = AXObserverCreate(pid, callback, axObserverPtr)
                    
                    if err == .success {
                        // The axObserver object was successfully created, so register it to observe kAXUIElementDestroyedNotification.
                        
                        /// A pointer to `self` to be sent to the `callback` closure as external context through its `refcon` parameter.
                        let refcon = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
                        err = AXObserverAddNotification(axObserverPtr.pointee!, axElement, kAXUIElementDestroyedNotification as CFString, refcon)
                        
                        if err == .success {
                            // The axObserver object was successfully registered, so install it in the run loop. Memory for the axObserverPtr will be deallocated immediately after this statement by virtue of the defer statement above. It will be invalidated and removed from the run loop at the end of the callback closure, above.
                            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(axObserverPtr.pointee!), CFRunLoopMode.commonModes)
                        }
                    }
                }
            }
        }
        
        self.isValid = true // self has been successfully initialized
    }
    
    /**
     Handles a call from the `AXObserverCallback` closure when the `axElement` represented by this `AccessibleElement` is destroyed in the user interface; for example, when a window or menu is closed. The callback closure was set up in the designated initializer.
     
     This handler sets the element's `isDestroyed` property to `true`. The property is used, for example, to change the color of destroyed elements displayed in the master split item when its view is updated.
     
     The handler also posts `elementWasDestroyedNotification` and calls the `elementWasDestroyed(_:)` delegate method if it is implemented by the client.
     */
    func handleDestruction() {
        
        // set the AccessibleElement's isDestroyed property to true
        self.isDestroyed = true
        
        /// A `Notification` to be posted to the default Notification Center. The notification name is created in the extension on `Notification.Name` at the end of this file.
        let notification = Notification(name: Notification.Name.elementWasDestroyedNotification, object: self, userInfo: self.cachedAttributes)
        
        // Call the AccessibleElementDelegate formal protocol delegate method, if implemented, so that the delegate gets the message when axElement is destroyed in the user interface.
        self.delegate?.elementWasDestroyed(notification)

        // Post a notification so that every object that registered to observe it gets the message when axElement is destroyed in the user interface.
        NotificationCenter.default.post(notification)
    }
    
    // MARK: - CLASS METHODS
    
    /**
     Creates and returns an AccessibleElement object representing a system-wide AXUIElement object.
     
     - returns: An `AccessibleElement` with an `axElement` member having an accessibility API role of "AXSystemWide".
     */
    public class func makeSystemWideElement() -> Any? {
        // Wrapper for AXUIElementCreateSystemWide().
        let axElement = AXUIElementCreateSystemWide()
        return AccessibleElement(axElement: axElement)
    }
    
    /**
     Creates and returns an AccessibleElement object representing a root application AXUIElement object.
     
     The application's process identifier (PID) can be obtained from the `processIdentifier` property of any of the application's user interface elements or from the `NSRunningApplication` `processIdentifier` property. This initializer fails if `pid` is negative because a negative PID does not define a specific process. Apple's reference documentation for `NSRunningApplication`'s `processIdentifier` property says, "Not all applications have a pid. Applications without a pid return a value of -1." See the NOTE about accessibility and the process identifier (PID), above.

     - parameter processIdentifier: The process identifier (PID) of the application.
     
     - returns: An `AccessibleElement` with an `axElement` member having an accessibility API role of "AXApplication".
     */
    public class func makeApplicationElement(processIdentifier pid: pid_t) -> Any? {
        // Wrapper for AXUIElementCreateApplication(_:).
        guard pid >= 0 else {
            print("failed to create application element because PID is negative")
            return nil
        }
        let axElement = AXUIElementCreateApplication(pid)
        return AccessibleElement(axElement: axElement)
    }
    
    // MARK: - ACCESSIBILITY UTILITIES
    
    //  Assistive applications for computer users with disabilities, as well as many general-purpose applications that monitor or control the computer, use Apple's accessibility and Quartz Event Taps technologies. For security reasons, these technologies require one-time authorization with an administrator password. In OS X Mountain Lion 10.8 or earlier, a user could enable access globally by selecting the "Enable access for assistive devices" checkbox in Accessibility (formerly Universal Access) preferences or on a per-application basis by calling the AXMakeProcessTrusted function in an embedded helper application running as root, and global access could be granted programmatically using AppleScript. In OS X Mavericks 10.9 or later, access can only be granted manually on a per-application basis in the Privacy pane's Accessibility list in Security & Privacy preferences.
    // The isProcessTrusted() and isProcessTrustedOrPrompt() class methods here are wrappers for the two basic accessibility API functions, AXIsProcessTrusted() and AXIsProcessTrustedWithOptions(_:). The first determines whether the current application has been granted access to control the computer using accessibility features, and the second does that and also prompts the user to grant access manually and assists the user by opening the Accessibility list.
    // For more flexible user control of accessibility access, a client can make use of the AccessAuthorizer class, instead. The class makes the authorization process as simple as possible for the user by providing customizable alerts and explanations and by monitoring changes to the Accessibility list that might occur behind the user's back.
    
    public class func isProcessTrusted() -> Bool {
        // Wrapper for AXIsProcessTrusted().
        // Returns true if the calling process has been granted access to control the computer using accessibility features. This is a read-only function reporting the current state of access. It does not present an alert, add the process to the Accessibility list in the Privacy tab of Security & Privacy preferences, or have any other side effects. Call it directly instead of assigning it to a property in order to learn of accessibility changes that may have been made behind the client's back since the last call. Alternatively, register to observe the System Preferences "com.apple.accessibility.api" distributed notification to learn of accessibility changes immediately. To warn the user if access has not been granted, call isProcessTrustedOrPrompt(), instead.
        return AXIsProcessTrusted()
    }
    
    public class func isProcessTrustedOrPrompt() -> Bool {
        // Wrapper for AXIsProcessTrustedWithOptions(_:).
        // Returns true if the calling process has been granted access to control the computer using accessibility features. If access has not been granted, returns false immediately and then presents an asynchronous alert warning the user. The alert allows the user to open System Preferences or to deny access. If the user chooses to open System Preferences, the Accessibility list in the Privacy tab of Security & Privacy preferences is opened and the calling process is added to the list. It is the user's responsibility to grant accessibility manually, if desired, by unlocking System Preferences and selecting the calling process's checkbox. The appearance, wording and behavior of the alert are controlled by the system. To determine whether access has been granted without presenting a warning, call isProcessTrusted(), instead.
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    public func activateApplication() -> Bool {
        // Activates the running application owning this AccessibleElement object. See the NOTE about accessibility and the process identifier (PID), above.
        var pid: pid_t = -1
        let err = AXUIElementGetPid(axElement, &pid)
        if err == AXError.success && pid >= 0 {
            if let app = NSRunningApplication(processIdentifier: pid) {
                return app.activate(options: .activateIgnoringOtherApps)
            }
        }
        return false
    }
    
    // MARK: - ELEMENT UTILITIES

    public static func == (lhs: AccessibleElement, rhs: AccessibleElement) -> Bool {
//   public static func == (left: AccessibleElement, right: AccessibleElement) -> Bool {
        // Returns true if both AccessibleElement instances are valid and refer to the same user interface element, application element or system-wide element. This provides custom meaning for the == equivalence operator when used to compare AccessibleElement instances.
        // This operator works even if the elements are destroyed (for example, a window is closed). The AXUIElement object of a destroyed element was designed to continue to respond to CFEqual(_:_:) and to return its original process identifier (PID), although most of the accessibility API functions called on a destroyed element return errors. However, the operator returns false if either instance has been invalidated.
        return lhs.isValid && rhs.isValid && CFEqual(lhs.axElement, rhs.axElement)
    }
    
    public func isEqual(to element: AccessibleElement) -> Bool {
        // Returns true if self is equal to element in the sense of their custom == operator; that is, if both instances are valid and refer to the same user interface element, application element or system-wide element, even if the element is destroyed. However, the method returns false if the instances have been invalidated.
        // This method is more efficient than isEqual(_:). Use it only if both instances are known to be AccessibilityElements.
        return self == element
    }
    
    override open func isEqual(_ element: Any?) -> Bool {
        // Protocol method per Foundation's NSObjectProtocol.
        // Returns true if self is equal to element in the sense of their custom == operator; that is, if both instances are valid and refer to the same user interface element, application element or system-wide element, even if the element is destroyed. However, the method returns false if the instances have been invalidated; that is, if their axElement references are nil.
        // The required hash variable is created above.
        if self === element as! AccessibleElement { // pointer equality
            return true
        }
        if (element == nil) || (type(of: element) != type(of: self)) { // class inequality
            return false
        }
        return isEqual(to: element as! AccessibleElement)
    }
    
    // MARK: - ATTRIBUTES
    
    // MARK: ATTRIBUTE VALUES
    // The framework's attribute value methods get or set the value of an attribute of an AccessibleElement object given the attribute's name. Objects returned by these methods are optionals of type AnyObject?. AnyObject is the Swift form of Core Foundation's CFTypeRef base type, a generic object reference type used as a placeholder for specific Core Foundation object types such as CFString and AXUIElement.
    
    // MARK: Public methods
    // These public attribute value methods provide a general means for clients to get or set the value of any attribute of an AccessibleElement given the accessibility API attribute name. The general methods check the CFTypeRef type of the attribute to determine its Swift type. The framework's public named attribute computed properties, such as AXRole, AXParent and AXChildren, are slightly more efficient because they require no type checking.
    
    public func attributeValue(for name: String) -> AnyObject? {
        // Returns the named attribute's value as a Core Foundation object, such as a CFString, AXUIElement or CFArray object. Core Foundation accessibility API AXUIElement objects are converted to AccessibleElement objects, whether standing alone or in an array.
        guard var object = objectAttributeValue(for: name)
            else {return nil}
        
        // Process AXUIElement and CFArray attribute values.
        let objectTypeID = CFGetTypeID(object)
        if (objectTypeID == AXUIElementGetTypeID()) {
            // Convert a Core Foundation AXUIElement object to an AccessibleElement object.
            object = elementAttributeValue(for: name, objectValue: object)!
        } else if (objectTypeID == CFArrayGetTypeID()) {
            // Convert a Core Foundation [AXUIElement] array to an [AccessibleElement] array.
            if (object is [AXUIElement]) {
                object = (elementArrayAttributeValue(for: name, objectValue: object) as AnyObject)
            }
        }
        
        return object
    }
    
    public func setAttributeValue(_ object: AnyObject, for name: String) {
        // Sets the named attribute's value to a Core Foundation object, such as a CFString, AXUIElement or CFArray object. AccessibleElement objects are converted to Core Foundation accessibility API AXUIElement objects, whether standing alone or in an array.
        setObjectAttributeValue(object, for: name)
    }

    // MARK: Private methods
    // These private attribute value methods support a more efficient means for clients to get or set the value of certain specific named attributes of an AccessibleElement. The private methods are called by the framework's public named attribute computed properties, such as AXRole, AXParent and AXChildren, each of which has a known CFTypeRef type or an array of known CFTypeRef types declared in the accessibility API. As a result, none of the public properties requires the type checking done in the framework's more general public attributeValue(for:) and setAttribute(_:for:) methods. Each of these private methods returns a Swift object or an array of Swift objects corresponding to the public property's CFTypeRef, or, in the case of the AXUIElement CFTypeRef, an AccessibleElement object or an array of AccessibleElement objects. Because they require no type checking, the framework's public properties are slightly more efficient than the public attribute value methods.
    
    private func objectAttributeValue(for name: String) -> AnyObject? {
        // Returns the named attribute's value as a Core Foundation object, such as a CFString, AXUIElement or CFArray object. AXUIElement and CFArray attribute values are further processed in objectArrayAttributeValue(for:), elementAttributeValue(for:objectValue:), and elementArrayAttributeValue(for:objectValue:).
        // Wrapper for the accessibility API AXUIElementCopyAttributeValue() function.
        
        func handleError(_ error: AXError) {
            // TODO: Add error handling
        }
        
        var object: AnyObject?
        let err = AXUIElementCopyAttributeValue(axElement, name as CFString, &object)
        if err != AXError.success {
            handleError(err)
            return nil
        }
        return object
    }
    
    private func setObjectAttributeValue(_ object: AnyObject, for name: String) {
        // Sets the named attribute's value to a Core Foundation object, such as a CFString, AXUIElement or CFArray object. AXUIElement and CFArray attribute values are first processed in setObjectArrayAttributeValue(for:), setElementAttributeValue(for:objectValue:), and setElementArrayAttributeValue(for:objectValue:).
        // Wrapper for the accessibility API AXUIElementSetAttributeValue() function.
        
        func handleError(_ error: AXError) {
            // TODO: Add error handling
        }
        
        let err = AXUIElementSetAttributeValue(axElement, name as CFString, object)
        if err != AXError.success {
            handleError(err)
        }
    }
    
    private func objectArrayAttributeValue(for name: String) -> AnyObject? {
        // Returns an array of Core Foundation objects, other than Core Foundation accessibility API AXUIElement objects, that are the named attribute's value, such as an array of CFString objects.
        guard let array: [AnyObject] = objectAttributeValue(for: name) as! [AnyObject]?
            else {return nil}
        // TODO: Write this
        return array as AnyObject
    }
    
    private func elementAttributeValue(for name: String, objectValue: AnyObject?) -> AccessibleElement? {
        // Obtains a Core Foundation accessibility API AXUIElement object if not already provided by attributeValue(for:), and uses it to return an AccessibleElement object created by calling the designated initializer. [[[A delegate is not set.]]]
        guard let value: AXUIElement = (objectValue != nil) ? (objectValue as! AXUIElement) : objectAttributeValue(for: name) as! AXUIElement?
            else {return nil}
        // TODO: Add code for class registration mechanism
        return AccessibleElement(axElement: value)
    }
    
    // TODO: Write func setElementAttributeValue(_:for:)?
    /* TO BE WRITTEN
    // This should first convert the AccessibleElement object to its CFTypeRef equivalent, then call setAttributeValue(_:for:). Also need to write object array and element array setters on the same model.
    private func setElementAttributeValue(_ object: AccessibleElement, for name: String) {
    }
    */
    
    private func elementArrayAttributeValue(for name: String, objectValue: AnyObject?) -> [AccessibleElement]? {
        // Obtains an array of Core Foundation accessibility API AXUIElement objects if not already provided by attributeValue(for:), and uses it to return an array of AccessibleElement objects created by calling the designated initializer. [[[A delegate is not set.]]]
        guard let value: [AXUIElement] = (objectValue != nil) ? (objectValue as! [AXUIElement]) : objectAttributeValue(for: name) as! [AXUIElement]?
            else {return nil}
        return value.compactMap {elementAttributeValue(for:name, objectValue: $0)!}
    }
    
    // MARK: General methods
    // These general methods are public methods used by clients to get the value of any available attribute.

    // MARK: ATTRIBUTE UTILITIES
    
    public func count(for attribute: String) -> Int? {
        // Wrapper for AXUIElementGetAttributeValueCount(_:_:_:). Returns nil on error; for example, if attribute does not have an array value.
        
        func handleError(_ error: AXError) {
            // TODO: Add error handling
        }
        
        var count: Int = 0
        let err = AXUIElementGetAttributeValueCount(axElement, attribute as CFString, &count)
        guard err == AXError.success else {
            handleError(err)
            return nil
        }
        
        return count
    }
    
    public func isRole(_ role: String) -> Bool {
        // Returns YES if the AXRole attribute of self is role.
        return AXRole == role
    }

    public func childCount() -> Int {
        // Returns the number of children of self, or 0 on error; for example, if self does not have a kAXChildrenAttribute.
        guard let count = count(for: kAXChildrenAttribute) else {return 0}
        return count
    }
    
    // MARK: ATTRIBUTE PROPERTIES
    // The framework's public named attribute computed properties can be used by clients to get and set the value of a number of specific commonly used attributes of an AccessibleElement. The property name is the accessibility API attribute name. These computed properties are a convenient shorthand alternative to the framework's public general attribute value methods, valueForAttribute(_:) and setValueForAttribute(). These properties obtain the attribute value by calling Core Foundation accessibility API functions through the framework's public and private general attribute value methods.
    // Some of the attribute values returned by these properties, including AXRole, AXRoleDescription, AXSubrole and AXTitle, are obtained from cachedAttributes if self has been destroyed.
    
    // MARK: Non-Parameterized Attributes
    
    // MARK: informational attributes

    public var AXRole: String? {
        // Query the accessibility API for the role of self, falling back to cachedAttributes if it fails, for example, because the element was destroyed.
        // The init(axElement:observesDestruction:) designated initializer ensures that every AccessibleElement instance has a valid role attribute when it is created, but this property returns AXRole as an optional in case of an unexpected error.
        if let role: AnyObject = objectAttributeValue(for: kAXRoleAttribute) {
            return role as? String
        }
        return cachedAttributes?[kAXRoleAttribute]
    }
    
    public var AXSubrole: String? {
        // Query the accessibility API for the subrole of self, falling back to cachedAttributes if it fails, for example, because the element was destroyed.
        if let subrole: AnyObject = objectAttributeValue(for: kAXSubroleAttribute) {
            return subrole as? String
        }
        return cachedAttributes?[kAXSubroleAttribute]
    }
    
    public var AXRoleDescription: String? {
        // Query the accessibility API for the role description of self, falling back to cachedAttributes if it fails, for example, because the element was destroyed.
        if let roleDescription: AnyObject = objectAttributeValue(for: kAXRoleDescriptionAttribute) {
            return roleDescription as? String
        }
        return cachedAttributes?[kAXRoleDescriptionAttribute]
    }
    
    public var AXHelp: String? {
        // Query the accessibility API for the help text of self, falling back to cachedAttributes if it fails, for example, because the element was destroyed.
        if let help: AnyObject = objectAttributeValue(for: kAXHelpAttribute) {
            return help as? String
        }
        return cachedAttributes?[kAXHelpAttribute]
    }
    
    public var AXTitle: String? {
        // Query the accessibility API for the title of self, falling back to cachedAttributes if it fails, for example, because the element was destroyed.
        if let title: AnyObject = objectAttributeValue(for: kAXTitleAttribute) {
            return title as? String
        }
        // TODO: Find a way to protect against changed titles that are not cached.
        return cachedAttributes?[kAXTitleAttribute]
    }
    
    // MARK: hierarchy attributes

    public var AXParent: AccessibleElement? {
        // Query the accessibility API for the parent element of self, returning nil if self is a root application element.
        if isRole(kAXApplicationRole) {
            // TODO: How handle a system-wide element?
            // A root application element has no parent.
            return nil
        }
//            return attributeValue(for: kAXParentAttribute) as? AccessibleElement
        return elementAttributeValue(for: kAXParentAttribute, objectValue: nil)
    }
    
    public var AXChildren: [AccessibleElement]? {
        // Query the accessibility API for the children elements of self, [[[returning an empty array if self has no children???]]].
//        attributeValue(for: kAXChildrenAttribute) as? [AccessibleElement]
        elementArrayAttributeValue(for: kAXChildrenAttribute, objectValue: nil)
    }
    
    // MARK: application attributes
    
    public var AXHidden: Bool {
        get {
            CFBooleanGetValue(objectAttributeValue(for: kAXHiddenAttribute) as! CFBoolean?)
        }
        set {
            setObjectAttributeValue(newValue as CFBoolean, for: kAXHiddenAttribute)
        }
    }

}

// MARK: - EXTENSIONS

extension Notification.Name {
    /// Name of the notification posted when the `AccessibleElement` is destroyed in the client's user interface. The notification object is the `AccessibleElement` that sent the notification. The `userInfo` dictionary contains the `cachedAttributes` array.
    public static let elementWasDestroyedNotification = Notification.Name(rawValue: "PFAccessibleElementWasDestroyed")
}

// MARK: - PROTOCOLS, CONFORMANCE AND SUPPORT

// MARK: NSCopying Protocol

extension AccessibleElement: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return type(of: self).init(axElement: self.axElement)!
    }
}

// MARK: AccessibleElementDelegate Protocol

public protocol AccessibleElementDelegate: AnyObject {
    // Clients that implement this delegate method must declare that they adopt this formal protocol.
    
    func elementWasDestroyed(_ notification: Notification)
}

