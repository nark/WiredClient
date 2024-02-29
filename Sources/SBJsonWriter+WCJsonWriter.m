//
//  SBJsonWriter+WCJsonWriter.m
//  WiredClient
//
//  Created by Rafaël Warnault on 10/09/13.
//
//



@implementation SBJson4Writer (WCJsonWriter)

+ (id)writer {
    static SBJson4Writer *_instance;
    
    if(!_instance)
        _instance = [[SBJson4Writer alloc] init];

    return _instance;
}

@end
