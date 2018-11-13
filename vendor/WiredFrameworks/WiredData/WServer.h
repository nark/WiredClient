#import "_WServer.h"

@interface WServer : _WServer {
    NSInteger unreadCount;
}

@property (nonatomic, setter=setConnected:) BOOL isConnected;
@property (nonatomic, retain) id connection;
@property (nonatomic, retain) NSMutableString *chatString;
@property (nonatomic, readonly) NSInteger unreadCount;
@property (nonatomic, readonly) NSInteger unreadPrivateMessagesCount;
@property (nonatomic, readonly) NSInteger unreadChatMessagesCount;
@property (nonatomic, readonly) NSString *versionString;
@property (nonatomic, readonly) NSString *hostString;
@property (nonatomic, readonly) NSString *urlString;

- (void)resetChatUnreads;

@end
