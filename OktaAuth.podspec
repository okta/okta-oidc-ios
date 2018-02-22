Pod::Spec.new do |s|
  s.name             = 'OktaAuth'
  s.version          = '0.2.0'
  s.summary          = 'SDK to easily integrate AppAuth with Okta'
  s.description      = <<-DESC
Integrate your native app with Okta using the AppAuth library.
                       DESC

  s.homepage         = 'https://github.com/okta/okta-sdk-appauth-ios'
  s.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  s.authors          = { "Okta Developers" => "developer@okta.com"}
  s.source           = { :git => 'https://github.com/okta/okta-sdk-appauth-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'Okta/**/*'
  s.dependency 'AppAuth', '~> 0.91.0'
  s.dependency 'Vinculum', '~> 0.2.0'
  s.dependency 'HydraAsync', '~> 1.0.1'
end
