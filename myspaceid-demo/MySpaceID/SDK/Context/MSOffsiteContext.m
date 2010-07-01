//
//  MSOffsiteContext.m
//  MySpaceID
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import "MSOffsiteContext.h"
#import "OAServiceTicket.h"
#import "OAToken.h"
#import "OAConsumer.h"
#import "OADataFetcher.h"
#import "NSString+URLEncoding.h"


@implementation MSOffsiteContext

+ (MSOffsiteContext*) contextWithConsumerKey:(NSString*) consumerKey
							consumerSecret:(NSString*) consumerSecret
							tokenKey:(NSString*) oauthKey
							tokenSecret:(NSString*) oauthSecret
							urlScheme:(NSString*) urlScheme
{
	MSOffsiteContext *context = [[[MSOffsiteContext alloc] init] autorelease];
	context.consumerKey = consumerKey;
	context.consumerSecret = consumerSecret;
	context.oauthKey = oauthKey;
	context.oauthSecret = oauthSecret;
	context.urlScheme = urlScheme;
	
	if(context.oauthKey == nil)
	{
		NSString *accessTokenExists = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessTokenKey"];
		NSString *requestTokenExists =  [[NSUserDefaults standardUserDefaults] objectForKey:@"requestTokenKey"];
		if(accessTokenExists)
		{
			NSString *accessTokenKey =  [[NSUserDefaults standardUserDefaults] objectForKey:@"accessTokenKey"];
			NSString *accessTokenSecret =  [[NSUserDefaults standardUserDefaults] objectForKey:@"accessTokenSecret"];
			context.accessToken = [[OAToken tokenWithKey:accessTokenKey secret:accessTokenSecret] retain]; 
			context.oauthKey = accessTokenKey;
			context.oauthSecret = accessTokenSecret;
		}
		else if(requestTokenExists)
		{
			NSString *requestTokenKey =  [[NSUserDefaults standardUserDefaults] objectForKey:@"requestTokenKey"];
			NSString *requestTokenSecret =  [[NSUserDefaults standardUserDefaults] objectForKey:@"requestTokenSecret"];
			context.requestToken = [OAToken tokenWithKey:requestTokenKey secret:requestTokenSecret]; 
			context.oauthKey = requestTokenKey;
			context.oauthSecret = requestTokenSecret;
		}
	}
	else {
		context.accessToken = [[OAToken tokenWithKey:[oauthKey copy] secret: [oauthSecret copy]] retain]; 
		
	}

	return context;
}

-(id) init
{
	if (self = [super init])
	{
		request= nil;
		consumer = nil;
	}
	
	return self;
}

- (void) dealloc{
	[consumer release];
	[request release];
	[super dealloc];
}

-(void) getRequestToken
{
	if (consumer)
	{
		[consumer release];
		consumer = nil;
	}
	if (request)
	{
		[request release];
		request = nil;
	}

	consumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret];
	NSURL *url = [NSURL URLWithString:@"http://api.myspace.com/request_token"];
	request = [[OAMutableURLRequest alloc] initWithURL:url
											  consumer:consumer
												 token:nil   // we don't have a Token yet
												 realm:nil];  // our service provider doesn't specify a realm
	
	[request setHTTPMethod:@"GET"];
	OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
	/*
	[fetcher fetchDataWithRequest:request
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(requestTokenTicket:didFinishWithError:)];
	
	 */
	[fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(requestTokenTicket:didFinishWithError:) makeAsync:NO];
}

-(void) getAccessToken
{
	if (consumer)
	{
		[consumer release];
		consumer = nil;
	}
		
	consumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret];
	
	NSURL *url = [NSURL URLWithString:@"http://api.myspace.com/access_token"];
	if(requestToken == nil)
	{
		NSString *requestTokenKey =  [[NSUserDefaults standardUserDefaults] objectForKey:@"requestTokenKey"];
		NSString *requestTokenSecret =  [[NSUserDefaults standardUserDefaults] objectForKey:@"requestTokenSecret"];
		requestToken = [OAToken tokenWithKey:requestTokenKey secret:requestTokenSecret]; 
	}
		
	if(requestToken)
	{
		if (request)
		{
			[request release];
			request = nil;
		}
		request = [[OAMutableURLRequest alloc] initWithURL:url
													   consumer:consumer
														  token:requestToken   // we don't have a Token yet
														  realm:nil];  // our service provider doesn't specify a realm
		[request setHTTPMethod:@"GET"];
		
		OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
		/*
		[fetcher fetchDataWithRequest:request
							 delegate:self
					didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
					  didFailSelector:@selector(accessTokenTicket:didFinishWithError:)];
		
		 */
		[fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
					  didFailSelector:@selector(accessTokenTicket:didFinishWithError:) makeAsync:NO];
		
	}
}

