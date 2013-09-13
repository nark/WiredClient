#import "WDBroadcastsConversation.h"
#import "WCDatabaseController.h"

#import "WCConversation.h"

@implementation WDBroadcastsConversation

+ (WDBroadcastsConversation *)conversationWithUser:(WCUser *)user connection:(WCServerConnection *)connection {
    WDBroadcastsConversation *conversation;
    
    conversation = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    [conversation setServerName:[connection name]];
    [conversation setNick:[user nick]];
    [conversation setConnection:connection];
    [conversation setIdentifier:[connection URLIdentifier]];
    [conversation setUser:user];
    
    return conversation;
}


+ (WDBroadcastsConversation *)conversationWithConversation:(WCBroadcastConversation *)oldConversation {
    WDBroadcastsConversation *conversation;
    
    conversation = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    [conversation setServerName:[[oldConversation connection] name]];
    [conversation setNick:[oldConversation nick]];
    [conversation setIdentifier:[[oldConversation connection] URLIdentifier]];
    [conversation setConnection:[oldConversation connection]];
    [conversation setUser:[oldConversation user]];
    
    return conversation;
}

@end
