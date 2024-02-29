//
//  NSTreeController+WIAppKit.m
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 14/03/13.
//  Copyright (c) 2013 Read-Write. All rights reserved.
//

#import "NSTreeController+WIAppKit.h"

@implementation NSTreeController (WIAppKit)

- (NSArray *)rootNodes {
	return [[self arrangedObjects] childNodes];
}

- (NSArray *)flattenedNodes;
{
	NSMutableArray *mutableArray = [NSMutableArray array];
	for (NSTreeNode *node in [self rootNodes]) {
		[mutableArray addObject:node];
		if (![[node valueForKey:[self leafKeyPath]] boolValue])
			[mutableArray addObjectsFromArray:[node valueForKey:@"descendants"]];
	}
	return [[mutableArray copy] autorelease];
}

- (NSTreeNode *)treeNodeForObject:(id)object;
{
	NSTreeNode *treeNode = nil;
	for (NSTreeNode *node in [self rootNodes]) {
		if ([node representedObject] == object) {
			treeNode = node;
			break;
		}
	}
	return treeNode;
}

- (NSIndexPath *)indexPathOfObject:(id)object;
{
	return [[self treeNodeForObject:object] indexPath];
}


@end
