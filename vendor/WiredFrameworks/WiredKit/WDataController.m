//
//  WDataController.m
//  iWi
//
//  Created by Rafaël Warnault on 26/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import "WDataController.h"
#import "WConnection.h"
//#import "NSManagedObjectContext+Fetch.h"



NSString * const WDataControllerUpdateUsersNotification = @"WDataControllerUpdateUsersNotification";
NSString * const WDataControllerUpdateChatNotification = @"WDataControllerUpdateChatNotification";
NSString * const WDataControllerUpdateMessagesNotification = @"WDataControllerUpdateMessagesNotification";


@interface WDataController (Fetching)

- (WChat *)fetchChat:(WIP7Message *)message;
- (WConversation *)fetchConversation:(WIP7Message *)message;

- (WUser *)fetchOrCreateOrUpdateUser:(WIP7Message *)message;
- (WUser *)fetchUser:(WIP7Message *)message;
- (WUser *)fetchUserForID:(WIP7UInt32)userID;
- (WUser *)createUser:(WIP7Message *)message;
- (BOOL)updateUser:(WUser *)user withMessage:(WIP7Message *)message;

- (WChatMessage *)fetchOrCreateOrUpdateChatMessage:(WIP7Message *)message;
- (WChatMessage *)fetchChatMessage:(WIP7Message *)message;
- (WChatMessage *)createChatMessage:(WIP7Message *)message;

- (WPrivateMessage *)fetchOrCreateOrUpdatePrivateMessage:(WIP7Message *)message;
- (WPrivateMessage *)fetchPrivateMessage:(WIP7Message *)message;
- (WPrivateMessage *)createPrivateMessage:(WIP7Message *)message;

- (WEvent *)createEvent:(WIP7Message *)message;

@end



@implementation WDataController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize server = _server;

- (id)initWithServer:(WServer *)server {
    self = [super init];
    if (self) {
        _server = [server retain];
        _managedObjectContext = [server.managedObjectContext retain];
    }
    return self;
}

- (void)dealloc {
    [_managedObjectContext release];
    [_server release];
    [super dealloc];
}

- (void)receiveMessage:(WIP7Message *)message {
    
    if([message.name isEqualToString:@"wired.server_info"]) {
        
        NSLog(@"server_info");
        [self updateServer:message];
        [self save];
        
    } else if([message.name isEqualToString:@"wired.host_info"]) {
        
        NSLog(@"host_info");
        [self updateServer:message];
        [self save];
        
    } else if([message.name isEqualToString:@"wired.chat.user_list"] ||
       [message.name isEqualToString:@"wired.chat.user_join"]) {
        //NSLog(@"user_join : %@", message);
        WUser *user = [self fetchOrCreateOrUpdateUser:message];
        
        if([self save]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WDataControllerUpdateUsersNotification object:user];
        }
                
    } else if([message.name isEqualToString:@"wired.chat.user_leave"]) {
        
       WUser *user = [self fetchUser:message];
        
        if(user) {
            [self.managedObjectContext deleteObject:user];
            if([self save]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:WDataControllerUpdateUsersNotification object:user];
            }
        }
            
    } else if([message.name isEqualToString:@"wired.chat.user_status"]) {
        WUser *user = [self fetchUser:message];
        
        if(user) {
            if([self updateUser:user withMessage:message]) {
                if([self save]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:WDataControllerUpdateUsersNotification object:user];
                }
            }
        }
        
        
    } else if([message.name isEqualToString:@"wired.chat.say"] ||
              [message.name isEqualToString:@"wired.chat.me"]) {
        
        WChatMessage *chatMessage = [self fetchOrCreateOrUpdateChatMessage:message];
        if(chatMessage) {
            if([self save]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:WDataControllerUpdateChatNotification object:chatMessage];
            }
        }
        
    } else if([message.name isEqualToString:@"wired.message.message"]) {
        WPrivateMessage *privateMessage = [self createPrivateMessage:message];
        if(privateMessage) {
            if([self save]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:WDataControllerUpdateMessagesNotification object:privateMessage];
            }
        }
        
    } else if([message.name isEqualToString:@"wired.chat.topic"]) {
        WChat *chat = [self fetchChat:message];
        
        if(![chat.topic isEqualToString:[message stringForName:@"wired.chat.topic.topic"]])
            [chat setTopic:[message stringForName:@"wired.chat.topic.topic"]];
        
        if(![chat.topicNick isEqualToString:[message stringForName:@"wired.chat.topic.nick"]])
            [chat setTopicNick:[message stringForName:@"wired.chat.topic.nick"]];
        
        if(![chat.topicTime isEqualToDate:[message dateForName:@"wired.chat.topic.time"]])
            [chat setTopicTime:[message dateForName:@"wired.chat.topic.time"]];
    }
}

