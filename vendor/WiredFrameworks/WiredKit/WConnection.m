//
//  WConnectionController.m
//  iWi
//
//  Created by Rafaël Warnault on 23/11/11.
//  Copyright (c) 2011 Read-Write. All rights reserved.
//

#import "WConnection.h"



NSString * const WConnectionReceiveMessage = @"WConnectionReceiveMessage";
WIP7Spec *WCP7Spec;





@interface WConnection (Private)
- (NSUInteger)sendMessage:(WIP7Message *)message;
- (void)wiredClientInfoReply:(WIP7Message *)message;
@end



@interface WConnection (Helper)
- (WIP7Message *)clientInfoMessage;
- (WIP7Message *)setNickMessage;
- (WIP7Message *)setStatusMessage;
- (WIP7Message *)setIconMessage;
- (WIP7Message *)loginMessage;
- (WIP7Message *)joinChatMessage;
- (WIP7Message *)userListMessage;
@end



@implementation WConnection


@synthesize url             = _url;
@synthesize login           = _login;
@synthesize password        = _password;
@synthesize link            = _link;
@synthesize isConnected     = _isConnected;
@synthesize wiredURL        = _wiredURL;
@synthesize proxies         = _proxies;
@synthesize userID          = _userID;
@synthesize delegate        = _delegate;
@synthesize dataController  = _dataController;

@dynamic    nick;
@dynamic    status;
@dynamic    icon;



- (id)init {
    self = [super init];
    if (self) {
        _proxies = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithURL:(NSString *)u login:(NSString *)l password:(NSString *)p {
    self = [self init];
    if (self) {
        _url                = [u retain];
        _login              = [l retain];
        _password           = [p retain];
        _link               = nil;
        _dataController     = nil;
        _nick               = [@"WiredKit Client" retain];
        _status             = [@"Xcoder" retain];
        _icon               = nil;
        
        [self setConnected:NO];
        
        NSInteger port = 4871;
        NSString *host = self.url;
        
        // parse URL
        if([self.url rangeOfString:@":"].location != NSNotFound) {
            NSArray *comps = [self.url componentsSeparatedByString:@":"];
            NSString *portString = [comps objectAtIndex:1];
            port = [portString integerValue];
            host = [comps objectAtIndex:0];
        }
        
        _wiredURL = [[WIURL alloc] initWithScheme:@"wiredp7" host:host port:port];
        [_wiredURL setUser:self.login];
        [_wiredURL setPassword:self.password];
    }
    return self;
}

- (void)dealloc {
    
    if(self.link && [self.link isReading])
        [self.link terminate];

    [self disconnect];
    
    [_url release],             _url = nil;
    [_login release],           _login = nil;
    [_password release],        _password = nil;
    [_link release],            _link = nil;
    [_proxies release],         _proxies = nil;
    [_delegate release],        _delegate = nil;
    [_dataController release],  _dataController = nil;
    [_currentBlock release],    _currentBlock = nil;
    [_nick release],            _nick = nil;
    [_status release],          _status = nil;
    [_icon release],            _icon = nil;
    
    [super dealloc];
}

- (void)connectWithBlock:(WConnectionBlock)block {
    
    _currentBlock = [block copy];
    
    self.link = [[[WLink alloc] initLinkWithURL:self.wiredURL p7Spec:WCP7Spec] autorelease];

    [self.link setDelegate:self];
    
    // add observers
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"UserNick" 
                                               options:NSKeyValueObservingOptionNew 
                                               context:nil];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"UserStatus" 
                                               options:NSKeyValueObservingOptionNew 
                                               context:nil];
    
    [self.link connect];
}

- (void)disconnect {
    //NSLog(@"disconnect");
    
    // try to terminate the link 
    if(self.link && [self.link isReading])
        [self.link terminate];
    
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"UserNick"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"UserStatus"];
    
    [self.link disconnect];
}