-(void) logOut
{
	[accessToken release];
	accessToken = nil;
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessTokenKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessTokenSecret"];
	[[NSUserDefaults standardUserDefaults] synchronize];

}

- (BOOL) isLoggedIn
{
	if(self.accessToken)
	{
		NSLog(@"Access.Token.Key: %@", accessToken.key);
		NSLog(@"Access.Token.Secret: %@", accessToken.secret);
		return true;
	}
	NSString *accessTokenExists = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessTokenKey"];
	if(accessTokenExists)
	{
		NSString *accessTokenKey =  [[NSUserDefaults standardUserDefaults] objectForKey:@"accessTokenKey"];
		NSString *accessTokenSecret =  [[NSUserDefaults standardUserDefaults] objectForKey:@"accessTokenSecret"];
		NSLog(@"Access.Token.Key: %@", accessTokenKey);
		NSLog(@"Access.Token.Secret: %@", accessTokenSecret);
		self.accessToken = [OAToken tokenWithKey:accessTokenKey secret:accessTokenSecret] ; 
		return true;
	}
	return false;
}

- (void) makeRequest:(NSURL*)url method:(NSString*)method body:(NSString*) body delegate:(id<OAResponseDelegate>)delegate
{

	NSData *bodyData = nil;
	NSString *contentType = nil;
	if(body)
	{
		bodyData = [body dataUsingEncoding:NSASCIIStringEncoding];
		contentType = @"application/x-www-form-urlencoded";
	} 
	[self makeRequest:url method:method body:bodyData contentType:contentType delegate:delegate];
			
}

- (void) makeRequest:(NSURL*)url method:(NSString*)method body:(NSData*) body 
		 contentType:(NSString*) contentType delegate: (id<OAResponseDelegate>)delegate
{
	if(accessToken)
	{
		if (consumer)
		{
		    [consumer release];
			consumer = nil;
		}
		if (request)
		{
		    [request release];
			request = nil;
		}
		consumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret] ;
		request = [[OAMutableURLRequest alloc] initWithURL:url
												  consumer:consumer
													 token:accessToken   
													 realm:nil] ;// our service provider doesn't specify a realm
		
		[request setHTTPMethod:method];
		if(body)
		{
			[request setHTTPBody:body];
			if(contentType)
				[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
			else {
				[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			}
			
		} 
		OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
		BOOL makeAsync = NO;
		if(MSDelegate)
			makeAsync = YES;
		[fetcher fetchDataWithRequest:request delegate:delegate didFinishSelector:@selector(apiTicket:didFinishWithData:)
					  didFailSelector:@selector(apiTicket:didFinishWithError:) makeAsync:makeAsync];
		
	}
}


//Private

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	//NSLog([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	if (ticket.succeeded) {
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		
		[[NSUserDefaults standardUserDefaults] setObject:[requestToken key]  forKey:@"requestTokenKey"];
		[[NSUserDefaults standardUserDefaults] setObject:[requestToken secret] forKey:@"requestTokenSecret"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		NSString *callBackUrl = [NSString stringWithFormat: @"%@://oauthcallback", self.urlScheme];
		NSString *url = [NSString stringWithFormat:@"http://api.myspace.com/authorize?oauth_token=%@&oauth_callback=%@"
						 , [requestToken.key encodedURLString], [callBackUrl encodedURLString]] ;
		NSURL *authUrl = [NSURL URLWithString: url];
		[[UIApplication sharedApplication] openURL:authUrl];
		[responseBody release];
	}
}

-(void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithError:(NSError *)error{
	
	NSLog(@"Error occurred with RequestToken call.");
	
}


- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	//NSLog([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	if (ticket.succeeded) {
		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[[NSUserDefaults standardUserDefaults] setObject:[accessToken key] forKey:@"accessTokenKey"];
		[[NSUserDefaults standardUserDefaults] setObject:[accessToken secret] forKey:@"accessTokenSecret"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"requestTokenKey"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"requestTokenSecret"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[responseBody release];
	}
}

-(void) accessTokenTicket:(OAServiceTicket *)ticket didFinishWithError:(NSError *) error {
	
	NSLog(@"access token had an error");
}


@end
