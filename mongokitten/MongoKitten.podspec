Pod::Spec.new do |s|
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.14'
  s.name             = 'MongoKitten'
  s.version          = '5.1.11'
  s.summary          = 'A pure swift, native MongoDB driver'

  s.description      = <<-DESC
High and low level APIs for interacting with MongoDB databases. Supports codable, transactions and all async.
                       DESC

  s.swift_version = '4.2'
  s.homepage         = 'https://github.com/OpenKitten/MongoKitten'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'joannis' => 'joannis@orlandos.nl' }
  s.source           = { :git => 'https://github.com/OpenKitten/MongoKitten.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/joannisorlandos'

  s.dependency     'BSON', '~> 6.0.2'
  s.default_subspecs = 'Core', 'GridFS', 'Mobile'

  s.subspec '_MongoKittenCrypto' do |sub|
    sub.source_files = 'Sources/_MongoKittenCrypto/**/*'
  end
  
  s.subspec 'GridFS' do |sub|
    sub.source_files = 'Sources/GridFS/**/*'
    sub.dependency     'MongoKitten/Core'
  end
  
  s.subspec 'Networking' do |sub|
    sub.ios.deployment_target = '12.0'
    sub.ios.dependency     'SwiftNIOTransportServices', '~> 0.5'
    sub.macos.dependency     'SwiftNIOTransportServices', '~> 0.5'
    sub.dependency     'MongoKitten/Core'
  end

  s.subspec 'Mobile' do |sub|
    sub.ios.dependency     'mongo_embedded', '~> 4.0'
    sub.dependency     'MongoKitten/Core'
  end

  s.subspec 'Core' do |sub|
    sub.source_files = 'Sources/MongoKitten/**/*'
    sub.dependency     'MongoKitten/_MongoKittenCrypto'
    sub.osx.dependency 'SwiftNIOTLS', '~> 1.4'
  end
end
