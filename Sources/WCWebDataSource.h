//
//  WCWebDataSource.h
//  WiredClient
//
//  Created by Rafaël Warnault on 08/09/13.
//
//

@protocol WCWebDataSource <NSObject>

- (BOOL)loadScriptWithName:(NSString *)name;

- (NSString *)lastMessageDate;

- (NSString *)JSONObjectsUntilDate:(NSString *)date withLimit:(NSUInteger)limit;

@end