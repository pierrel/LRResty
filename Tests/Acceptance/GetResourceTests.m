//
//  GetResourceTests.m
//  LRResty
//
//  Created by Luke Redpath on 03/08/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import "TestHelper.h"
#import "LRResty.h"

@interface GetResourceTests : SenTestCase <LRRestyClientResponseDelegate>
{
  LRRestyResponse *lastResponse;
  LRRestyClient *client;
}
@end

@implementation GetResourceTests

- (void)setUp
{
  client = [LRResty newClient];
}

- (void)testCanPerformGetRequestToResourceExtractTheResponseAsAString
{
  mimicGET(@"/simple/resource", andReturnBody(@"plain text response"), ^{
    [client get:resourceWithPathWithPort(@"/simple/resource", 11989) delegate:self];
  });
  
  assertEventuallyThat(&lastResponse, is(responseWithStatusAndBody(200, @"plain text response")));
}

- (void)testCanExtractHeadersFromResponse
{
  mimicGET(@"/simple/resource", andReturnResponseHeader(@"Content-Type", @"text/plain"), ^{
    [client get:resourceWithPathWithPort(@"/simple/resource", 11989) delegate:self];
  });
  
  assertEventuallyThat(&lastResponse, hasHeader(@"Content-Type", @"text/plain"));
}

- (void)testCanPerformGetRequestWithQueryParameters
{
  mimicGET(@"/simple/resource", andEchoRequest(), ^{
    [client get:resourceWithPathWithPort(@"/simple/resource", 11989) 
     parameters:[NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"] 
       delegate:self];
  });
    
  assertEventuallyThat(&lastResponse, is(responseWithRequestEcho(@"params.foo", @"bar")));
}

- (void)testCanPerformGetRequestWithCustomHeaders
{
  mimicGET(@"/simple/resource", andEchoRequest(), ^{  
    [client get:resourceWithPathWithPort(@"/simple/resource", 11989) 
     parameters:nil
        headers:[NSDictionary dictionaryWithObject:@"Resty" forKey:@"X-Test-Header"]
       delegate:self];
  });
  
  assertEventuallyThat(&lastResponse, is(responseWithRequestEcho(@"env.HTTP_X_TEST_HEADER", @"Resty")));
}

- (void)testCanModifyRequestsBeforeTheyAreSentUsingBlock
{
  mimicGET(@"/simple/resource", andEchoRequest(), ^{  
    [client attachRequestModifier:^(LRRestyRequest *request) {
      [request addHeader:@"X-Test-Header" value:@"Resty"];
    }];  
    [client get:resourceWithPathWithPort(@"/simple/resource", 11989) delegate:self];
  });
  
  assertEventuallyThat(&lastResponse, is(responseWithRequestEcho(@"env.HTTP_X_TEST_HEADER", @"Resty")));
  
}

- (void)testCanPerformGetRequestAndPassResponseToABlock
{
  __block LRRestyResponse *testLocalResponse = nil;
  
  serviceStubWillServe(anyResponse(), forGetRequestTo(@"/simple/resource"));
  
  [client get:resourceWithPath(@"/simple/resource") withBlock:^(LRRestyResponse *response) {
    testLocalResponse = [response retain];
  }];
  assertEventuallyThat(&testLocalResponse, is(responseWithStatus(200)));
  
  [testLocalResponse release];
}

#pragma mark -

- (void)restClient:(LRRestyClient *)client receivedResponse:(LRRestyResponse *)response;
{
  lastResponse = [response retain];
}

- (void)tearDown
{
  [lastResponse release]; lastResponse = nil;
  clearServiceStubs();
}

@end
