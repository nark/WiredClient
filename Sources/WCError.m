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

NSString * const WCWiredClientErrorDomain		= @"WCWiredClientErrorDomain";
NSString * const WCWiredProtocolErrorDomain		= @"WCWiredProtocolErrorDomain";


@implementation WCError

+ (id)errorWithWiredMessage:(WIP7Message *)message {
	WIP7Enum		error;
	
	if(![[message name] isEqualToString:@"wired.error"])
		return NULL;
	
	[message getEnum:&error forName:@"wired.error"];
	
	return [self errorWithDomain:WCWiredProtocolErrorDomain code:error argument:[message stringForName:@"wired.error.string"]];
}



#pragma mark -

- (NSString *)localizedDescription {
	if([[self userInfo] objectForKey:NSLocalizedDescriptionKey])
		return [[self userInfo] objectForKey:NSLocalizedDescriptionKey];
	
	if([[self domain] isEqualToString:WCWiredClientErrorDomain]) {
		switch((WCWiredClientError) [self code]) {
			case WCWiredClientServerDisconnected:
				return NSLS(@"Server Disconnected", @"WCWiredClientServerDisconnected title");
				break;
			
			case WCWiredClientBanned:
				return NSLS(@"Banned", @"WCWiredClientBanned title");
				break;
			
			case WCWiredClientTransferDownloadDirectoryNotFound:
				return NSLS(@"Transfer Destination Not Found", @"WCWiredClientTransferDownloadDirectoryNotFound title");
				break;
				
			case WCWiredClientTransferExists:
				return NSLS(@"Transfer Exists", @"WCWiredClientTransferExists title");
				break;
				
			case WCWiredClientTransferFailed:
				return NSLS(@"Transfer Failed", @"WCWiredClientTransferFailed title");
				break;
				
			case WCWiredClientUserNotFound: 
				return NSLS(@"User Not Found", @"WCWiredClientUserNotFound title"); 
				break;
		}
	}
	else if([[self domain] isEqualToString:WCWiredProtocolErrorDomain]) {
		switch((WCWiredProtocolError) [self code]) {
			case WCWiredProtocolInternalError:
				return NSLS(@"Internal Server Error", @"Wired protocol error title");
				break;
		
			case WCWiredProtocolInvalidMessage:
				return NSLS(@"Invalid Message", @"Wired protocol error title");
				break;
		
			case WCWiredProtocolUnrecognizedMessage:
				return NSLS(@"Unrecognized Message", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolMessageOutOfSequence:
				return NSLS(@"Message Out of Sequence", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolLoginFailed:
				return NSLS(@"Login Failed", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolPermissionDenied:
				return NSLS(@"Permission Denied", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolNotSubscribed:
				return NSLS(@"Not Subscribed", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolAlreadySubscribed:
				return NSLS(@"Already Subscribed", @"Wired protocol error title");
				break;
				
			case WCWiredProtocolChatNotFound:
				return NSLS(@"Chat Not Found", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolAlreadyOnChat:
				return NSLS(@"Already On Chat", @"Wired protocol error title");
				break;
				
			case WCWiredProtocolNotOnChat:
				return NSLS(@"Not On Chat", @"Wired protocol error title");
				break;
				
			case WCWiredProtocolNotInvitedToChat:
				return NSLS(@"Not Invited To Chat", @"Wired protocol error title");
				break;
				
			case WCWiredProtocolUserNotFound:
				return NSLS(@"User Not Found", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolUserCannotBeDisconnected:
				return NSLS(@"Cannot Be Disconnected", @"Wired protocol error title");
				break;
		
			case WCWiredProtocolFileNotFound:
				return NSLS(@"File Or Folder Not Found", @"Wired protocol error title");
				break;
		
			case WCWiredProtocolFileExists:
				return NSLS(@"File Or Folder Exists", @"Wired protocol error title");
				break;
				
			case WCWiredProtocolAccountNotFound:
				return NSLS(@"Account Not found", @"Wired protocol error title");
				break;
				
			case WCWiredProtocolAccountExists:
				return NSLS(@"Account Exists", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolAccountInUse:
				return NSLS(@"Account In Use", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolTrackerNotEnabled:
				return NSLS(@"Tracker Not Enabled", @"Wired protocol error title");
				break;

			case WCWiredProtocolNotRegistered:
				return NSLS(@"Not Registered", @"Wired protocol error title");
				break;
				
			case WCWiredProtocolBanNotFound:
				return NSLS(@"Ban Not Found", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolBanExists:
				return NSLS(@"Ban Exists", @"Wired protocol error title");
				break;

			case WCWiredProtocolBoardNotFound:
				return NSLS(@"Board Not Found", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolBoardExists:
				return NSLS(@"Board Exists", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolThreadNotFound:
				return NSLS(@"Thread Not Found", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolPostNotFound:
				return NSLS(@"Post Not Found", @"Wired protocol error title");
				break;
			
			case WCWiredProtocolRsrcNotSupported:
				return NSLS(@"Resource Fork Not Supported.", @"Wired protocol error title");
				break;
		}
		
		return NSLS(@"Unknown Error", @"Wired protocol error title");
	}
	
	return [super localizedDescription];
}



- (NSString *)localizedFailureReason {
	id		argument;
	
	if([[self userInfo] objectForKey:NSLocalizedFailureReasonErrorKey])
		return [[self userInfo] objectForKey:NSLocalizedFailureReasonErrorKey];
	
	argument = [[self userInfo] objectForKey:WIArgumentErrorKey];

	if([[self domain] isEqualToString:WCWiredClientErrorDomain]) {
		switch((WCWiredClientError) [self code]) {
			case WCWiredClientServerDisconnected:
				return NSLS(@"The server has unexpectedly disconnected.", @"WCWiredClientServerDisconnected description");
				break;
				
			case WCWiredClientBanned:
				return NSLS(@"You have been banned from this server.", @"WCWiredClientBanned description");
				break;
			
			case WCWiredClientTransferDownloadDirectoryNotFound:
				return [NSSWF:NSLS(@"The transfer destination \u201c%@\u201d could not be found.", @"WCWiredClientTransferDownloadDirectoryNotFound description (path)"),
					argument];
				break;
				
			case WCWiredClientTransferExists:
				return [NSSWF:NSLS(@"The transfer of \u201c%@\u201d failed.", @"WCWiredClientTransferFailed description (name)"),
					argument];
				break;
				
			case WCWiredClientTransferFailed:
				return [NSSWF:NSLS(@"The transfer of \u201c%@\u201d failed.", @"WCWiredClientTransferFailed description (name)"),
					argument];
				break;
				
			case WCWiredClientUserNotFound: 
				return NSLS(@"Could not find the user you referred to. Perhaps that user left before the command could be completed.", @"WCWiredClientUserNotFound description"); 
				break; 
		}
	}
	else if([[self domain] isEqualToString:WCWiredProtocolErrorDomain]) {
		switch((WCWiredProtocolError) [self code]) {
			case WCWiredProtocolInternalError:
				if(argument) {
					return [NSSWF:NSLS(@"The server failed to process a command. The server administrator can check the log for more information.\n\nThe message from the server was \u201c%@\u201d.", @"Wired protocol error description (internal error string)"),
							argument];
				} else {
					return NSLS(@"The server failed to process a command. The server administrator can check the log for more information.", @"Wired protocol error description");
				}
				break;
		
			case WCWiredProtocolInvalidMessage:
				return NSLS(@"The server could not parse a message. This is probably because of an protocol incompatibility between the client and the server.", @"Wired protocol error description");
				break;
		
			case WCWiredProtocolUnrecognizedMessage:
				return NSLS(@"The server did not recognize a message. This is probably because of an protocol incompatibility between the client and the server.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolMessageOutOfSequence:
				return NSLS(@"The server received a message out of sequence. This is probably because of an protocol incompatibility between the client and the server.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolLoginFailed:
				return NSLS(@"Could not login, the user name and/or password you supplied was rejected.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolPermissionDenied:
				return NSLS(@"The command could not be completed due to insufficient privileges.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolNotSubscribed:
				return NSLS(@"Could not unsubscribe because you have not subscribed.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolAlreadySubscribed:
				return NSLS(@"Could not subscribe because you are already subscribed.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolChatNotFound:
				return NSLS(@"Could not find the chat you referred to. Perhaps the chat has been removed.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolAlreadyOnChat:
				return NSLS(@"Could not join the chat because you have already joined it.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolNotOnChat:
				return NSLS(@"Could not send message to the chat because you have not joined it.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolNotInvitedToChat:
				return NSLS(@"Could not join the chat because you have not been invited.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolUserNotFound:
				return NSLS(@"Could not find the user you referred to. Perhaps that user left before the command could be completed.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolUserCannotBeDisconnected:
				return NSLS(@"The client you tried to disconnect is protected.", @"Wired protocol error description");
				break;
		
			case WCWiredProtocolFileNotFound:
				return NSLS(@"Could not find the file or folder you referred to. Perhaps someone deleted it.", @"Wired protocol error description");
				break;
		
			case WCWiredProtocolFileExists:
				return NSLS(@"Could not create the file or folder, it already exists.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolAccountNotFound:
				return NSLS(@"Could not find the account you referred to. Perhaps someone deleted it.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolAccountExists:
				return NSLS(@"The account you tried to create already exists on the server.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolAccountInUse:
				return NSLS(@"The account you tried to delete is currently used by a logged in user.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolTrackerNotEnabled:
				return NSLS(@"This server does not function as a tracker.", @"Wired protocol error description");
				break;

			case WCWiredProtocolNotRegistered:
				return NSLS(@"Could not update with tracker because you are not registered.", @"Wired protocol error description");
				break;
				
			case WCWiredProtocolBanNotFound:
				return NSLS(@"Could not find the ban you referred to. Perhaps someone deleted it.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolBanExists:
				return NSLS(@"The ban you tried to create already exists on the server", @"Wired protocol error description");
				break;

			case WCWiredProtocolBoardNotFound:
				return NSLS(@"Could not find the board you referred to. Perhaps someone deleted it.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolBoardExists:
				return NSLS(@"The board you tried to create already exists on the server.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolThreadNotFound:
				return NSLS(@"Could not find the thread you referred to. Perhaps someone deleted it.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolPostNotFound:
				return NSLS(@"Could not find the post you referred to. Perhaps someone deleted it.", @"Wired protocol error description");
				break;
			
			case WCWiredProtocolRsrcNotSupported:
				return NSLS(@"This server does not support resource fork transfers.", @"Wired protocol error description");
				break;
		}
			
		return [NSSWF:NSLS(@"An unknown server error occured. The error received from the server was %u.", @"Wired protocol error description (code)"), [self code]];
	}
	
	return [super localizedFailureReason];
}


@end
