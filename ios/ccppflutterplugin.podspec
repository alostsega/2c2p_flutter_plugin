#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ccppflutterplugin.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ccppflutterplugin'
  s.version          = '0.0.2'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://www.ichob.co'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CHOMCHOB' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
    s.vendored_frameworks = 'PGW.framework'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
end
