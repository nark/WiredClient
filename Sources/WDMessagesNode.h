#import "_WDMessagesNode.h"

enum _WDMessageDirection {
	WDMessageFrom,
	WDMessageTo
};
typedef enum _WDMessageDirection	WDMessageDirection;


@interface WDMessagesNode : _WDMessagesNode {
    WCServerConnection    *_connection;
}

@property (readonly) NSString                       *timeAgo;
@property (readwrite, retain) WCServerConnection    *connection;

@end
