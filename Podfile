# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

def shared_extension_pods
  pod 'Analytics', '~> 3.0'
  pod 'KeychainSwift', '~> 11.0'
end

def shared_pods
  pod 'Analytics', '~> 3.0'
  pod 'PhoneNumberKit', '~> 2.1'
  pod 'AWSS3'
  pod 'SwiftyStoreKit'
  pod 'KeychainSwift', '~> 11.0'
end

target 'MessageFilter' do
  use_frameworks!
  shared_extension_pods
end

target 'Text Protector' do
  use_frameworks!
  shared_pods
end

target 'MessageFilter Pro' do
    use_frameworks!
    shared_extension_pods
end

target 'Text Protector Pro' do
    use_frameworks!
    shared_pods    
end

post_install do |installer| 
    installer.pods_project.build_configurations.each do |config|
      if config.name == 'Release'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
      else
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      end    
    end
end
