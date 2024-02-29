//
//  NSManagedObjectContext+Fetch.h
//  Sub
//
//  Created by nark on 15/05/11.
//  Copyright 2011 Read-Write. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSManagedObjectContext (Fetch)
- (NSArray *)fetchEntitiesNammed:(NSString *)name withPredicate:(NSPredicate *)predicate error:(NSError **)error;
- (id)fetchEntityNammed:(NSString *)name withPredicate:(NSPredicate *)predicate error:(NSError **)error;
- (void)deleteEntitiesNamed:(NSString *)inEntity withPredicate:(NSPredicate *)predicate;

@end
