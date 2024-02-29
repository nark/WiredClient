/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <WiredAppKit/NSAlert-WIAppKit.h>

#import <Foundation/NSException.h>
#import <Foundation/NSString.h>




void OABeginAlertSheet(NSString *title, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, NSWindow *docWindow, WIAlertSheetCompletionHandler completionHandler, NSString *msgFormat, ...);




@interface _WIAlertSheetCompletionHandlerRunner : NSObject
{
    NSAlert *_alert;
    WIAlertSheetCompletionHandler _completionHandler;
}
@end


@implementation _WIAlertSheetCompletionHandlerRunner

- initWithAlert:(NSAlert *)alert completionHandler:(WIAlertSheetCompletionHandler)completionHandler;
{
    if (!(self = [super init]))
        return nil;
    
    _alert = [alert retain];
    _completionHandler = [completionHandler copy];
    return self;
}
- (void)dealloc;
{
    [_alert release];
    [_completionHandler release];
    [super dealloc];
}

- (void)startOnWindow:(NSWindow *)parentWindow;
{
    // We have to live until the callback, but a -retain will annoy clang-sa.
	[self performSelector:@selector(retain)];
    [_alert beginSheetModalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    NSAssert(alert == _alert,@"Got a alert different from what I expected -- This should never happen");
    
    // Clean up the hidden -retain from -startOnWindow:, first and with -autorelease in case the block asplodes.
    [self performSelector:@selector(autorelease)];
    
    if (_completionHandler)
        _completionHandler(_alert, returnCode);
}

@end







@implementation NSAlert(WIAppKit)

- (void)runNonModal {
	[self beginSheetModalForWindow:NULL];
}



- (void)beginSheetModalForWindow:(NSWindow *)window {
	[self beginSheetModalForWindow:window modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}



- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(WIAlertSheetCompletionHandler)completionHandler;
{
    _WIAlertSheetCompletionHandlerRunner *runner = [[_WIAlertSheetCompletionHandlerRunner alloc] initWithAlert:self completionHandler:completionHandler];
    [runner startOnWindow:window];
    [runner release];
}


@end








void OABeginAlertSheet(NSString *title, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, NSWindow *docWindow, WIAlertSheetCompletionHandler completionHandler, NSString *msgFormat, ...)
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    
    if (msgFormat) {
        va_list args;
        va_start(args, msgFormat);
        NSString *informationalText = [[NSString alloc] initWithFormat:msgFormat arguments:args];
        va_end(args);
        
        [alert setInformativeText:informationalText];
        [informationalText release];
    }
    
    if (defaultButton)
        [alert addButtonWithTitle:defaultButton];
    if (alternateButton)
        [alert addButtonWithTitle:alternateButton];
    if (otherButton)
        [alert addButtonWithTitle:otherButton];
    
    //[alert beginSheetModalForWindow:docWindow completionHandler:completionHandler];
    [alert release]; // retained by the runner while the sheet is up
}