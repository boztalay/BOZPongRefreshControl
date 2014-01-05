Pod::Spec.new do |s|
  s.name         = "BOZPongRefreshControl"
  s.version      = "0.0.1"
  s.summary      = "A pull-down-to-refresh control for iOS that plays pong, originally created for the MHacks III iOS app"

  s.homepage     = "https://github.com/jcon5294/BOZPongRefreshControl"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.authors      = { "Ben Oztalay" => "boztalay@umich.edu", "Joseph Constan" => "jcon5294@gmail.com" }

  s.platform     = :ios

  s.source       = { :git => "https://github.com/jcon5294/BOZPongRefreshControl.git", :tag => "0.0.1" }

  s.source_files  = 'BOZPongRefreshControl/*.{h,m}'
  s.public_header_files = 'BOZPongRefreshControl/*.h'

  s.framework  = 'UIKit'
  s.requires_arc = true

end
