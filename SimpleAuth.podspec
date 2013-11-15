Pod::Spec.new do |s|
  s.name         = 'SimpleAuth'
  s.version      = '0.1.0'
  s.summary      = 'Library for doing things with social auth.'
  s.homepage     = 'https://github.com/SimpleAuth/SimpleAuth'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Caleb Davenport' => 'caleb@seesaw.co' }
  s.source       = { :git => 'https://github.com/SimpleAuth/SimpleAuth.git', :tag => "v#{s.version}" }

  s.source_files = 'SimpleAuth/**/*.{h,m}'
  s.requires_arc = true
  
  s.ios.deployment_target = '6.0'
  s.ios.frameworks = 'Accounts', 'Social', 'Security', 'UIKit'
end