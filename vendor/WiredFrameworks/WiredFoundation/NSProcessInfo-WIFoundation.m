/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
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

#import <WiredFoundation/NSProcessInfo-WIFoundation.h>

void WIEnableSuddenTermination(void) {
	if([[NSProcessInfo processInfo] respondsToSelector:@selector(enableSuddenTermination)])
		[[NSProcessInfo processInfo] performSelector:@selector(enableSuddenTermination)];
}



void WIDisableSuddenTermination(void) {
	if([[NSProcessInfo processInfo] respondsToSelector:@selector(disableSuddenTermination)])
		[[NSProcessInfo processInfo] performSelector:@selector(disableSuddenTermination)];
}



@implementation NSProcessInfo(WIFoundation)

- (unsigned long long)amountOfMemory {
	uint64_t	value;
	size_t		size;
	int			mib[] = {CTL_HW, HW_MEMSIZE};
	
	size = sizeof(value);
	
	if(sysctl(mib, 2, &value, &size, NULL, 0) < 0) {
		NSLog(@"sysctl: %s", strerror(errno));
		
		return 0;
	}
	
	return value;
}

@end
