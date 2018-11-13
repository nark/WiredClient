//
//  WDataController.h
//  iWi
//
//  Created by Rafaël Warnault on 26/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const WDataControllerUpdateUsersNotification;
extern NSString * const WDataControllerUpdateChatNotification;
extern NSString * const WDataControllerUpdateMessagesNotification;


@interface WDataController : NSObject

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WServer *server;

- (BOOL)updateServer:(WIP7Message *)message;
- (WConversation *)fetchConversationForNick:(NSString *)nick;

- (id)initWithServer:(WServer *)server;
- (void)receiveMessage:(WIP7Message *)message;

- (void)cleanUsers;
- (BOOL)save;


@end
