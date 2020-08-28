//
//  OktaOidcHTTPProtocol.h
//  okta-oidc
//
//  Created by Lihao Li on 8/27/20.
//  Copyright © 2020 Okta. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OktaOidcHTTPProtocol <NSObject>

- (void)willSendRequest: (nullable NSURLRequest *)request;
- (void)didReceiveResponse: (nullable NSURLResponse *)response;

@end
