#import "_WDMessage.h"



@class WCUser;



@interface WDMessage : _WDMessage

@property (readonly) NSString                       *messageString;
@property (readonly) NSImage                        *unreadImage;
@property (readonly) NSImage                        *directionImage;

- (BOOL)belongsToConnection:(WCServerConnection *)connection;

@end
