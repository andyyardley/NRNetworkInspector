//
//  NRNetworkInspector.m
//  NRNetworkInspector
//
//  Created by Andy on 18/08/2014.
//  Copyright (c) 2014 niveusrosea. All rights reserved.
//

#import "NRNetworkInspector.h"
#import <GCDWebServer/GCDWebServerDataResponse.h>

@implementation NRNetworkInspector

+ (void)load
{
    
    
}

+ (instancetype)sharedInstance
{
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (void)start
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Override point for customization after application launch.
        
        GCDWebServer* webServer = [[GCDWebServer alloc] init];
        
        // Add a handler to respond to GET requests on any URL
        [webServer addDefaultHandlerForMethod:@"GET"
                                 requestClass:[GCDWebServerRequest class]
                                 processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                     
                                     if ([request.path isEqualToString:@"/data"])
                                         return [GCDWebServerDataResponse responseWithJSONObject:[NRNetworkInspector sharedInstance].requests];
                                     return [GCDWebServerDataResponse responseWithHTML:@"<html>\
                                             <body>\
                                             Test\
                                             </body>\
                                             </html>"];
                                     
                                 }];
        
        // Use convenience method that runs server on port 8080
        // until SIGINT (Ctrl-C in Terminal) or SIGTERM is received
        [webServer startWithPort:8080 bonjourName:nil];
        NSLog(@"Visit %@ in your web browser", webServer.serverURL);
        
    });
    
}

- (void)addRequest:(NSDictionary *)request
{
    self.requests = [self.requests arrayByAddingObject:request];
}

- (NSArray *)requests
{
    if (!_requests)
        _requests = @[];
    return _requests;
}

- (NSString *)requestsAsJSON
{
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.requests options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end
