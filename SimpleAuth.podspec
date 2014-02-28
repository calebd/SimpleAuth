Pod::Spec.new do |s|
  s.name         = 'SimpleAuth'
  s.version      = '0.3.3'
  s.summary      = 'Simple social authentication for iOS.'
  s.homepage     = 'https://github.com/calebd/SimpleAuth'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Caleb Davenport' => 'calebmdavenport@gmail.com' }
  s.source       = { :git => 'https://github.com/calebd/SimpleAuth.git', :tag => "v#{s.version}" }
  s.requires_arc = true
  s.platform     = :ios, '6.0'

  s.subspec 'Core' do |ss|
    ss.source_files = 'SimpleAuth/**/*.{h,m}'
    ss.public_header_files = 'SimpleAuth/SimpleAuth.h'
    ss.exclude_files = 'SimpleAuth/UI'
    ss.dependency 'ReactiveCocoa'
    ss.dependency 'CMDQueryStringSerialization'
  end

  s.subspec 'UI' do |ss|
    ss.dependency 'SimpleAuth/Core'

    ss.ios.source_files = 'SimpleAuth/UI/ios/**/*.{h,m}'
    ss.ios.frameworks = 'UIKit'

    # ss.osx.source_files = 'SimpleAuth/UI/mac/**/*.{h,m}'
    # ss.osx.frameworks = 'AppKit'
  end

  s.subspec 'Twitter' do |ss|
    ss.dependency 'SimpleAuth/UI'

    ss.source_files = 'Providers/Twitter/**/*.{h,m}'
    ss.frameworks = 'Accounts', 'Social'

    ss.dependency 'cocoa-oauth'
  end

  s.subspec 'Facebook' do |ss|
    ss.dependency 'SimpleAuth/Core'

    ss.source_files = 'Providers/Facebook/**/*.{h,m}'
    ss.frameworks = 'Accounts', 'Social'
  end

  s.subspec 'FacebookWeb' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Providers/FacebookWeb/**/*.{h,m}'
  end

  s.subspec 'Instagram' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Providers/Instagram/**/*.{h,m}'
  end

  s.subspec 'TwitterWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'

    ss.source_files = 'Providers/TwitterWeb/**/*.{h,m}'

    ss.dependency 'cocoa-oauth'
  end

  s.subspec 'Meetup' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Providers/Meetup/**/*.{h,m}'
  end

  s.subspec 'Tumblr' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'SimpleAuth/UI'

    ss.source_files = 'Providers/Tumblr/**/*.{h,m}'

    ss.dependency 'cocoa-oauth'
  end

  s.subspec 'FoursquareWeb' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Providers/FoursquareWeb/**/*.{h,m}'
  end

  s.subspec 'DropboxWeb' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Providers/DropboxWeb/**/*.{h,m}'
  end

  s.subspec 'LinkedInWeb' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Providers/LinkedIn/**/*.{h,m}'
  end

  s.subspec 'SinaWeiboWeb' do |ss|
    ss.dependency 'SimpleAuth/UI'
    ss.source_files = 'Providers/SinaWeiboWeb/**/*.{h,m}'
  end
end