- (void)cleanUsers {
    WChat *publicChat = self.server.publicChat;
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(ANY chats == %@)", publicChat];
    [self.managedObjectContext deleteEntitiesNamed:@"User" withPredicate:p];
}

- (BOOL)save {
    BOOL ret = NO;
    NSError *error = nil;
    
    if(![self.managedObjectContext save:&error]) {
        NSLog(@"ERROR : Core Data save error : %@", [error localizedDescription]);
    } else {
        ret = YES;
    }
    
    return ret;
}

- (WConversation *)fetchConversationForNick:(NSString *)nick {
    WConversation *conv = nil;
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(withNick like[cd] %@)", nick];
    conv = [self.managedObjectContext fetchEntityNammed:@"Conversation" withPredicate:p error:nil];
    
    return conv;
}


- (BOOL)updateServer:(WIP7Message *)message {
    
    WIP7UInt32 files, size;
    BOOL updated = NO;
    
    if([message.name isEqualToString:@"wired.server_info"]) {
        
        WIP7UInt64		files, size;
        WIP7UInt32		downloads, uploads, downloadSpeed, uploadSpeed;
        WIP7Bool		supportsResourceForks;
        
        [message getBool:&supportsResourceForks forName:@"wired.info.supports_rsrc"];
                
        if(![self.server.appName isEqualToString:[message stringForName:@"wired.info.application.name"]]) {
            
            [self.server setAppName:[message stringForName:@"wired.info.application.name"]];
            updated = YES;
            
        }
        if(![self.server.appVersion isEqualToString:[message stringForName:@"wired.info.application.version"]]) {
            [self.server setAppVersion:[message stringForName:@"wired.info.application.version"]];
            updated = YES;
            
        }
        if(![self.server.appBuild isEqualToString:[message stringForName:@"wired.info.application.build"]]) {
            [self.server setAppBuild:[message stringForName:@"wired.info.application.build"]];
            updated = YES;
            
        }
        if(![self.server.osName isEqualToString:[message stringForName:@"wired.info.os.name"]]) {
            [self.server setOsName:[message stringForName:@"wired.info.os.name"]];
            updated = YES;
            
        }
        if(![self.server.osVersion isEqualToString:[message stringForName:@"wired.info.os.version"]]) {
            [self.server setOsVersion:[message stringForName:@"wired.info.os.version"]];
            updated = YES;
            
        }
        if(![self.server.arch isEqualToString:[message stringForName:@"wired.info.arch"]]) {
            [self.server setArch:[message stringForName:@"wired.info.arch"]];
            updated = YES;
        }
                
        if(![self.server.serverName isEqualToString:[message stringForName:@"wired.info.name"]]) {
            [self.server setServerName:[message stringForName:@"wired.info.name"]];
            updated = YES;
            
        }
        if(![self.server.serverDescription isEqualToString:[message stringForName:@"wired.info.description"]]) {
            [self.server setServerDescription:[message stringForName:@"wired.info.description"]];
            updated = YES;
            
        }
        if(!self.server.banner || ![self.server.banner isEqualToData:[message dataForName:@"wired.info.banner"]]) {
            [self.server setBanner:[message dataForName:@"wired.info.banner"]];
            updated = YES;
            
        } 
        if([message getUInt64:&size forName:@"wired.info.files.size"] && size != self.server.size.unsignedLongLongValue) {
            [self.server setSize:[NSNumber numberWithUnsignedInt:size]];
            updated = YES;
            
        }
        if([message getUInt64:&files forName:@"wired.info.files.count"] && files != self.server.numberOfFiles.unsignedLongLongValue) {
            [self.server setNumberOfFiles:[NSNumber numberWithUnsignedInt:files]];
            updated = YES;
            
        } 
        if([message getUInt32:&downloads forName:@"wired.info.downloads"] && downloads != self.server.downloads.unsignedIntValue) {
            [self.server setDownloads:[NSNumber numberWithUnsignedInt:downloads]];
            updated = YES;
            
        } 
        if([message getUInt32:&uploads forName:@"wired.info.uploads"] && uploads != self.server.uploads.unsignedIntValue) {
            [self.server setUploads:[NSNumber numberWithUnsignedInt:uploads]];
            updated = YES;
            
        } 
        if([message getUInt32:&uploadSpeed forName:@"wired.info.upload_speed"] && uploadSpeed != self.server.uploadSpeed.unsignedIntValue) {
            [self.server setUploadSpeed:[NSNumber numberWithUnsignedInt:uploadSpeed]];
            updated = YES;
            
        } 
        if([message getUInt32:&downloadSpeed forName:@"wired.info.download_speed"] && downloadSpeed != self.server.downloadSpeed.unsignedIntValue) {
            [self.server setDownloadSpeed:[NSNumber numberWithUnsignedInt:downloadSpeed]];
            updated = YES;
            
        }
        if([message getBool:&supportsResourceForks forName:@"wired.info.supports_rsrc"] && supportsResourceForks != self.server.supportRsrc.boolValue) {
            [self.server setSupportRsrc:[NSNumber numberWithBool:supportsResourceForks]];
            updated = YES;
            
        }
        if(![[message dateForName:@"wired.info.start_time"] isEqualToDate:self.server.startTime]) {
            [self.server setStartTime:[message dateForName:@"wired.info.start_time"]];
            updated = YES;
            
        }
    }
    
    if(updated)
        [self save];
    
    return updated;
}


