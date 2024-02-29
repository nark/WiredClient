#import "WDConversation.h"
#import "WDWiredModel.h"
#import "WCUser.h"
#import "WCApplicationController.h"
#import "NSDate+TimeAgo.h"






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
    if(!_connection) {
        if([[self identifier] isEqualToString:[connection URLIdentifier]] ||
           [[[_connection bookmark] objectForKey:WCBookmarksIdentifier] isEqualToString:[connection bookmarkIdentifier]])
            return YES;
    }
    
    return NO;
}



- (void)revalidateForConnection:(WCServerConnection *)connection {
	WDMessage		*message;
    
    NSLog(@"revalidateForConnection : %@ <> %@", [self identifier], [connection URLIdentifier]);
        
	for(message in self.messages) {		
		if([message belongsToConnection:connection])
			[message setConnection:connection];

	}
    if([self belongsToConnection:connection])
        [self setConnection:connection];
}


- (void)invalidateForConnection:(WCServerConnection *)connection {
	WDMessage		*message;
    
	for(message in self.messages) {
		if([message connection] == connection) {
			[message setConnection:NULL];
			[message setUser:NULL];
		}
	}
	
    if([self belongsToConnection:connection] && [[self user] userID] ==[connection userID]) {
        [self setConnection:NULL];
        [self setUser:NULL];
    }
}






- (void)invalidateForUser:(WCUser *)user {
	WDMessage		*message;
		
	for(message in self.messages) {	
		if([message user] == user)
			[message setUser:NULL];
	}
    
    if([self user] == user)
        [self setUser:NULL];
}



- (void)revalidateForUser:(WCUser *)user {
	WDMessage		*message;
		
	for(message in self.messages) {
        if([[user nick] isEqualToString:[message nick]])
            if(![message user] && [message connection] == [user connection])
                [message setUser:user];
	}
    
    NSLog(@"revalidateForUser : %@ <> %@", user.nick, [self nick]);
    NSLog(@"self user connection : %@", [[self user] connection]);
    NSLog(@"revalidateForUser : %@ <> %@", [self connection], [user connection]);
    
    if([[user nick] isEqualToString:[self nick]])
        if(![[self user] connection] && [self connection] == [user connection])
            [self setUser:user];
}





#pragma mark -

- (NSString *)timeAgo {
    NSString            *timeAgo = @"";
    WIDateFormatter     *df;
    
    df = [[WCApplicationController sharedController] dateFormatter];

    if(self.date) {
        timeAgo = [self.date timeAgoWithLimit:3600*24*7 dateFormatter:df];
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
