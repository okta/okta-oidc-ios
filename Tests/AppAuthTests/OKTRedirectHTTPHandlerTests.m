/*
 * Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

#import <XCTest/XCTest.h>
#import "OKTRedirectHTTPHandler.h"
#import "OKTLoopbackHTTPServer.h"

@interface OKTRedirectHTTPHandlerTests<OKTExternalUserAgentSession> : XCTestCase

@property BOOL resumeExternalUserAgentFlowWithURLCalled;

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL;

@end

@interface OKTRedirectHTTPHandler(Private)

- (BOOL)isOptionsHTTPServerRequest:(HTTPServerRequest *)request;
- (void)HTTPConnection:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess;

@end

@implementation OKTRedirectHTTPHandlerTests

- (void)testIsOptionsHTTPServerRequest {
    OKTRedirectHTTPHandler *handler = [OKTRedirectHTTPHandler new];
    CFStringRef url = CFSTR("http://www.okta.com");
    CFURLRef myURL = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);
    
    CFStringRef requestMethod = CFSTR("GET");
    CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, myURL, kCFHTTPVersion1_1);
    HTTPConnection *connection = [[HTTPConnection alloc] initWithPeerAddress:nil inputStream:nil outputStream:nil forServer:nil];
    HTTPServerRequest *request = [[HTTPServerRequest alloc] initWithRequest:myRequest connection:connection];
    BOOL isOptionsRequest = [handler isOptionsHTTPServerRequest: request];
    XCTAssertFalse(isOptionsRequest);
    
    requestMethod = CFSTR("OPTIONS");
    myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, myURL, kCFHTTPVersion1_1);
    request = [[HTTPServerRequest alloc] initWithRequest:myRequest connection:connection];
    isOptionsRequest = [handler isOptionsHTTPServerRequest: request];
    XCTAssertTrue(isOptionsRequest);
    
    requestMethod = CFSTR("options");
    myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, myURL, kCFHTTPVersion1_1);
    request = [[HTTPServerRequest alloc] initWithRequest:myRequest connection:connection];
    isOptionsRequest = [handler isOptionsHTTPServerRequest: request];
    XCTAssertTrue(isOptionsRequest);
    
    isOptionsRequest = [handler isOptionsHTTPServerRequest: nil];
    XCTAssertFalse(isOptionsRequest);
}

- (void)testDidReceiveRequestDelegate_NoOptionsHeader {
    OKTRedirectHTTPHandler *handler = [OKTRedirectHTTPHandler new];
    handler.currentAuthorizationFlow = (id<OKTExternalUserAgentSession>)self;
    CFStringRef url = CFSTR("http://www.okta.com");
    CFURLRef myURL = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);
    CFStringRef requestMethod = CFSTR("GET");
    CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, myURL, kCFHTTPVersion1_1);
    HTTPConnection *connection = [[HTTPConnection alloc] initWithPeerAddress:nil inputStream:nil outputStream:nil forServer:nil];
    HTTPServerRequest *request = [[HTTPServerRequest alloc] initWithRequest:myRequest connection:connection];
    
    self.resumeExternalUserAgentFlowWithURLCalled = NO;
    [handler HTTPConnection:connection didReceiveRequest:request];
    XCTAssertTrue(self.resumeExternalUserAgentFlowWithURLCalled);
    
    myURL = nil;
    requestMethod = CFSTR("GET");
    myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, myURL, kCFHTTPVersion1_1);
    request = [[HTTPServerRequest alloc] initWithRequest:myRequest connection:connection];
    self.resumeExternalUserAgentFlowWithURLCalled = NO;
    [handler HTTPConnection:connection didReceiveRequest:request];
    XCTAssertFalse(self.resumeExternalUserAgentFlowWithURLCalled);
}

- (void)testDidReceiveRequestDelegate_WithOptionsHeader {
    OKTRedirectHTTPHandler *handler = [OKTRedirectHTTPHandler new];
    handler.currentAuthorizationFlow = (id<OKTExternalUserAgentSession>)self;
    CFStringRef url = CFSTR("http://www.okta.com");
    CFURLRef myURL = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);
    CFStringRef requestMethod = CFSTR("OPTIONS");
    CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, myURL, kCFHTTPVersion1_1);
    HTTPConnection *connection = [[HTTPConnection alloc] initWithPeerAddress:nil inputStream:nil outputStream:nil forServer:nil];
    HTTPServerRequest *request = [[HTTPServerRequest alloc] initWithRequest:myRequest connection:connection];
    CFStringRef privateNetworkHeader = CFSTR("Access-Control-Request-Private-Network");
    CFStringRef privateNetworkValue = CFSTR("true");
    CFHTTPMessageSetHeaderFieldValue(myRequest, privateNetworkHeader, privateNetworkValue);
    CFStringRef originHeader = CFSTR("Origin");
    CFStringRef originValue = CFSTR("http://www.okta.com");
    CFHTTPMessageSetHeaderFieldValue(myRequest, originHeader, originValue);
    
    self.resumeExternalUserAgentFlowWithURLCalled = NO;
    [handler HTTPConnection:connection didReceiveRequest:request];
    XCTAssertFalse(self.resumeExternalUserAgentFlowWithURLCalled);
    
    CFHTTPMessageRef response = request.response;
    
    originHeader = CFHTTPMessageCopyHeaderFieldValue(response, (__bridge CFStringRef)@"Access-Control-Allow-Origin");
    BOOL originHeaderExists = CFStringCompare(originHeader, originValue, kCFCompareCaseInsensitive) == kCFCompareEqualTo;
    XCTAssertTrue(originHeaderExists);
    
    CFStringRef allowCredentialsHeader = CFHTTPMessageCopyHeaderFieldValue(response, (__bridge CFStringRef)@"Access-Control-Allow-Credentials");
    BOOL allowCredentialsHeaderExists = CFStringCompare(allowCredentialsHeader, (__bridge CFStringRef)@"true", kCFCompareCaseInsensitive) == kCFCompareEqualTo;
    XCTAssertTrue(allowCredentialsHeaderExists);
    
    CFStringRef allowPrivateNetworkHeader = CFHTTPMessageCopyHeaderFieldValue(response, (__bridge CFStringRef)@"Access-Control-Allow-Private-Network");
    BOOL allowPrivateNetworkHeaderExists = CFStringCompare(allowPrivateNetworkHeader, (__bridge CFStringRef)@"true", kCFCompareCaseInsensitive) == kCFCompareEqualTo;
    XCTAssertTrue(allowPrivateNetworkHeaderExists);
    
    CFStringRef contentLengthHeader = CFHTTPMessageCopyHeaderFieldValue(response, (__bridge CFStringRef)@"Content-Length");
    BOOL contentLengthHeaderExists = CFStringCompare(contentLengthHeader, (__bridge CFStringRef)@"0", kCFCompareCaseInsensitive) == kCFCompareEqualTo;
    XCTAssertTrue(contentLengthHeaderExists);
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL {
    self.resumeExternalUserAgentFlowWithURLCalled = YES;
    return true;
}

- (void)failExternalUserAgentFlowWithError:(NSError *)error {
}

@end
