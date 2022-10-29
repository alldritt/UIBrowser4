//
//  NSBrowser+PFSmallBrowserAdditions.m
//  UIBrowser3
//
//  Created by Bill Cheeseman on 2017-10-18.
//  Copyright © 2017 PFiddlesoft. All rights reserved.
//

#import "NSBrowser+PFSmallBrowserAdditions.h"

@implementation NSBrowser (PFSmallBrowserAdditions)

- (void)pfSetUsesSmallHorizontalScroller:(BOOL)flag {
    id scroller = [[[[self subviews] objectAtIndex:0] subviews] objectAtIndex:1];
    if ([scroller isKindOfClass:[NSScroller class]]) {
        [scroller setControlSize:(flag) ? NSControlSizeSmall : NSControlSizeRegular];
    }
}

- (void)pfSetUsesSmallColumnScrollers:(BOOL)flag {
    _brflags.usesSmallScrollers = flag;
}

- (void)pfSetUsesSmallTitleFont:(BOOL)flag {
    _brflags.usesSmallSizeTitleFont = flag;
}

@end
