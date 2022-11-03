//
//  AccessAuthorizer.swift
//  PFAccessibilityAuthorizer2
//
//  Created by Bill Cheeseman on 2017-11-07.
//  Copyright © 2017-2020 Bill Cheeseman. All rights reserved. Used by permission.
//
//  Version 2.0.0
//

import Cocoa

/**
 *PFAccessibilityAuthorizer2* is a framework to be embedded in any macOS application that uses Apple's accessibility API or Quartz event taps. It supports granting access to an assistive application to monitor or control the computer using accessibility features in OS X Yosemite 10.10 or later. It is written using Swift 4.0. It is the successor to the *QSWAccessibilityAuthorizer* Objective-C class file. It is not intended to be subclassed.
 
 Assistive applications for computer users with disabilities use Apple's accessibility and Quartz event taps technologies to monitor or control the computer, as do many general-purpose applications. For security reasons, every application that uses these technologies requires one-time authorization with an administrator password. In OS X Mountain Lion 10.8 or earlier, a user could enable access globally for all application at once by selecting the "Enable access for assistive devices" checkbox in *Accessibility* (formerly *Universal Access*) preferences or on a per-application basis by calling the `AXMakeProcessTrusted()` function in an embedded helper application running as root, and global access could be enabled programmatically using AppleScript. In OS X Mavericks 10.9 or later, however, access can only be granted manually on a per-application basis in *Security & Privacy* preferences by selecting the application's checkbox in the *Privacy* pane's *Accessibility* list. The *PFAccessibilityAuthorizer2* framework's `AccessAuthorizer` class makes the manual authorization process as easy as possible for the user by providing explanatory alerts, by programmatically opening *System Preferences* to the *Accessibility* list, and by automatically adding a checkbox for the client application to the *Accessibility* list. The `AccessAuthorizer` class can also monitor and respond to changes to the *Accessibility* list made by the user or by automated processes.
 
 The easiest way to use the framework is to create an `AccessAuthorizer` object by creating a local instance in the application delegate and calling its designated initializer in the client application delegate's `applicationWillFinishLaunching(_:)` delegate method. Nothing more is required. When the application finishes launching, if access has not already been granted, `AccessAuthorizer` automatically presents a custom application-modal dialog alerting the user that the application would like to monitor or control the computer using accessibility features and offering to open *System Prefrerences* so the user can grant access. It automatically adds a checkbox for the application to the *Privacy* pane's *Accessibility* list.  When the user grants access or changes access status thereafter in *System Preferences*, `AccessAuthorizer` will present another alert informing the user that access has been granted or denied. The user can suppress these subsequent alerts at any time by selecting the standard suppression textbox in the alert.
 
 Alternatively, `AccessAuthorizer` can be initialized by calling its convenience initializer. The convenience initializer has several parameters that can be used to control the format of the alerts. The `systemAlert` parameter can be passed in as `true` to use the built-in system modal dialog instead of the framework's custom alert to request access. The `sheets` parameter can be passed in as `true` to use document-modal sheets instead of application-modal dialogs for the alerts (except for the system alert, which is only available as an application-modal dialog and therefore ignores the `sheets` parameter). If `sheets` is `true`, the optional `parentWindow` parameter can be passed in as a reference to the client application window to which the sheet should be attached. For single-window library or "shoebox" applications, the `parentWindow` parameter can be omitted or passed in as `nil`, and the framework will automatically attach the sheets to the application's main window. If no parent window is specified and the application does not have a main window, the framework falls back to presenting an application-modal dialog.
 
 `AccessAuthorizer` can be prevented from presenting the alert requesting access when the application finishes launching simply by initializing it in the client application delegate's `applicationDidFinishLaunching(_:) delegate method, or later, instead of the `applicationWillFinishLaunching(_:)` delegate method. In that case, the alert requesting access can be presented by calling the framework's public `requestAccess()` method in response to any suitable event or user action. For example, it could be called in an action method connected to a button or menu item in the client application.
 
 The framework implements one public computed property and four public methods in addition to the designated and convenience initializers:
 
 • The `isAccessEnabled` property allows a client application to determine whether it has been granted access to the computer using accessibility features. The client can use the value returned by this property to set the state of user interface elements that depend upon accessibility being enabled or to enable or disable application functionality that depends on accessibility. It has no side effects.
 
 • The `requestAccess()` method presents an alert requesting the user to grant access to the client application to monitor or control the computer using accessibility features, if access is not already enabled for the client application. This is the same method the framework uses to present its automatic alert requesting access. When presentation of the automatic alert is prevented by initializing `AccessAuthorizer` in the client application delegate's `applicationDidFinishLaunching(_:) delegate method, this method can be called explicitly to present the alert at any time.
 
• The `openAccessibilityList(update:)` method can be used directly, but it is primarily intended to be called by action methods implemented by the client application. It opens the *Privacy* pane's *Accessibility* list in *System Preferences*. If the `addingCurrentApplication` parameter value is `false`, it opens the list without adding the client application's checkbox to the list. This is convenient after the application has been added to the list by other means, to allow the user to toggle access by manually selecting or deselecting the application's checkbox at any time. It also might be used to let the user examine the list before the application has been added to it. If the `addingCurrentApplication` parameter value is `true`, the method updates the *Accessibility* list by adding the client application's checkbox if it is not already present, and then it opens the list so the user can, if desired, select the checkbox to grant access to the application. This technique is typically used in an action method attached to a button or menu item, which might be named "Open System Preferences," to allow the user to grant or deny access by manually selecting or deselecting the application's checkbox at any time. The method should be used in this fashion whenever the application might not previously have been added to the list.
 
 • The `suppressAlerts(_:)` action method suppresses all of the framework access alerts that contain a suppression button, namely, the alerts shown by default when the user grants or denies access in System Preferences. Attach it to a button or checkbox in the client application's preferences or to a menu item in the client application's View menu, if desired. It can also be used to configure the framework so that these alerts are always suppressed, by calling it in the application delegate's `applicationDidFinishLaunching(_:)` delegate method; in that case, it may be best to omit any user interface element that would revive alerts.
 
• The `reviveAlerts(_:)` action method unsuppresses previously suppressed framework access alerts, whether they were suppressed using the standard suppression checkbox in alerts or by using the `suppressAlerts(_:)` action method. Attach it to a button or checkbox in the client application's preferences or to a menu item in the client application's `View` menu, if desired.
 
 The `didChangeAccessStatusNotification` notification is posted when access is granted or denied to the client application in *System Preferences*. The notification object is the `NSRunningApplication` `current` application that was granted or denied access in the *Accessibility* list. This notification contains a `userInfo` dictionary with an enumeration value of `Access.granted` or `Access.denied` for the key `accessStatusKey`, letting observers know whether access was granted or denied. Register to observe this notification as needed to update user interface elements in real time even while the client application is in the background.
 
 The `willPresentAccessAlertNotification` and `didDismissAccessAlertNotification` notifications are posted immediately before and after the framework presents its sheets or modal alerts informing the user that access was granted or denied. The notification object is the `NSRunningApplication` object that is the `current` application. These notifications contain a `userInfo` dictionary holding a dictionary with a value of `true` or `false` for the key `useSheetsKey`, letting observers know whether framework alerts are presented as sheets (`true`) or modal alerts (`false`). Register to observe these notifications as needed to handle any client application alert that may be open when one of these framework alerts is about to be presented and to clean up after it is dismissed.
 */
