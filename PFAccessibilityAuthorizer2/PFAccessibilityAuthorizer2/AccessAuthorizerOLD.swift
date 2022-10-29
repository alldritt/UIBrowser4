//
//  AccessAuthorizer.swift
//  PFAccessibilityAuthorizer2
//
//  Created by Bill Cheeseman on 2017-11-07.
//  Copyright © 2017 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 2.0.0
//

import Cocoa

/**
 *PFAccessibilityAuthorizer2* is a framework to be embedded in any macOS application that uses Apple's accessibility API or Quartz event taps. It supports granting access to an assistive application to monitor or control the computer using accessibility features in OS X Yosemite 10.10 or later. It is written using Swift 4.0. It is the successor to the *QSWAccessibilityAuthorizer* Objective-C class file. It is not intended to be subclassed.
 
 Assistive applications for computer users with disabilities use Apple's accessibility and Quartz event taps technologies to monitor or control the computer, as do many general-purpose applications. For security reasons, every application that uses these technologies requires one-time authorization with an administrator password. In OS X Mountain Lion 10.8 or earlier, a user could enable access globally for all application at once by selecting the "Enable access for assistive devices" checkbox in *Accessibility* (formerly *Universal Access*) preferences or on a per-application basis by calling the `AXMakeProcessTrusted()` function in an embedded helper application running as root, and global access could be enabled programmatically using AppleScript. In OS X Mavericks 10.9 or later, however, access can only be granted manually on a per-application basis in *Security & Privacy* preferences by selecting the application's checkbox in the *Privacy* pane's *Accessibility* list. The *PFAccessibilityAuthorizer2* framework's `AccessAuthorizer` class makes the manual authorization process as easy as possible for the user by providing explanatory alerts, by programmatically opening *System Preferences* to the *Accessibility* list, and by automatically adding a checkbox for the client application to the *Accessibility* list. The `AccessAuthorizer` class can also monitor and respond to changes to the *Accessibility* list made by the user or by automated processes.
 
 To use the framework, add it to a client application project as an embedded framework. Instantiate and initialize an `AccessAuthorizer` object by calling its designated initializer in the application delegate's `applicationWillFinishLaunching(_:)` delegate method, or earlier. `AccessAuthorizer` must be initialized before the client application delegate's `applicationDidFinishLaunching(_:)` delegate method is called, so that `AccessAuthorizer` will be timely registered as an observer of the client application's `NSApplication.didFinishLaunchingNotification` notification. `AccessAuthorizer`'s `useSheets` property must be set up in the client application before it finishes launching, because `AccessAuthorizer` may display its first alert in its own `applicationDidFinishLaunching(_:)` notification method.
 
 The framework can be used without calling any of its methods other than its designated initializer. By default, if access has not previously been granted to the client application, the framework automatically presents a custom modal alert when it has finished launching, offering to open *System Preferences* so the user can grant access. It also automatically adds a checkbox for the application to the *Privacy* pane's *Accessibility* list. Thereafter, whenever the user enables or disables access in *System Preferences*, the framework brings the client application forward and presents a modal alert advising that access has been granted or denied and explaining how to turn it back off or on. A standard suppression checkbox allows the user to suppress these alerts going forward.
 
 The framework implements one public computed property and four public methods in addition to the designated initializer, all of which are optional:
 
 • The `isAccessEnabled` property allows a client application to determine whether it has been granted access to the computer using accessibility features. The client can use the value returned by this property to set the state of user interface elements that depend upon accessibility being enabled or to enable or disable application functionality that depends on accessibility. It has no side effects.
 
 • The `openAccessibilityList(addingCurrentApplication:)` method can be used directly, but it is primarily intended to be called by action methods implemented by the client application. It opens the *Privacy* pane's *Accessibility* list in *System Preferences*. If the `addingCurrentApplication` parameter value is `false`, it opens the list without adding the client application's checkbox to the list. This technique is convenient after the application has been added to the list by other means, to allow the user to toggle access by manually selecting or deselecting the application's checkbox at any time. It also might be used to let the user examine the list before the application has been added to it. If the `addingCurrentApplication` parameter value is `true`, the method updates the *Accessibility* list by adding the client application's checkbox if it is not already present, and then it opens the list so the user can, if desired, select the checkbox to grant access to the application. This technique is typically used in an action method attached to a button or menu item, which might be named "Open System Preferences," to allow the user to grant or deny access by manually selecting or deselecting the application's checkbox at any time. The method should be used in this fashion whenever the application might not previously have been added to the list.
 
 • The `suppressAlerts(_:)` action method suppresses all of the framework access alerts that contain a suppression button, namely, the alerts shown by default when the user grants or denies access in System Preferences. Attach it to a button or checkbox in the client application's preferences or to a menu item in the client application's View menu, if desired. It can also be used to configure the framework so that these alerts are always suppressed, by calling it in the application delegate's `applicationDidFinishLaunching(_:)` delegate method; in that case, it may be best to omit any user interface element that would revive alerts.
 
• The `reviveAlerts(_:)` action method unsuppresses previously suppressed framework access alerts, whether they were suppressed using the standard suppression checkbox in alerts or by using the `suppressAlerts(_:)` action method. Attach it to a button or checkbox in the client application's preferences or to a menu item in the client application's `View` menu, if desired.
 
 • The `requestAccess()` method ....
 
 // TODO: change this to describe the new convenience intializer, and move it up to the top of the list.
 • The `useSheets(_:withParentWindow:)` method configures the framework so that its alerts are presented as sheets (set the `flag` parameter value to `true`) or modal alerts (set the `flag` parameter value to `false`). If `flag` is `true`, the `parentWindow` parameter value must be set to the window to which the sheets will be attached. If `flag` is `false`, the `parentWindow` parameter value is ignored. The default is to use modal alerts. If sheets are preferred, this method should be called in the client application delegate's `applicationWillFinishLaunching(_:)` delegate method.
 
 The `didToggleAccessNotification` notification is posted when access is granted or denied to the client application in *System Preferences*. The notification object is the `NSRunningApplication` `current` application that was granted or denied access in the Accessibility list. This notification contains a `userInfo` dictionary with an enumeration value of `Access.granted` or `Access.denied` for the key `accessStatusKey`, letting observers know whether access was granted or denied. Register to observe this notification as needed to update user interface elements in real time even while the client application is in the background.
 
 The `willPresentAccessAlertNotification` and `didDismissAccessAlertNotification` notifications are posted immediately before and after the framework presents its sheets or modal alerts informing the user that access was granted or denied. The notification object is the `NSRunningApplication` object that is the `current` application. These notifications contain a `userInfo` dictionary holding a dictionary with a value of `true` or `false` for the key `useSheetsKey`, letting observers know whether framework alerts are presented as sheets (`true`) or modal alerts (`false`). Register to observe these notifications as needed to handle any client application alert that may be open when one of these framework alerts is about to be presented and to clean up after it is dismissed.
 */
