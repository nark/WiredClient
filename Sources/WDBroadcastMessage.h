#import "_WDBroadcastMessage.h"
#import "WCMessage.h"

@interface WDBroadcastMessage : _WDBroadcastMessage {}

+ (WDBroadcastMessage *)broadcastFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection;
+ (WDBroadcastMessage *)messageWithMessage:(WCBroadcastMessage *)message context:(NSManagedObjectContext *)context;

@end
