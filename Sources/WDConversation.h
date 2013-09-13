#import "_WDConversation.h"

@class WCUser;

@interface WDConversation : _WDConversation {}

@property (readonly) NSImage                        *userIcon;
@property (readonly) NSImage                        *broadcastIcon;
@property (readonly) NSString                       *timeAgo;
@property (readonly) NSString                       *conversationFullname;
@property (readonly) NSString                       *lastMessage;
@property (readonly) NSString                       *unreadsString;
@property (readonly) NSNumber                       *hasUnreads;
@property (readonly) NSArray                        *sortedMessages;
@property (readonly) BOOL                           isUnread;

- (NSInteger)numberOfUnreadMessages;

- (void)setUnread:(BOOL)unread;
- (void)markAsRead;

- (BOOL)belongsToConnection:(WCServerConnection *)connection;
- (void)invalidateForConnection:(WCServerConnection *)connection;
- (void)revalidateForConnection:(WCServerConnection *)connection;
- (void)invalidateForUser:(WCUser *)user;
- (void)revalidateForUser:(WCUser *)user;

@end
