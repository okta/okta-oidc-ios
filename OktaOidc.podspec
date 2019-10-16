Pod::Spec.new do |s|
  s.name             = 'OktaOidc'
  s.version          = '3.6.0'
  s.summary          = 'SDK to easily integrate AppAuth with Okta'
  s.description      = <<-DESC
Integrate your native app with Okta using the AppAuth library.
                       DESC
  s.platforms    = { :ios => "9.0", :osx => "10.10"}
  s.homepage         = 'https://github.com/okta/okta-oidc-ios'
  s.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  s.authors          = { "Okta Developers" => "developer@okta.com"}
  s.source           = { :git => 'https://github.com/okta/okta-oidc-ios.git', :tag => s.version.to_s }
  s.swift_version = '4.2'

  s.subspec 'Core' do |core|
     core.source_files = 'Okta/AppAuth/*.{h,m}','Okta/OktaOidc/OktaUserAgent.{h,m}'
     core.ios.source_files      = 'Okta/AppAuth/iOS/*.{h,m}'
     core.ios.deployment_target = '9.0'
     core.osx.source_files = 'Okta/AppAuth/macOS/**/*.{h,m}'
     core.osx.deployment_target = '10.10'
  end
 
  s.source_files = 'Okta/OktaOidc/*.{h,m,swift}','Okta/OktaOidc/Tasks/*.{h,m,swift}'
  s.exclude_files = 'Okta/OktaOidc/OktaUserAgent.{h,m}'
  s.ios.source_files = 'Okta/OktaOidc/iOS/*.{swift}','Okta/OktaOidc/Tasks/iOS/*.{swift}'
  s.ios.deployment_target = '9.0'
  s.osx.source_files = 'Okta/OktaOidc/macOS/*.{swift}','Okta/OktaOidc/Tasks/macOS/*.{swift}'
  s.osx.deployment_target = '10.10'
end
