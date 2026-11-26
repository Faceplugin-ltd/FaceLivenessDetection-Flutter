Pod::Spec.new do |s|
  s.name             = 'face_liveness_sdk'
  s.version          = '0.2.0'
  s.summary          = 'FacePlugin Face Liveness Detection SDK for Flutter.'
  s.description      = <<-DESC
On-device passive anti-spoofing and guided active liveness. The engine and both camera screens are
the native FacePlugin implementations, vendored from Face-LivenessDetection-iOS.
                       DESC
  s.homepage         = 'https://faceplugin.com'
  s.license          = { :type => 'Commercial', :text => 'FacePlugin commercial license. See https://faceplugin.com' }
  s.author           = { 'FacePlugin' => 'info@faceplugin.com' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.libraries        = 'c++'

  # Prefer device frameworks CocoaPods can embed. FacePPlugin is the ios-arm64
  # slice inside FacePlugin.xcframework — vendor that slice so ld looks for
  # -framework FacePPlugin, not FacePlugin (same as the recognition Flutter app).
  frameworks = []
  missing = []
  %w[
    facerecognitionsdk
    FacePluginSDK
    FacePPlugin
    FaceDetect
  ].each do |base|
    xc = File.join(__dir__, 'Frameworks', "#{base}.xcframework")
    fw = File.join(__dir__, 'Frameworks', "#{base}.framework")
    slice = File.join(__dir__, 'Frameworks', 'FacePlugin.xcframework', 'ios-arm64', "#{base}.framework")
    if File.directory?(fw)
      frameworks << "Frameworks/#{base}.framework"
    elsif File.directory?(xc)
      frameworks << "Frameworks/#{base}.xcframework"
    elsif File.directory?(slice)
      frameworks << "Frameworks/FacePlugin.xcframework/ios-arm64/#{base}.framework"
    else
      missing << base
    end
  end

  unless missing.empty?
    raise Pod::Informative, <<~MSG
      face_liveness_sdk: missing engine framework(s) in ios/Frameworks:
        #{missing.join("\n  ")}

      They are the same binaries the native iOS app embeds. Copy them from
      Face-LivenessDetection-iOS into ios/Frameworks/, then run `pod install` again.
    MSG
  end

  s.vendored_frameworks = frameworks

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited) -framework "facerecognitionsdk" -framework "FacePluginSDK" -framework "FacePPlugin" -framework "FaceDetect" -framework "UniformTypeIdentifiers" -lc++',
  }
end