@end






@implementation WDataController (Fetching)


- (WChat *)fetchPublicChat {
    WChat *chat = nil;
        
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(chatID == 1) && (server == %@)", self.server];
    chat = [self.managedObjectContext fetchEntityNammed:@"Chat" withPredicate:p error:nil];
    
    return chat;
}

- (WChat *)fetchChat:(WIP7Message *)message {
    WChat *chat = nil;
    WIP7UInt32 chatID;
    
    [message getUInt32:&chatID forName:@"wired.chat.id"];
    
    NSNumber *chatIDNumber = [NSNumber numberWithUnsignedInt:chatID];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(chatID == %@) && (server == %@)", chatIDNumber, self.server];
    chat = [self.managedObjectContext fetchEntityNammed:@"Chat" withPredicate:p error:nil];
    
    return chat;
}

- (WConversation *)fetchConversation:(WIP7Message *)message {
    WIP7UInt32 userID;
    WConversation *conv = nil;
    WUser *user = nil;

    [message getUInt32:&userID forName:@"wired.user.id"];    
    user = [self fetchUser:message];
    
    if(user) {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"(withNick like[cd] %@)", user.nick];
        conv = [self.managedObjectContext fetchEntityNammed:@"Conversation" withPredicate:p error:nil];
    }
    
    return conv;
}


- (WUser *)fetchOrCreateOrUpdateUser:(WIP7Message *)message {
    WUser *user = nil;
    
    user = [self fetchUser:message];
    
    if(!user) // if not, create it
        user = [self createUser:message];
    else // else, update it
        [self updateUser:user withMessage:message];
    
    return user;
}

- (WUser *)fetchUser:(WIP7Message *)message {
    WUser *user = nil;
    WChat *publicChat = [self.server publicChat];
    WIP7UInt32 userID;
    
    [message getUInt32:&userID forName:@"wired.user.id"];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(ANY chats == %@) AND (userID == %@)", publicChat, [NSNumber numberWithUnsignedInt:userID]];
    user = [self.managedObjectContext fetchEntityNammed:@"User" withPredicate:p error:nil];
    
    return user;
}

- (WUser *)fetchUserForID:(WIP7UInt32)userID {
    WUser *user = nil;
    WChat *publicChat = [self.server publicChat];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(ANY chats == %@) AND (userID == %@)", publicChat, [NSNumber numberWithUnsignedInt:userID]];
    user = [self.managedObjectContext fetchEntityNammed:@"User" withPredicate:p error:nil];
    
    return user;
}

- (WUser *)createUser:(WIP7Message *)message {
    WUser *newUser = nil;
    //NSLog(@"createUser for server : %@", self.server.serverName);
    
    WIP7UInt32 userID;
    WIP7Bool isIlde;
    WIP7Enum wiredColor;
    
    [message getUInt32:&userID forName:@"wired.user.id"];
    [message getBool:&isIlde forName:@"wired.user.idle"];
    [message getEnum:&wiredColor forName:@"wired.account.color"];
    
    newUser = [WUser insertInManagedObjectContext:self.managedObjectContext];
    [newUser setUserID:[NSNumber numberWithUnsignedInt:userID]];
    [newUser setIdle:[NSNumber numberWithBool:isIlde]];
    [newUser setNick:[message stringForName:@"wired.user.nick"]];
    [newUser setStatus:[message stringForName:@"wired.user.status"]];
    [newUser setIcon:[message dataForName:@"wired.user.icon"]];
    [newUser setWiredColor:[NSNumber numberWithInt:wiredColor]];
    
    [self.server.publicChat addUsersObject:newUser];
    [newUser addChatsObject:self.server.publicChat];
    
    return newUser;
}

