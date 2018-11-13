# README

### About

This project is a fork of the Wired library (libwired) created by Axel Andersson at [Zanka Software](http://www.zankasoftware.com/wired/). It was created and is mainly intended for use by the Wired network suite. It contains collections and other data structures, and portable abstractions for many OS services, like threads, sockets, files, etc.

Wired library is based on a XML specification system called P7 which manage protocol version, message declaration and data structures. It provides an object-oriented API written in C language. It has its own runtime and classes, and provides mechanisms to manage network connections and remote messaging. The network layer supports SSL encryption and X.509 certificate.

### Requirements

This program is mainly tested on Debian/Ubuntu distributions and Mac OS X. The source code is under BSD license and is totally free for use with respect of this attributed license. 

Wired library uses several external dependencies, which are usually distributed with operating systems:

* OpenSSL (encryption)
* libxml2 (P7 support)
* zlib (compression)
* sqlite3 (server backend)

* GNU Autotools, if compiling from the Git repository.

### Getting started

If compiling from the Git repository, first generate the configure script using the following command:

`./bootstrap`

To compile libwired, please refer to the configure help using the following command:

`./configure --help`

Use the following commands to generate documentation:

`./documentation`

This will generate a Doxygen style source code documentation in the doc/ directory and a wired.htlm file in the p7/ directory.