public class AccessAuthorizer: NSObject {
    // AccessAuthorizer is a subclass of NSObject because it requires some NSObject features. For example, the accessibilityListDidChange(_:) notification method performs the noteNewAccessStatus(_:) method's selector.
    
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
    
    /// Name of notification posted whenever the client application's access status changes. The notification object is the `NSRunningApplication` `current` application. The `userInfo` dictionary reports whether access was granted or denied for the key `accessStatusKey`.
    public static let didChangeAccessStatusNotification = Notification.Name(rawValue: "PFDidChangeAccessStatus")
    /// Name of notification posted when the client application's access granted or denied alert is about to be presented. The notification object is the `NSRunningApplication` `current` application. The `userInfo` dictionary reports whether the alert is a document-modal sheet instead of an application-modal dialog for the key `useSheetsKey` and (if the alert is a document-modal sheet instead of an application-modal dialog) refers to the parent window to which the sheet is attached for the key `parentWindowKey`.
    public static let willPresentAccessAlertNotification = Notification.Name(rawValue: "PFWillPresentAccessAlert")
    /// Name of notification posted when the client application's access granted or denied alert was dismissed. The notification object is the `NSRunningApplication` `current` application. The `userInfo` dictionary reports whether the alert is a document-modal sheet instead of an application-modal dialog for the key `useSheetsKey` and (if the alert is a document-modal sheet instead of an application-modal dialog) refers to the parent window to which the sheet is attached for the key `parentWindowKey`.
    public static let didDismissAccessAlertNotification = Notification.Name(rawValue: "PFDidDismissAccessAlert")
    
    // Notification userInfo keys.
    
