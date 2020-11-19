Pod::Spec.new do |s|
  s.name             = 'OktaOidc'
  s.version          = '3.9.2'
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
     appauth.source_files = 'Okta/AppAuth/*.{h,m}','Sources/OktaOidc/Internal/OktaUserAgent.{h,m}'
     appauth.ios.source_files      = 'Okta/AppAuth/iOS/*.{h,m}'
     appauth.ios.deployment_target = '11.0'
     appauth.osx.source_files = 'Okta/AppAuth/macOS/**/*.{h,m}'
     appauth.osx.deployment_target = '10.10'
  end

  s.subspec 'Okta' do |okta|
     okta.dependency 'OktaOidc/AppAuth'
     okta.subspec 'Classes' do |classes|
        classes.source_files = 'Sources/OktaOidc/*.{h,m,swift}',
                                            'Sources/OktaOidc/Internal/*.{h,m,swift}',
                                            'Sources/OktaOidc/Internal/Tasks/*.{h,m,swift}'
        classes.exclude_files = 'Sources/OktaOidc/OktaOidc.swift',
                                              'Sources/OktaOidc/iOS/OktaOidc+Browser.swift',
                                              'Sources/OktaOidc/macOS/OktaOidc+Browser.swift'
        classes.ios.source_files = 'Sources/OktaOidc/iOS/*.{swift}',
                                                  'Sources/OktaOidc/Internal/iOS/*.{swift}',
                                                  'Sources/OktaOidc/Internal/Tasks/iOS/*.{swift}'
        classes.ios.deployment_target = '11.0'
        classes.osx.source_files = 'Sources/OktaOidc/macOS/*.{swift}',
                                                   'Sources/OktaOidc/Internal/macOS/*.{swift}',
                                                   'Sources/OktaOidc/Internal/Tasks/macOS/*.{swift}'
        classes.osx.deployment_target = '10.10'        
     end
     okta.source_files = 'Sources/OktaOidc/OktaOidc.swift'
     okta.ios.source_files = 'Sources/OktaOidc/iOS/OktaOidc+Browser.swift'
     okta.osx.source_files = 'Sources/OktaOidc/macOS/OktaOidc+Browser.swift'
  end

s.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '${SRCROOT}/OktaOidc/**' }
end
