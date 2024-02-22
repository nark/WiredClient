//
//  WIEmoticonPack.h
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 30/09/13.
//  Copyright (c) 2013 Read-Write.fr. All rights reserved.
//

#import <WiredFoundation/WiredFoundation.h>

#define	WIEmoticonPackPBoardType         @"fr.read-write.WiredAppKit.WIEmoticonPack"

@interface WIEmoticonPack : WIObject <NSCopying, NSPasteboardWriting, NSPasteboardReading> {
    NSBundle			*_bundle;
    NSString			*_path;
    NSString			*_name;
	NSString			*_serviceClass;
    NSMutableArray		*_emoticonArray;
	NSArray				*_enabledEmoticonArray;
    BOOL				_enabled;
}

@property (readwrite, retain) NSBundle              *bundle;
@property (readwrite, retain) NSString              *path;
@property (readwrite, retain) NSString              *name;
@property (readwrite, retain) NSArray               *emoticons;
@property (readwrite, retain) NSArray               *enabledEmoticons;
@property (readwrite, getter = isEnabled) BOOL      enabled;

+ (id)emoticonPackFromPath:(NSString *)path;

- (NSImage *)previewImage;

- (void)setEnabled:(BOOL)enabled all:(BOOL)all;
- (void)setDisabledEmoticons:(NSArray *)array;

- (NSString *)packKey;

@end
