#import "WServer.h"
#import "WChatMessage.h"
#import "NSManagedObjectContext+Fetch.h"

@implementation WServer

@synthesize connection;
@synthesize chatString;
@synthesize isConnected;
@dynamic unreadPrivateMessagesCount;
@dynamic unreadChatMessagesCount;
@dynamic unreadCount;
@dynamic versionString;
@dynamic hostString;
@dynamic urlString;


- (void)dealloc {
    [chatString release];
    [connection release];
    [super dealloc];
}

- (NSInteger)unreadCount {
    return [self unreadPrivateMessagesCount];
}

- (NSInteger)unreadPrivateMessagesCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(read == NO) AND (server == %@)", self];
    NSArray *unreads = [self.managedObjectContext fetchEntitiesNammed:@"PrivateMessage" withPredicate:predicate error:nil];

    if(unreads && unreads.count > 0)
        return unreads.count;
    
    return 0;
}

- (NSInteger)unreadChatMessagesCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(read == NO) AND (chat == %@)", self.publicChat];
    NSArray *unreads = [self.managedObjectContext fetchEntitiesNammed:@"ChatMessage" withPredicate:predicate error:nil];

    if(unreads && unreads.count > 0)
        return unreads.count;
    
    return 0;
}

- (void)resetChatUnreads {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(read == NO) AND (chat == %@)", self.publicChat];
    NSArray *unreads = [self.managedObjectContext fetchEntitiesNammed:@"ChatMessage" withPredicate:predicate error:nil];
    
    for(WChatMessage *msg in unreads) {
        [msg setRead:[NSNumber numberWithBool:YES]];
    }
}



- (NSString *)versionString {
    NSMutableString *str  = [NSMutableString string];
    
    if(self.appName)
        [str appendFormat:@"%@ ", self.appName];
    
    if(self.appVersion)
        [str appendFormat:@"%@ ", self.appVersion];
    
    if(self.appBuild && self.appBuild.length > 0)
        [str appendFormat:@"(%@)", self.appBuild];
    else 
        [str appendFormat:@"(0)"];
    
    return str;
}

- (NSString *)hostString {
    NSMutableString *str  = [NSMutableString string];
    
    if(self.osName)
        [str appendFormat:@"%@ ", self.osName];
    
    if(self.osVersion)
        [str appendFormat:@"%@ ", self.osVersion];
    
    if(self.arch && self.arch.length > 0)
        [str appendFormat:@"(%@)", self.arch];
    else 
        [str appendFormat:@"(Unknow arch)"];
    
    return str;
}

- (NSString *)urlString {    
    return [NSString stringWithFormat:@"wiredp7://%@", self.address];
}


@end
