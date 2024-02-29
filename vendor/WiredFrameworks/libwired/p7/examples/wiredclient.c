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

#include <stdlib.h>

#include <wired/wired.h>

static void						wc_usage(void);

static void						wc_client(wi_url_t *);
static wi_p7_socket_t *			wc_connect(wi_url_t *);
static wi_boolean_t				wc_login(wi_p7_socket_t *, wi_url_t *);


static wi_p7_spec_t				*wc_spec;


int main(int argc, const char **argv) {
	wi_pool_t			*pool;
	wi_string_t			*user, *password;
	wi_mutable_url_t	*url;
	int					ch;
	
	wi_initialize();
	wi_load(argc, argv);
	
	wi_log_tool 	= true;
	wi_log_level 	= WI_LOG_DEBUG;
	
	pool			= wi_pool_init(wi_pool_alloc());
	
	user 			= WI_STR("guest");
	password		= WI_STR("");
	
	while((ch = getopt(argc, (char * const *) argv, "p:u:")) != -1) {
		switch(ch) {
			case 'p':
				password = wi_string_with_cstring(optarg);
				break;
				
			case 'u':
				user = wi_string_with_cstring(optarg);
				break;
				
			case '?':
			case 'h':
			default:
				wc_usage();
				break;
		}
	}
	
	argc -= optind;
	argv += optind;
	
	if(argc != 1)
		wc_usage();
	
	wc_spec = wi_p7_spec_init_with_file(wi_p7_spec_alloc(), WI_STR("wired.xml"), WI_P7_CLIENT);
	
	if(!wc_spec)
		wi_log_fatal(WI_STR("Could not open wired.xml: %m"));
	
	url = wi_url_init_with_string(wi_mutable_url_alloc(), wi_string_with_cstring(argv[0]));
	wi_mutable_url_set_scheme(url, WI_STR("wired"));
	
	if(!url)
		wc_usage();
	
	wi_mutable_url_set_user(url, user);
	wi_mutable_url_set_password(url, password);
	
	if(wi_url_port(url) == 0)
		wi_mutable_url_set_port(url, 4871);
	
	if(!wi_url_is_valid(url))
		wc_usage();
	
	signal(SIGPIPE, SIG_IGN);
	
	wc_client(url);
	
	wi_release(pool);
	
	return 0;
}



static void wc_usage(void) {
	fprintf(stderr,
"Usage: wiredclient [-p password] [-u user] host\n\
\n\
Options:\n\
    -p password         password\n\
    -u user             user\n\
\n\
By Axel Andersson <dev@read-write.fr>\n");
	
	exit(2);
}



#pragma mark -

static void wc_client(wi_url_t *url) {
	wi_p7_socket_t		*socket;
	wi_p7_message_t		*message;
	
	socket = wc_connect(url);
	
	if(!socket)
		return;
	
	if(!wc_login(socket, url)) {
		wi_log_err(WI_STR("Could not login to %@: %m"), wi_url_host(url));
		
		return;
	}

	wi_log_info(WI_STR("Listing files at /..."));
			
	message = wi_p7_message_with_name(WI_STR("wired.file.list_directory"), wc_spec);
	wi_p7_message_set_string_for_name(message, WI_STR("/"), WI_STR("wired.file.path"));
	
	if(!wi_p7_socket_write_message(socket, 0.0, message)) {
		wi_log_err(WI_STR("Could not send message to %@: %m"), wi_url_host(url));
		
		return;
	}
	
	while((message = wi_p7_socket_read_message(socket, 0.0))) {
		if(wi_is_equal(wi_p7_message_name(message), WI_STR("wired.file.file_list")))
			wi_log_info(WI_STR("\t%@"), wi_p7_message_string_for_name(message, WI_STR("wired.file.path")));
		else if(wi_is_equal(wi_p7_message_name(message), WI_STR("wired.file.file_list.done")))
			break;
	}
	
	if(!message) {
		wi_log_err(WI_STR("Could not read message from %@: %m"), wi_url_host(url));
		
		return;
	}

	wi_log_info(WI_STR("Exiting"));
}



#pragma mark -

