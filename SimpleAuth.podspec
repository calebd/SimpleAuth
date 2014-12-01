Pod::Spec.new do |s|
  s.name         = 'SimpleAuth'
  s.version      = '0.3.7'
  s.summary      = 'Simple social authentication for iOS.'
  s.homepage     = 'https://github.com/calebd/SimpleAuth'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Caleb Davenport' => 'calebmdavenport@gmail.com' }
  s.source       = { :git => 'https://github.com/calebd/SimpleAuth.git', :tag => "v#{s.version}" }
  s.requires_arc = true
  s.platform     = :ios, '6.0'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Pod/Core'
    ss.public_header_files = 'Pod/Core/SimpleAuth.h', 'Pod/Core/SimpleAuthDefines.h'
    ss.dependency 'ReactiveCocoa'
    ss.dependency 'CMDQueryStringSerialization'

    ss.ios.frameworks = 'UIKit'
    ss.ios.source_files = 'Pod/Core/ios'
    ss.ios.resource_bundle = { 'SimpleAuth' => [ 'Pod/Resources/*.lproj' ] }
  end

  s.subspec 'UI' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.ios.source_files = 'Pod/UI/ios/*.{h,m}'
    ss.ios.frameworks = 'UIKit'
  end

  s.subspec 'Twitter' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.dependency 'cocoa-oauth'
    ss.frameworks = 'Accounts', 'Social'
    ss.source_files = 'Pod/Providers/Twitter'
  end

  s.subspec 'Facebook' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.frameworks = 'Accounts', 'Social'
    ss.source_files = 'Pod/Providers/Facebook'
  end

  s.subspec 'FacebookWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/FacebookWeb'
  end

  s.subspec 'Instagram' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/Instagram'
  end

  s.subspec 'TwitterWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/TwitterWeb'
  end

  s.subspec 'Meetup' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/Meetup'
  end

  s.subspec 'Tumblr' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/Tumblr'
  end

  s.subspec 'FoursquareWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/FoursquareWeb'
  end

  s.subspec 'DropboxWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/DropboxWeb'
  end

  s.subspec 'LinkedInWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/LinkedIn'
  end

  s.subspec 'SinaWeiboWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/SinaWeiboWeb'
  end

  s.subspec 'GoogleWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/GoogleWeb'
  end

  s.subspec 'TripIt' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/TripIt'
  end

  s.subspec 'Trello' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/Trello'
  end

  s.subspec 'Strava' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/Strava'
  end
end