public class AccessAuthorizer: NSObject {
    // AccessAuthorizer is a subclass of NSObject because it requires some NSObject features. For example, the didToggleAccess(_:) notification method performs the noteNewAccessStatus() method's selector.
    
    // MARK: - PROPERTIES
    
    // MARK: Public properties
    
    /**
     Bool value reporting whether access has been granted to the client application to monitor or control the computer using accessibility features.
    
     This computed property does not present an alert, and it does not add the client application to the *Privacy* pane's *Accessibility* list in *Security & Privacy* preferences.
     */
    public var isAccessEnabled: Bool {
        return AXIsProcessTrusted()
    }
    
    // Notification names.
    
    /// Name of notification posted whenever the client application's access status changes in System Preferences.
    public static let didToggleAccessNotification = Notification.Name(rawValue: "PFDidToggleAccess")
    /// Name of notification posted when the client application's access granted or denied alert is about to be presented.
    public static let willPresentAccessAlertNotification = Notification.Name(rawValue: "PFWillPresentAccessAlert")
    /// Name of notification posted when the client application's access granted or denied alert was dismissed.
    public static let didDismissAccessAlertNotification = Notification.Name(rawValue: "PFDidDismissAccessAlert")
    
    // Notification userInfo keys.
    
    /// Key for `userInfo` `Access` enumeration value in `didToggleAccessNotification` notification.
    public static let accessStatusKey = "access status"
    /// Key for `userInfo` Bool value in `willPresentAccessAlertNotification` and `didDismissAccessAlertNotification` notifications.
    public static let useSheetsKey = "use sheets on parent window"
    
    /// Access-changed-alerts-are-suppressed key for user defaults.
    public static let accessChangedAlertsSuppressedDefaultsKey = "access changed alerts are suppressed"
    
    // MARK: Internal properties
    
    /// Enumeration type for saving the access status of the client application as 'Access.granted' or 'Access.denied'.
    enum Access {
        case granted, denied
        mutating func set(_ flag: Bool) {
            self = flag ? .granted : .denied
        }
    }
    
    /// Enumeration value saving the access status of the client application. It is set to the current value in `init()` and updated when changed in `noteNewAccessStatus()`.
    var accessStatus = Access.denied // default value
    
    /// `Bool` value controlling whether the client application presents the built-in system modal access alert to request access. It defaults to `false`, causing the framework to use the framework's custom Request Access alert, instead. It is set to `true` if the convenience initializer's `systemAlert` parameter value is `true`. If `useSystemModalAccessAlert` is `true`, the framework ignores the `useSheets` property with respect to the built-in system modal access alert because it is only available as a modal alert..
    var useSystemModalAccessAlert = false // default value
    
    /// A `tuple` value controlling whether the client application presents the framework's alerts as document-modal sheets to request access and to notify the user that access has been granted or denied. The `flag` element of the tuple value defaults to `false`, causing the framework to use application-modal dialogs. It is set to `true` if the convenience initializer's `sheets` parameter value is `true`. If the `useSystemModalAccessAlert` property is `true`, the framework ignores the `useSheets` property with respect to the built-in system modal access alert because it is only available as an application-modal dialog, but the other alerts are still presented as document-modal sheets if `useSheets` is `true`.
    var useSheets: (flag: Bool, parentWindow: NSWindow?) = (false, nil) // default value
    
