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

#import <WiredAppKit/NSWorkspace-WIAppKit.h>

@implementation NSWorkspace(WIAppKit)

- (NSUInteger)processIdentifierForCommand:(NSString *)processName {
	struct kinfo_proc	*procs = NULL;
	const char			*name;
	size_t				i, size, entries;
	pid_t				pid = 0;
	int					mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL};
	
	if(sysctl(mib, 3, NULL, &size, NULL, 0) == 0) {
		entries = size / sizeof(struct kinfo_proc);
		procs = (struct kinfo_proc *) malloc(size);
		
		if(sysctl(mib, 3, procs, &size, NULL, 0) == 0) {
			name = [processName UTF8String];
			
			for(i = 0; i < entries; i++) {
				if(strcmp(procs[i].kp_proc.p_comm, name) == 0) {
					pid = procs[i].kp_proc.p_pid;
					
					break;
				}
			}
		} else {
			NSLog(@"sysctl: %s", strerror(errno));
		}
	} else {
		NSLog(@"sysctl: %s", strerror(errno));
	}
	
	if(procs)
		free(procs);
	
	return pid;
}



- (NSString *)commandForProcessIdentifier:(NSUInteger)pid {
	struct kinfo_proc	proc;
	size_t				size = sizeof(proc);
	int					mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, (int) pid};
	
	if(sysctl(mib, 4, &proc, &size, NULL, 0) < 0) {
		NSLog(@"sysctl: %s", strerror(errno));
		
		return NULL;
	}
	
	return [NSString stringWithUTF8String:proc.kp_proc.p_comm];
}



#pragma mark -

- (BOOL)changeDesktopPicture:(NSString *)path {
	AppleEvent		event = { typeNull, NULL }, replyEvent = { typeNull, NULL };
	AEDesc			desc = { typeNull, NULL };
	AEBuildError	buildError;
	AliasHandle		alias;
	FSRef			fsRef;
	OSType			type = 'MACS';
	OSStatus		status;
	OSErr			err;
	char			state;

	status = FSPathMakeRef((UInt8 *) [path fileSystemRepresentation], &fsRef, NULL);

	if(status != noErr) {
		NSLog(@"*** FSPathMakeRef(): %d", (int)status);

		return NO;
	}

	err = FSNewAlias(NULL, &fsRef, &alias);

	if(err != noErr || !alias) {
		NSLog(@"*** FSNewAlias(): %d", err);

		return NO;
	}

	state = HGetState((Handle) alias);
	HLock((Handle) alias);
	err = AECreateDesc(typeAlias, *alias, GetHandleSize((Handle) alias), &desc);
	HSetState((Handle) alias, state);
	DisposeHandle((Handle) alias);

	if(err != noErr) {
		NSLog(@"*** AECreateDesc(): %d", err);

		return NO;
	}

	err = AEBuildAppleEvent(kAECoreSuite, kAESetData, typeApplSignature, &type, sizeof(type),
							kAutoGenerateReturnID, kAnyTransactionID, &event, &buildError,
							"'----':'obj '{want:type(prop),form:prop,seld:type('dpic'),from:'null'()},data:(@)",
							&desc);

	if(err != noErr) {
		NSLog(@"AEBuildAppleEvent(): %d", err);
		AEDisposeDesc(&event);

		return NO;
	}

	err = AESend(&event, &replyEvent, kAENoReply, kAENormalPriority, kNoTimeOut, NULL, NULL);
	AEDisposeDesc(&event);

	if(err != noErr) {
		NSLog(@"AESend(): %d", err);

		return NO;
	}
	
	return YES;
}



#pragma mark -

- (void)ejectCDDrive {
	NSTask		*task;
	
	task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/drutil" arguments:[NSArray arrayWithObject:@"eject"]];
	
	[task waitUntilExit];
}

@end
