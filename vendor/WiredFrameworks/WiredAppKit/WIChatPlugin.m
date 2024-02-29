//
//  WIChatPlugin.m
//  wired
//
//  Created by Rafaël Warnault on 16/06/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WIChatPlugin.h"

@implementation WIChatPlugin



#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc
{
    [_command release];
    [super dealloc];
}





#pragma mark -

- (void)initPlugin {
	 _command		= nil;
	_hasArguments	= NO;
}


- (NSString *)commandOutput {
	return nil;
}




#pragma mark -

- (NSString *)command {
	return _command;
}



@end
