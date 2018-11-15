source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
platform :osx, '10.10'

target 'Wired Client' do
    pod 'Sparkle'
    pod 'SBJson4', '~> 4.0.0'
    pod 'NSDate+TimeAgo'
    pod 'OpenSSL-Universal'
end

target 'WiredNetworking' do
    project 'vendor/WiredFrameworks/WiredFrameworks.xcodeproj'
    workspace 'vendor/WiredFrameworks/WiredFrameworks.xcworkspace'
    pod 'OpenSSL-Universal'
end

target 'libwired-osx' do
    project 'vendor/WiredFrameworks/WiredFrameworks.xcodeproj'
    workspace 'vendor/WiredFrameworks/WiredFrameworks.xcworkspace'
    pod 'OpenSSL-Universal'
end
