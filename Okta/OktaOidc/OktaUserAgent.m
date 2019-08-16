/*
 * Copyright (c) 2017-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

#import "OktaUserAgent.h"
#include <sys/utsname.h>

@implementation OktaUserAgent

+(NSString*)userAgentVersion {
    return @"3.5.1";
}

+(NSString*)userAgentHeaderKey {
    return @"User-Agent";
}

+(NSString*)userAgentHeaderValue {
    
    NSString *bundleVersion = [self.class userAgentVersion];
    NSString *systemVersion = [[NSProcessInfo processInfo] operatingSystemVersionString];
    struct utsname deviceInfo;
    uname(&deviceInfo);
    NSString *deviceModel = [NSString stringWithUTF8String:deviceInfo.machine];
    NSString *formattedString = [NSString stringWithFormat:@"okta-oidc-ios/%@ iOS/%@ Device/%@", bundleVersion.length > 0 ? bundleVersion : @"", systemVersion, deviceModel];
    return formattedString;
}

@end
