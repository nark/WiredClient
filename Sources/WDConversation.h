#import "_WDConversation.h"

@class WCUser;

@interface WDConversation : _WDConversation {}

@property (readonly) NSImage                        *userIcon;
@property (readonly) NSImage                        *broadcastIcon;
@property (readonly) NSString                       *timeAgo;
@property (readonly) NSString                       *conversationFullname;
@property (readonly) NSString                       *unreadsString;
@property (readonly) NSNumber                       *hasUnreads;
@property (readonly) BOOL                           isUnread;

- (NSInteger)numberOfUnreadMessages;

- (BOOL)belongsToConnection:(WCServerConnection *)connection;
- (void)invalidateForConnection:(WCServerConnection *)connection;
- (void)revalidateForConnection:(WCServerConnection *)connection;
- (void)invalidateForUser:(WCUser *)user;
- (void)revalidateForUser:(WCUser *)user;

@end
