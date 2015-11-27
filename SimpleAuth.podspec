Pod::Spec.new do |s|
  s.name         = 'SimpleAuth'
  s.version      = '0.3.9'
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

  s.subspec 'Twitter' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'cocoa-oauth'
    ss.frameworks = 'Accounts', 'Social'
    ss.source_files = 'Pod/Providers/Twitter'
    ss.private_header_files = 'Pod/Providers/Twitter/*.h'
  end

  s.subspec 'Facebook' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.frameworks = 'Accounts', 'Social'
    ss.source_files = 'Pod/Providers/Facebook'
    ss.private_header_files = 'Pod/Providers/Facebook/*.h'
  end

  s.subspec 'FacebookWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/FacebookWeb'
    ss.private_header_files = 'Pod/Providers/FacebookWeb/*.h'
  end

  s.subspec 'Instagram' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/Instagram'
    ss.private_header_files = 'Pod/Providers/Instagram/*.h'
  end

  s.subspec 'TwitterWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/TwitterWeb'
    ss.private_header_files = 'Pod/Providers/TwitterWeb/*.h'
  end

  s.subspec 'Meetup' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/Meetup'
    ss.private_header_files = 'Pod/Providers/Meetup/*.h'
  end

  s.subspec 'Tumblr' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/Tumblr'
    ss.private_header_files = 'Pod/Providers/Tumblr/*.h'
  end

  s.subspec 'FoursquareWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/FoursquareWeb'
    ss.private_header_files = 'Pod/Providers/FoursquareWeb/*.h'
  end

  s.subspec 'DropboxWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/DropboxWeb'
    ss.private_header_files = 'Pod/Providers/DropboxWeb/*.h'
  end

  s.subspec 'LinkedInWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/LinkedIn'
    ss.private_header_files = 'Pod/Providers/LinkedIn/*.h'
  end

  s.subspec 'SinaWeiboWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/SinaWeiboWeb'
    ss.private_header_files = 'Pod/Providers/SinaWeiboWeb/*.h'
  end

  s.subspec 'GoogleWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/GoogleWeb'
    ss.private_header_files = 'Pod/Providers/GoogleWeb/*.h'
  end

  s.subspec 'TripIt' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.dependency 'cocoa-oauth'
    ss.source_files = 'Pod/Providers/TripIt'
    ss.private_header_files = 'Pod/Providers/TripIt/*.h'
  end

  s.subspec 'Trello' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/Trello'
    ss.private_header_files = 'Pod/Providers/Trello/*.h'
  end

  s.subspec 'Strava' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/Strava'
    ss.private_header_files = 'Pod/Providers/Strava/*.h'
  end

  s.subspec 'BoxWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/BoxWeb'
    ss.private_header_files = 'Pod/Providers/BoxWeb/*.h'
  end

  s.subspec 'OneDriveWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/OneDriveWeb'
    ss.private_header_files = 'Pod/Providers/OneDriveWeb/*.h'
  end

  s.subspec 'MailChimp' do |ss|
    ss.dependency 'SimpleAuth/Core'
    ss.source_files = 'Pod/Providers/MailChimp'
    ss.private_header_files = 'Pod/Providers/MailChimp/*.h'
  end

end
