//
//  NSURLConnection+NetworkInterceptor.m
//  NRNetworkInspector
//
//  Created by Andy on 18/08/2014.
//  Copyright (c) 2014 niveusrosea. All rights reserved.
//

#import "NSURLConnection+NetworkInterceptor.h"
#import <objc/runtime.h>
#import "NRNetworkInspector.h"

static NSString *const kNRIRequest = @"req";
static NSString *const kNRIResponse = @"res";
static NSString *const kNRIURL = @"url";
static NSString *const kNRIHeaders = @"head";
static NSString *const kNRITime = @"time";
static NSString *const kNRIStatusCode = @"statusCode";
static NSString *const kNRISuccess = @"success";
static NSString *const kNRIBody = @"body";

@interface NRIConnectionDelegate : NSProxy <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, weak) id<NSURLConnectionDelegate, NSURLConnectionDataDelegate> delegate;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic) BOOL success;

@end

@implementation NSURLConnection (NetworkInterceptor)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getInstanceMethod([self class], @selector(initWithRequest:delegate:));
        Method swizzledMethod = class_getInstanceMethod([self class], @selector(swizzle_initWithRequest:delegate:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
        originalMethod = class_getInstanceMethod([self class], @selector(initWithRequest:delegate:startImmediately:));
        swizzledMethod = class_getInstanceMethod([self class], @selector(swizzle_initWithRequest:delegate:startImmediately:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (id)swizzle_initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    NRIConnectionDelegate *newDelegate = [NRIConnectionDelegate alloc];
    newDelegate.delegate = delegate;
    newDelegate.request = request;
    newDelegate.startDate = [NSDate new];
    return [self swizzle_initWithRequest:request delegate:newDelegate startImmediately:startImmediately];
}

- (id)swizzle_initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
    NRIConnectionDelegate *newDelegate = [NRIConnectionDelegate alloc];
    newDelegate.delegate = delegate;
    newDelegate.request = request;
    newDelegate.startDate = [NSDate new];
    return [self swizzle_initWithRequest:request delegate:newDelegate];
}

@end

@implementation NRIConnectionDelegate

#pragma mark NSProxy

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    if (class_respondsToSelector(object_getClass(self), invocation.selector))
        [invocation invokeWithTarget:self];
    else
        [invocation invokeWithTarget:self.delegate];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if (class_respondsToSelector(object_getClass(self), sel))
    {
        return [self methodSignatureForSelector:sel];
    }
    if ([self.delegate respondsToSelector:@selector(methodSignatureForSelector:)] && [self.delegate respondsToSelector:sel])
        return [(id)self.delegate methodSignatureForSelector:sel];
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (class_respondsToSelector(object_getClass(self), aSelector))
        return YES;
    else if ([self.delegate respondsToSelector:@selector(respondsToSelector:)])
        return [self.delegate respondsToSelector:aSelector];
    return NO;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.endDate = [NSDate new];
    self.success = true;
    [self storeNetworkTransactionData];
    [self.delegate connectionDidFinishLoading:connection];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    self.data = [NSMutableData new];
    [self.delegate connection:connection didReceiveResponse:response];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];
    [self.delegate connection:connection didReceiveData:data];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.endDate = [NSDate new];
    self.success = false;
    [self storeNetworkTransactionData];
    [self.delegate connection:connection didFailWithError:error];
}

- (void)storeNetworkTransactionData
{
    
    NSMutableDictionary *requestDict = [@{
        kNRIURL: self.request.URL.description,
        kNRITime: @([self.startDate timeIntervalSince1970]),
        kNRIHeaders: [self.request allHTTPHeaderFields]
    } mutableCopy];
    
    NSMutableDictionary *responseDict = [@{
        kNRITime: @([self.endDate timeIntervalSince1970])
    } mutableCopy];
    
    if ([self.response isKindOfClass:[NSHTTPURLResponse class]])
    {
        [responseDict addEntriesFromDictionary:@{
                                                 kNRIHeaders: [((NSHTTPURLResponse *)self.response) allHeaderFields],
                                                 kNRIBody: [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding],
                                                 kNRIStatusCode: @([((NSHTTPURLResponse *)self.response) statusCode]),
                                                 }];
    }
    
    [[NRNetworkInspector sharedInstance] addRequest:@{
                                                  kNRISuccess: @(self.success),
                                                  kNRIRequest: [requestDict copy],
                                                  kNRIResponse: [responseDict copy]
                                                  }];
}

@end