- (void)loginWithBlock:(WTransactionBlock)block {
    // start the login session
    [self sendMessage:[self clientInfoMessage] withBlock:^(WIP7Message *response, NSError *error) {
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(connection:receiveMessage:)])
            [self.delegate connection:self receiveMessage:response];
        
        [self sendMessage:[self setNickMessage] withBlock:^(WIP7Message *response, NSError *error) {
            [self sendMessage:[self setStatusMessage] withBlock:^(WIP7Message *response, NSError *error) {
                [self sendMessage:[self setIconMessage] withBlock:^(WIP7Message *response, NSError *error) {                    
                    [self sendMessage:[self loginMessage] withBlock:^(WIP7Message *response, NSError *error) {
                        
                        // store userID 
                        [response getUInt32:&_userID forName:@"wired.user.id"];
                        
                        [self sendMessage:[self joinChatMessage] withBlock:^(WIP7Message *response, NSError *error) {
                            
                            block(response, error);
                            
                            if(self.delegate && [self.delegate respondsToSelector:@selector(connection:loginSucceeded:)])
                                [self.delegate connection:self loginSucceeded:response];
                        }];
                    }];
                }];
            }];
        }];
    }];
}

- (void)sendMessage:(WIP7Message *)message withBlock:(WTransactionBlock)block {
    //NSLog(@"sendMessage:withBlock:");
    WIP7UInt32		transaction;
	
    // increment the transaction
	transaction = ++_transaction;
	[message setUInt32:transaction forName:@"wired.transaction"];

    // build asynchronous block proxy dictionnary
    NSMutableDictionary *trasactionProxy = [NSMutableDictionary dictionary];    
    
    [trasactionProxy setValue:[block copy] forKey:@"block"];
    [trasactionProxy setValue:[NSValue value:&transaction withObjCType:@encode(WIP7UInt32)] forKey:@"transaction"];
    
    // store the proxy with transaction number as index field
    [self.proxies addObject:trasactionProxy]; 
    
    // send the message
    [self.link sendMessage:message];
}





#pragma mark - Connection send messages

- (void)sendChatSayMessage:(NSString *)msg 
                withChatID:(WIP7UInt32)chatID
                 withBlock:(WTransactionBlock)block {
    
    WIP7Message *message = [WIP7Message messageWithName:@"wired.chat.send_say" spec:WCP7Spec];
    [message setString:msg forName:@"wired.chat.say"];
    [message setUInt32:1 forName:@"wired.chat.id"];
    
    [self sendMessage:message withBlock:^(WIP7Message *response, NSError *error) {
        block(response, error);
    }];
}


- (void)sendChatMeMessage:(NSString *)msg 
               withChatID:(WIP7UInt32)chatID
                withBlock:(WTransactionBlock)block {
    
    WIP7Message *message = [WIP7Message messageWithName:@"wired.chat.send_me" spec:WCP7Spec];
    [message setString:msg forName:@"wired.chat.me"];
    [message setUInt32:1 forName:@"wired.chat.id"];
    
    [self sendMessage:message withBlock:^(WIP7Message *response, NSError *error) {
        block(response, error);
    }];
}

- (void)sendPrivateMessage:(NSString *)message
                withUserID:(WIP7UInt32)userID
                 withBlock:(WTransactionBlock)block {
    
    WIP7Message *msg = [WIP7Message messageWithName:@"wired.message.send_message" spec:WCP7Spec];
    [msg setString:message forName:@"wired.message.message"];
    [msg setUInt32:userID forName:@"wired.user.id"];
    
    [self sendMessage:msg withBlock:^(WIP7Message *response, NSError *error) {
        block(response, error);
    }];
}





#pragma mark - Observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([object isEqual:[NSUserDefaults standardUserDefaults]]) {
        if([keyPath isEqualToString:@"UserNick"]) {
            [self sendMessage:[self setNickMessage] withBlock:^(WIP7Message *response, NSError *error) {
                // deal with error if needed
            }];
            
            
        } else if([keyPath isEqualToString:@"UserStatus"]) {
            [self sendMessage:[self setStatusMessage] withBlock:^(WIP7Message *response, NSError *error) {
                // deal with error if needed
            }];
            
        }
    }
}




