#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint no_screenshot.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'no_screenshot'
  s.version          = '0.10.0'
  s.summary          = 'Flutter plugin to enable, disable or toggle screenshot support in your application.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/FlutterPlaza/no_screenshot'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FlutterPlaza' => 'dev@flutterplaza.com' }
  s.source           = { :path => '.' }
  s.source_files = 'no_screenshot/Sources/no_screenshot/**/*.swift', 'Classes/**/*.{h,m}'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.resource_bundles = { 'no_screenshot_privacy' => ['no_screenshot/Sources/no_screenshot/PrivacyInfo.xcprivacy'] }

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = "5.0"
end
