//
//  WITemplateBundleManager.m
//  wired
//
//  Created by Rafaël Warnault on 08/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WITemplateBundleManager.h"
#import "WITemplateBundle.h"



@interface WITemplateBundleManager (Private)

- (void)_checkTemplateDirectory;
- (NSString *)_templateDirectoryPath;

- (void)_reloadTemplates;

@end



@implementation WITemplateBundleManager



#pragma mark -

+ (id)templateManagerForPath:(NSString *)path {
	return [[[[self class] alloc] initWithPath:path] autorelease];
}

+ (id)templateManagerForPath:(NSString *)path isPrivate:(BOOL)private {
	return [[[[self class] alloc] initWithPath:path private:private] autorelease];
}




#pragma mark -

- (id)initWithPath:(NSString *)path;
{
    self = [super init];
    if (self) {
        _path			= [path retain];
		_templates		= [[NSMutableArray alloc] init];
		_private		= YES;
		
		[self _checkTemplateDirectory];
		[self _reloadTemplates];
    }
    return self;
}


- (id)initWithPath:(NSString *)path private:(BOOL)private
{
    self = [super init];
    if (self) {
        _path			= [path retain];
		_templates		= [[NSMutableArray alloc] init];
		_private		= private;
		
		[self _checkTemplateDirectory];
		[self _reloadTemplates];
    }
    return self;
}


- (void)dealloc
{
	[_path release];
    [_templates release];
    [super dealloc];
}




#pragma mark -

- (BOOL)addTemplateAtPath:(NSString *)path {
	WITemplateBundle	*newBundle;
	NSString			*destination;
	NSError				*error;
	
	if(_private)
		return NO;
	
	newBundle	= [WITemplateBundle templateWithPath:path];
	
	if(!newBundle)
		return NO;
	
	if([self templateWithIdentifier:[newBundle bundleIdentifier]])
		return NO;
	
	destination = [[self _templateDirectoryPath] stringByAppendingPathComponent:[path lastPathComponent]];
	
	if(![[NSFileManager defaultManager] copyItemAtPath:path toPath:destination error:&error]) {
		NSLog(@"ERROR: %@", error);
		return NO;
	}
	
	[self _reloadTemplates];
		
	return YES;
}



- (BOOL)removeTemplate:(WITemplateBundle *)bundle {
	NSError			*error;
	
	if(_private)
		return NO;
	
	@synchronized(_templates) {
		if([_templates containsObject:bundle])
			[_templates removeObject:bundle];
	}
	
	if([[NSFileManager defaultManager] removeItemAtPath:[bundle bundlePath] error:&error])
		return YES;
	
	return NO;
}



- (WITemplateBundle *)templateWithIdentifier:(NSString *)identifier {
		
	for(WITemplateBundle *bundle in _templates) {
		if([[bundle bundleIdentifier] isEqualTo:identifier])
			return bundle;
	}
	return nil;
}





#pragma mark -

- (NSString *)path {
	return _path;
}



- (NSArray *)templates {
	return _templates;
}



- (BOOL)isPrivate {
	return _private;
}





#pragma mark -

- (void)_checkTemplateDirectory {
	[[NSFileManager defaultManager] createDirectoryAtPath:[self _templateDirectoryPath]];
}



- (NSString *)_templateDirectoryPath {
	return [[self path] stringByAppendingPathComponent:@"Templates"];
}



- (void)_reloadTemplates {
	WITemplateBundle	*bundle;	
	NSArray				*fileNames;
	NSString			*filePath;
	NSError				*error;
	
	@synchronized(_templates) {
		[_templates removeAllObjects];
		
		error			= nil;
		fileNames		= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self _templateDirectoryPath] error:&error];
		
		if(error != nil)
			return;
		
		for(NSString *fileName in fileNames) {
			filePath	= [[self _templateDirectoryPath] stringByAppendingPathComponent:fileName];
			
			if([[filePath pathExtension] isEqualToString:@"WiredTemplate"]) {
				bundle	= [WITemplateBundle templateWithPath:filePath];
				
				if(bundle)
					[_templates addObject:bundle];
			}
			
			bundle		= nil;
			filePath	= nil;
		}
	}
}


@end



