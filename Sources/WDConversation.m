#import "WDConversation.h"
#import "WDWiredModel.h"
#import "WCUser.h"




@interface WDConversation (Private)

- (NSArray *)       _sortedMessages;
- (WDMessage *)     _lastMessage;

@end


@implementation WDConversation (Private)

#pragma mark -

- (NSArray *)_sortedMessages {
    NSSortDescriptor *descriptor;
    
    descriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    
    return [self.messages sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
}



- (WDMessage *)_lastMessage {
    if(![self _sortedMessages] || [[self _sortedMessages] count] == 0)
        return nil;
    
    return [[self _sortedMessages] objectAtIndex:0];
}

@end





@implementation WDConversation

#pragma mark -

@dynamic userIcon;
@dynamic broadcastIcon;
@dynamic timeAgo;
@dynamic conversationFullname;
@dynamic lastMessage;
@dynamic sortedMessages;
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
    else if([key isEqualToString:@"lastMessage"]) {
        set = [NSSet setWithObjects:@"messages", nil];
    }
    else if([key isEqualToString:@"sortedMessages"]) {
        set = [NSSet setWithObjects:@"messages", nil];
    }
    else if([key isEqualToString:@"userIcon"]) {
        set = [NSSet setWithObjects:@"user", @"connection", nil];
    }
    else if([key isEqualToString:@"unreadsString"]) {
        set = [NSSet setWithObjects:@"isUnread", nil];
    }
    else if([key isEqualToString:@"hasUnreads"]) {
        set = [NSSet setWithObjects:@"isUnread", nil];
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

- (void)setUnread:(BOOL)unread {
    [self willChangeValueForKey:@"isUnread"];
    for(WDMessage *message in self.messages) {
        [message setUnreadValue:unread];
    }
    [self didChangeValueForKey:@"isUnread"];
}


- (void)markAsRead {
    [self willChangeValueForKey:@"isUnread"];
    for(WDMessage *message in self.messages) {
        [message setUnreadValue:NO];
    }
    [self didChangeValueForKey:@"isUnread"];
}


#pragma mark -

- (NSString *)timeAgo {
    NSString    *timeAgo = @"";

    if(self.date) {
        timeAgo = [self.date timeAgoWithLimit:3600*24*7];
    }
    
    return [timeAgo stringByAppendingFormat:@" - %@", self.serverName];
}


- (NSString *)conversationFullname {
    return [NSString stringWithFormat:@"%@@%@", [self nick], [self serverName]];
}


- (NSString *)lastMessage {
    return [[self _lastMessage] messageString];
}



- (NSArray *)sortedMessages {
    return [self _sortedMessages];
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
        icon = [NSImage imageNamed:@"BroadcastsConversation"];
    }
    else {
        icon = nil;
    }
    
    return icon;
}



- (BOOL)isUnread {
    return ([self numberOfUnreadMessages] > 0);
}



- (NSNumber *)hasUnreads {
    return [NSNumber numberWithBool:[self isUnread]];
}



- (NSString *)unreadsString {
    NSString    *unreads = @"";
    NSInteger   unreadsCount = 0;
    
    unreadsCount = [self numberOfUnreadMessages];
    
    if(unreadsCount > 0)
        unreads = [NSString stringWithFormat:@"%ld", (long)unreadsCount];
        
    return unreads;
}


- (NSInteger)numberOfUnreadMessages {
    NSInteger unreads = 0;
    
    for(WDMessage *message in self.messages) {
        if(message.unreadValue)
            unreads++;
    }
    
    return unreads;
}

@end
