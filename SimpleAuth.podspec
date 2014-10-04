Pod::Spec.new do |s|
  s.name         = 'SimpleAuth'
  s.version      = '0.3.6'
  s.summary      = 'Simple social authentication for iOS.'
  s.homepage     = 'https://github.com/calebd/SimpleAuth'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Caleb Davenport' => 'calebmdavenport@gmail.com' }
  s.source       = { :git => 'https://github.com/calebd/SimpleAuth.git', :tag => "v#{s.version}" }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.10'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Pod/Core'
    ss.public_header_files = 'Pod/Core/SimpleAuth.h'

    ss.dependency 'ReactiveCocoa'
    ss.dependency 'CMDQueryStringSerialization'

    ss.ios.frameworks = 'UIKit'
    ss.ios.source_files = 'Pod/Core/ios'

    ss.osx.frameworks = 'Cocoa', 'Webkit'
    ss.osx.source_files = 'Pod/Core/osx'
  end

  s.subspec 'Twitter' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'cocoa-oauth'
    ss.frameworks = 'Accounts', 'Social'
    ss.source_files = 'Pod/Providers/Twitter'
  end

  s.subspec 'Facebook' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.frameworks = 'Accounts', 'Social'
    ss.ios.source_files = 'Pod/Providers/Facebook'
  end

  s.subspec 'FacebookWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/Providers/FacebookWeb'
  end

  s.subspec 'Instagram' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/Providers/Instagram'
  end

  s.subspec 'TwitterWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'cocoa-oauth'
    ss.ios.source_files = 'Pod/Providers/TwitterWeb'
  end

  s.subspec 'Meetup' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/Providers/Meetup'
  end

  s.subspec 'Tumblr' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'cocoa-oauth'
    ss.ios.source_files = 'Pod/Providers/Tumblr'
  end

  s.subspec 'FoursquareWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/Providers/FoursquareWeb'
  end

  s.subspec 'DropboxWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/Providers/DropboxWeb'
  end

  s.subspec 'LinkedInWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/Providers/LinkedIn'
  end

  s.subspec 'SinaWeiboWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/Providers/SinaWeiboWeb'
  end
end
