//
//  WIEmoticon.m
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 30/09/13.
//  Copyright (c) 2013 Read-Write.fr. All rights reserved.
//

#import "WIEmoticon.h"


@interface WIEmoticon (Private)

- (WIEmoticon *)_initWithPath:(NSString *)path
                  equivalents:(NSArray *)textEquivalents
                         name:(NSString *)name
                         pack:(WIEmoticonPack *)pack;

@end



@implementation WIEmoticon (Private)

- (WIEmoticon *)_initWithPath:(NSString *)path
                  equivalents:(NSArray *)textEquivalents
                         name:(NSString *)name
                         pack:(WIEmoticonPack *)pack
{
    if ((self = [super init])) {
		_path               = [path retain];
		_name               = [name retain];
		_textEquivalents    = [textEquivalents retain];
		_pack               = [pack retain];
        _enabled            = NO;
    }
    
    return self;
}


@end






@implementation WIEmoticon

#pragma mark -

@synthesize path                = _path;
@synthesize name                = _name;
@synthesize textEquivalents     = _textEquivalents;
@synthesize pack                = _pack;
@synthesize enabled             = _enabled;
@dynamic    image;
@dynamic    equivalent;
@dynamic    sortedEquivalents;


#pragma mark -

+ (id)emoticonWithPath:(NSString *)path
           equivalents:(NSArray *)textEquivalents
                  name:(NSString *)name
                  pack:(WIEmoticonPack *)pack
{
    return [[[[self class] alloc] _initWithPath:path
                                    equivalents:textEquivalents
                                           name:name
                                           pack:pack] autorelease];
}





#pragma mark -

- (void)dealloc
{
    [_path release];
    [_name release];
    [_sortedEquivalents release];
    [_textEquivalents release];
    [_pack release];
    [_image release];
    
    [super dealloc];
}





#pragma mark -

- (NSImage *)image {
    if(!_image) _image = [[NSImage alloc] initWithContentsOfFile:_path];
    return _image;
}


- (NSString *)equivalent {
    return [_textEquivalents objectAtIndex:0];
}


- (NSArray *)sortedEquivalents {
    NSArray *descriptors;
    
    if(!_sortedEquivalents) {
        descriptors = [NSArray arrayWithObject:
                       [NSSortDescriptor sortDescriptorWithKey:@"length"
                                                     ascending:NO]];
        
        _sortedEquivalents = [[self.textEquivalents sortedArrayUsingDescriptors:descriptors] retain];
    }
    return _sortedEquivalents;
}


@end
