Pod::Spec.new do |s|

  s.name         = 'IMProcessing'
  s.version      = '0.13.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'denn nevera' => 'denn.nevera@gmail.com' }
  s.homepage     = 'http://degradr.photo'
  s.summary      = 'IMProcessing is an image processing framework based on Apple Metal'
  s.description  = 'IMProcessing is an image processing framework provides original effect image/photo. It can be called "masterwork" image processing.'

  s.source       = { :git => 'https://bitbucket.org/degrader/improcessing.git', :tag => s.version }

  s.osx.deployment_target = "10.12"
  s.ios.deployment_target = "10.2"
  s.swift_version = "5.0"

  s.source_files        = 'IMProcessing/Classes/**/*.{h,swift,m,mm}', 'IMProcessing/Classes/*.{swift}', 'IMProcessing/Classes/**/*.h','IMProcessing/Classes/Shaders/*.h', 'vendor/libjpeg-turbo/include/*'
  s.public_header_files = 'IMProcessing/Classes/**/*.h','IMProcessing/Classes/Shaders/*.h'
  # s.vendored_libraries  = 'vendor/libjpeg-turbo/lib/libturbojpeg.a'
  s.header_dir   = 'IMProcessing'
  s.frameworks   = 'Metal'
  # s.dependency:  'Surge', :git => 'https://github.com/dnevera/surge.git', :tag => '1.0.2'
  s.dependency  'Surge'
  #
  # does not work with cocoapods 1.0.0rc2
  #
  # TODO: find solution for -OSX/-IOS enviroment variable, at the moment i don;t know what hould it be, so use paths to boths platform
  # MTL shaders has platform independent sources
  #
  s.xcconfig = { 'MTL_HEADER_SEARCH_PATHS' => '$(PODS_CONFIGURATION_BUILD_DIR)/IMProcessing/IMProcessing.framework/Headers $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessing-OSX/IMProcessing.framework/Headers $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessing-iOS/IMProcessing.framework/Headers  $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessingUI/IMProcessingUI.framework/Headers $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessingUI-OSX/IMProcessingUI.framework/Headers $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessingUI-iOS/IMProcessingUI.framework/Headers'}

  s.requires_arc = true

end
