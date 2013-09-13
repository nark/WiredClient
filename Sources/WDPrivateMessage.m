#import "WDPrivateMessage.h"
#import "WCDatabaseController.h"
#import "WCUser.h"


@implementation WDPrivateMessage

#pragma mark -

+ (WDPrivateMessage *)messageFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection {
    WDPrivateMessage *privateMessage;
    
    privateMessage = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    
    [privateMessage setMessage:message];
    [privateMessage setConnection:connection];
    [privateMessage setNick:[user nick]];
    [privateMessage setDate:[NSDate date]];
    [privateMessage setUnreadValue:YES];
    [privateMessage setDirectionValue:WDMessageFrom];
    [privateMessage setUser:user];
    
    return privateMessage;
}


+ (WDPrivateMessage *)messageToSomeoneFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection {
    WDPrivateMessage *privateMessage;
    
    privateMessage = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    
    [privateMessage setMessage:message];
    [privateMessage setConnection:connection];
    [privateMessage setNick:[user nick]];
    [privateMessage setDate:[NSDate date]];
    [privateMessage setUnreadValue:YES];
    [privateMessage setDirectionValue:WDMessageTo];
    [privateMessage setUser:user];
    
    return privateMessage;
}



#pragma mark -

+ (WDPrivateMessage *)messageWithMessage:(WCPrivateMessage *)message {
    WDPrivateMessage *privateMessage;
    
    privateMessage = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    
    [privateMessage setMessage:[message message]];
    [privateMessage setConnection:[message connection]];
    [privateMessage setNick:[message nick]];
    [privateMessage setDate:[message date]];
    [privateMessage setUnreadValue:[message isUnread]];
    [privateMessage setDirectionValue:[message direction]];
    [privateMessage setUser:[message user]];
    
    return privateMessage;
}

@end
