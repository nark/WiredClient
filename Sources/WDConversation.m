#import "WDConversation.h"
#import "WDWiredModel.h"
#import "WCUser.h"







@implementation WDConversation

#pragma mark -

@dynamic userIcon;
@dynamic broadcastIcon;
@dynamic timeAgo;
@dynamic conversationFullname;
@dynamic unreadsString;
@dynamic hasUnreads;
@dynamic isUnread;




#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *set;
    
    if([key isEqualToString:@"conversationFullname"]) {
        set = [NSSet setWithObjects:@"nick", @"conversationName", nil];
    }
    else if([key isEqualToString:@"timeAgo"]) {
        set = [NSSet setWithObjects:@"messages", nil];
    }
    else if([key isEqualToString:@"userIcon"]) {
        set = [NSSet setWithObjects:@"user", @"connection", nil];
    }
    else if([key isEqualToString:@"broadcastIcon"]) {
        set = [NSSet setWithObjects:@"direction", nil];
    }
    else if([key isEqualToString:@"unreadsString"]) {
        set = [NSSet setWithObjects:@"numberOfUnreads", nil];
    }
    else if([key isEqualToString:@"hasUnreads"]) {
        set = [NSSet setWithObjects:@"numberOfUnreads", nil];
    }
    else if([key isEqualToString:@"isUnread"]) {
        set = [NSSet setWithObjects:@"numberOfUnreads", nil];
    }
    else {
        set = nil;
    }
    
    return set;
}






#pragma mark -

- (BOOL)belongsToConnection:(WCServerConnection *)connection {
	if(![self connection]) {
		if([[[[self connection] URL] hostpair] isEqualToString:[connection URLIdentifier]] ||
		   [[[[self connection] bookmark] objectForKey:WCBookmarksIdentifier] isEqualToString:[connection bookmarkIdentifier]])
			return YES;
	}
	
	return NO;
}



- (void)invalidateForConnection:(WCServerConnection *)connection {
	WDMessage		*message;
	   
	for(message in self.messages) {		
		if([message connection] == connection) {
			[message setConnection:NULL];
			[message setUser:NULL];
		}
	}
	
	[self setConnection:NULL];
    [self setUser:NULL];
}



- (void)revalidateForConnection:(WCServerConnection *)connection {
	WDMessage		*message;
        
	for(message in self.messages) {		
		if([message belongsToConnection:connection])
			[message setConnection:connection];

	}
    
    [self setConnection:connection];
}



- (void)invalidateForUser:(WCUser *)user {
	WDMessage		*message;
		
	for(message in self.messages) {	
		if([message user] == user)
			[message setUser:NULL];
	}
}



- (void)revalidateForUser:(WCUser *)user {
	WDMessage		*message;
		
	for(message in self.messages) {
        if([[user nick] isEqualToString:[message nick]])
            [message setUser:user];
	}
    
    if([[user nick] isEqualToString:[self nick]])
        [self setUser:user];
}



#pragma mark -

- (NSString *)timeAgo {
    NSString    *timeAgo = @"";

    if(self.date) {
        timeAgo = [self.date timeAgoWithLimit:3600*24*7];
    }
    
    return timeAgo;
}


- (NSString *)conversationFullname {
    return [NSString stringWithFormat:@"%@@%@", [self nick], [self serverName]];
}



- (NSImage *)userIcon {
    NSImage *icon;
    
    icon = [self.user icon];
    
    if(!icon) {
        icon = [NSImage imageNamed:@"SenderImagePlaceholder"];
    }
    
    return icon;
}



- (NSImage *)broadcastIcon {
    NSImage *icon;
    
    if([self isKindOfClass:[WDBroadcastsConversation class]]) {
        icon = [NSImage imageNamed:@"EventsAccounts"];
    }
    else if([self isKindOfClass:[WDMessagesConversation class]]) {
        if([self directionValue] == WCMessageFrom) {
            icon = [NSImage imageNamed:@"EventsMessages"];
        }
        else if([self directionValue] == WCMessageTo) {
            icon = [NSImage imageNamed:@"ReplyMessage"];
        } else {
            icon = [NSImage imageNamed:@"edit"];
        }
    }
    
    return icon;
}




#pragma mark -

- (BOOL)isUnread {
    return ([self numberOfUnreadsValue] > 0);
}



- (NSNumber *)hasUnreads {
    return [NSNumber numberWithBool:[self isUnread]];
}



- (NSString *)unreadsString {
    NSString    *unreads = @"";
    NSInteger   unreadsCount = 0;
    
    unreadsCount = [self numberOfUnreadsValue];
    
    if(unreadsCount > 0)
        unreads = [NSString stringWithFormat:@"%ld", (long)unreadsCount];
    
    return unreads;
}


- (NSInteger)numberOfUnreadMessages {
    return [self numberOfUnreadsValue];
}

@end
