//
//  NSManagedObjectContext+Fetch.m
//  Sub
//
//  Created by nark on 15/05/11.
//  Copyright 2011 Read-Write.fr. All rights reserved.
//

#import "NSManagedObjectContext+Fetch.h"


@implementation NSManagedObjectContext (Fetch)

- (NSArray *)fetchEntitiesNammed:(NSString *)name withPredicate:(NSPredicate *)predicate error:(NSError **)error {
    //NSError *error = nil;
	
    NSArray *ret = nil;
    
    @synchronized(self) {
        NSFetchRequest *request;
        NSEntityDescription *desc;
        
        desc = [NSEntityDescription entityForName:name inManagedObjectContext:self];
        request = [[NSFetchRequest alloc] init];
        
        [request setEntity:desc];
        if(predicate)
            [request setPredicate:predicate];
        
        ret = [self executeFetchRequest:request error:error];	
        [request release];
    }
    return ret;	
}



- (NSArray *)fetchEntitiesNammed:(NSString *)name withPredicate:(NSPredicate *)predicate descriptor:(NSSortDescriptor *)descriptor limit:(NSInteger)limit error:(NSError **)error {
    //NSError *error = nil;
    
   
	
    NSArray *ret = nil;
    
    @synchronized(self) {
        NSFetchRequest *request;
        NSEntityDescription *desc;
        
        desc = [NSEntityDescription entityForName:name inManagedObjectContext:self];
        request = [[NSFetchRequest alloc] init];
        
        [request setFetchLimit:limit];
        [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
        [request setEntity:desc];
        
        if(predicate)
            [request setPredicate:predicate];
        
        ret = [self executeFetchRequest:request error:error];
        [request release];
        
    }
    return ret;
}



- (id)fetchEntityNammed:(NSString *)name withPredicate:(NSPredicate *)predicate error:(NSError **)error {
    id ret = nil;
    
    @synchronized(self) {
        NSArray *entities = nil;
        NSFetchRequest *request;
        NSEntityDescription *desc;
        
        desc = [NSEntityDescription entityForName:name inManagedObjectContext:self];
        request = [[NSFetchRequest alloc] init];
        
        [request setEntity:desc];
        if(predicate)
            [request setPredicate:predicate];
        
        entities = [self executeFetchRequest:request error:error];	
        [request release];
        
        if(entities && [entities count] > 0) {
            ret = [entities objectAtIndex:0];
        }
    }
    return ret;
}


@end
