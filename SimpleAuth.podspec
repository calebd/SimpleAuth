Pod::Spec.new do |s|
  s.name         = 'SimpleAuth'
  s.version      = '0.2.1'
  s.summary      = 'Library for doing things with social auth.'
  s.homepage     = 'https://github.com/SimpleAuth/SimpleAuth'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Caleb Davenport' => 'caleb@seesaw.co' }
  s.source       = { :git => 'https://github.com/SimpleAuth/SimpleAuth.git', :tag => "v#{s.version}" }
  s.requires_arc = true
  s.platform     = :ios, '6.0'
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'SimpleAuth/**/*.{h,m}'
    ss.public_header_files = 'SimpleAuth/SipmleAuth.h'
    ss.dependency 'ReactiveCocoa'
    ss.dependency 'SAMCategories'
  end
  
  s.subspec 'Twitter' do |ss|
    ss.dependency 'SimpleAuth/Core'
    
    ss.source_files = 'Providers/Twitter/**/*.{h,m}'
    ss.frameworks = 'Accounts', 'Social', 'UIKit'
    
    ss.dependency 'cocoa-oauth'
  end
  
  s.subspec 'Facebook' do |ss|
    ss.dependency 'SimpleAuth/Core'
    
    ss.source_files = 'Providers/Facebook/**/*.{h,m}'
    ss.frameworks = 'Accounts', 'Social'
  end
  
  s.subspec 'Instagram' do |ss|
    ss.dependency 'SimpleAuth/Core'
    
    ss.source_files = 'Providers/Instagram/**/*.{h,m}'
    ss.frameworks = 'UIKit'
  end
  
  s.subspec 'TwitterWeb' do |ss|
    ss.dependency 'SimpleAuth/Core'
    
    ss.source_files = 'Providers/TwitterWeb/**/*.{h,m}'
    ss.frameworks = 'UIKit'
    
    ss.dependency 'cocoa-oauth'
  end
end