#import "_WDMessagesConversation.h"

@class WCUser, WCMessageConversation;

@interface WDMessagesConversation : _WDMessagesConversation {}

+ (WDMessagesConversation *)conversationWithUser:(WCUser *)user connection:(WCServerConnection *)connection;
+ (WDMessagesConversation *)conversationWithConversation:(WCMessageConversation *)conversation context:(NSManagedObjectContext *)context;

@end