- (BOOL)updateUser:(WUser *)user withMessage:(WIP7Message *)message {
    BOOL wasUpdated = NO;
    
    WIP7UInt32 userID;
    WIP7Bool isIlde;
    WIP7Enum wiredColor;
    
    [message getEnum:&wiredColor forName:@"wired.account.color"];
    [message getBool:&isIlde forName:@"wired.user.idle"];
    
    if (isIlde != [user.idle boolValue]) {
        [user setIdle:[NSNumber numberWithBool:isIlde]];
        wasUpdated = YES;
    }
    
    if (![[message stringForName:@"wired.user.nick"] isEqualToString:user.nick]) {
        [user setNick:[message stringForName:@"wired.user.nick"]];
        wasUpdated = YES;
    }
    
    if (![[message stringForName:@"wired.user.status"] isEqualToString:user.status]) {
        [user setStatus:[message stringForName:@"wired.user.status"]];
        wasUpdated = YES;
    }
    
    if (![[message dataForName:@"wired.user.icon"] isEqualToData:user.icon]) {
        [user setIcon:[message dataForName:@"wired.user.icon"]];
        wasUpdated = YES;
    }
    
    if (wiredColor != user.wiredColor.integerValue) {
        [user setWiredColor:[NSNumber numberWithInt:wiredColor]];
        wasUpdated = YES;
    }
    
    
    return wasUpdated;
}



- (WChatMessage *)fetchOrCreateOrUpdateChatMessage:(WIP7Message *)message {
    WChatMessage *chatMessage = nil;
 
    if(!chatMessage) {
        chatMessage = [self createChatMessage:message];
    }
    
    return chatMessage;
}

- (WChatMessage *)fetchChatMessage:(WIP7Message *)message {
    WChatMessage *chatMessage = nil;

    return chatMessage;
}

- (WChatMessage *)createChatMessage:(WIP7Message *)message {
    NSLog(@"createChatMessage");
    
    WChatMessage *chatMessage = nil;
    WChat *chat = nil;
    WUser *user = nil;
        
    WIP7UInt32 userID;
    WIP7UInt32 chatID;
    
    [message getUInt32:&chatID forName:@"wired.chat.id"];
    [message getUInt32:&userID forName:@"wired.user.id"];
    
    user = [self fetchUser:message];
    chat = [self fetchChat:message];
        
    if(user && chat) {
        NSDate *now = [[NSDate alloc] init]; 
        
        chatMessage = [WChatMessage insertInManagedObjectContext:self.managedObjectContext];
        if([message stringForName:@"wired.chat.say"]) {
            [chatMessage setText:[message stringForName:@"wired.chat.say"]];
            chatMessage.type = @"say";
        } else {
            [chatMessage setText:[message stringForName:@"wired.chat.me"]];
            chatMessage.type = @"me";
        }
        chatMessage.userID = user.userID;
        chatMessage.nick = user.nick;
        chatMessage.sentDate = now; 
        
        if(![chatMessage.nick isEqualToString:[self.server.connection valueForKey:@"nick"]]) {
            chatMessage.read = [NSNumber numberWithBool:NO];
        }
        
        [chat addMessagesObject:chatMessage];
        [chatMessage setChat:chat];
                
        [now release];
    }
    return chatMessage;
}


- (WPrivateMessage *)fetchOrCreateOrUpdatePrivateMessage:(WIP7Message *)message {
    WPrivateMessage *privateMessage = nil;
    
    if(!privateMessage) {
        privateMessage = [self createPrivateMessage:message];
    }
    
    return privateMessage;
}

- (WPrivateMessage *)fetchPrivateMessage:(WIP7Message *)message {
    return nil;
}

- (WPrivateMessage *)createPrivateMessage:(WIP7Message *)message {
    WPrivateMessage *privateMessage = nil;
    NSDate *now = [NSDate date]; 
    WUser *fromUser = nil;
    WUser *toUser = nil;
    
    WIP7UInt32 userID;
    [message getUInt32:&userID forName:@"wired.user.id"];    
    fromUser = [self fetchUser:message];
    
    // get an existing conversation
    WConversation *conversation = [self fetchConversation:message];
    if(!conversation) {
        conversation = [WConversation insertInManagedObjectContext:self.managedObjectContext];
        [conversation setWithNick:fromUser.nick];
    }
    
    //toUser = [self fetchUserForID:[[self.server.connection valueForKey:@"userID"] unsignedIntValue]];
    
    if(fromUser) {
        privateMessage = [WPrivateMessage insertInManagedObjectContext:self.managedObjectContext];
        privateMessage.text = [message stringForName:@"wired.message.message"];
        privateMessage.userID = fromUser.userID;
        privateMessage.nick = fromUser.nick;
        privateMessage.sentDate = now;
        privateMessage.read = [NSNumber numberWithBool:NO];
        
        [self.server addPrivateMessagesObject:privateMessage];
        [privateMessage setServer:self.server];
        
        [conversation addMessagesObject:privateMessage];
    }
    
    return privateMessage;
}


- (WEvent *)createEvent:(WIP7Message *)message {
    WEvent *event = [WEvent insertInManagedObjectContext:self.managedObjectContext];
    
    if([message.name isEqualToString:@"wired.chat.topic"]) {
        
    }
    
    return event;
}

@end
