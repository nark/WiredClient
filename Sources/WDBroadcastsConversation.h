#import "_WDBroadcastsConversation.h"

@class WCBroadcastConversation;

@interface WDBroadcastsConversation : _WDBroadcastsConversation {}

+ (WDBroadcastsConversation *)conversationWithUser:(WCUser *)user connection:(WCServerConnection *)connection;

+ (WDBroadcastsConversation *)conversationWithConversation:(WCBroadcastConversation *)oldConversation context:(NSManagedObjectContext *)context;

@end
