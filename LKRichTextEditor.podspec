#
# Be sure to run `pod lib lint LKRichTextEditor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LKRichTextEditor'
  s.version          = '0.1.0'
  s.summary          = 'A short description of LKRichTextEditor.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  基于uitextview的富文本编辑器，支持粗体、下划线、斜体、插入图片功能，富文本转html，html转富文本
                       DESC

  s.homepage         = 'https://github.com/LKShadow/LKRichTextEditor'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '李考' => '10857553@boe.com.cn' }
  s.source           = { :git => 'https://github.com/LKShadow/LKRichTextEditor.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'LKRichTextEditor/Classes/**/*'
  
   s.resource_bundles = {
     'LKRichTextEditor' => ['LKRichTextEditor/Assets/LKEditorImageResource.xcassets']
   }
   s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
   s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
#   s.dependency 'Masonry', '~> 1.1.0'
  
end