    /// `NSAlert` value used by `alertRequestAccess()`, `alertDidGrantAcces()` and `alertDidDenyAccess()` to hold a configured access alert while the `NSApplication` `didBecomeActiveNotification` is observed and, after a delay, calls `presentRequestAccessSheet()` or `presentGrantOrDenySheet()`.
    var pendingAlert: NSAlert? = nil
    
    // MARK: - INITIALIZATION
    
   public override init() { // designated initializer
    // Call this designated initializer in the client application delegate's applicationWillFinishLaunching(_:) or applicationDidFinishLaunching(_:) delegate method to instantiate an AccessAuthorizer object and initialize it with default settings. By default, AccessAuthorizer presents a custom Request Access alert to request the user to grant access to the client application, and it uses modal alerts for the Request Access alert and for the Did Grant Access and Did Deny Access alerts. To use the built-in system modal alert to request access, or to use sheets instead of modal alerts to request access and report changes in access status, call AccessAuthorizer's convenience initializer with appropriate parameter values.
    // To present the custom Request Access alert or the built-in system modal alert to request access when the client application launches, instantiate the AccessAuthorizer object in the client application delegate's applicationWillFinishLaunching(_:) delegate method. Nothing more is required. The alert will automatically be presented when the application finishes launching.
    // To present either alert later, instead, in response to an event or a user action, instantiate the AccessAuthorizer object in the client application delegate's applicationDidFinishLaunching(_:) delegate method. Thereafter, when the event occurs or the user takes action requiring access, call the framework's requestAccess() method.
    
        super.init()
    
        // Register to observe the client application's didFinishLaunchingNotification and willTerminateNotification notifications, to manage its access status. Self is removed as an observer in applicationWillTerminate(_:).
    if !NSRunningApplication.current.isFinishedLaunching {
        // Register to observe didFinishLaunchingNotification only if the client application has not yet finished launching.
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidFinishLaunching), name: NSApplication.didFinishLaunchingNotification, object: nil)
    }
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillTerminate), name: NSApplication.willTerminateNotification, object: nil)

        // Register to observe the System Preferences "com.apple.accessibility.api" distributed notification, to learn when the user toggles access for any application in the Privacy pane's Accessibility list in Security & Privacy preferences. The notification contains nil object and userInfo values, so extraordinary measures are required to determine whether it was this application's accessibility status that changed. See didToggleAccess(_:) and noteNewAccessStatus(), below, for details. Self is removed as an observer in applicationWillTerminate(_:).
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.didToggleAccess), name: NSNotification.Name(rawValue: "com.apple.accessibility.api"), object: nil, suspensionBehavior: .deliverImmediately)
        
        // Save the access status of the client application, to compare it to the new access status in noteNewAccessStatus() when it is changed. This does not add the client application to the Accessibility list.
        accessStatus.set(isAccessEnabled)
   }
    
    public convenience init(systemAlert: Bool, sheets: Bool, parentWindow: NSWindow? = nil) {
        assert(sheets == false || parentWindow != nil, "sheets is true, but parentWindow is nil.")
        
        self.init()
        
        useSystemModalAccessAlert = systemAlert
        useSheets = (sheets, nil)
//       useSheets = (sheets, parentWindow!)
    }
    
    // MARK: - ACTION METHODS AND SUPPORT
    
    // TODO: fix the markup
    /**
     Presents an alert requesting the user to grant access to the client application to monitor or control the computer using accessibility features, if access is not already enabled for the client application.
     
     This method is called internally by the *PFAccessibilityAuthorizer2* framework's `applicationDidFinishLaunching(_:)` notification method. To present the alert, the client application need only instantiate and initialize an `AccessAuthorizer` object in the application delegate's `applicationWillFinishLaunching(_:)` delegate method. The framework does the rest.
     
     By default, the method presents a modal alert. The alert uses custom wording provided by the framework because the `systemAlert` parameter value is passed as `false` when this method is called in the framework's `applicationDidFinishLaunching(_:) notification method. A client application can cause the framework to use the built-in system modal alert, instead, by calling the framework's convenience initializer with a `useSystemAlert` parameter value of `true`. This sets the framework's `useSystemModalAccessAlert` property to `true`, which causes the framework's `applicationDidFinishLuaunching(_:)` notification method to pass a `systemAlert` parameter value of `true` in the call to this method.
     
     Clients can present the custom alert (but not the system alert) in the form of a sheet attached to a client application window, instead of a modal alert, by calling the framework's convenience initializer with a `useSheets` parameter value of `true` and an appropriate window reference as its optional `parentWindow` parameter value. This sets the `flag` element of the `useSheets` instance property to `true` and the `parentWindow` element to a reference to the client application window specified in the `window` parameter value.
     
     *See also:* `applicationDidFinishLaunching(_:)`.
     
     - note: There is no equivalent *QSWAccessibilityAuthorizer* method.
     
     - parameter systemAlert: Bool value controlling whether the client application uses the built-in modal alert provided by the system instead of the custom framework alert used by default.
     */
    public func requestAccess() {
        // Called in the applicationDidFinishLaunching(_:) notification method.
        
        if !isAccessEnabled {
            if useSystemModalAccessAlert {
                let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
                AXIsProcessTrustedWithOptions(options) // ignore result
            } else {
                updateAccessibilityList() // add this application's checkbox to the Accessibility list
                alertRequestAccess()
            }
        }
    }
    
    /**
     Adds the client application to the *Accessibility* list in the *Security & Privacy* pane's *Privacy* tab in *System Preferences*, if necessary.
     
     This method adds the calling application to the *Accessibility* list without opening the list. Call this method before presenting a custom accessibility alert and opening the list for the user, to ensure that the application's checkbox is in the list for the user to select or deselect when it is opened. The built-in system alert adds the application to the list automatically.
     
     *See also:* `openAccessibilityList(addingCurrentApplication:)`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `- updateAccessibilityList:`.
     */
    func updateAccessibilityList() {
        // Setting the option dictionary's value to false for the kAXTrustedCheckOptionPrompt key is not needed because the AXIsProcessTrustedWithOptions(_:) function is documented to behave the same when NULL is passed in the parameter.
        AXIsProcessTrustedWithOptions(nil); // ignore result
    }
    
    /**
     Opens the *Accessibility* list in the *Security & Privacy* pane's *Privacy* tab in *System Preferences*, without presenting an alert.
     
     If the `addApplication` parameter value is `true`, this method adds the calling application to the *Accessibility* list. It does not remove it from the list or change the state of its checkbox if it is already in the list.
     
     Access cannot be granted or denied programmatically for security reasons. This method opens the *Accessibility* list for the user without presenting an alert. The user must unlock the preference pane with an administrator password before making changes. The user can add an application to the list by dragging and dropping its icon. Selecting or deselecting its checkbox enables or disables access for it manually.
     
     Connect an action method calling this method to a button or menu item, which might be named "Open System Preferences," to help the user to enable or disable access manually at any time. This method should be called with the `addApplication` parameter value set to `true` whenever the application might not previously have been added to the *Accessibility* list, typically the first time an access alert is presented. There is no harm in calling this method with the parameter value set to `true` after the application has been added to the list, because it does not add duplicates. However, it can be called with the parameter value set to `false` whenever the calling application is known to be in the *Accessibility* list already, for example, when an alert is presented in response to a notification that the value of the checkbox has changed (such as `alertDidGrantAccess()` and `alertDidDenyAccess()`). It could also be used in this fashion to view the list before the application is added to it.
     
     *See also:* `updateAccessibilityList()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* methods are `-openAccessibilityList:` and `-updateAndOpenAccessibilityList:`.
     
     - parameter addApplication: Bool value controlling whether the client application is added to the *Accessibility* list before it is opened.
     
     */
    public func openAccessibilityList(addingCurrentApplication addApplication: Bool) {
        if addApplication {
            updateAccessibilityList()
        }
        
        // Based on the example in Technical Note TN2084 - Using AppleScript Scripts in Cocoa Applications.
        if let script = NSAppleScript(source:"tell application \"System Preferences\"\ntell pane id \"com.apple.preference.security\" to reveal anchor \"Privacy_Accessibility\"\nactivate\nend tell") {
            script.executeAndReturnError(nil) // ignore return value and any error
        }
    }
    
    /**
     Suppresses all of the *PFAccessibilityAuthorizer2* access alerts that contain a suppression button; namely, the alerts shown by default when the user grants or denies access in *System Preferences*.
     
     Connect this action method to a button or checkbox in application preferences or a menu item in the application's `View` menu, if desired. It can also be used to configure *PFAccessibilityAuthorizer2* so that these alerts are always suppressed, by calling it in the application delegate's `applicationDidFinishLaunching(_:)` delegate method; in that case, it may be best to omit any user interface element that would revive alerts.
     
     *See also:* `reviveAlerts(_:).
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-suppressAlerts:`.
     
     - parameter sender: The object that sent the action.
     */
    @IBAction public func suppressAlerts(_ sender: Any) {
        UserDefaults.standard.set(true, forKey:AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
    }
    
    /**
     Unsuppresses previously suppressed *PFAccessibilityAuthorizer2* access alerts, whether they were suppressed using the standard suppression checkbox in an alert or by using the suppressAlerts(_:) action method.
     
     Connect this action method to a button or checkbox in application preferences or a menu item in the application's `View` menu, if desired.
     
     *See also:* `suppressAlerts(_:).
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-reviveAlerts:`.
     
     - parameter sender: The object that sent the action.
     */
    @IBAction public func reviveAlerts(_ sender: Any) {
        // Unsuppresses previously suppressed QSWAccessibilityAuthorizer alerts, whether they were suppressed using the standard suppression checkbox in an alert or by using the -suppressAlerts action method.
        // Connect this action method to a button or checkbox in application preferences or a menu item in the application's View menu, if desired.
        UserDefaults.standard.set(false, forKey:AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
    }
    
    // MARK: - NOTIFICATION METHODS AND SUPPORT
    
    /**
     Presents an alert requesting the user to grant access to the client application.
     
     This notification method is called only if `AccessAuthorizer` was instantiated and initialized in the client application delegate's `applicationWillFinishLaunching(_:)` delegate method or earlier, because the framework's designated initializer registers to observe the `NSApplication.didFinishLaunchingNotification` notification only if it is called before the client application is finished launching. Otherwise, if `AccessAuthorizer` was instantiated and initialized in the client application delegate's `applicationDidFinishLaunching(_:)` delegate method or later, the application must call the `requestAccess()` method explicitly at an appropriate time.
     
     The built-in system modal alert is used to request access if the framework's `useSystemModalAccessAlert` property is `true`. If the `useSystemModalAccessAlert` property is `false`, the framework's custom Request Access alert is used, instead. The custom alert is presented as a modal alert by default, but it is presented as a sheet if the framework's `useSheets` property is `true`. If the `useSystemModalAccessAlert` property is `true`, it ignores the `useSheets` property because the built-in system alert is available only as a modal alert.
     
     *See also:* `requestAccess()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-applicationDidFinishLaunching:`.
     
     - parameter notification: the NSApplication.didFinishLaunchingNotification notification.
     */
    @objc func applicationDidFinishLaunching(_ notification: NSNotification) {
        // Request the user to grant access if access is not currently authorized. Adds this application to the System Preferences Accessibility list if it is not already in the list.
        requestAccess()
    }
    
    // TODO: The removeObserver documentation says unregistering is not needed in macOS 10.11 and later.
    /**
     Removes the framework as an observer of local and distributed notifications.
     
     This notification method is called when the client application is about to terminate. The framework's designated initializer registers to observe the `NSApplication.willTerminateNotification` notification.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-applicationWillTerminate:`.
     
     - parameter notification: the NSApplication.willTerminateNotification notification.
     */
    @objc func applicationWillTerminate(_ notification: NSNotification) {
        DistributedNotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    // TODO: Can I devise a notification to get this exactly right?
    /**
     Performs the noteNewAccessStatus(_) method's selector after a short delay, to present an alert and post notifications when the access status of the client application changes.
     
     This notification method is called every time the client application's access status changes from `disabled` to `enabled` or from `enabled` to `disabled`. To do this, the framework's designated initializer registers `AccessAuthorizer` to observe the *System Preferences* distributed notification named "com.apple.accessibility.api".
     
     The method delays 0.5 seconds before performing the `noteNewAccessStatus()` method. The delay is necessary because experimentation suggests that the change usually takes effect in the next iteration of the run loop after the notification is posted, although sometimes the change is picked up at the time of the notification and sometimes as much as half a second after the time of the notification. Trying to get the the "before" value when the notification is received is unreliable, because distributed notifications are relatively slow and the notification sometimes captures the "after" value. Also, Apple might revise the notification mechanism in the future so that *System Preferences* always reports the "after" value when the notification is posted. The framework therefore captures the initial value in the `accessStatus` property in the designated initializer and updates it in noteNewAccessStatus() shortly after a change is detected.
     
     *See also:* `noteNewAccessStatus()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-didToggleAccessStatus:`.
     
     - parameter notification: the "com.apple.accessibility.api" distributed notification.
     */
    @objc func didToggleAccess(_ notification: NSNotification) {
        perform(#selector(noteNewAccessStatus), with: nil, afterDelay: 0.5) // 0.5 seconds
    }

    /**
     Presents an alert and posts notifications when the access status of the client application changes.
     
     This method is performed by the `didToggleAccess(_:)` notification method shortly after the client application's access status changes from `disabled` to `enabled` or from `enabled` to `disabled`.
     
     *See also:* `didToggleAccess(_:)`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-noteNewAccessStatus`.
     */
    @objc func noteNewAccessStatus() {
        let oldAccessStatus = accessStatus // "before" value
        accessStatus.set(isAccessEnabled) // new or "after" value
        
        if accessStatus != oldAccessStatus { // if they are different, the user must have changed this application's access status, and we therefore know that the Accessibility List has already been updated to add this application.
            
            // Close any open accessAuthorizer sheet before presenting new sheet.  It is the application's responsibility to close any open sheets or modal alerts that are unrelated to accessAuthorizer in response to this notification. (Can't close a modal alert from outside, but new modal alert will be presented when user closes any open accessAuthorizer modal alert.)
            if !UserDefaults.standard.bool(forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey) {
                if useSheets.flag {
                    let oldSheet = useSheets.parentWindow?.attachedSheet // useSheets.parentWindow may be nil if application is using modal alerts
                    if oldSheet != nil {
                        useSheets.parentWindow?.endSheet(oldSheet!) // sheet functionality was moved from NSApplication to NSWindow in OS X Mavericks 10.9
                        oldSheet!.orderOut(self)
                    }
                }
            }
            
            // Post a didToggleAccessNotification, and present an alert if not suppressed.
            if accessStatus == .granted {
                // Access was granted.
                NotificationCenter.default.post(name: AccessAuthorizer.didToggleAccessNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.accessStatusKey: true])
                if !UserDefaults.standard.bool(forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey) {
                    alertDidGrantAccess()
                }
            } else {
                // Access was denied.
                NotificationCenter.default.post(name: AccessAuthorizer.didToggleAccessNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.accessStatusKey: false])
                if !UserDefaults.standard.bool(forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey) {
                    alertDidDenyAccess()
                }
            }
        }
    }
    
    // MARK: - ALERTS
    
    /* NOTE about the name of the application requiring access:
     
     The AccessAuthorizer alerts are written on the understanding that the client application, referred to by NSRunningApplication's `current` property, is the application that requires access. The application's name displayed in the alerts is obtained by getting the client application's displayName from the File Manager. The displayName is preferred per Apple Technical Q&A QA1544 because it reflects any change made in the Finder.
     
     This works correctly when the client application is being run normally as a built application launched by the Finder or, for example, by an AppleScript script. The alerts report that the client application is the application that requires access.
     
     However, when the client application is being run in debug mode in Xcode, Xcode is the application that requires access. The built-in system access alert presented by the AXIsProcessTrustedWithOptions(_:) accessibility API function correctly displays Xcode's name in these circumstances. But, for the PFAccessibilityAuthorizer2 framework's custom alerts, a reliable way to identify the application requiring access in debug mode has not been found.
     
     Getting the name using the NSWorkspace frontmostApplication or menuBarOwningApplication property, when the application launches and before it is brought to the front by a message such as activateIgnoringOtherApps, does yield the correct behavior whether the application is run from the Finder or in debug mode in Xcode. However, it does not display the correct name in alerts that are presented after the application has been brought to the front. Also, the alert incorrectly identifies "AppleScript Editor" as the application requiring access if the application is run from AppleScript Editor using the statement 'run application "<application name>"'. We have also unsuccessfully tried the UNIX parent application, the application that launched the application, and the embedded Applescript command 'name of current application'. Inquiries on Apple's developer mailing lists have not elicited an answer.
     
     When you are testing a client application that uses the PFAccessibilityAuthorizer2 framework, you will just have to remember to grant or deny access to Xcode in the System preferences Accessibility list, even though these alerts ask you to grant access to the client application.
     */
    
    /**
     Presents a custom alert requesting the user to grant the client application access to monitor or control the computer using accessibility features, if access is not already enabled when the application is launched.
     
     This method is called in the framework's `requestAccess()` method, which is called in the framework's `applicationDidFinishLaunching(_:)` notification method or directly by the client application.
     
     The alert is presented as a document-modal sheet if the `useSheets.flag` instance property is `true`, or as an application-modal dialog if `useSheets.flag` is `false`. If presented as a sheet, the sheet is attached to the client application window specified by `useSheets.parentWindow`.
     
     If `useSheets.parentWindow` is `nil`, the sheet is attached to the client application's main window, if it has one. This is useful for single-window library or "shoebox" applications. If the main window is `nil`, the alert is presented as an application-modal dialog.
     
     This custom alert is presented if the framework's designated initializer is called to initialize the `AccessAuthorizer` object, or if a `systemAlert` parameter value of `false` is passed in when calling the framework's convenience initializer. To present the built-in system modal alert to request access, instead, pass a `systemAlert` parameter value of `true` when calling the framework's convenience initializer.
     
     *See also:* `requestAccess()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-alertAccessNotAllowed`.
     */
    func alertRequestAccess() {

        // Get the name of the application requiring access. The displayName is preferred per Apple Technical Q&A QA1544 because it reflects any change made in the Finder.
        guard let path = NSRunningApplication.current.bundleURL?.path else {
            assertionFailure("Failed to obtain the application's bundle URL needed to display its name.")
            return
        }
        /// The client application's display name.
        let applicationName = FileManager.default.displayName(atPath: path)

        // Create and configure a custom alert to use instead of the built-in system modal alert.
        /// The Request Access alert.
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = NSLocalizedString("“\(applicationName)” would like to monitor or control this computer using accessibility features.", comment: "Message text for accessibility not allowed alert")
        alert.informativeText = NSLocalizedString("To grant access, open Security & Privacy preferences and select “\(applicationName)” in the Privacy tab's Accessibility list. An administrator password may be required to unlock System Preferences.", comment: "Informative text for request access alert")
        alert.addButton(withTitle: NSLocalizedString("Deny", comment: "Name of Deny button"))
        alert.addButton(withTitle: NSLocalizedString("Open System Preferences", comment: "Name of Open System Preferences button"))
        pendingAlert = alert

        // Present the alert as a sheet or dialog.
        if useSheets.flag {
            if NSApp.isActive {
                presentRequestSheet()
            } else {
                // The presentRequestSheet() method tries to attach the sheet to the client application's main window if useSheets.flag is true but useSheets.parentWindow is nil. However, the NSApplication mainWindow property is nil when the application is in the background. This method therefore activates the client application before presenting the sheet. Apple's reference documentation for activate(ignoringOtherApps:) warns that "there may be a time lag before the app activates—you should not assume the app will be active immediately after sending this message." This method therefore observes NSApplicationDelegate's didBecomeActiveNotification to delay presenting the sheet until the client application becomes active. If the client application does not have a main window and NSApp.mainWindow therefore remains nil, presentRequestSheet() falls back to presentRequestDialog().
                NotificationCenter.default.addObserver(self, selector: #selector(presentRequestSheet), name: NSApplication.didBecomeActiveNotification, object: nil) // removed in presentRequestSheet()
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            presentRequestDialog()
        }
    }
    
    /**
     Presents an alert informing the user that the client application was denied access to monitor or control the computer using accessibility features.
     
     This method is called in the framework's `noteNewAccessStatus()` method after access for this application is changed from `enabled` to `disabled` in *System Preferences*.
     
     It posts the `willPresentAccessAlertNotification` and `didDismissAccessAlertNotification` notifications so the client application can monitor alert suppression, if desired.

     The client application can prevent this alert from being presented by calling the suppressAlerts(_:) action method in, for example, the applicationDidFinishLaunching(_:) delegate method.
     
     *See also:* `alertDidGrantAccess()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-alertAccessDenied`.
     */
    func alertDidDenyAccess() {
        
        // Get the name of the application requiring access. The displayName is preferred for display per Apple Technical Q&A QA1544 because it reflects any change made in the Finder.
        guard let path = NSRunningApplication.current.bundleURL?.path else {
            assertionFailure("Failed to obtain the application's bundle URL needed to display its name.")
            return
        }
        /// The client application's display name.
        let applicationName = FileManager.default.displayName(atPath: path)

        // Create and configure an alert.
        /// The Did Deny Access alert.
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = NSLocalizedString("“\(applicationName)” was denied access to this computer using accessibility features.", comment: "Message text for accessibility denied alert")
        alert.informativeText = NSLocalizedString("To grant access again, open Security & Privacy preferences and select “\(applicationName)” in the Privacy tab's Accessibility list. An administrator password may be required to unlock System Preferences.", comment: "Informative text for access denied alert")
        alert.showsSuppressionButton = true
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: "Name of Continue button"))
        alert.addButton(withTitle: NSLocalizedString("Open System Preferences", comment: "Name of Open System Preferences button"))
        pendingAlert = alert

        // Post willPresentAccessAlertNotification. The didDismissAccessAlertNotification is posted in presentGrantOrDenySheet() or presentGrantOrDenyDialog().
        NotificationCenter.default.post(name: AccessAuthorizer.willPresentAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: useSheets.flag])
        
        // Present the alert as a sheet or dialog.
        if useSheets.flag {
            if NSApp.isActive {
                presentGrantOrDenySheet()
            } else {
                // The presentGrantOrDenySheet() method tries to attach the sheet to the client application's main window if useSheets.flag is true but useSheets.parentWindow is nil. However, the NSApplication mainWindow property is nil when the application is in the background, as it will be if, for example, the user is changing the Accessibility list in Security & Privacy preferences. This method therefore activates the client application before presenting the sheet. Apple's reference documentation for activate(ignoringOtherApps:) warns that "there may be a time lag before the app activates—you should not assume the app will be active immediately after sending this message." This method therefore observes NSApplicationDelegate's didBecomeActiveNotification to delay presenting the sheet until the client application becomes active. If the client application does not have a main window and NSApp.mainWindow therefore remains nil, presentGrantOrDenySheet() falls back to presentGrantOrDenyDialog().
                NotificationCenter.default.addObserver(self, selector: #selector(presentGrantOrDenySheet), name: NSApplication.didBecomeActiveNotification, object: nil) // removed in presentGrantOrDenySheet()
                NSApp.activate(ignoringOtherApps: true)
           }
        } else {
            presentGrantOrDenyDialog()
        }
    }

    /**
     Presents an alert informing the user that the client application was granted access to monitor or control the computer using accessibility features.

     This method is called in the framework's `noteNewAccessStatus()` method after access for this application is changed from `disabled` to `enabled` in *System Preferences*.
     
     It posts the `willPresentAccessAlertNotification` and `didDismissAccessAlertNotification` notifications so the client application can monitor alert suppression, if desired.
     
     The client application can prevent this alert from being presented by calling the suppressAlerts(_:) action method in, for example, the applicationDidFinishLaunching(_:) delegate method.
     
     *See also:* `alertDidDenyAccess()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-alertAccessGranted`.
     */
    func alertDidGrantAccess() {
        
        // Get the name of the application requiring access. The displayName is preferred for display per Apple Technical Q&A QA1544 because it reflects any change made in the Finder.
        guard let path = NSRunningApplication.current.bundleURL?.path else {
            assertionFailure("Failed to obtain the application's bundle URL needed to display its name.")
            return
        }
        /// The client application's display name.
        let applicationName = FileManager.default.displayName(atPath: path)
        
        // Create and configure an alert.
        /// The Did Grant Access alert.
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = NSLocalizedString("“\(applicationName)” was granted access to this computer using accessibility features.", comment: "Message text for accessibility granted alert")
        alert.informativeText = NSLocalizedString("To deny access again, open Security & Privacy preferences and deselect “\(applicationName)” in the Privacy tab's Accessibility list. An administrator password may be required to unlock System Preferences.", comment: "Informative text for access granted alert")
        alert.showsSuppressionButton = true
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: "Name of Continue button"))
        alert.addButton(withTitle: NSLocalizedString("Open System Preferences", comment: "Name of Open System Preferences button"))
        pendingAlert = alert
        
        // Post willPresentAccessAlertNotification. The didDismissAccessAlertNotification is posted in presentGrantOrDenySheet() or presentGrantOrDenyDialog().
        NotificationCenter.default.post(name: AccessAuthorizer.willPresentAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: useSheets.flag])
        
        // Present the alert as a sheet or dialog.
        if useSheets.flag {
            if NSApp.isActive {
                presentGrantOrDenySheet()
            } else {
                // The presentGrantOrDenySheet() method tries to attach the sheet to the client application's main window if useSheets.flag is true but useSheets.parentWindow is nil. However, the NSApplication mainWindow property is nil when the application is in the background, as it will be if, for example, the user is changing the Accessibility list in Security & Privacy preferences. This method therefore activates the client application before presenting the sheet. Apple's reference documentation for activate(ignoringOtherApps:) warns that "there may be a time lag before the app activates—you should not assume the app will be active immediately after sending this message." This method therefore observes NSApplicationDelegate's didBecomeActiveNotification to delay presenting the sheet until the client application becomes active. If the client application does not have a main window and NSApp.mainWindow therefore remains nil, presentGrantOrDenySheet() falls back to presentGrantOrDenyDialog().
                NotificationCenter.default.addObserver(self, selector: #selector(presentGrantOrDenySheet), name: NSApplication.didBecomeActiveNotification, object: nil) // removed in presentGrantOrDenySheet()
                NSApp.activate(ignoringOtherApps: true)
           }
        } else {
            presentGrantOrDenyDialog()
        }
    }
    
    /**
     Presents the pending Request Access alert as a document-modal sheet. The sheet is attached to the client application window specified by the `useSheets.parentwindow` instance property or, if the `parentWindow` element is `nil`, then to its main window. If the main window is `nil`, presents the alert as an application-modal dialog.
     */
    @objc func presentRequestSheet() {
        guard let alert = pendingAlert else {return}
        
        // Set the parent window.
        var window = useSheets.parentWindow
        if window == nil {
            window = NSApp.mainWindow
            if window == nil {
                presentRequestDialog()
                return
            }
        }
        
        // Present the alert.
        alert.beginSheetModal(for: window!, completionHandler: {
            (returnCode: NSApplication.ModalResponse) in
            
            // Handle button clicked.
            if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                self.openAccessibilityList(addingCurrentApplication: false)
            }
            
            // Remove any applicationDidBecomeActiveNotification observer.
            NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
            
            // Reset pendingAlert
            self.pendingAlert = nil
        })
    }
    
    /**
     Presents the pending Request Access alert as an application-modal dialog.
     */
    @objc func presentRequestDialog() {
        guard let alert = pendingAlert else {return}
        
        alert.window.preventsApplicationTerminationWhenModal = false
        
        // Present the alert.
        let returnCode = alert.runModal()
        
        // Handle button clicked.
        if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
            openAccessibilityList(addingCurrentApplication: false)
        }
        
        // Reset pendingAlert
        pendingAlert = nil
    }

    /**
     Presents the pending Access Granted or Access Denied alert as a document-modal sheet. The sheet is attached to the client application window specified by the `useSheets.parentwindow` instance property or, if the `parentWindow` element is `nil`, then to its main window. If the main window is `nil`, presents the alert as an application-modal dialog.
     */
    @objc func presentGrantOrDenySheet() {
        guard let alert = pendingAlert else {return}
        
        // Set the parent window.
        var window = useSheets.parentWindow
        if window == nil {
            window = NSApp.mainWindow
            if window == nil {
                presentGrantOrDenyDialog()
                return
            }
        }
        
        // Present the alert.
        alert.beginSheetModal(for: window!, completionHandler: {
            (returnCode: NSApplication.ModalResponse) in
            
            // Handle suppression button state.
            if alert.suppressionButton!.state == NSControl.StateValue.on {
                UserDefaults.standard.set(true, forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
            }
            
            // Post a didDismissAccessAlertNotification for sheet.
            NotificationCenter.default.post(name: AccessAuthorizer.didDismissAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: self.useSheets.flag])
            
            // Handle button clicked.
            if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                self.openAccessibilityList(addingCurrentApplication: false)
            }
            
            // Remove any applicationDidBecomeActiveNotification observer.
            NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
            
            // Reset pendingAlert
            self.pendingAlert = nil
        })
    }
    
    /**
     Presents the pending Access Granted or Access Denied alert as an application-modal dialog.
     */
    @objc func presentGrantOrDenyDialog() {
        guard let alert = pendingAlert else {return}
        
        alert.window.preventsApplicationTerminationWhenModal = false
        
        // Present the alert.
        let returnCode = alert.runModal()
        
        // Handle suppression button state.
        if alert.suppressionButton!.state == NSControl.StateValue.on {
            UserDefaults.standard.set(true, forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
        }
        
        // Post a didDismissAccessAlertNotification for sheet.
        NotificationCenter.default.post(name: AccessAuthorizer.didDismissAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: self.useSheets.flag])
        
        // Handle button clicked.
        if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
            openAccessibilityList(addingCurrentApplication: false)
        }
        
        // Reset pendingAlert
        pendingAlert = nil
    }
    
}
