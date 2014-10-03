Pod::Spec.new do |s|
  s.name         = 'SimpleAuth'
  s.version      = '0.3.6'
  s.summary      = 'Simple social authentication for iOS.'
  s.homepage     = 'https://github.com/calebd/SimpleAuth'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Caleb Davenport' => 'calebmdavenport@gmail.com' }
  s.source       = { :git => 'https://github.com/calebd/SimpleAuth.git', :tag => "v#{s.version}" }
  s.requires_arc = true
  s.platform     = :ios, '6.0'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Pod/Core/*.{h,m}'
    ss.public_header_files = 'Pod/Core/SimpleAuth.h'
    ss.dependency 'ReactiveCocoa'
    ss.dependency 'CMDQueryStringSerialization'
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
    ss.source_files = 'Pod/Providers/Twitter/*.{h,m}'
  end

  s.subspec 'Facebook' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.frameworks = 'Accounts', 'Social'
    ss.source_files = 'Pod/Providers/Facebook/*.{h,m}'
  end

  s.subspec 'FacebookWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/FacebookWeb/*.{h,m}'
  end

  s.subspec 'Instagram' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/Instagram/*.{h,m}'
  end

  s.subspec 'TwitterWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/TwitterWeb/*.{h,m}'
  end

  s.subspec 'Meetup' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/Meetup/*.{h,m}'
  end

  s.subspec 'Tumblr' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/Tumblr/*.{h,m}'
  end

  s.subspec 'FoursquareWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/FoursquareWeb/*.{h,m}'
  end

  s.subspec 'DropboxWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/DropboxWeb/*.{h,m}'
  end

  s.subspec 'LinkedInWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/LinkedIn/*.{h,m}'
  end

  s.subspec 'SinaWeiboWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Pod/Providers/SinaWeiboWeb/*.{h,m}'
  end
end