#pragma mark - WLinkController delegate

- (void)linkConnected:(WLink *)link {
    //NSLog(@"linkConnected");
    [self setConnected:YES];
    
    if(_currentBlock) {
        _currentBlock(link);
        _currentBlock = nil;
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(connectionSucceeded:)])
        [self.delegate connectionSucceeded:self];
}

- (void)linkClosed:(WLink *)link error:(WIError *)error {
    //NSLog(@"linkClosed : %@", error);    
    [self setConnected:NO];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(connectionClosed:withError:)])
        [self.delegate connectionClosed:self withError:error];
}

- (void)linkTerminated:(WLink *)link {
    //NSLog(@"linkTerminated");   
    [self setConnected:NO];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(connectionClosed:withError:)])
        [self.delegate connectionClosed:self withError:nil];
}

- (void)link:(WLink *)link sentMessage:(WIP7Message *)message {
    //NSLog(@"sentMessage : %@", [message name]);     
}

- (void)link:(WLink *)link receivedMessage:(WIP7Message *)message {
    
    //NSLog(@"receivedMessage : %@", [message name]); 
    
    // deal with asynchronous blocks
    WIP7UInt32 receivedTransaction, sendedTransaction; 
    WTransactionBlock block;
    NSDictionary *toRemoveProxy = nil;
    
    // get the current transaction identifier
    [message getUInt32:&receivedTransaction forName:@"wired.transaction"];

    // we check error message here
    if([message.name isEqualToString:@"wired.error"]) {
        
        WError *error = [WError errorWithWiredMessage:message];
        if(self.delegate && [self.delegate respondsToSelector:@selector(connection:receiveError:)])
            [self.delegate connection:self receiveError:error];
        
    } else {
        // use Core Data if possible
        if(self.dataController) {
            [self.dataController receiveMessage:message];
        }   
        
        // notify
        [[NSNotificationCenter defaultCenter] postNotificationName:WConnectionReceiveMessage 
                                                            object:message 
                                                          userInfo:[NSDictionary dictionaryWithObject:self forKey:@"WConnection"]];
    }
    
    // find sender block and call it
    for(NSDictionary *dict in self.proxies) {
        NSValue *proxyValue = [dict valueForKey:@"transaction"];
        [proxyValue getValue:&sendedTransaction];
        
        if(sendedTransaction == receivedTransaction) {
            block = [dict valueForKey:@"block"];
            toRemoveProxy = dict;
            continue;
        }
    }
    if(toRemoveProxy) {
        NSError *error = [WError errorWithWiredMessage:message];
        block(message, error);
        [block release];
        [self.proxies removeObject:toRemoveProxy];
    }
    
}




#pragma mark - Private methods

- (NSUInteger)sendMessage:(WIP7Message *)message {
	WIP7UInt32		transaction;
	
	transaction = ++_transaction;
	[message setUInt32:transaction forName:@"wired.transaction"];
	[self.link sendMessage:message];
    
	return transaction;
}

- (void)wiredClientInfoReply:(WIP7Message *)message {
	[self sendMessage:[self setNickMessage]];
	[self sendMessage:[self setStatusMessage]];
	[self sendMessage:[self setIconMessage]];
	[self sendMessage:[self loginMessage]];
}




#pragma mark - Accessor custom methods

- (void)setNick:(NSString *)nick {
    if(_nick)
        [_nick release], _nick = nil;
    
    _nick = [nick retain];
    if(self.isConnected)
        [self sendMessage:[self setNickMessage] withBlock:^(WIP7Message *response, NSError *error) { }];
}

- (NSString *)nick {
    return _nick;
}


- (void)setStatus:(NSString *)status {
    if(_status)
        [_status release], _status = nil;
    
    _status = [status retain];
    if(self.isConnected)
        [self sendMessage:[self setStatusMessage] withBlock:^(WIP7Message *response, NSError *error) { }];
}

