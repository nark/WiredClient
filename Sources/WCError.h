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

extern NSString * const							WCWiredClientErrorDomain;
extern NSString * const							WCWiredProtocolErrorDomain;


enum _WCWiredClientError {
	WCWiredClientServerDisconnected,
	WCWiredClientBanned,
	WCWiredClientTransferDownloadDirectoryNotFound,
	WCWiredClientTransferExists,
	WCWiredClientTransferFailed,
	WCWiredClientUserNotFound,
};
typedef enum _WCWiredClientError				WCWiredClientError;

enum _WCWiredProtocolError {
	WCWiredProtocolInternalError				= 0,
	WCWiredProtocolInvalidMessage				= 1,
	WCWiredProtocolUnrecognizedMessage			= 2,
	WCWiredProtocolMessageOutOfSequence			= 3,
	WCWiredProtocolLoginFailed					= 4,
	WCWiredProtocolPermissionDenied				= 5,
	WCWiredProtocolNotSubscribed				= 6,
	WCWiredProtocolAlreadySubscribed			= 7,
	WCWiredProtocolChatNotFound					= 8,
	WCWiredProtocolAlreadyOnChat				= 9,
	WCWiredProtocolNotOnChat					= 10,
	WCWiredProtocolNotInvitedToChat				= 11,
	WCWiredProtocolUserNotFound					= 12,
	WCWiredProtocolUserCannotBeDisconnected		= 13,
	WCWiredProtocolFileNotFound					= 14,
	WCWiredProtocolFileExists					= 15,
	WCWiredProtocolAccountNotFound				= 16,
	WCWiredProtocolAccountExists				= 17,
	WCWiredProtocolAccountInUse					= 18,
	WCWiredProtocolTrackerNotEnabled			= 19,
	WCWiredProtocolNotRegistered				= 20,
	WCWiredProtocolBanNotFound					= 21,
	WCWiredProtocolBanExists					= 22,
	WCWiredProtocolBoardNotFound				= 23,
	WCWiredProtocolBoardExists					= 24,
	WCWiredProtocolThreadNotFound				= 25,
	WCWiredProtocolPostNotFound					= 26,
	WCWiredProtocolRsrcNotSupported				= 27
};
typedef enum _WCWiredProtocolError				WCWiredProtocolError;


@interface WCError : WIError

+ (id)errorWithWiredMessage:(WIP7Message *)message;

@end
