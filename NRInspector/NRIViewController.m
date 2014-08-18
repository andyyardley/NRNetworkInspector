//
//  NRIViewController.m
//  NRInspector
//
//  Created by Andy on 18/08/2014.
//  Copyright (c) 2014 niveusrosea. All rights reserved.
//

#import "NRIViewController.h"

@interface NRIViewController ()

@property (nonatomic, strong) NSMutableData *serviceData;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation NRIViewController

- (IBAction)click:(id)sender
{
    [self makeNetworkCall];
}

- (void)makeNetworkCall
{
	NSError *error = nil;
    
	NSData *data = [NSJSONSerialization dataWithJSONObject:@{} options:0 error:&error];
    
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
	
	[urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[urlRequest setHTTPBody:data];
	[urlRequest setHTTPMethod:@"POST"];
    
	[urlRequest setURL:[NSURL URLWithString:@"http://www.google.com/"]];
	
	self.serviceData = [NSMutableData data];
    
	self.connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	
	[self.connection start];
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate

-(void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    
}

-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	[self.serviceData appendData:data];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    
}

@end
