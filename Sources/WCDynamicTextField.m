//
//  WCDynamicTextField.m
//  Wired Client
//
//  Created by Rafael Warnault on 02/05/2020.
//
//  From
//  TSTTextGrowth.m
//  autoGrowingExample
//
//  Created by Scott O'Brien on 1/01/13.
//  Fixed by Douglas Heriot on 1/01/13, inspired by
//  https://github.com/jerrykrinock/CategoriesObjC/blob/master/NS(Attributed)String%2BGeometrics/NS(Attributed)String%2BGeometrics.m
//  https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/TextLayout/Tasks/StringHeight.html
//  http://stackoverflow.com/questions/14107385/getting-a-nstextfield-to-grow-with-the-text-in-auto-layout
//  Copyright (c) 2013 Scott O'Brien. All rights reserved.
//

#import "WCDynamicTextField.h"

@interface WCDynamicTextField()
{
    BOOL _hasLastIntrinsicSize;
    BOOL _isEditing;
    NSSize _lastIntrinsicSize;
}

@end

@implementation WCDynamicTextField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)textDidBeginEditing:(NSNotification *)notification
{
    [super textDidBeginEditing:notification];
    _isEditing = YES;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    [super textDidEndEditing:notification];
    _isEditing = NO;
}

- (void)textDidChange:(NSNotification *)notification
{
    [super textDidChange:notification];
    [self invalidateIntrinsicContentSize];
}

-(NSSize)intrinsicContentSize
{
    NSSize intrinsicSize = _lastIntrinsicSize;
    
    // Only update the size if we’re editing the text, or if we’ve not set it yet
    // If we try and update it while another text field is selected, it may shrink back down to only the size of one line (for some reason?)
    if(_isEditing || !_hasLastIntrinsicSize)
    {
        intrinsicSize = [super intrinsicContentSize];
        
        // If we’re being edited, get the shared NSTextView field editor, so we can get more info
        NSText *fieldEditor = [self.window fieldEditor:NO forObject:self];
        if([fieldEditor isKindOfClass:[NSTextView class]])
        {
            NSTextView *textView = (NSTextView *)fieldEditor;
            NSRect usedRect = [textView.textContainer.layoutManager usedRectForTextContainer:textView.textContainer];
            
            usedRect.size.height += 5.0; // magic number! (the field editor TextView is offset within the NSTextField. It’s easy to get the space above (it’s origin), but it’s difficult to get the default spacing for the bottom, as we may be changing the height
            
            intrinsicSize.height = usedRect.size.height;
        }
        
        // If you want to set a limit to how far the text view can grow.
        if (intrinsicSize.height > 100)
        {
                        intrinsicSize = _lastIntrinsicSize;
                }
                else
                {
                        _lastIntrinsicSize = intrinsicSize;
                        _hasLastIntrinsicSize = YES;
                }
                
    }
    
    return intrinsicSize;
}

@end
