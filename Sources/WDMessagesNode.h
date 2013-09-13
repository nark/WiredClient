#import "_WDMessagesNode.h"

enum _WDMessageDirection {
	WDMessageFrom,
	WDMessageTo
};
typedef enum _WDMessageDirection	WDMessageDirection;


@interface WDMessagesNode : _WDMessagesNode

@property (readonly) NSString                       *timeAgo;
@property (readwrite, retain) WCServerConnection    *connection;

@end
