# Wired Frameworks

WiredFrameworks is an Xcode project that regroups library and framework targets involved in the Wired 2.0 implementation on Apple platforms (OSX and iOS).

See this [page](http://www.read-write.fr/wired/wiki) to find more documentation about Wired

## Details

The Xcode project is composed of the following main targets:

- libwired (osx, ios) -> https://github.com/nark/libwired
- WiredFoundation (osx, ios)
- WiredNetworking (osx, ios)
- WiredAppKit (osx)
- WiredUIKit (ios)

## How to use it

For every platforms:
* Init required submodules (libwired and openssl):

		cd WiredFrameworks/
		git submodule update --init --recursive
				
* Add `WiredFrameworks.xcodeproj` as a subproject to your Xcode project.

#### For OSX:

1. In your project's Build Phases, Add libwired-osx, WiredFoundation, WiredNetworking and WiredNetworking **targets as dependencies** of your project.

2. **Link your binary** with WiredFoundation, WiredNetworking and WiredNetworking frameworks.

3. Add a **Copy Files Phase** with its **destination** pointing to "Frameworks" directory, then add WiredFoundation, WiredNetworking and WiredNetworking products to it.

4. In your project's Build Settings, add `@loader_path/../Frameworks` **Runpath Search Paths**.

5. And add `"$(BUILT_PRODUCTS_DIR)"` to **Header Search Paths**.

#### For iOS:

TODO...


## Authors

Most of the code distributed here was originally written by Axel Andersson at Zanka Software. My contribution here is mainly related to iOS support and bug fixing.

This code is distributed under BSD license, and it is free for personal or commercial use.
		
- Copyright (c) 2003-2009 Axel Andersson, All rights reserved.
- Copyright (c) 2011-2013 Rafaël Warnault, All rights reserved.
		
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
		
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
		
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

