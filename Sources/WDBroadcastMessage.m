#import "WDBroadcastMessage.h"
#import "WCDatabaseController.h"

@implementation WDBroadcastMessage

+ (WDBroadcastMessage *)broadcastFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection {
    WDBroadcastMessage *broadcastMessage;
    
    broadcastMessage = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    
    [broadcastMessage setMessage:message];
    [broadcastMessage setConnection:connection];
    [broadcastMessage setNick:[user nick]];
    [broadcastMessage setDate:[NSDate date]];
    [broadcastMessage setUnreadValue:YES];
    [broadcastMessage setDirectionValue:WDMessageFrom];
    [broadcastMessage setUser:user];
    
    return broadcastMessage;
}


#pragma mark -

+ (WDBroadcastMessage *)messageWithMessage:(WCBroadcastMessage *)message context:(NSManagedObjectContext *)context {
    WDBroadcastMessage *broadcastMessage;
    
    broadcastMessage = [[self class] insertInManagedObjectContext: context];
    
    [broadcastMessage setMessage:[message message]];
    [broadcastMessage setConnection:[message connection]];
    [broadcastMessage setNick:[message nick]];
    [broadcastMessage setDate:[message date]];
    [broadcastMessage setUnreadValue:[message isUnread]];
    [broadcastMessage setDirectionValue:[message direction]];
    [broadcastMessage setUser:[message user]];
    
    return broadcastMessage;
}


@end
