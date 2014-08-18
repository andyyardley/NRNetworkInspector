//
//  NRNetworkInspector.h
//  NRNetworkInspector
//
//  Created by Andy on 18/08/2014.
//  Copyright (c) 2014 niveusrosea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURLConnection+NetworkInterceptor.h"

@interface NRNetworkInspector : NSObject

@property (nonatomic, strong) NSArray *requests;

+ (instancetype)sharedInstance;

- (void)addRequest:(NSDictionary *)request;

- (NSString *)requestsAsJSON;

@end
