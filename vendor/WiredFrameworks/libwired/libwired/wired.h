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

/**
 * @file wired.h 
 * @brief This header file include every public headers of the library
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 */

#ifndef WIRED_H
#define WIRED_H 1

#include <wired/wi-address.h>
#include <wired/wi-array.h>
#include <wired/wi-assert.h>
#include <wired/wi-base.h>
#include <wired/wi-byteorder.h>
#include <wired/wi-cipher.h>
#include <wired/wi-config.h>
#include <wired/wi-compat.h>
#include <wired/wi-data.h>
#include <wired/wi-date.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-digest.h>
#include <wired/wi-enumerator.h>
#include <wired/wi-error.h>
#include <wired/wi-file.h>
#include <wired/wi-fs.h>
#include <wired/wi-fsenumerator.h>
#include <wired/wi-fsevents.h>
#include <wired/wi-fts.h>
#include <wired/wi-host.h>
#include <wired/wi-ip.h>
#include <wired/wi-libxml2.h>
#include <wired/wi-lock.h>
#include <wired/wi-log.h>
#include <wired/wi-macros.h>
#include <wired/wi-null.h>
#include <wired/wi-number.h>
#include <wired/wi-p7-message.h>
#include <wired/wi-p7-socket.h>
#include <wired/wi-p7-spec.h>
#include <wired/wi-plist.h>
#include <wired/wi-pool.h>
#include <wired/wi-process.h>
#include <wired/wi-random.h>
#include <wired/wi-rsa.h>
#include <wired/wi-regexp.h>
#include <wired/wi-runtime.h>
#include <wired/wi-set.h>
#include <wired/wi-settings.h>
#include <wired/wi-socket.h>
#include <wired/wi-speed-calculator.h>
#include <wired/wi-sqlite3.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>
#include <wired/wi-task.h>
#include <wired/wi-terminal.h>
#include <wired/wi-test.h>
#include <wired/wi-timer.h>
#include <wired/wi-thread.h>
#include <wired/wi-url.h>
#include <wired/wi-uuid.h>
#include <wired/wi-version.h>
#include <wired/wi-wired.h>
#include <wired/wi-x509.h>

#endif /* WIRED_H */


/*! \mainpage Presentation of libwired
 *
 * \section Introduction
 *
 * This is the source-code documentation of libwired. This library was created and 
 * is mainly intended for use by the Wired network suite. It contains collections 
 * and other data structures, and portable abstractions for many OS services, 
 * like threads, sockets, files, etc.
 *
 * libwired is written in ANSI-C to ensure portability for many operating systems. The 
 * programming interface is mainly written following object-oriented C techniques.
 * The implementation logic and vocabulary are very close to GNUstep/Cocoa APIs.
 *
 * The Wired protocol is a BBS-oriented network protocol (similar to Hotline, Carracho, 
 * KDX, etc.). It provides communication features like chat, messaging, and file 
 * tranfers in a very secure server/client architecture. 
 *
 * \section Requirements
 *
 * \subsection OpenSSL
 *
 * http://www.openssl.org/source/
 *
 * \subsection libxml2
 *
 * http://xmlsoft.org/
 *
 * \subsection sqlite3
 *
 * http://www.sqlite.org/
 *
 *
 * \section Architecture
 *
 * The Wired library is composed of several logical modules.
 * 
 * \code
 * libwired/
 *     base/
 *     collections/
 *     crypto/
 *     data/
 *     file/
 *     misc/
 *     net/
 *     p7/
 *     system/
 *     thridparty/
 *     thread/
 * \endcode
 *
 * \subsection Base
 *
 * The base module mainly provides base types, functions and macros for the Wired
 * object-oriented runtime and library management.
 *
 * \subsection Collections
 *
 * The collection module regroups Wired classes to manage collections of objects,
 * like array, set, dictionary and their related object enumerating operations.
 *
 * \subsection Crypto
 *
 * The crypto module handles cryptographic features, mainly built around OpenSSL
 * and CommonCrypto libraries, in order to make the Wired network protocol secure.
 *
 * \subsection Data
 *
 * The data module regroups object representations of low-level data types like 
 * raw data, strings, dates, numbers, etc.
 *
 * \subsection File
 *
 * The data module provides file management features by taking care of operating
 * systems implemenations.
 *
 * \subsection Misc
 *
 * The misc module regroups miscellaneous classes used by the Wired library for
 * errors management, regular expressions, config files management, etc.
 *
 * \subsection Net
 *
 * The net module regroups low-level implementation for point-to-point network
 * communications using sockets.
 *
 * \subsection P7
 *
 * The p7 module regroups classes related to the network implementation of the 
 * Wired protocol version 2.0, based on a XML specification. 
 * 
 * \subsection System
 *
 * The system module provides an interface to interact with operating system
 * features like process, logs, tasks, terminal, etc.
 * 
 * \subsection Third-Party
 *
 * The thirdparty module regroups wrappers for third-party libraries. Here it 
 * is about libxml2 and sqlite3 libraries.
 *
 * \subsection Thread
 *
 * The thread module provides support for threads and locks based on pthread
 * library if this component is provided by the target operating system.
 *
 * <BR><BR>
 *
 */
