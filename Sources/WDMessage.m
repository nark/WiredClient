#import "WDMessage.h"
#import "WDWiredModel.h"
#import "WCChatController.h"

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
		if([[[[self connection] URL] hostpair] isEqualToString:[connection URLIdentifier]] ||
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
    NSDateFormatter     *dateFormatter;
    NSMutableString     *messageString;
    NSString            *dateString;
    NSImage             *icon;
    NSImage             *unread;
    
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    
    messageString = [NSMutableString stringWithString:self.message];
    
    if(![WCChatController isHTMLString:messageString]) {
        
        [WCChatController applyHTMLEscapingToMutableString:messageString];
        [WCChatController applyHTMLTagsForURLToMutableString:messageString];
        
        if([[[self connection] theme] boolForKey:WCThemesShowSmileys])
            [WCChatController applyHTMLTagsForSmileysToMutableString:messageString];
    }
    
    [messageString replaceOccurrencesOfString:@"\n" withString:@"<br />\n"];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
    
    dateString = [dateFormatter stringFromDate:self.date];
    [dateFormatter release];
    
    icon       = (!self.conversation.connection || ![self user]) ? [NSImage imageNamed:@"SenderImagePlaceholder"] : [[self user] icon];
    unread     = (self.unreadValue) ? self.unreadImage : [NSImage imageNamed:@"ReadThread"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            messageString,                                                  @"message",
            self.nick,                                                      @"nick",
            dateString,                                                     @"date",
            [[unread TIFFRepresentation] base64EncodedString],              @"unread",
            self.direction,                                                 @"direction",
            [NSNumber numberWithInteger:[self.user userID]],                @"userID",
            [[icon TIFFRepresentation] base64EncodedString],                @"icon",
            [self.conversation.connection name],                            @"server",
            nil];
}

@end
