//
//  OKTNativeSSOData.h
//  Pods
//
//  Created by Dan Cinnamon on 6/29/21.
//

@class OKTNativeSSOData;

@interface OKTNativeSSOData : NSObject <NSSecureCoding>

@property(nonatomic, readonly, nullable) NSString *deviceSecret;
@property(nonatomic, readonly, nullable) NSString *idToken;

- (instancetype)initWithDeviceSecret:(NSString *)deviceSecret
                             idToken:(NSString *)idToken;
@end
