//
//  SBJsonWriter+WCJsonWriter.m
//  WiredClient
//
//  Created by Rafaël Warnault on 10/09/13.
//
//

#import "SBJsonWriter+WCJsonWriter.h"

@implementation SBJsonWriter (WCJsonWriter)

static SBJsonWriter *_instance;

+ (id)writer {
    if(!_instance)
        _instance = [[SBJsonWriter alloc] init];

    return _instance;
}

@end
