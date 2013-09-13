#import "WDMessagesConversation.h"
#import "WCDatabaseController.h"

#import "WCConversation.h"


@implementation WDMessagesConversation

+ (WDMessagesConversation *)conversationWithUser:(WCUser *)user connection:(WCServerConnection *)connection {
    WDMessagesConversation *conversation;
    
    conversation = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    [conversation setServerName:[connection name]];
    [conversation setNick:[user nick]];
    [conversation setIdentifier:[connection URLIdentifier]];
    [conversation setConnection:connection];
    [conversation setUser:user];
        
    return conversation;
}


+ (WDMessagesConversation *)conversationWithConversation:(WCMessageConversation *)oldConversation {
    WDMessagesConversation *conversation;
    
    conversation = [[self class] insertInManagedObjectContext:[WCDatabaseController context]];
    [conversation setServerName:[[oldConversation connection] name]];
    [conversation setNick:[oldConversation nick]];
    [conversation setIdentifier:[[oldConversation connection] URLIdentifier]];
    [conversation setConnection:[oldConversation connection]];
    [conversation setUser:[oldConversation user]];
    
    return conversation;
}


@end
