/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
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

#import "WCAccount.h"
#import "WCServerConnection.h"
#import "WCTransfer.h"
#import "WCUser.h"

@interface WCUser(Private)

- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;

@end


@implementation WCUser(Private)

- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	NSImage			*image;
	WIP7UInt32		uid, cipherBits;
	WIP7Enum		color;
	WIP7Bool		idle;

	self = [super initWithConnection:connection];
	
	[message getUInt32:&uid forName:@"wired.user.id"];
	[message getBool:&idle forName:@"wired.user.idle"];
	
	if([message getUInt32:&cipherBits forName:@"wired.user.cipher.bits"])
	   _cipherBits = cipherBits;
	
	if([message getEnum:&color forName:@"wired.account.color"])
		_color = color;
	else
		_color = WCAccountColorBlack;
	
	_userID = uid;
	
	[self setIdle:idle];
	[self setNick:[message stringForName:@"wired.user.nick"]];
	[self setStatus:[message stringForName:@"wired.user.status"]];
	
	image = [[NSImage alloc] initWithData:[message dataForName:@"wired.user.icon"]];
	
	if(image) {
		if([image size].width > 0.0 && [image size].height > 0.0)
			[self setIcon:image];

		[image release];
	}
	
	_login			= [[message stringForName:@"wired.user.login"] retain];
	_address		= [[message stringForName:@"wired.user.ip"] retain];
	_host			= [[message stringForName:@"wired.user.host"] retain];
	_version		= [[WCServerConnection versionStringForMessage:message] retain];
	_cipherName		= [[message stringForName:@"wired.user.cipher.name"] retain];
	_joinDate		= [[message dateForName:@"wired.user.login_time"] retain];
	_idleDate		= [[message dateForName:@"wired.user.idle_time"] retain];
	_transfer		= [[WCTransfer transferWithMessage:message connection:connection] retain];
	
	if(!_joinDate)
		_joinDate = [[NSDate date] retain];
	
	return self;
}

@end


@implementation WCUser

+ (NSColor *)colorForColor:(WCAccountColor)color idleTint:(BOOL)idleTint {
	NSColor		*value;
	
	switch(color) {
		case WCAccountColorBlack:
		default:
			value = [NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.0 alpha:1.0];
			break;
			
		case WCAccountColorRed:
			value = [NSColor redColor];
			break;
			
		case WCAccountColorOrange:
			value = [NSColor orangeColor];
			break;
			
		case WCAccountColorGreen:
			value = [NSColor colorWithCalibratedRed:0.0 green:0.8 blue:0.0 alpha:1.0];
			break;
			
		case WCAccountColorBlue:
			value = [NSColor blueColor];
			break;
			
		case WCAccountColorPurple:
			value = [NSColor purpleColor];
			break;
	}
	
	if(idleTint) {
		if(color == WCAccountColorBlack) {
			value = [NSColor colorWithCalibratedHue:[value hueComponent]
										 saturation:[value saturationComponent]
										 brightness:0.5
											  alpha:[value alphaComponent]];
		} else {
			value = [NSColor colorWithCalibratedHue:[value hueComponent]
										 saturation:0.5
										 brightness:[value brightnessComponent]
											  alpha:[value alphaComponent]];
		}
	}
	
	return value;
}



#pragma mark -

+ (id)userWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithMessage:message connection:connection] autorelease];
}



- (void)dealloc {
	[_nick release];
	[_status release];
	[_icon release];
	[_login release];
	[_address release];
	[_host release];
	[_version release];
	[_joinDate release];
	[_idleDate release];
	[_account release];
	[_transfer release];

	[super dealloc];
}



#pragma mark -

- (BOOL)isEqual:(id)object {
	if(![self isKindOfClass:[object class]])
		return NO;
	
	return [self userID] == [object userID];
}



- (NSUInteger)hash {
	return [self userID];
}



#pragma mark -

- (void)setIdle:(BOOL)value {
	_idle = value;
}



- (void)setIcon:(NSImage *)icon {
	[icon retain];
	[_icon release];

	_icon = icon;
}



- (void)setNick:(NSString *)nick {
	[nick retain];
	[_nick release];

	_nick = nick;
}



- (void)setStatus:(NSString *)status {
	[status retain];
	[_status release];

	_status = status;
}



- (void)setAccount:(WCUserAccount *)account {
	[account retain];
	[_account release];

	_account = account;
}



- (void)setColor:(WCAccountColor)color {
	_color = color;
}



#pragma mark -

- (NSUInteger)userID {
	return _userID;
}



- (BOOL)isIdle {
	return _idle;
}



- (NSImage *)icon {
	return _icon;
}



- (NSImage *)iconWithIdleTint:(BOOL)value {
	return _idle && value
		? [_icon tintedImageWithColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]]
		: _icon;
}



- (NSString *)nick {
	return _nick;
}



- (NSString *)status {
	return _status;
}



- (NSString *)login {
	return _login;
}



- (NSString *)address {
	return _address;
}



- (NSString *)host {
	return _host;
}



- (NSString *)version {
	return _version;
}



- (NSUInteger)cipherBits {
	return _cipherBits;
}



- (NSString *)cipherName {
	return _cipherName;
}



- (NSDate *)joinDate {
	return _joinDate;
}



- (NSDate *)idleDate {
	return _idleDate;
}



- (WCUserAccount *)account {
	return _account;
}



- (WCTransfer *)transfer {
	return _transfer;
}



- (WCAccountColor)color {
	return _color;
}



#pragma mark -

- (BOOL)isIgnored {
	NSEnumerator	*enumerator;
	NSDictionary	*ignore;

	enumerator = [[[WCSettings settings] objectForKey:WCIgnores] objectEnumerator];

	while((ignore = [enumerator nextObject])) {
		if([[ignore objectForKey:WCIgnoresNick] isEqualToString:[self nick]])
			return YES;
	}

	return NO;
}

@end
