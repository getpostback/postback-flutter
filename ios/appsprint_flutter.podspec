Pod::Spec.new do |s|
  s.name             = 'appsprint_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Flutter AppSprint attribution SDK'
  s.description      = 'Flutter plugin wrapper for AppSprint attribution.'
  s.homepage         = 'https://appsprint.app'
  s.license          = { :type => 'MIT' }
  s.author           = { 'AppSprint' => 'support@appsprint.app' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.swift_version = '5.0'
  s.ios.vendored_frameworks = 'AppSprintSDK.xcframework'
end
