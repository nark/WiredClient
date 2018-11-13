# Wired Client Source Code

This repository hosts Wired Client source code. You will find an Xcode project named "WiredClient.xcworkspace" that contains a Wired Client target ready to deploy a 10.7+ compatible application (64-bit).

## Prerequisites

- Mac OS X 10.11+
- Xcode 9.0+
- Homebrew 1.4+
- CocoaPods 1.2+

## How to compile Wired Client

0. Install dependencies using [Homebrew](https://brew.sh):
		
		brew install mogenerator
		brew install openssl
		
1. Get sources on GitHub:

		git clone https://github.com/sc1sm3/WiredClient.git
		
2. Move into the sources directory:
		
		cd WiredClient
		
3. Init and clone every git submodules:

		git submodule update --init --recursive
		
4. Install pods:

		pod install
		
	OpenSSL should be linked to `/usr/local/opt/openssl/lib`, or you will have to update `Header Search Path` and `Library Search Path` build settings in Xcode in order to make it works with your OpenSSL installation.
		
5. Open `WiredClient.xcworkspace` with Xcode

6. Select scheme `Wired Client` and be sure to use "Debug" Build Configuration

7. Launch Build, Wired Client.app should launch automatically when finished


## Troubleshooting

If you encounter an error during compilation with Xcode crying about `wired.h` not found, got to Build Product folder and rename "libwired/" directory to "wired/". Then try to build again.

## License

This code is distributed under BSD license, and it is free for personal or commercial use.
		
- Copyright (c) 2003-2009 Axel Andersson, All rights reserved.
- Copyright (c) 2011-2013 Rafaël Warnault, All rights reserved.
		
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
		
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
		
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

