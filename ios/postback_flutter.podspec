Pod::Spec.new do |s|
  s.name             = 'postback_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Flutter Postback attribution SDK'
  s.description      = 'Flutter plugin wrapper for Postback attribution.'
  s.homepage         = 'https://postback.sh'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Postback' => 'support@postback.sh' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.swift_version = '5.0'
  s.ios.vendored_frameworks = 'PostbackSDK.xcframework'
  s.frameworks = 'Foundation', 'UIKit', 'CoreTelephony', 'Metal', 'CoreGraphics', 'CryptoKit', 'AdServices', 'AppTrackingTransparency', 'AdSupport'
end
