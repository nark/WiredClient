//
//  WCWebDataSource.h
//  WiredClient
//
//  Created by Rafaël Warnault on 08/09/13.
//
//

@protocol WCWebDataSource <NSObject>

///* Utils */
//- (NSUInteger)numberOfObjects;
//
///* JSON Representations */
//- (NSString *)JSONObjects;
//- (NSString *)JSONObjectsFromOffset:(NSUInteger)offset withLimit:(NSUInteger)limit;
//- (NSString *)JSONObjectAtIndex:(NSUInteger)index;

- (BOOL)loadScriptWithName:(NSString *)name;

- (NSString *)lastMessageDate;

- (NSString *)JSONObjectsUntilDate:(NSString *)date withLimit:(NSUInteger)limit;

@end