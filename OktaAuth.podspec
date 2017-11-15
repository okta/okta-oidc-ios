#
# Be sure to run `pod lib lint Okta.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OktaAuth'
  s.version          = '0.1.0'
  s.summary          = 'SDK to easily integrate AppAuth with Okta'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Integrate your native app with Okta using the AppAuth library.
                       DESC

  s.homepage         = 'https://github.com/okta/okta-sdk-appauth-ios'
  s.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  s.authors          = { "Okta Developers" => "developer@okta.com"}
  s.source           = { :git => 'https://github.com/okta/okta-sdk-appauth-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'Okta/**/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'AppAuth', '~> 0.91.0'
end