    /// Key for `Bool` value in the `userInfo` dictionary of the `didChangeAccessStatusNotification` notification, reporting whether access was granted or denied.
    public static let accessStatusKey = "access status"
    /// Key for `Bool` value in the `userInfo` dictionaries of the `willPresentAccessAlertNotification` and `didDismissAccessAlertNotification` notifications, reporting whether the alert is a document-modal sheet instead of an application-modal dialog.
    public static let useSheetsKey = "use sheets"
    /// Key for `NSWindow` value in the `userInfo` dictionaries of the `willPresentAccessAlertNotification` and `didDismissAccessAlertNotification` notifications, refering to the parent window to which the sheet is attached if the alert is a document-modal sheet instead of an application-modal dialog.
    public static let parentWindowKey = "parent window"

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
    
    /// Enumeration value saving the access status of the client application. It is set to the current value in `init()` and updated when changed in `noteNewAccessStatus(_:)`.
    var accessStatus = Access.denied // default value
    
    /// `Bool` value controlling whether the client application presents the built-in system modal alert to request access. It defaults to `false`, causing the framework to use the framework's custom Request Access alert, instead. It is set to `true` if the convenience initializer's `systemAlert` parameter value is `true`. If `useSystemAccessAlert` is `true`, the framework ignores the `useSheets` property with respect to the built-in system modal alert because it is only available as an application-modal dialog.
    var useSystemAccessAlert = false // default value
    
    /// A `tuple` value controlling whether the client application presents the framework's alerts as document-modal sheets to request access and to notify the user that access has been granted or denied. The `flag` element of the tuple value defaults to `false`, causing the framework to use application-modal dialogs. It is set to `true` if the convenience initializer's `sheets` parameter value is `true`. If the `useSystemAccessAlert` property is `true`, the framework ignores the `useSheets` property with respect to the built-in system modal access alert because it is only available as an application-modal dialog, but the other alerts are still presented as document-modal sheets if `useSheets` is `true`.
    var useSheets: (flag: Bool, parentWindow: NSWindow?) = (false, nil) // default value
    
    /// `NSAlert` value used by `alertRequestAccess()`, `alertDidGrantAccess()` and `alertDidDenyAccess()` to hold a configured access alert while the `NSApplication` `didBecomeActiveNotification` is observed and, after a delay, calls `presentRequestSheet()` or `presentGrantOrDenySheet()`.
    var pendingAlert: NSAlert? = nil
    
    // MARK: - INITIALIZATION
    
