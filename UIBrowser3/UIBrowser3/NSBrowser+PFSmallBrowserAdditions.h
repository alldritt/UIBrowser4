//
//  NSBrowser+PFSmallBrowserAdditions.h
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-10-18.
//  Copyright © 2017 PFiddlesoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// AppKit's NSBrowser class has not publicly supported small or mini size browsers for many years, and Interface Builder cannot create them. Interface Builder goes so far as to revert the NSBrowser Control Size setting to Regular automatically if you attempt to set it to Small or Mini manually, and all attempts to set NSBrowser's controlSize property inherited from NSControl to Small or Mini programmatically are ignored and the value is always reported as Regular.
// This Objective-C category on NSBrowser works around this size limitation by implementing methods to set the browser's cell prototype size to NSSmallSize and create small scroll bars and column titles. To do this, an Objective-C category is required in order to access NSBrowser's _brflags private instance variable, which includes .usesSmallScrollers and .usesSmallSizeTitleFont flags. Swift extensions are unable to access AppKit classes' private instance variables.
// WARNING: The use of private Cocoa instance variables is discouraged because Apple can change them without notice in future releases of macOS. Apple has never changed these NSBrowser private instance variables. Apple announced in 2018 that it would block all use of private instance variables in a future release of macOS; see my bug report 41209462 2018-06-18, now closed.

@interface NSBrowser (PFSmallBrowserAdditions)

- (void)pfSetUsesSmallHorizontalScroller:(BOOL)flag;
- (void)pfSetUsesSmallColumnScrollers:(BOOL)flag;
- (void)pfSetUsesSmallTitleFont:(BOOL)flag;

@end
