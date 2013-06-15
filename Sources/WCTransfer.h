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

#import "WCServerConnectionObject.h"

enum _WCTransferState {
	WCTransferWaiting,
	WCTransferLocallyQueued,
	WCTransferQueued,
	WCTransferListing,
	WCTransferCreatingDirectories,
	WCTransferRunning,
	WCTransferPausing,
	WCTransferPaused,
	WCTransferStopping,
	WCTransferStopped,
	WCTransferDisconnecting,
	WCTransferDisconnected,
	WCTransferRemoving,
	WCTransferFinished
};
typedef enum _WCTransferState			WCTransferState;


@class WCFile, WCServerConnection, WCTransferConnection;

@interface WCTransfer : WCServerConnectionObject <NSCoding, NSCopying> {
	NSString							*_identifier;
	
	WCTransferState						_state;
	NSUInteger							_queuePosition;
	NSUInteger							_transaction;
	BOOL								_folder;
	WCTransferConnection				*_transferConnection;
	NSString							*_name;
	NSString							*_localPath;
	NSString							*_remotePath;
	NSString							*_destinationPath;
	WCFile								*_file;
	WIUnclickableProgressIndicator		*_progressIndicator;
	NSImage								*_icon;

	NSDate								*_startDate;
	NSTimeInterval						_accumulatedTime;
	NSUInteger							_speedLimit;
	
	NSMutableArray						*_untransferredFilesList, *_transferredFilesList;
	NSMutableSet						*_untransferredFilesSet, *_transferredFilesSet;
	NSMutableArray						*_uncreatedDirectoriesList, *_createdDirectoriesList;
	NSMutableSet						*_uncreatedDirectoriesSet, *_createdDirectoriesSet;
	
	NSConditionLock						*_terminationLock;
	
@public
	wi_speed_calculator_t				*_speedCalculator;
	double								_speed;
	WIFileOffset						_dataTransferred;
	WIFileOffset						_rsrcTransferred;
	WIFileOffset						_actualTransferred;
	WIFileOffset						_size;
}

+ (id)transferWithConnection:(WCServerConnection *)connection;
+ (id)transferWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;

- (NSString *)identifier;

- (void)setState:(WCTransferState)state;
- (WCTransferState)state;
- (void)setQueuePosition:(NSUInteger)queuePosition;
- (NSUInteger)queuePosition;
- (void)setTransaction:(NSUInteger)transaction;
- (NSUInteger)transaction;
- (void)setSpeed:(double)speed;
- (double)speed;
- (NSUInteger)speedLimit;
- (NSTimeInterval)accumulatedTime;
- (void)setSize:(WIFileOffset)size;
- (WIFileOffset)size;
- (void)setDataTransferred:(WIFileOffset)transferred;
- (WIFileOffset)dataTransferred;
- (void)setRsrcTransferred:(WIFileOffset)transferred;
- (WIFileOffset)rsrcTransferred;
- (void)setActualTransferred:(WIFileOffset)actualTransferred;
- (WIFileOffset)actualTransferred;

- (void)setFolder:(BOOL)value;
- (BOOL)isFolder;

- (void)setTransferConnection:(WCTransferConnection *)transferConnection;
- (WCTransferConnection *)transferConnection;
- (void)setName:(NSString *)name;
- (NSString *)name;
- (void)setLocalPath:(NSString *)path;
- (NSString *)localPath;
- (void)setRemotePath:(NSString *)path;
- (NSString *)remotePath;
- (void)setDestinationPath:(NSString *)path;
- (NSString *)destinationPath;
- (void)setFile:(WCFile *)file;
- (WCFile *)file;
- (void)setProgressIndicator:(WIUnclickableProgressIndicator *)progressIndicator;
- (WIUnclickableProgressIndicator *)progressIndicator;

- (NSURL *)previewItemURL;

- (BOOL)isWorking;
- (BOOL)isTerminating;
- (BOOL)isStopped;
- (void)signalTerminated;
- (BOOL)waitUntilTerminatedBeforeDate:(NSDate *)date;
- (NSImage *)icon;
- (void)refreshSpeedLimit;

- (BOOL)containsUntransferredFile:(WCFile *)file;
- (BOOL)containsTransferredFile:(WCFile *)file;
- (BOOL)containsUncreatedDirectory:(WCFile *)directory;
- (BOOL)containsCreatedDirectory:(WCFile *)directory;

- (NSUInteger)numberOfUntransferredFiles;
- (NSUInteger)numberOfTransferredFiles;
- (WCFile *)firstUntransferredFile;
- (void)addUntransferredFile:(WCFile *)file;
- (void)removeUntransferredFile:(WCFile *)file;
- (void)addTransferredFile:(WCFile *)file;
- (void)removeTransferredFile:(WCFile *)file;

- (void)addUncreatedDirectory:(WCFile *)directory;
- (void)removeUncreatedDirectory:(WCFile *)directory;
- (void)removeAllUncreatedDirectories;
- (void)addCreatedDirectory:(WCFile *)directory;
- (void)removeCreatedDirectory:(WCFile *)directory;
- (NSArray *)uncreatedDirectories;
- (NSArray *)createdDirectories;

@end


@interface WCDownloadTransfer : WCTransfer

@end


@interface WCUploadTransfer : WCTransfer

@end
