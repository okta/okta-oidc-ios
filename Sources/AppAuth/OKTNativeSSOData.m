//
//  OKTNativeSSOData.m
//  OktaJWT
//
//  Created by Dan Cinnamon on 6/29/21.
//

#import "OKTNativeSSOData.h"


static NSString *const kDeviceSecretKey = @"deviceSecret";
static NSString *const kIdTokenKey = @"idToken";

@implementation OKTNativeSSOData

- (instancetype)initWithDeviceSecret:(NSString *)deviceSecret
                             idToken:(NSString *)idToken {
    self = [super init];
    _deviceSecret = deviceSecret;
    _idToken = idToken;
    return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _deviceSecret = [aDecoder decodeObjectOfClass:[NSString class] forKey:kDeviceSecretKey];
    _idToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:kIdTokenKey];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_deviceSecret forKey:kDeviceSecretKey];
  [aCoder encodeObject:_idToken forKey:kIdTokenKey];
}

@end
