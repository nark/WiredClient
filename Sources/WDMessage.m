#import "WDMessage.h"
#import "WDWiredModel.h"
#import "WCChatController.h"
#import "NSDate+TimeAgo.h"

@implementation WDMessage



#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *set;
    
    if([key isEqualToString:@"messageString"]) {
        set = [NSSet setWithObjects:@"message", nil];
    }
    else if([key isEqualToString:@"unreadImage"]) {
        set = [NSSet setWithObjects:@"unread", nil];
        
    }
    else {
        set = nil;
    }
    
    return set;
}






#pragma mark -

@dynamic messageString;
@dynamic directionImage;
@dynamic unreadImage;







#pragma mark -

- (BOOL)belongsToConnection:(WCServerConnection *)connection {
	if(![self connection]) {
		if([[connection URLIdentifier] isEqualToString:[self identifier]] ||
		   [[[[self connection] bookmark] objectForKey:WCBookmarksIdentifier] isEqualToString:[connection bookmarkIdentifier]])
			return YES;
	}
	
	return NO;
}





#pragma mark -

- (NSString *)messageString {
    return [self message];
}


- (NSImage *)directionImage {
    return (self.directionValue == WDMessageFrom) ?
    [NSImage imageNamed:@"InMailboxTemplate"] :
    [NSImage imageNamed:@"SentMailboxTemplate"];
}


- (NSImage *)unreadImage {
    return (self.unreadValue) ? [NSImage imageNamed:@"UnreadThread"] : nil;
}





#pragma mark -

- (NSSet *)messages {
    return nil;
}




#pragma mark -

- (id)proxyForJson {
    NSMutableString     *messageString;
    NSImage             *icon;
    NSImage             *unread;
        
    messageString = [NSMutableString stringWithString:self.message];
    
    if(![WCChatController isHTMLString:messageString]) {
        [WCChatController applyHTMLEscapingToMutableString:messageString];
        
        if([WCChatController checkHTMLRestrictionsForString:messageString])
            [WCChatController applyHTMLTagsForURLToMutableString:messageString];
        
        if([[[self connection] theme] boolForKey:WCThemesShowSmileys])
            [WCChatController applyHTMLTagsForSmileysToMutableString:messageString];
    }
    
    icon    = (!self.conversation.connection || ![self user]) ? [NSImage imageNamed:@"SenderImagePlaceholder"] : [[self user] icon];
    unread = (self.unreadValue) ? self.unreadImage : [NSImage imageNamed:@"ReadThread"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            messageString,                                                  @"message",
            self.nick,                                                      @"nick",
            [self.date JSDate],                                             @"date",
            [self.date timeAgoWithLimit:(3600*24*30)],                      @"timeAgo",
            [[unread TIFFRepresentation] base64EncodedString],              @"unread",
            self.direction,                                                 @"direction",
            [NSNumber numberWithInteger:[self.user userID]],                @"userID",
            [[icon TIFFRepresentation] base64EncodedString],                @"icon",
            [self.conversation.connection name],                            @"server",
            nil];
}

@end
