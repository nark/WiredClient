#import "_WDPrivateMessage.h"
#import "WCMessage.h"

@interface WDPrivateMessage : _WDPrivateMessage {}

+ (WDPrivateMessage *)messageFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection;
+ (WDPrivateMessage *)messageToSomeoneFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection;

+ (WDPrivateMessage *)messageWithMessage:(WCPrivateMessage *)message;

@end
