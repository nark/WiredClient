/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <WiredNetworking/WIP7Message.h>
#import <WiredNetworking/WIP7NotificationCenter.h>

@interface WIP7Notification : WIObject {
@public
	id						_observer;
	NSString				*_messageName;
	WIP7UInt32				_transaction;
	SEL						_selector;
}

@end


@implementation WIP7Notification

- (void)dealloc {
	[_messageName release];
	
	[super dealloc];
}

@end



@implementation WIP7NotificationCenter

- (id)init {
	self = [super init];
	
	_messageNameObservers = [[NSMutableArray alloc] init];
	_transactionObservers = [[NSMutableArray alloc] init];

	return self;
}



- (void)dealloc {
	[_messageNameObservers release];
	[_transactionObservers release];
	
	[super dealloc];
}



#pragma mark -

- (void)setTransactionFieldName:(NSString *)transactionFieldName {
	[transactionFieldName retain];
	[_transactionFieldName release];
	
	_transactionFieldName = transactionFieldName;
}



- (NSString *)transactionFieldName {
	return _transactionFieldName;
}



#pragma mark -

- (void)addObserver:(id)observer selector:(SEL)selector messageName:(NSString *)messageName {
	WIP7Notification		*notification;
	
	notification = [[WIP7Notification alloc] init];
	notification->_observer = observer;
	notification->_messageName = [messageName retain];
	notification->_selector = selector;
	[_messageNameObservers addObject:notification];
	[notification release];
}



- (void)addObserver:(id)observer selector:(SEL)selector message:(WIP7Message *)message {
	WIP7Notification		*notification;
	WIP7UInt32				transaction;
	
	if(_transactionFieldName && [message getUInt32:&transaction forName:_transactionFieldName]) {
		notification = [[WIP7Notification alloc] init];
		notification->_observer = observer;
		notification->_transaction = transaction;
		notification->_selector = selector;
		[_transactionObservers addObject:notification];
		[notification release];
	}
}



- (void)removeObserver:(id)observer messageName:(NSString *)messageName {
	WIP7Notification		*notification;
	NSUInteger				i, count;
	
	count = [_messageNameObservers count];
	
	for(i = 0; i < count; i++) {
		notification = [_messageNameObservers objectAtIndex:i];
		
		if(notification->_observer == observer &&
		   [notification->_messageName isEqualToString:messageName]) {
			[_messageNameObservers removeObjectAtIndex:i];
			
			i--;
			count--;
		}
	}
}



- (void)removeObserver:(id)observer message:(WIP7Message *)message {
	WIP7Notification		*notification;
	WIP7UInt32				transaction;
	NSUInteger				i, count;
	
	if(_transactionFieldName && [message getUInt32:&transaction forName:_transactionFieldName]) {
		count = [_transactionObservers count];
		
		for(i = 0; i < count; i++) {
			notification = [_transactionObservers objectAtIndex:i];
			
			if(notification->_observer == observer &&
			   notification->_transaction == transaction) {
				[_transactionObservers removeObjectAtIndex:i];
				
				i--;
				count--;
			}
		}
	}
}



- (void)removeObserver:(id)observer {
	WIP7Notification		*notification;
	NSUInteger				i, count;
	
	count = [_messageNameObservers count];
	
	for(i = 0; i < count; i++) {
		notification = [_messageNameObservers objectAtIndex:i];
		
		if(notification->_observer == observer) {
			[_messageNameObservers removeObjectAtIndex:i];
			
			i--;
			count--;
		}
	}

	count = [_transactionObservers count];
	
	for(i = 0; i < count; i++) {
		notification = [_transactionObservers objectAtIndex:i];
		
		if(notification->_observer == observer) {
			[_transactionObservers removeObjectAtIndex:i];
			
			i--;
			count--;
		}
	}
}



- (void)postMessage:(WIP7Message *)message {
	NSString				*messageName;
	WIP7Notification		*notification;
	NSUInteger				i;
	WIP7UInt32				transaction;
	BOOL					posted = NO;

	if(_transactionFieldName && [message getUInt32:&transaction forName:_transactionFieldName]) {
		for(i = 0; i < [_transactionObservers count]; i++) {
			notification = [_transactionObservers objectAtIndex:i];
			
			if(notification->_transaction == transaction) {
				[notification->_observer performSelector:notification->_selector withObject:message];
				
				posted = YES;
			}
		}
	}
	
	if(!posted) {
		messageName = [message name];
		
		if(messageName) {
			for(i = 0; i < [_messageNameObservers count]; i++) {
				notification = [_messageNameObservers objectAtIndex:i];
				
				if([notification->_messageName isEqualToString:messageName])
					[notification->_observer performSelector:notification->_selector withObject:message];
			}
		}
	}
}

@end
