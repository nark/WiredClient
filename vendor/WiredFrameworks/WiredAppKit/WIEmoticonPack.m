//
//  WIEmoticonPack.m
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 30/09/13.
//  Copyright (c) 2013 Read-Write.fr. All rights reserved.
//

#import "WIEmoticonPack.h"
#import "WIEmoticon.h"
#import "NSImage-WIAppKit.h"


#define WI_EMOTICON_PLIST_FILENAME	   		@"Emoticons.plist"
#define WI_EMOTICON_LIST					@"Emoticons"

#define WI_EMOTICON_EQUIVALENTS             @"Equivalents"
#define WI_EMOTICON_NAME					@"Name"




@interface WIEmoticonPack (Private)

- (id)_initEmoticonPackFromPath:(NSString *)path;

- (void)_loadEmoticons;

@end




@implementation WIEmoticonPack (Private)

- (id)_initEmoticonPackFromPath:(NSString *)path {
    NSString    *localizedName;
    
    self = [super init];
    if (self) {
        _path           = [path retain];
        _bundle         = [[NSBundle bundleWithPath:_path] retain];
        
        if(!_bundle) return nil;
        
		if ((localizedName = [[_bundle localizedInfoDictionary] objectForKey:_name])) {
			_name = [localizedName retain];
		} else {
            _name = [[[path lastPathComponent] stringByDeletingPathExtension] retain];
        }
        
        _emoticonArray          = [[NSMutableArray alloc] init];
        _enabledEmoticonArray   = nil;
    }
    return self;
}



- (void)_loadEmoticons {
    NSString            *infoDictPath;
	NSDictionary        *infoDict, *emoticons;

    infoDictPath    = [_bundle pathForResource:WI_EMOTICON_PLIST_FILENAME ofType:nil];
    infoDict        = [NSDictionary dictionaryWithContentsOfFile:infoDictPath];
    
    emoticons       = [infoDict objectForKey:WI_EMOTICON_LIST];
    
    [emoticons enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSArray     *equivalents;
        NSString    *emoticonName;
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            emoticonName    = [(NSDictionary *)obj objectForKey:WI_EMOTICON_NAME];
            equivalents     = [(NSDictionary *)obj objectForKey:WI_EMOTICON_EQUIVALENTS];
            
            [_emoticonArray addObject:[WIEmoticon emoticonWithPath:[_bundle pathForImageResource:key]
                                                       equivalents:equivalents
                                                              name:emoticonName
                                                              pack:self]];
        }
    }];
}


@end




@implementation WIEmoticonPack

#pragma mark -

@synthesize bundle                  = _bundle;
@synthesize path                    = _path;
@synthesize name                    = _name;

@dynamic    enabled;
@dynamic    emoticons;
@dynamic    enabledEmoticons;



#pragma mark -

+ (id)emoticonPackFromPath:(NSString *)path {
    return [[[[self class] alloc] _initEmoticonPackFromPath:path] autorelease];
}



#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
    WIEmoticonPack	*newPack = [[WIEmoticonPack alloc] _initEmoticonPackFromPath:_path];
    
	newPack->_emoticonArray = [_emoticonArray mutableCopy];
	newPack->_path          = _path;
	newPack->_bundle        = _bundle;
	newPack->_name          = _name;
    
    return newPack;
}


#pragma mark -

- (void)dealloc
{
    [_bundle release];
    [_path release];
    [_name release];
    [_emoticonArray release];
    [_enabledEmoticonArray release];
    
    [super dealloc];
}




#pragma mark -

- (NSArray *)emoticons {
	if (!_emoticonArray || [_emoticonArray count] == 0) [self _loadEmoticons];
	return _emoticonArray;
}


- (NSArray *)enabledEmoticons {
    NSPredicate *predicate;
    
    if (!_enabledEmoticonArray) {
        predicate               = [NSPredicate predicateWithFormat:@"enabled == TRUE"];
		_enabledEmoticonArray   = [[self.emoticons filteredArrayUsingPredicate:predicate] retain];
	}
    
	return _enabledEmoticonArray;
}



- (BOOL)isEnabled {
    return _enabled;
}


- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
}


- (void)setEnabled:(BOOL)enabled all:(BOOL)all {
    _enabled = enabled;
    
    if(all)
        for(WIEmoticon *emoticon in self.emoticons)
            [emoticon setEnabled:enabled];
}



#pragma mark -

- (NSImage *)previewImage
{
    NSImage         *image;
	NSArray         *myEmoticons = [self emoticons];
	WIEmoticon      *emoticon;
    
	for (emoticon in myEmoticons) {
		NSArray *equivalents = [emoticon textEquivalents];
		if ([equivalents containsObject:@":)"] || [equivalents containsObject:@":-)"]) {
			break;
		}
	}
    
	//If we didn't find a happy emoticon, use the first one in the array
	if (!emoticon && [myEmoticons count]) {
		emoticon = [myEmoticons objectAtIndex:0];
	}
    
    image = [[[emoticon image] copy] autorelease];
    
    [image setSize:NSMakeSize(16, 16)];
    
	return image;
}



- (void)setDisabledEmoticons:(NSArray *)array
{
    //Flag our emoticons as enabled/disabled
    for (WIEmoticon *emoticon in self.emoticons) {
        [emoticon setEnabled:(![array containsObject:[emoticon name]])];
    }
	
	//reset the emabled emoticon list
	if (_enabledEmoticonArray) {
        [_enabledEmoticonArray release]; _enabledEmoticonArray = nil;
	}
}


- (NSString *)packKey {
    return [NSSWF:@"Pack:%@", self.name];
}



#pragma mark -
#pragma mark NSPasteboardWriting support

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return [NSArray arrayWithObjects:(id)WIEmoticonPackPBoardType, nil];
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    return [self.packKey pasteboardPropertyListForType:type];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([self.packKey respondsToSelector:@selector(writingOptionsForType:pasteboard:)]) {
        return [self.packKey writingOptionsForType:type pasteboard:pasteboard];
    } else {
        return 0;
    }
}



#pragma mark -
#pragma mark  NSPasteboardReading support

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    // We allow creation from folder and image URLs only, but there is no way to specify just file URLs that contain images
    return [NSArray arrayWithObjects:(id)WIEmoticonPackPBoardType, nil];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    return NSPasteboardReadingAsString;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    // We recreate the appropriate object
    [self release];
    self = nil;
//    // We only have URLs accepted. Create the URL
//    NSURL *url = [[[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] autorelease];
//    // Now see what the data type is; if it isn't an image, we return nil
//    NSString *urlUTI;
//    if ([url getResourceValue:&urlUTI forKey:NSURLTypeIdentifierKey error:NULL]) {
//        // We could use UTTypeConformsTo((CFStringRef)type, kUTTypeImage), but we want to make sure it is an image UTI type that NSImage can handle
//        if ([[NSImage imageTypes] containsObject:urlUTI]) {
//            // We can use it with NSImage
//            self = [[ATDesktopImageEntity alloc] initWithFileURL:url];
//        } else if ([urlUTI isEqualToString:(id)kUTTypeFolder]) {
//            // It is a folder
//            self = [[ATDesktopFolderEntity alloc] initWithFileURL:url];
//        }
//    }
    // We may return nil
    return self;
}



#pragma mark -

- (NSString *)description {
    return self.packKey;
}

@end
