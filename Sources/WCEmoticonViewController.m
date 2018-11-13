//
//  WCEmoticonViewController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 30/09/13.
//
//

#import "WCEmoticonViewController.h"
#import "WCApplicationController.h"
#import "WCChatController.h"
#import "WCPublicChat.h"
#import "WCPreferences.h"


static WCEmoticonViewController *_emoticonController;


@interface WCEmoticonViewController ()

@end

@implementation WCEmoticonViewController

@synthesize delegate = _delegate;
@dynamic    emoticons;




#pragma mark -

+ (id)emoticonController {
    if(!_emoticonController)
        _emoticonController = [[[self class] alloc] init];
    
    return _emoticonController;
}




#pragma mark -

- (id)init
{
    self = [super initWithNibName:@"EmoticonView" bundle:nil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(emoticonsDidChange:)
                                                     name:WCEmoticonsDidChangeNotification];
    }
    
    return self;
}



- (void)dealloc
{
    [_textField release];
    [_popover release];
    [_delegate release];
    
    [super dealloc];
}






#pragma mark -

- (void)emoticonsDidChange:(NSNotification *)notification {
    [_emoticonsArrayController rearrangeObjects];
}



#pragma mark -

- (void)popoverWithSender:(id)sender textView:(NSTextView *)view {
    if(_textView) [_textView release]; _textView = nil;
    _textView = [view retain];
    
    if(_textField) [_textField release]; _textField = nil;
    
    if(!_popover) {
        _popover = [[NSPopover alloc] init];
        
        _popover.contentViewController = [WCEmoticonViewController emoticonController];
        _popover.contentSize = [[[WCEmoticonViewController emoticonController] view] frame].size;
        _popover.behavior = NSPopoverBehaviorTransient;
        _popover.delegate = self;

        [_popover showRelativeToRect:[sender bounds]
                                       ofView:sender
                                preferredEdge:NSMaxYEdge];
    } else {
        [_popover close];
        [_popover release];
        _popover = nil;
    }
}


- (void)popoverWithSender:(id)sender textField:(NSTextField *)view {
    if(_textField) [_textField release]; _textField = nil;
    _textField = [view retain];
    
    if(_textView) [_textView release]; _textView = nil;
    
    if(!_popover) {
        _popover = [[NSPopover alloc] init];
        
        _popover.contentViewController = [WCEmoticonViewController emoticonController];
        _popover.contentSize = [[[WCEmoticonViewController emoticonController] view] frame].size;
        _popover.behavior = NSPopoverBehaviorTransient;
        _popover.delegate = self;
        
        [_popover showRelativeToRect:[sender bounds]
                              ofView:sender
                       preferredEdge:NSMaxYEdge];
    } else {
        [_popover close];
        [_popover release];
        _popover = nil;
    }
}



#pragma mark -

- (void)popoverWillShow:(NSNotification *)notification {
    if([_popoverWindow isVisible]) {
        [_popoverWindow close];
    }
}

- (void)popoverDidClose:(NSNotification *)notification {
    if([notification object] == _popover) {
        [_popover release];
        _popover = nil;
    }
}

- (NSWindow *)detachableWindowForPopover:(NSPopover *)popover {
    return _popoverWindow;
}






#pragma mark -

- (IBAction)emoticonClicked:(id)sender {    
    WIEmoticon                  *emoticon;
    NSFileWrapper               *wrapper;
	NSTextAttachment            *attachment;
	NSAttributedString          *attributedString;
    NSMutableAttributedString   *oldString;
    NSMutableString             *equivalent;
    
    emoticon            = (WIEmoticon *)[sender representedObject];
    NSURL *emoticonURL  = [NSURL fileURLWithPath:[emoticon path]];
    wrapper             = [[NSFileWrapper alloc] initWithURL:emoticonURL options:0 error:nil];
    equivalent          = [NSMutableString stringWithString:[emoticon equivalent]];
	attachment			= [[WITextAttachment alloc] initWithFileWrapper:wrapper
                                                          string:equivalent];
    
	attributedString	= [NSAttributedString attributedStringWithAttachment:attachment];
	   
    if(_textView) {
        [_textView tryToPerform:@selector(insertText:) with:attributedString];
        [_textView tryToPerform:@selector(insertText:) with:@" "];
        
        [self.delegate emoticonViewController:self
                            didInsertEmoticon:emoticon
                                    inControl:(NSControl *)_textView];
    }
    if(_textField) {
        oldString = [[NSMutableAttributedString alloc] initWithAttributedString:[_textField attributedStringValue]];
        
        [oldString appendAttributedString:attributedString];
        [oldString appendAttributedString:[NSAttributedString attributedStringWithString:@" "]];
        
        [_textField setAttributedStringValue:oldString];
        [oldString release];
        
        [self.delegate emoticonViewController:self
                            didInsertEmoticon:emoticon
                                    inControl:(NSControl *)_textField];
    }
    
	[attachment release];
	[wrapper release];
}




#pragma mark -

- (NSArray *)emoticons {
    return [[[WCPreferences preferences] emoticonPreferences] enabledEmoticons];
}

@end
