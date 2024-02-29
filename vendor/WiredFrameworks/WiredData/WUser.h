#import "_WUser.h"


@class WServer;

@interface WUser : _WUser {}

- (NSInteger)unreadCountForServer:(WServer *)server ;

@end
