//
//  SourceListColoredView.h
//  WiredAppKit
//
//  Created by Rafael Warnault on 04/05/2020.
//  Copyright © 2020 Read-Write. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WISourceListColoredView : NSView {
    NSColor *_backgroundColor;
    BOOL _observingKeyState;
}

@property (nonatomic, assign, getter = isObservingKeyState) BOOL observingKeyState;
@property (nonatomic, strong) NSColor *backgroundColor;

- (void)addWindowKeyStateObservers;
- (void)setBackgroundColor:(NSColor *)backgroundColor;

@end