- (NSString *)status {
    return _status;
}


- (void)setIcon:(id)icon {
    if(_icon)
        [_icon release], _icon = nil;
    
    _icon = [icon retain];
    if(self.isConnected)
        [self sendMessage:[self setIconMessage] withBlock:^(WIP7Message *response, NSError *error) { }];
}

- (id)icon {
    return _icon;
}




#pragma mark - Helper methods

- (WIP7Message *)clientInfoMessage {
	static NSString		*applicationName, *applicationVersion, *applicationBuild, *osName, *osVersion, *arch;
	NSBundle			*bundle;
	NSDictionary		*dictionary;
	WIP7Message			*message;
	
	if(!applicationName) {
		bundle				= [NSBundle mainBundle];
		//dictionary			= [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
		
        applicationName		= [[bundle objectForInfoDictionaryKey:@"CFBundleExecutable"] retain];
        applicationVersion	= [[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] retain];
        applicationBuild	= [[bundle objectForInfoDictionaryKey:@"CFBundleVersion"] retain];   
        
		osName				= @"iOS";
		osVersion			= @"5.0";
		arch				= @"armv7";
	}
    
    // double check 
    if(!applicationName) {
        applicationName     = [[NSString stringWithString:@"Unknow App"] retain];
        applicationVersion  = [[NSString stringWithString:@"0.0"] retain];
        applicationBuild    = [[NSString stringWithString:@"0"] unsignedIntValue];
    }
    
	message = [WIP7Message messageWithName:@"wired.client_info" spec:WCP7Spec];
    [message setString:applicationName forName:@"wired.info.application.name"];
    [message setString:applicationVersion forName:@"wired.info.application.version"];
    [message setString:applicationBuild forName:@"wired.info.application.build"];
    [message setString:osName forName:@"wired.info.os.name"];
    [message setString:osVersion forName:@"wired.info.os.version"];
    [message setString:arch forName:@"wired.info.arch"];

	[message setBool:YES forName:@"wired.info.supports_rsrc"];
	
	return message;
}

- (WIP7Message *)loginMessage {
	NSString		*login, *password;
	WIP7Message		*message;
	
	login = ([[[self wiredURL] user] length] > 0) ? [[self wiredURL] user] : @"guest";
	password = ([[[self wiredURL] password] length] > 0) ? [[[self wiredURL] password] SHA1] : [@"" SHA1];
	
	message = [WIP7Message messageWithName:@"wired.send_login" spec:WCP7Spec];
	[message setString:login forName:@"wired.user.login"];
	[message setString:password forName:@"wired.user.password"];
	
	return message;
}

- (WIP7Message *)setNickMessage {
	WIP7Message		*message;
    
	message = [WIP7Message messageWithName:@"wired.user.set_nick" spec:WCP7Spec];
	[message setString:self.nick forName:@"wired.user.nick"];
	
	return message;
}



- (WIP7Message *)setStatusMessage {
	WIP7Message		*message;
    
	message = [WIP7Message messageWithName:@"wired.user.set_status" spec:WCP7Spec];
	[message setString:self.status forName:@"wired.user.status"];
	
	return message;
}



- (WIP7Message *)setIconMessage {
	WIP7Message		*message;
    
	message = [WIP7Message messageWithName:@"wired.user.set_icon" spec:WCP7Spec];
	[message setData:self.icon forName:@"wired.user.icon"];
	
	return message;
}


- (WIP7Message *)joinChatMessage {
	WIP7Message		*message;
    
	message = [WIP7Message messageWithName:@"wired.chat.join_chat" spec:WCP7Spec];
	[message setUInt32:1 forName:@"wired.chat.id"];
	
	return message;
}


- (WIP7Message *)userListMessage {
    WIP7Message		*message;
    
	message = [WIP7Message messageWithName:@"wired.chat.get_users" spec:WCP7Spec];
	
	return message;
}

@end



