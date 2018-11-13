//
//  WiredData.h
//  WiredData
//
//  Created by Rafaël Warnault on 30/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import <WiredData/WChat.h>
#import <WiredData/WChatMessage.h>
#import <WiredData/WConversation.h>
#import <WiredData/WEvent.h>
#import <WiredData/WMessage.h>
#import <WiredData/WNode.h>
#import <WiredData/WPrivateMessage.h>
#import <WiredData/WServer.h>
#import <WiredData/WUser.h>

#import <WiredData/NSManagedObjectContext+Fetch.h>


@interface WiredData : NSObject

+ (NSManagedObjectModel *)managedObjectModel;

@end