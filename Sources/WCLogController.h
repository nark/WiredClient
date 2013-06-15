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

#import "WCAdministration.h"

@interface WCLogController : WCAdministrationController {
	IBOutlet NSButton					*_allFilterButton;
	IBOutlet NSButton					*_infoFilterButton;
	IBOutlet NSButton					*_warningsFilterButton;
	IBOutlet NSButton					*_errorsFilterButton;
	IBOutlet NSSearchField				*_messageSearchField;
	
	IBOutlet WITableView				*_logTableView;
	IBOutlet NSTableColumn				*_timeTableColumn;
	IBOutlet NSTableColumn				*_imageTableColumn;
	IBOutlet NSTableColumn				*_messageTableColumn;
	
	NSMutableArray						*_allEntries;
	NSMutableArray						*_listedEntries;
	NSMutableArray						*_receivedEntries;
	NSMutableArray						*_shownEntries;
	WIDateFormatter						*_dateFormatter;
	
	NSString							*_messageFilter;
	
	BOOL								_requested;
}

- (IBAction)all:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)warnings:(id)sender;
- (IBAction)errors:(id)sender;
- (IBAction)message:(id)sender;

@end
