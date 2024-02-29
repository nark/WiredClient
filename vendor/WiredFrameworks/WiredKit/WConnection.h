//
//  WConnectionController.h
//  iWi
//
//  This class tends to abstract the wired connection management
//  by handling login, transaction counting and block-style method.
//
//  Created by Rafaël Warnault on 23/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDataController.h"
#import "WLink.h"
#import "WError.h"

extern NSString * const WConnectionReceiveMessage;
extern WIP7Spec *WCP7Spec;


/*** WConnectionBlock 
 * Returned object can be :
 * - WLink in case off success
 * - NSError in case off failure */
typedef void (^WConnectionBlock)(id object);

/*** WTransactionBlock
 * This block is called once the response message
 * associated to request message transaction identifier 
 * is received. It provides a response message or error object */
typedef void (^WTransactionBlock)(WIP7Message *response, NSError *error);


// needed here
@protocol WConnectionDelegate;
@class WConnection;


/*** WConnection
 * This class intents to provide a block-based programming 
 * interface to manage a Wired client connection. 
 * The connection link is managed by a strict delegate system
 * and the communication with the server ... bla.. blahbla
 */

@interface WConnection : WIObject {
    WIP7UInt32          _transaction;
    WConnectionBlock    _currentBlock;
    NSString *          _nick;
    NSString *          _status;
    id                  _icon;
}

@property (nonatomic, retain) id<WConnectionDelegate> delegate;
@property (nonatomic, retain) WLink *link;
@property (nonatomic, retain) WIURL *wiredURL;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *login;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *nick;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) id        icon;
@property (nonatomic, retain) NSMutableArray *proxies;
@property (nonatomic, retain) WDataController *dataController; // can be attached to use Core Data storage
@property (readwrite, setter=setConnected:) BOOL isConnected;
@property (readonly) WIP7UInt32 userID;

/* Init a connection object with URL, login and password */
- (id)initWithURL:(NSString *)u login:(NSString *)l password:(NSString *)p;

/* Connect to a wired server */
- (void)connectWithBlock:(WConnectionBlock)block;
/* Disconnect from a wired server */
- (void)disconnect;

/***
 * Start login dialog with the server. This cant be used until the 
 * connection was established with the server (see connectionSucceeded: 
 * from WConnectionDelegate protocol). 
 * The login dialog is composed of following messages :
 *
 * #  SENT:                         RECEIVED:
 * 1. wired.client_info         ->  wired.server_info
 * 2. wired.user.set_nick       ->  wired.okay
 * 3. wired.user.set_status     ->  wired.okay
 * 4. wired.user.set_icon       ->  wired.okay
 * 5. wired.user.send_login     ->  wired.login && wired.account.privileges
 * 6. wired.chat.join_chat      ->  wired.chat.user_list && wired.chat.user_list.done
 *
 * When the dialog is done, the connection call connection:loginSucceeded: delegate method.
 * */
- (void)loginWithBlock:(WTransactionBlock)block;


/***
 * Send a message and call the transaction block when the response message 
 * corresponding to the request message transaction is received */
- (void)sendMessage:(WIP7Message *)messag withBlock:(WTransactionBlock)block;

/* Common helper (and example) message methods */
- (void)sendChatSayMessage:(NSString *)message 
                withChatID:(WIP7UInt32)chatID
                 withBlock:(WTransactionBlock)block;

- (void)sendChatMeMessage:(NSString *)message 
               withChatID:(WIP7UInt32)chatID
                withBlock:(WTransactionBlock)block;

- (void)sendPrivateMessage:(NSString *)message
                withUserID:(WIP7UInt32)userID
                 withBlock:(WTransactionBlock)block;

@end



@protocol WConnectionDelegate <NSObject>

@optional
- (void)connectionSucceeded:(WConnection *)controller;
- (void)connection:(WConnection *)controller failedWithError:(NSError *)error;
- (void)connection:(WConnection *)controller loginSucceeded:(WIP7Message *)message;
- (void)connection:(WConnection *)connection receiveMessage:(WIP7Message *)message;
- (void)connection:(WConnection *)controller receiveError:(NSError *)error;
- (void)connectionClosed:(WConnection *)controller withError:(NSError *)error;
@end
