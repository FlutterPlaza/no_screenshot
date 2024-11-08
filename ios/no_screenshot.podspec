#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint no_screenshot.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'no_screenshot'
  s.version          = '0.3.2-beta.1'
  s.summary          = 'Flutter plugin to enable, disable or toggle screenshot support in your application.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/FlutterPlaza/no_screenshot'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FlutterPlaza' => 'dev@flutterplaza.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  # Updated the dependency version to remove the wildcard and use a specific version range
  s.dependency       'ScreenProtectorKit', '~> 1.3.1'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  # Updated swift_version to a single version as an array is not supported for this attribute
  s.swift_version    = "5.0"
end
