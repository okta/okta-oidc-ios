Pod::Spec.new do |s|
  s.name             = 'OktaOidc'
  s.version          = '3.8.0'
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
     appauth.source_files = 'Okta/AppAuth/*.{h,m}','Okta/OktaOidc/Internal/OktaUserAgent.{h,m}'
     appauth.ios.source_files      = 'Okta/AppAuth/iOS/*.{h,m}'
     appauth.ios.deployment_target = '11.0'
     appauth.osx.source_files = 'Okta/AppAuth/macOS/**/*.{h,m}'
     appauth.osx.deployment_target = '10.10'
  end

  s.subspec 'Okta' do |okta|
     okta.dependency 'OktaOidc/AppAuth'
     okta.subspec 'Classes' do |classes|
        classes.source_files = 'Okta/OktaOidc/*.{h,m,swift}',
                                            'Okta/OktaOidc/Internal/*.{h,m,swift}',
                                            'Okta/OktaOidc/Internal/Tasks/*.{h,m,swift}'
        classes.exclude_files = 'Okta/OktaOidc/OktaOidc.swift',
                                              'Okta/OktaOidc/iOS/OktaOidc+Browser.swift',
                                              'Okta/OktaOidc/macOS/OktaOidc+Browser.swift'
        classes.ios.source_files = 'Okta/OktaOidc/iOS/*.{swift}',
                                                  'Okta/OktaOidc/Internal/iOS/*.{swift}',
                                                  'Okta/OktaOidc/Internal/Tasks/iOS/*.{swift}'
        classes.ios.deployment_target = '11.0'
        classes.osx.source_files = 'Okta/OktaOidc/macOS/*.{swift}',
                                                   'Okta/OktaOidc/Internal/macOS/*.{swift}',
                                                   'Okta/OktaOidc/Internal/Tasks/macOS/*.{swift}'
        classes.osx.deployment_target = '10.10'        
     end
     okta.source_files = 'Okta/OktaOidc/OktaOidc.swift'
     okta.ios.source_files = 'Okta/OktaOidc/iOS/OktaOidc+Browser.swift'
     okta.osx.source_files = 'Okta/OktaOidc/macOS/OktaOidc+Browser.swift'
  end

s.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '${SRCROOT}/OktaOidc/**' }
end
