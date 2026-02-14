#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint no_screenshot.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'no_screenshot'
  s.version          = '0.6.0'
  s.summary          = 'Flutter plugin to enable, disable or toggle screenshot support in your application.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/FlutterPlaza/no_screenshot'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FlutterPlaza' => 'dev@flutterplaza.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
