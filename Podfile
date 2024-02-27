source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
platform :osx, '10.13'

target 'Wired Client' do
    pod 'SBJson4', '~> 4.0.0'
    pod 'NSDate+TimeAgo'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'SBJson4' || target.name == 'NSDate+TimeAgo'
            target.build_configurations.each do |config|
                config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.13'
            end
        end
    end
end