    public override init() { // designated initializer
        // Call this designated initializer in the client application delegate's applicationWillFinishLaunching(_:) or applicationDidFinishLaunching(_:) delegate method to initialize an AccessAuthorizer object with default settings. By default, AccessAuthorizer presents a custom Request Access alert to request the user to grant access to the client application, and it uses application-modal dialogs for the Request Access alert and for the Did Grant Access and Did Deny Access alerts. To use the built-in system modal alert to request access, or to use sheets instead of modal dialogs to request access and report changes in access status, call AccessAuthorizer's convenience initializer with appropriate parameter values.
        // To present the custom Request Access alert or the built-in system modal alert to request access when the client application launches, instantiate the AccessAuthorizer object in the client application delegate's applicationWillFinishLaunching(_:) delegate method or earlier. The alert will automatically be presented when the application finishes launching.
        // To present either alert later, instead, in response to an event or a user action requiring access, instantiate the AccessAuthorizer object in the client application delegate's applicationDidFinishLaunching(_:) delegate method or later. Thereafter, when the event occurs or the user takes action requiring access, call the framework's requestAccess() method explicitly.
        
        super.init()
        
        // Register to observe the client application's didFinishLaunchingNotification notification, to manage its access status. Self is removed as an observer in applicationWillTerminate(_:) under OS X Yosemite 10.10 or earlier.
        if !NSRunningApplication.current.isFinishedLaunching {
            // Register to observe didFinishLaunchingNotification only if the client application has not yet finished launching.
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidFinishLaunching(_:)), name: NSApplication.didFinishLaunchingNotification, object: nil)
        }
        
        // Register to observe the client application's willTerminateNotification notification to remove self as a notification observer in applicationWillTerminate(_:) under OS X Yosemite 10.10 or earlier. Apple's reference documentation for NSNotificationCenter says this about removing observers: "If your app targets ... macOS 10.11 and later, you don't need to unregister an observer in its dealloc method."
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber10_10) {
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillTerminate(_:)), name: NSApplication.willTerminateNotification, object: nil)
        }
        
        // Register to observe the System Preferences "com.apple.accessibility.api" distributed notification, to learn when the user changes the access status of any application in the Privacy pane's Accessibility list in Security & Privacy preferences. The distributed notification contains nil object and userInfo values, so extraordinary measures are required to determine whether it was this application's access status that changed. See accessibilityListDidChange(_:) and noteNewAccessStatus(_:), below, for details. Self is removed as an observer in applicationWillTerminate(_:) under OS X Yosemite 10.10 or earlier.
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.accessibilityListDidChange(_:)), name: NSNotification.Name(rawValue: "com.apple.accessibility.api"), object: nil, suspensionBehavior: .deliverImmediately)
        
        // Save the access status of the client application, to compare it to the new access status in noteNewAccessStatus(_:) when it is changed. This does not add the client application to the Accessibility list.
        accessStatus.set(isAccessEnabled)
    }
    
    /**
     Convenience initializer to create an `AccessAuthorizer` object and set its principal features; namely, whether it will request access by presenting the built-in system modal alert instead of the framework's custom alert, whether it will present the alerts as document-modal sheets instead of application-modal dialogs, and, if as sheets, the client application window that they will be attached to. If the parameter values will be `false`, `false` and `nil`, respectively, it is slightly more efficient to call the designated initializer. (If the client window is a subclass of NSPanel, AccessAuthorizer will always use dialogs instead of sheets, ignoring these parameters.)
     
     To present the custom Request Access alert or the built-in system modal alert to request access when the client application launches, instantiate the `AccessAuthorizer` object in the client application delegate's `applicationWillFinishLaunching(_:)` delegate method or earlier. The alert will automatically be presented when the application finishes launching.
     
     To present either alert later, instead of at launch, in response to an event or a user action, instantiate the `AccessAuthorizer` object in the client application delegate's `applicationDidFinishLaunching(_:)` delegate method or later. Thereafter, when the event occurs or the user takes action requiring access, call the framework's `requestAccess()` method explicitly.
     
     If the `systemAlert` parameter value is true, `AccessAuthorizer` ignores the `sheets` parameter when it presents the built-in system alert because it is only available as an application-modal dialog.
     
     - parameter systemAlert: `Bool` value specifying whether the built-in system modal dialog should be used to request access, instead of the framework's custom alert.
     
     - parameter sheets: `Bool` value controlling whether alerts should be presented as document-modal sheets attached to a window, instead of application-modal dialogs.
     
     - parameter parentWindow: An `NSWindow` object representing the client application window to which sheets should be attached, or `nil` to specify the application's main window.
     */
    public convenience init(systemAlert: Bool, sheets: Bool, parentWindow: NSWindow? = nil) {
        self.init()
        
        useSystemAccessAlert = systemAlert
        useSheets = (sheets, parentWindow)
    }
    
    // MARK: - ACTION METHODS AND SUPPORT
    
    /**
     Presents an alert requesting the user to grant access to the client application to monitor or control the computer using accessibility features, if access is not already enabled for the client application. The alert offers to open *System Preferences* so the user can grant access in the *Privacy* tab's *Accessibility* list in the *Security & Privacy* pane.
     
     This method can be called automatically to present the alert at application launch. The client application need only initialize an `AccessAuthorizer` object in the application delegate's `applicationWillFinishLaunching(_:)` delegate method or earlier, and the framework does the rest. This causes the method to be called via the framework's `applicationDidFinishLaunching(_:)` notification method.
     
     The client application can also call this method explicitly later, in case the user denied access at application launch. Typically, an application would call it a second time in response to an event or user action that requires access. The application can even suppress the automatic launch-time alert and rely solely on an explicit later call to this method, by initializing `AccessAuthorizer` in the client application delegate's `applicationDidFinishLaunching(_:) delegate method or later and then calling this method in an action method attached to a button or menu item.
     
     As an alternative to requesting access in an alert, a client application can simply open the *System Preferences* *Accessibility* list directly by calling `openAccessibilityList(update:). This is useful, for example, in an action method attached to a checkbox or menu item that allows the user to enable or disable access at any time.
     
     By default, this method presents a custom application-modal alert using wording provided by the framework, if `AccessAuthorizer` is initialized using the designated initializer. Alternatively, the convenience initializer can be used with the `systemAlert` and `sheets` parameter values passed as `false`. A client application can tell the framework to use the built-in system modal alert, instead, by calling the framework's convenience initializer with a `systemAlert` parameter value of `true`. This sets the framework's `useSystemAccessAlert` instance property to `true`.
     
     Clients can present the custom alert (but not the system modal alert) as a document-modal sheet attached to a client application window, instead of an application-modal dialog, by calling the framework's convenience initializer with a `sheets` parameter value of `true` and an appropriate window reference as its `parentWindow` parameter value. This sets the `flag` element of the `useSheets` instance property to `true`. The `parentWindow` parameter is optional; it can be omitted or passed as `nil` to attach the sheet to the client application's main window, a convenience typically used by a single-window library or "shoebox" application.
     
     The framework is designed to require that the alert's format be specified once when `AccessAuthorizer` is initialized. To ensure a consistent user experience, the alert's format cannot be changed later.
     
     *See also:* `applicationDidFinishLaunching(_:)`.
     
     - note: There is no equivalent *QSWAccessibilityAuthorizer* method.
     */
    @objc public func requestAccess() {
        if !isAccessEnabled {
            if useSystemAccessAlert {
                let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
                AXIsProcessTrustedWithOptions(options) // ignore result
            } else {
                updateAccessibilityList() // add this application's checkbox to the Accessibility list
                alertRequestAccess()
            }
        }
    }
    
    /**
     Adds the client application to the *Accessibility* list in the *Security & Privacy* pane's *Privacy* tab in *System Preferences*, if necessary, without opening the list.
     
     Call this method before presenting a custom accessibility alert or opening the list for the user, to ensure that the application's checkbox is in the list for the user to select or deselect when it is opened. The built-in system alert adds the application to the list automatically.
     
     *See also:* `openAccessibilityList(update:)`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `- updateAccessibilityList:`.
     */
    func updateAccessibilityList() {
        // Setting the option dictionary's value to false for the kAXTrustedCheckOptionPrompt key is not needed because the AXIsProcessTrustedWithOptions(_:) function is documented to behave the same when nil is passed in the parameter.
        AXIsProcessTrustedWithOptions(nil); // ignore result
    }
    
    /**
     Opens the *Accessibility* list in the *Security & Privacy* pane's *Privacy* tab in *System Preferences*, without presenting an alert.
     
     If the `addApplication` parameter value is `true`, this method adds the calling application to the *Accessibility* list. It does not remove it from the list or change the state of its checkbox if it is already in the list.
     
     Access cannot be granted or denied programmatically for security reasons. The user must unlock *System Preferences* with an administrator password before making changes. The user can add an application to the list by dragging and dropping its icon if it is not already in the list. Selecting or deselecting its checkbox enables or disables access manually.
     
     Connect an action method calling this method to a button or menu item, which might be named "Open System Preferences," to help the user to enable or disable access at any time. This method should be called with the `addApplication` parameter value set to `true` whenever the application might not previously have been added to the *Accessibility* list, typically the first time an access alert is presented. There is no harm in calling this method with the parameter value set to `true` after the application has been added to the list, because it does not add duplicates. However, it can be called with the parameter value set to `false` whenever the calling application is known to be in the *Accessibility* list already, for example, when an alert is presented in response to a notification that the value of the checkbox has changed (such as `alertDidGrantAccess()` and `alertDidDenyAccess()`). It could also be used in this fashion to view the list before the application is added to it.
     
     *See also:* `updateAccessibilityList()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* methods are `-openAccessibilityList:` and `-updateAndOpenAccessibilityList:`.
     
     - parameter addApplication: Bool value controlling whether the client application is added to the *Accessibility* list before it is opened.
     
     */
    public func openAccessibilityList(update: Bool) {
        if update {
            updateAccessibilityList()
        }

        // Opens the Accessibility list in the Security & Privacy pane's Privacy tab in System Preferences.
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    
    /**
     Suppresses all of the framework's access alerts that contain a suppression button; namely, the alerts shown by default when the user grants or denies access in *System Preferences*.
     
     Connect this action method to a button or checkbox in application preferences or a menu item in the application's `View` menu, if desired. It can also be used to configure the framework so that these alerts are always suppressed, by calling it in the application delegate's `applicationDidFinishLaunching(_:)` delegate method; in that case, it may be best to omit any user interface element that would revive alerts.
     
     *See also:* `reviveAlerts(_:)`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-suppressAlerts:`.
     
     - parameter sender: The object that sent the action.
     */
    @IBAction public func suppressAlerts(_ sender: Any) {
        UserDefaults.standard.set(true, forKey:AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
    }
    
    /**
     Unsuppresses previously suppressed framework access alerts, whether they were suppressed using the standard suppression checkbox in an alert or by using the `suppressAlerts(_:)` action method.
     
     Connect this action method to a button or checkbox in application preferences or a menu item in the application's `View` menu, if desired.
     
     *See also:* `suppressAlerts(_:)`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-reviveAlerts:`.
     
     - parameter sender: The object that sent the action.
     */
    @IBAction public func reviveAlerts(_ sender: Any) {
        UserDefaults.standard.set(false, forKey:AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
    }
    
    // MARK: - NOTIFICATION METHODS AND SUPPORT
    
    /**
     Presents an alert requesting the user to grant access when the client application finishes launching.
     
     This notification method is called only if `AccessAuthorizer` was initialized in the client application delegate's `applicationWillFinishLaunching(_:)` delegate method or earlier. The framework's designated initializer registers to observe the `NSApplication.didFinishLaunchingNotification` notification only if it is called before the client application is finished launching. Otherwise, if `AccessAuthorizer` was initialized in the client application delegate's `applicationDidFinishLaunching(_:)` delegate method or later, the application must call the `requestAccess()` method explicitly at an appropriate time.
     
     The built-in system modal alert is used to request access if the framework's `useSystemAccessAlert` property is `true`. If the `useSystemAccessAlert` property is `false`, the framework's custom Request Access alert is used, instead. The custom alert is presented as an application-modal alert by default, but it is presented as a document_modal sheet if the framework's `useSheets` property is `true`. If the `useSystemAccessAlert` property is `true`, the framework ignores the `useSheets` property because the built-in system alert is available only as an application-modal dialog.
     
     *See also:* `requestAccess()`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-applicationDidFinishLaunching:`.
     
     - parameter notification: A notification named `didFinishLaunchingNotification`. Calling the object method of this notification returns the `NSApplication` object itself.
     */
    @objc func applicationDidFinishLaunching(_ notification: NSNotification) {
        requestAccess()
    }
    
    /**
     Removes the framework as an observer of local and distributed notifications.
     
     This notification method is called in OS X Yosemite 10.10 or earlier when the client application is about to terminate. In Yosemite or earlier, the framework's designated initializer registers to observe the `NSApplication.willTerminateNotification` notification.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-applicationWillTerminate:`.
     
     - parameter notification: A notification named `willTerminateNotification`. Calling the object method of this notification returns the `NSApplication` object itself.
     */
    @objc func applicationWillTerminate(_ notification: NSNotification) {
        // Apple's reference documentation for NSNotificationCenter says this about removing observers: "If your app targets ... macOS 10.11 and later, you don't need to unregister an observer in its dealloc method."
        DistributedNotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    /**
     Tests whether the *System Preferences* accessibility notification that triggered this method was reporting a change in the client application's access status and, if so, calls noteNewAccessStatus(_:).
     
     This notification method is called when `AccessAuthorizer` receives a distributed notification posted by *System Preferences* due to a change in the *Accessibility* list. The framework's designated initializer registers `AccessAuthorizer` to observe the distributed notification named "com.apple.accessibility.api". The notification does not specify which application's access status changed, so further steps are necessary to determine whether it was the client application's status that changed and, if so, whether its access is now enabled or disabled.
     
     To make the determination, this method creates a scheduled repeating timer that waits up to a second for the client application to register its new access status, in case it was in fact the client application whose status was changed. If a change in the client application's status is detected during that period, the method then calls the `noteNewAccessStatus(_:)` method to act on the change. It is not safe to make the determination immediately upon receipt of the distributed notification, because the client application may not register the change internally before `AccessAuthorizer` receives the distributed notification. Experimentation demonstrates that the client application can sometimes take almost a second to register the change in its access status, so waiting only until the next iteration of the run loop is not sufficient.
     
     *See also:* `noteNewAccessStatus(_:)`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-didToggleAccessStatus:`.
     
     - parameter notification: The "com.apple.accessibility.api" distributed notification.
     */
    @objc func accessibilityListDidChange(_ notification: NSNotification) {
        // This timer requires macOS Sierra 10.12 or later.
        var elapsedTime = 0.0
        let maxTime = 1.0
        let timeInterval = 0.1
        var status = Access.denied // initialize status
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) {
            timer in
            status.set(self.isAccessEnabled)
            if status != self.accessStatus {
                // The client application's access status changed.
                self.noteNewAccessStatus(status)
                timer.invalidate()
            }
            elapsedTime += timeInterval
            if elapsedTime > maxTime {
                timer.invalidate()
            }
        }
    }
    
    /**
     Presents an alert and posts notifications about a change in the client application's access status.
     
     This method is called by the `accessibilityListDidChange(_:)` notification method after it determines that a distributed notification posted by *System Preferences* was due to a change in the client application's access status.
     
     *See also:* `accessibilityListDidChange(_:)`.
     
     - note: The equivalent *QSWAccessibilityAuthorizer* method is `-noteNewAccessStatus`.
     */
    func noteNewAccessStatus(_ status: Access) {
        // Update the accessStatus instance property.
        accessStatus = status
        
        // Close any open accessAuthorizer sheet before presenting a new sheet.  It is the application's responsibility to close any open sheets or modal alerts that are unrelated to accessAuthorizer in response to this notification.
        if !UserDefaults.standard.bool(forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey) {
            if useSheets.flag {
                let oldSheet = useSheets.parentWindow?.attachedSheet // useSheets.parentWindow may be nil if application is using modal alerts
                if oldSheet != nil {
                    useSheets.parentWindow?.endSheet(oldSheet!) // sheet functionality was moved from NSApplication to NSWindow in OS X Mavericks 10.9
                    oldSheet!.orderOut(self)
                }
            }
        }
        
        // Post a didChangeAccessStatusNotification notification and present an alert if alerts are not suppressed.
        if status == .granted {
            // Access was granted.
            NotificationCenter.default.post(name: AccessAuthorizer.didChangeAccessStatusNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.accessStatusKey: true])
            if !UserDefaults.standard.bool(forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey) {
                alertDidGrantAccess()
            }
        } else {
            // Access was denied.
            NotificationCenter.default.post(name: AccessAuthorizer.didChangeAccessStatusNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.accessStatusKey: false])
            if !UserDefaults.standard.bool(forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey) {
                alertDidDenyAccess()
            }
        }
    }
    
    // MARK: - ALERTS
    
    /* NOTE about the name of the application requiring access:
     
     The AccessAuthorizer alerts are written on the understanding that the client application, referred to by NSRunningApplication's `current` property, is the application that requires access. The application's name displayed in the alerts is obtained by getting the client application's displayName from the File Manager. The displayName is preferred for display per Apple Technical Q&A QA1544 because it reflects any change made in the Finder.
     
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
        alert.informativeText = NSLocalizedString("To grant access, open the Security & Privacy pane in System Preferences and select “\(applicationName)” in the Privacy tab's Accessibility list. An administrator password may be required to unlock System Preferences.", comment: "Informative text for request access alert")
        alert.addButton(withTitle: NSLocalizedString("Open System Preferences", comment: "Name of Open System Preferences button"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Name of Cancel button"))
        pendingAlert = alert

        // Present the alert as a sheet or dialog.
        if useSheets.flag {
            if NSApp.isActive {
                presentRequestSheet()
            } else {
                // The presentRequestSheet() method tries to attach the sheet to the client application's main window if useSheets.flag is true but useSheets.parentWindow is nil. However, the NSApplication mainWindow property is nil when the application is in the background. This method therefore activates the client application before presenting the sheet. Furthermore, Apple's reference documentation for activate(ignoringOtherApps:) warns that "there may be a time lag before the app activates—you should not assume the app will be active immediately after sending this message." This method therefore observes NSApplicationDelegate's didBecomeActiveNotification to delay presenting the sheet until the client application becomes active. If the client application does not have a main window and NSApp.mainWindow therefore remains nil, or if main window is an NSPanel, presentRequestSheet() falls back to presentRequestDialog().
                NotificationCenter.default.addObserver(self, selector: #selector(presentRequestSheet), name: NSApplication.didBecomeActiveNotification, object: nil) // removed in presentRequestSheet()
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            presentRequestDialog()
        }
    }
    
    /**
     Presents an alert informing the user that the client application was denied access to monitor or control the computer using accessibility features.
     
     This method is called in the framework's `noteNewAccessStatus(_:)` method after access for this application is changed from `enabled` to `disabled` in *System Preferences*.
     
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
        alert.informativeText = NSLocalizedString("To grant access again, open the Security & Privacy pane in System Preferences and select “\(applicationName)” in the Privacy tab's Accessibility list. An administrator password may be required to unlock System Preferences.", comment: "Informative text for access denied alert")
        alert.showsSuppressionButton = true
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: "Name of Continue button"))
        // alert.addButton(withTitle: NSLocalizedString("Open System Preferences", comment: "Name of Open System Preferences button"))
        pendingAlert = alert

        // Present the alert as a sheet or dialog.
        if useSheets.flag {
            if NSApp.isActive {
                presentGrantOrDenySheet()
            } else {
                // The presentGrantOrDenySheet() method tries to attach the sheet to the client application's main window if useSheets.flag is true but useSheets.parentWindow is nil. However, the NSApplication mainWindow property is nil when the application is in the background, as it will be if, for example, the user is changing the Accessibility list in Security & Privacy preferences. This method therefore activates the client application before presenting the sheet. Furthermore, Apple's reference documentation for activate(ignoringOtherApps:) warns that "there may be a time lag before the app activates—you should not assume the app will be active immediately after sending this message." This method therefore observes NSApplicationDelegate's didBecomeActiveNotification to delay presenting the sheet until the client application becomes active. If the client application does not have a main window and NSApp.mainWindow therefore remains nil, or if main window is an NSPanel, presentGrantOrDenySheet() falls back to presentGrantOrDenyDialog().
                NotificationCenter.default.addObserver(self, selector: #selector(presentGrantOrDenySheet), name: NSApplication.didBecomeActiveNotification, object: nil) // removed in presentGrantOrDenySheet()
                NSApp.activate(ignoringOtherApps: true)
           }
        } else {
            presentGrantOrDenyDialog()
        }
    }

    /**
     Presents an alert informing the user that the client application was granted access to monitor or control the computer using accessibility features.

     This method is called in the framework's `noteNewAccessStatus(_:)` method after access for this application is changed from `disabled` to `enabled` in *System Preferences*.
     
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
        alert.informativeText = NSLocalizedString("To deny access again, open the Security & Privacy pane in System Preferences and deselect “\(applicationName)” in the Privacy tab's Accessibility list. An administrator password may be required to unlock System Preferences.", comment: "Informative text for access granted alert")
        alert.showsSuppressionButton = true
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: "Name of Continue button"))
        // alert.addButton(withTitle: NSLocalizedString("Open System Preferences", comment: "Name of Open System Preferences button"))
        pendingAlert = alert

        // Present the alert as a sheet or dialog.
        if useSheets.flag {
            if NSApp.isActive {
                presentGrantOrDenySheet()
            } else {
                // The presentGrantOrDenySheet() method tries to attach the sheet to the client application's main window if useSheets.flag is true but useSheets.parentWindow is nil. However, the NSApplication mainWindow property is nil when the application is in the background, as it will be if, for example, the user is changing the Accessibility list in Security & Privacy preferences. This method therefore activates the client application before presenting the sheet. Furthermore, Apple's reference documentation for activate(ignoringOtherApps:) warns that "there may be a time lag before the app activates—you should not assume the app will be active immediately after sending this message." This method therefore observes NSApplicationDelegate's didBecomeActiveNotification to delay presenting the sheet until the client application becomes active. If the client application does not have a main window and NSApp.mainWindow therefore remains nil, or if main window is an NSPanel, presentGrantOrDenySheet() falls back to presentGrantOrDenyDialog().
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
            if returnCode == NSApplication.ModalResponse.alertFirstButtonReturn {
                self.openAccessibilityList(update: false)
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
        if returnCode == NSApplication.ModalResponse.alertFirstButtonReturn {
            openAccessibilityList(update: false)
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
        
        // Post a willPresentAccessAlertNotification.
        NotificationCenter.default.post(name: AccessAuthorizer.willPresentAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: useSheets.flag, AccessAuthorizer.parentWindowKey: window as Any])

        // Present the alert.
        alert.beginSheetModal(for: window!, completionHandler: {
            (returnCode: NSApplication.ModalResponse) in
            
            // Handle suppression button state.
            if alert.suppressionButton!.state == NSControl.StateValue.on {
                UserDefaults.standard.set(true, forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
            }
            
            // Post a didDismissAccessAlertNotification for sheet.
            NotificationCenter.default.post(name: AccessAuthorizer.didDismissAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: self.useSheets.flag, AccessAuthorizer.parentWindowKey: window as Any])
            
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
        
        // Post a willPresentAccessAlertNotification.
        NotificationCenter.default.post(name: AccessAuthorizer.willPresentAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: useSheets.flag])

        // Present the alert.
        let _ = alert.runModal()
        
        // Handle suppression button state.
        if alert.suppressionButton!.state == NSControl.StateValue.on {
            UserDefaults.standard.set(true, forKey: AccessAuthorizer.accessChangedAlertsSuppressedDefaultsKey)
        }
        
        // Post a didDismissAccessAlertNotification.
        NotificationCenter.default.post(name: AccessAuthorizer.didDismissAccessAlertNotification, object: NSRunningApplication.current, userInfo: [AccessAuthorizer.useSheetsKey: self.useSheets.flag])
        
        // Reset pendingAlert
        pendingAlert = nil
    }
    
}
