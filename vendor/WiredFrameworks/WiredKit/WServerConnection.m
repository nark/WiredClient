//
//  WServerConnection.m
//  iWi
//
//  Created by Rafaël Warnault on 30/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import "WServerConnection.h"

@implementation WServerConnection

@synthesize server = _server;

- (id)initWithServer:(WServer *)server {
    self = [super initWithURL:server.address login:server.login password:server.password];
    if (self) {
        _server = [server retain];
    }
    return self;
}

- (void)dealloc {
    [_server release], _server = nil;
    [super dealloc];
}

@end
