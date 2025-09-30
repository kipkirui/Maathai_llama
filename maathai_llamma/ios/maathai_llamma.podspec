#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint maathai_llamma.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'maathai_llamma'
  s.version          = '0.1.0'
  s.summary          = 'Flutter bindings for llama.cpp offline inference.'
  s.description      = <<-DESC
Bindings that wrap llama.cpp to run GGUF models entirely offline from Flutter apps.
                       DESC
  s.homepage         = 'https://github.com/usemaathai/maathai_llamma'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Maathai' => 'support@usemaathai.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'maathai_llamma_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
