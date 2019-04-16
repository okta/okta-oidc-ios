Pod::Spec.new do |s|
  s.name             = 'OktaOidc'
  s.version          = '3.0.0'
  s.summary          = 'SDK to easily integrate AppAuth with Okta'
  s.description      = <<-DESC
Integrate your native app with Okta using the AppAuth library.
                       DESC

  s.homepage         = 'https://github.com/okta/okta-oidc-ios'
  s.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  s.authors          = { "Okta Developers" => "developer@okta.com"}
  s.source           = { :git => 'https://github.com/okta/okta-oidc-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'Okta/**/*'
end
