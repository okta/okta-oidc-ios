Pod::Spec.new do |s|
  s.name             = 'OktaOidc'
  s.version          = '3.11.2'
  s.summary          = 'SDK to easily integrate AppAuth with Okta'
  s.description      = <<-DESC
Integrate your native app with Okta using the AppAuth library.
                       DESC
  s.platforms    = { :ios => "11.0", :osx => "10.10"}
  s.homepage         = 'https://github.com/okta/okta-oidc-ios'
  s.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  s.authors          = { "Okta Developers" => "developer@okta.com"}
  s.source           = { :git => 'https://github.com/okta/okta-oidc-ios.git', :tag => s.version.to_s }
  s.swift_version = '5.0'

  s.subspec 'AppAuth' do |appauth|
     appauth.source_files = 'Sources/AppAuth/**/*.{h,m}'
     appauth.ios.deployment_target = '11.0'
     appauth.osx.deployment_target = '10.10'
  end

  s.subspec 'Okta' do |okta|
     okta.dependency 'OktaOidc/AppAuth'
     okta.source_files = 'Sources/OktaOidc/**/*.{h,swift}'
     okta.exclude_files = 'Sources/OktaOidc/Common/Exports.swift'
     okta.ios.deployment_target = '11.0'
     okta.osx.deployment_target = '10.10'
  end

  s.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '${SRCROOT}/Sources/**' }
end
