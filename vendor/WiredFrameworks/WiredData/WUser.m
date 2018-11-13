#import "WUser.h"
#import "WServer.h"
#import "NSManagedObjectContext+Fetch.h"

@implementation WUser

- (NSInteger)unreadCountForServer:(WServer *)server {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(read == NO) AND (conversation.withNick == %@) && (server == %@)", self.nick, server];
    NSArray *unreads = [self.managedObjectContext fetchEntitiesNammed:@"PrivateMessage" withPredicate:predicate error:nil];
    
    if(unreads && unreads.count > 0)
        return unreads.count;
    
    return 0;
}

@end
