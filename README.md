# Wired Client Source Code

This repository hosts Wired Client source code. You will find an Xcode project named "WiredClient.xcodeproj" that contains a Wired Client target ready to deploy a 10.6+ compatible application (i386).

## Prerequisites

- Mac OS X 10.8+
- Xcode 4.6+

## How to compile Wired Client

1. Get sources on GitHub:

		git clone https://github.com/nark/WiredClient.git
		
2. Move into the sources directory:
		
		cd WiredClient/
		
3. Init and clone every git submodules:

		git submodule update --init --recursive
		
4. Open `WiredClient.xcodeproj` with Xcode

5. Select scheme `Wired Client` and be sure to use "Debug" Build Configuration

6. Launch Build, Wired Client.app should launch automatically when finished


## Troubleshooting

If you encounter an error during compilation with Xcode crying about `wired.h` not found, got to Build Product folder and rename "libwired/" directory to "wired/". Then try to build again.

## License

This code is distributed under BSD license, and it is free for personal or commercial use.
		
- Copyright (c) 2003-2009 Axel Andersson, All rights reserved.
- Copyright (c) 2011-2013 Rafaël Warnault, All rights reserved.
		
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
		
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
		
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

