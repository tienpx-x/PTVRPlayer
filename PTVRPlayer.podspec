#
# Be sure to run `pod lib lint PTVRPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PTVRPlayer'
  s.version          = '1.0.0'
  s.summary          = 'PTVRPlayer allows you to build immersive cross-platform VR experiences for iOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/tienpx-x/PTVRPlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tienpx-xxx' => 'tienpx.xxx@gmail.com' }
  s.source           = { :git => 'https://github.com/tienpx-x/PTVRPlayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'PTVRPlayer/Classes/**/*'
  
   s.public_header_files = 'Pod/Classes/**/*.h'
   s.dependency 'Then'
   s.dependency 'SwiftProtobuf'
   s.dependency 'Result'
   
end