static wi_p7_socket_t * wc_connect(wi_url_t *url) {
	wi_enumerator_t		*enumerator;
	wi_socket_t			*socket;
	wi_p7_socket_t		*p7_socket;
	wi_array_t			*addresses;
	wi_address_t		*address;
	
	addresses = wi_host_addresses(wi_host_with_string(wi_url_host(url)));
	
	if(!addresses)
		return NULL;
	
	enumerator = wi_array_data_enumerator(addresses);
	
	while((address = wi_enumerator_next_data(enumerator))) {
		wi_address_set_port(address, wi_url_port(url));
		
		socket = wi_socket_with_address(address, WI_SOCKET_TCP);
		
		if(!socket)
			continue;
		
		wi_socket_set_interactive(socket, true);
		
		wi_log_info(WI_STR("Connecting to %@:%u..."), wi_address_string(address), wi_address_port(address));
		
		if(!wi_socket_connect(socket, 10.0)) {
			wi_socket_close(socket);
			
			continue;
		}
		
		wi_log_info(WI_STR("Connected, performing handshake"));

		p7_socket = wi_autorelease(wi_p7_socket_init_with_socket(wi_p7_socket_alloc(), socket, wc_spec));
		
		if(!wi_p7_socket_connect(p7_socket,
								 10.0,
								 WI_P7_COMPRESSION_DEFLATE | WI_P7_ENCRYPTION_RSA_AES256_SHA1 | WI_P7_CHECKSUM_SHA1,
								 WI_P7_BINARY,
								 wi_url_user(url),
								 wi_string_sha1(wi_url_password(url)))) {
			wi_log_err(WI_STR("Could not connect to %@: %m"), wi_address_string(address));
			
			wi_socket_close(socket);
			
			continue;
		}
		
		wi_log_info(WI_STR("Connected to P7 server with protocol %@ %@"),
			wi_p7_socket_remote_protocol_name(p7_socket), wi_p7_socket_remote_protocol_version(p7_socket));
		
		return p7_socket;
	}
	
	return NULL;
}



static wi_boolean_t wc_login(wi_p7_socket_t *socket, wi_url_t *url) {
	wi_p7_message_t		*message;
	wi_p7_uint32_t		id;
	
	wi_log_info(WI_STR("Performing Wired handshake..."));
	
	message = wi_p7_message_with_name(WI_STR("wired.client_info"), wc_spec);
	wi_p7_message_set_string_for_name(message, WI_STR("wiredclient"), WI_STR("wired.info.application.name"));
	wi_p7_message_set_string_for_name(message, WI_STR("1.0"), WI_STR("wired.info.application.version"));
	wi_p7_message_set_uint32_for_name(message, 1, WI_STR("wired.info.application.build"));
	wi_p7_message_set_string_for_name(message, wi_process_os_name(wi_process()), WI_STR("wired.info.os.name"));
	wi_p7_message_set_string_for_name(message, wi_process_os_release(wi_process()), WI_STR("wired.info.os.version"));
	wi_p7_message_set_string_for_name(message, wi_process_os_arch(wi_process()), WI_STR("wired.info.arch"));
	wi_p7_message_set_bool_for_name(message, false, WI_STR("wired.info.supports_rsrc"));

	if(!wi_p7_socket_write_message(socket, 0.0, message))
		return false;
	
	message = wi_p7_socket_read_message(socket, 0.0);
	
	if(!message)
		return false;
									  
	wi_log_info(WI_STR("Connected to \"%@\""), wi_p7_message_string_for_name(message, WI_STR("wired.info.name")));
	wi_log_info(WI_STR("Logging in as \"%@\"..."), wi_url_user(url));
	
	message = wi_p7_message_with_name(WI_STR("wired.send_login"), wc_spec);
	wi_p7_message_set_string_for_name(message, wi_url_user(url), WI_STR("wired.user.login"));
	wi_p7_message_set_string_for_name(message, wi_string_sha1(wi_url_password(url)), WI_STR("wired.user.password"));
	
	if(!wi_p7_socket_write_message(socket, 0.0, message))
		return false;
	
	message = wi_p7_socket_read_message(socket, 0.0);
	
	if(!message)
		return false;
	
	if(wi_is_equal(wi_p7_message_name(message), WI_STR("wired.login"))) {
		wi_p7_message_get_uint32_for_name(message, &id, WI_STR("wired.user.id"));

		wi_log_info(WI_STR("Logged in with user ID %u"), id);
	} else {
		wi_log_info(WI_STR("Login failed"));
		
		return false;
	}

	return true;
}
