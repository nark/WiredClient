//
//  WServerConnection.h
//  iWi
//
//  Created by Rafaël Warnault on 30/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WConnection.h"

@interface WServerConnection : WConnection

@property (nonatomic, retain) WServer *server;

- (id)initWithServer:(WServer *)server;

@end
