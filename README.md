# Wired Client Source Code

This repository hosts Wired Client source code. You will find an Xcode project named "WiredClient.xcworkspace" that contains a Wired Client target ready to deploy a 10.13+ compatible application (64-bit).

## Prerequisites

- Mac OS X 10.13+
- Xcode 13.0+
- Homebrew 1.8+
- CocoaPods 1.5+

## How to compile Wired Client

0. Install dependencies using [Homebrew](https://brew.sh):
		
		brew install mogenerator cocoapods
		
2. Get sources on GitHub:

		git clone https://github.com/profdrluigi/WiredClient.git
		
3. Move into the sources directory:
		
		cd WiredClient
		git clone https://github.com/ProfDrLuigi/libwired vendor/WiredFrameworks/libwired
		
5. Install pods:

		pod install
		
6. Open `WiredClient.xcworkspace` with Xcode

7. Select scheme `Wired Client` and be sure to use "Debug" Build Configuration (Menu > Product > Schemes > Edit Schemes > Run > Info  Build configuration)

8. Launch Build, Wired Client.app should launch automatically when finished


## Troubleshooting

If you encounter an error during compilation with Xcode crying about `wired.h` not found, got to Build Product folder and rename "libwired/" directory to "wired/". Then try to build again.

If you encounter any other problem, feel free to report it in the issues section here on GitHub.

## Contribute to the project

If you want to contribute to the Wired Client coding effort, check the following steps:

- Fork the project on GitHub
- Commit your changes to a separated branch
- Send us a pull-request to discuss about it

## License

This code is distributed under BSD license, and it is free for personal or commercial use.
		
- Copyright (c) 2003-2009 Axel Andersson, All rights reserved.
- Copyright (c) 2011-2019 Rafaël Warnault, All rights reserved.
		
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
		
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
		
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

