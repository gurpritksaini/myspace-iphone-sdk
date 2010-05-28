//
//  UnitTestController.m
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import "UnitTestController.h"
#import "UnitTestTableViewCell.h"
#import "MSSecurityContext.h"
#import "MSOffsiteContext.h"
#import "MSOnsiteContext.h"
#import "MSRoaApi.h"
#import "MSRestV1.h"
#import "MSOpenSearchApi.h"
#import "SBJSON.h"
#import "MSApi.h"
#import "MSConstants.h"

@implementation UnitTestController
@synthesize table;
@synthesize buttonStart;
@synthesize frameworks;
@synthesize keys;
@synthesize unitTestProgress;
@synthesize albumId;
@synthesize	 photoId;
@synthesize personId;
@synthesize appId;
@synthesize groupId;
@synthesize meSelector;


- (void)viewDidLoad {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"unitTests"
													 ofType:@"plist"];
	NSDictionary *dict = [[NSDictionary alloc]
						  initWithContentsOfFile:path];
	self.frameworks = dict;
	[dict release];
	NSArray *array = [[frameworks allKeys] sortedArrayUsingSelector:
					  @selector(compare:)];
	self.keys = array;
	NSMutableDictionary *unitTestsProgress = [NSMutableDictionary new];
	for(id key in self.frameworks)
	{
		NSArray *unitTests = [frameworks objectForKey:key];
		NSUInteger i, count = [unitTests count];
		for (i = 0; i < count; i++) {
			NSString *unitTestName = [NSString stringWithFormat:@"%@_%@", key,  [unitTests objectAtIndex:i]];
			NSMutableDictionary *unitTestProgressDict = [NSMutableDictionary dictionaryWithObjects:
												  [NSArray arrayWithObjects: @"false", @"",nil]
																			 forKeys:[NSArray arrayWithObjects: @"active", @"results", nil]];
			[unitTestsProgress setObject:unitTestProgressDict forKey:unitTestName];
		}
	}
	self.unitTestProgress = unitTestsProgress;
	[unitTestsProgress release];
}

#pragma mark --Unit Test Helper Methods--

////**********************************************************************
////  PLEASE UPDATE VALUES IN THIS METHOD BEFORE RUNNING YOUR UNIT TESTS
////**********************************************************************
- (MSSecurityContext*) setupContext{
	BOOL myAppIsOffsite = YES; 

	NSString *consumer_key = @"";
	NSString *consumer_secret = @"";
	
	NSString *access_token_key = @"";
	NSString *access_token_secret = @"";
	
	NSString *person_id = @"";
	NSString *application_id = @"";
	
	if (myAppIsOffsite) {
		
		MSOffsiteContext *context = [MSOffsiteContext contextWithConsumerKey:consumer_key 
														  consumerSecret:consumer_secret tokenKey:access_token_key tokenSecret:access_token_secret] ;
		[context setUrlScheme:@"myspaceid"];//CONSIDER USING A UNIQUE UrlScheme
		
		self.personId = person_id;
		self.appId = application_id;
		self.meSelector = MS_SELECTOR_ME;
		return context;
	}
	else {
		MSOnsiteContext *context = [MSOnsiteContext contextWithConsumerKey:access_token_key  
														consumerSecret:access_token_secret] ;
		[context setUrlScheme:@"myspaceid"];//CONSIDER USING A UNIQUE UrlScheme
		
		self.personId = person_id;
		self.appId = application_id;
		//Onsite applications can not use @ME selectors unless accompanied with a xoauth_requestor_id string paramater.
		//To do this, just add an xoauth_requestor_id parameter into the queryParams dictionary object of whatever request you are making.
		self.meSelector = person_id; 
		return context;
	}
}

- (void) fireUnitTest:(NSString*)unitTestName{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ];
	NSDictionary *progress = [unitTestProgress objectForKey:unitTestName];
	
	SEL unitTestFunctionSelector = NSSelectorFromString(unitTestName);
	NSMethodSignature * sig = nil;
	sig = [[self class] instanceMethodSignatureForSelector:unitTestFunctionSelector];
	NSInvocation * myInvocation = nil;
	myInvocation = [NSInvocation invocationWithMethodSignature:sig];
	[myInvocation setTarget:self];
	[myInvocation setSelector:unitTestFunctionSelector];
	BOOL result = false;	
	[myInvocation retainArguments];	
	[myInvocation invoke];
	[myInvocation getReturnValue:&result];
	
	[progress setValue:@"false" forKey:@"active"];
	if(result){
		[progress setValue:@"Pass" forKey:@"results"];
	}
	else {
		[progress setValue:@"Fail" forKey:@"results"];
	}
	[self performSelectorOnMainThread:@selector(reloadTheTable) withObject:nil waitUntilDone:NO];

	[pool release];
}

- (void) reloadTheTable{
	
	[table reloadData];
	
	
}

- (void) runUnitTest:(NSString*)unitTestName{
	
	NSDictionary *progress = [unitTestProgress objectForKey:unitTestName];
	[progress setValue:@"true" forKey:@"active"];
	
	[self reloadTheTable];
	[NSThread detachNewThreadSelector: @selector(fireUnitTest:) toTarget:self withObject:unitTestName];
	[self reloadTheTable];
}


- (void) runUnitTests{
for(id key in self.frameworks)
		{
			NSArray *unitTests = [frameworks objectForKey:key];
			NSUInteger i, count = [unitTests count];
			for (i = 0; i < count; i++) {
				NSString *unitTestName = [NSString stringWithFormat:@"%@_%@", key,  [unitTests objectAtIndex:i]];
				NSLog(@"Running UnitTest for %@", unitTestName);
				[self runUnitTest:unitTestName];
			}
		}
}

- (IBAction) butonClick : (id) sender{
	[self runUnitTests];
}

#pragma mark --OpenSocial 0.9 Tests--
- (BOOL) OpenSocial09_getPerson{
	
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getPerson");
		NSString *dataString = [roaApi getPerson:self.meSelector queryParameters:nil ];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getPerson: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getPerson Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getFriends{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getFriends");
		NSString *dataString = [roaApi getFriends:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getFriends: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getFriends Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	}

- (BOOL) OpenSocial09_getPersonWithKeys{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getPersonWithKeys");
		NSMutableArray *keysArray = [NSMutableArray new] ;
		[keysArray addObject:@"age"];
		[keysArray addObject:@"birthday"];
		[keysArray addObject:@"books"];
		NSMutableDictionary *params = [roaApi makeQueryDictionary:keysArray count:nil filterBy:nil filterOp:nil filterValue:nil format:nil statusId:nil postedDate:nil
													   startIndex:nil updatedSince:nil];
		[keysArray release];
		NSString *dataString =  [roaApi getPerson:self.meSelector queryParameters:params];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getPersonWithKeys: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getPersonWithKeys Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) OpenSocial09_getOnlineFriends{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getOnlineFriends");
		NSMutableDictionary *params = [roaApi makeQueryDictionary:nil count:nil filterBy:@"networkpresence"  
														 filterOp:@"equals" filterValue:@"online" format:@"xml" statusId:nil postedDate:nil
													   startIndex:nil updatedSince:nil];
		NSString *dataString = [roaApi getFriends:self.meSelector queryParameters:params];	
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getOnlineFriends: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getOnlineFriends Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) OpenSocial09_getAlbums{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getAlbums");
		NSString *dataString = [roaApi getAlbums:personId queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		SBJSON *json = [[SBJSON alloc] init];
		id jsonObj = [json objectWithString: dataString];
		NSArray *entries = [jsonObj objectForKey:@"entry"];
		NSAssert([entries count] > 0, @"Not enough Albums to run unit test");
		NSDictionary *firstAlbum = [entries objectAtIndex:0];
		self.albumId = [[firstAlbum objectForKey:@"album"] objectForKey:@"id"];
		[json release];
		NSLog(@"HTTP Output for OpenSocial09_getAlbums: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getAlbums Exception: %@", [e reason]);
		testResult = false;
	}
	@finally {
		return testResult;
	}
}
- (BOOL) OpenSocial09_updateAlbum{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_updateAlbum");
		if(self.albumId == nil)
			[self OpenSocial09_getAlbums];
		NSAssert((self.albumId !=nil), @"No AlbumId available to run test");
		NSString *dataString = [roaApi updateAlbum:self.meSelector albumId:self.albumId caption:@"testing" location:nil queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_updateAlbum: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getAlbums Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getMediaItems{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getMediaItems");
		if(self.albumId == nil)
			[self OpenSocial09_getAlbums];
		NSAssert((self.albumId !=nil), @"No AlbumId available to run test");
		NSString *dataString = [roaApi getMediaItems:self.meSelector albumId:self.albumId queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		SBJSON *json = [[SBJSON alloc] init];
		id jsonObj = [json objectWithString: dataString];
		NSArray *entries = [jsonObj objectForKey:@"entry"];
		NSAssert([entries count] > 0, @"Not enough Albums to run unit test");
		NSDictionary *firstMediaItem = [entries objectAtIndex:0];
		self.photoId = [[firstMediaItem objectForKey:@"mediaItem"] objectForKey:@"id"];
		[json release];
		NSLog(@"HTTP Output for OpenSocial09_getMediaItems: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getMediaItems Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getMediaItem{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getMediaItem");
		if(self.photoId == nil)
			[self OpenSocial09_getMediaItems];
		NSAssert((self.photoId !=nil), @"No PhotoId available to run test");
		NSString *dataString = [roaApi getMediaItem:personId albumId:self.albumId
										mediaItemId:self.photoId queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		
		NSLog(@"HTTP Output for OpenSocial09_getMediaItem: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getMediaItem Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) OpenSocial09_addPhoto{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_addPhoto");
		if(self.albumId == nil)
			[self OpenSocial09_getAlbums];
		NSAssert((self.albumId !=nil), @"No AlbumId available to run test");
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *imagePath = [bundle pathForResource:@"snowleopard" ofType:@"jpeg"];
		NSURL *photoURL = [NSURL fileURLWithPath:imagePath];
		NSData *photoData = [NSData dataWithContentsOfURL:photoURL];
		NSString *dataString =[roaApi addPhoto:self.meSelector albumId:albumId caption:@"cool new pic"
									 photoData:photoData imageType:nil queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_addPhoto: %@", dataString);
		
		testResult = ([roaApi responseStatusCode] == 201 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_addPhoto Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) OpenSocial09_getSupportedVideoCategories{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getSupportedVideoCategories");
		NSString *dataString =  [roaApi getSupportedVideoCategories:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getSupportedVideoCategories: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getSupportedVideoCategories Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}


- (BOOL) OpenSocial09_getVideos{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getVideos");
		NSString *dataString =  [roaApi getMediaItems:personId albumId:MS_SELECTOR_VIDEOS queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getVideos: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getVideos Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) OpenSocial09_addVideo{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_addVideo");
		if(self.albumId == nil)
			[self OpenSocial09_getAlbums];
		NSAssert((self.albumId !=nil), @"No AlbumId available to run test");
		//get a video category
		NSString *dataString = [roaApi getSupportedVideoCategories:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		SBJSON *json = [SBJSON new];
		id jsonObj = [json objectWithString:dataString];
		NSAssert(([jsonObj count] >0), @"Json Array expected values to run test");
		NSAssert(([[jsonObj objectAtIndex:0] objectForKey:@"id"] !=nil),@"Supported Video Category Id was not found. Test cannot continue.");
		NSString *categoryId = [[jsonObj objectAtIndex:0] objectForKey:@"id"];
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *moviePath = [bundle pathForResource:@"Movie" ofType:@"m4v"];
		NSAssert((moviePath !=nil && moviePath != @""), @"Movie.m4v was not found. Test cannot continue.");
		NSURL *videoURL = [NSURL fileURLWithPath:moviePath];
		NSData *webData = [NSData dataWithContentsOfURL:videoURL];
		NSArray *tags = [NSArray arrayWithObject:@"mobile-upload"];
		dataString =[roaApi addVideo:self.meSelector albumId:albumId caption:@"my cool vid" 
						   videoData:webData videoType:@"video/quicktime" description:@"here is a great video" 
								tags:tags msCategories:categoryId language:nil queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		[json release];
		NSLog(@"HTTP Output for OpenSocial09_addVideo: %@", dataString);
		
		testResult = ([roaApi responseStatusCode] == 201 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_addVideo Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) OpenSocial09_updateMediaItem{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_updateMediaItem");
		if(self.photoId == nil)
			[self OpenSocial09_getMediaItems];
		NSAssert((self.photoId !=nil), @"No PhotoId available to run test");
		NSString *dataString = [roaApi updateMediaItem:personId 
											   albumId:self.albumId mediaItemId:self.photoId 
												 title:@"testTitle" queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_updateMediaItem: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_updateMediaItem Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) OpenSocial09_getMediaItemComments{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getMediaItemComments");
		if(self.photoId == nil)
			[self OpenSocial09_getMediaItems];
		NSAssert((self.photoId !=nil), @"No PhotoId available to run test");
		NSString *dataString = [roaApi getMediaItemComments:self.personId 
													albumId:self.albumId mediaItemId:self.photoId queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getMediaItemComments: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getMediaItemComments Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getActivities{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getActivities");
		NSString *dataString = [roaApi getActivities:self.meSelector appId:nil queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getActivities: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getActivities Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}
- (BOOL) OpenSocial09_createActivity{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_createActivity");
		NSDictionary *contentDict = [NSDictionary	dictionaryWithObjects:[NSArray arrayWithObjects:@"content", @"testContent", nil] 
																forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]];
		NSArray *msParameters = [NSArray arrayWithObject:contentDict];
		NSString *dataString = [roaApi createActivity:@"template1" title:@"testTitle" body:@"testBody"
								   templateParameters:msParameters activityId:nil queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_createActivity: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 201 && dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_createActivity Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}
- (BOOL) OpenSocial09_getFriendActivities{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getFriendActivities");
		NSMutableArray *keysArray = [NSMutableArray new];
		[keysArray addObject:@"@all"];
		NSMutableDictionary *params = [roaApi makeQueryDictionary:keysArray count:nil filterBy:nil filterOp:nil filterValue:nil format:nil statusId:nil postedDate:nil
													   startIndex:nil updatedSince:nil];
		NSAssert((params !=nil), @"Params object needed to create request.");
		[keysArray release];
		NSString *dataString =[roaApi getFriendActivities:self.meSelector appId:nil queryParameters:params];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getFriendActivities: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getFriendActivities Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getAppActivities{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getAppActivities");
		NSString *dataString = [roaApi	 getFriendActivities:self.meSelector appId:MS_SELECTOR_APP queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getAppActivities: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getAppActivities Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_addAppData{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_addAppData");
		NSArray *fieldKeys = [NSArray arrayWithObject:@"test"];
		NSArray *fieldValues = [NSArray arrayWithObject:@"testValue"];
		NSString *dataString = [roaApi addAppData:self.meSelector userId:personId
										 selector:MS_SELECTOR_SELF appId:self.appId keys:fieldKeys values:fieldValues queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_addAppData: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_addAppData Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getAppDataWithKeys{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getAppDataWithKeys");
		NSArray *fieldKeys = [NSArray arrayWithObject:@"test"];
		NSMutableDictionary *params = [roaApi makeQueryDictionary:fieldKeys count:nil filterBy:nil filterOp:nil filterValue:nil format:nil statusId:nil postedDate:nil
													   startIndex:nil updatedSince:nil];
		
		NSString *dataString = [roaApi getAppData:self.meSelector selector:MS_SELECTOR_SELF appId:self.appId 
								  queryParameters:params];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getAppDataWithKeys: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getAppDataWithKeys Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_deleteAppData{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_deleteAppData");
		NSArray *fieldKeys = [NSArray arrayWithObject:@"test"];
		NSString *dataString = [roaApi deleteAppData:self.meSelector selector:MS_SELECTOR_SELF 
											   appId:self.appId keys:fieldKeys queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_deleteAppData: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_deleteAppData Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getGroups{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getGroups");
		NSString *dataString = [roaApi getGroups:personId queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		
		SBJSON	*json = [SBJSON new];
		id jsonObj = [json objectWithString:dataString];
		NSAssert(([jsonObj objectForKey:@"entry"] !=nil), @"'entry' property was not found in Json response. Required to run test.");
		NSArray *entry = [jsonObj objectForKey:@"entry"];
		if([entry count] >0)
		{
			NSDictionary *firstGroup = [entry objectAtIndex:0];
			self.groupId = [[firstGroup objectForKey:@"group"] objectForKey:@"id"];
		}
		[json release];
		
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getGroups: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getGroups Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) OpenSocial09_getGroup{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getGroup");
		if(self.groupId == nil)
			[self OpenSocial09_getGroups];
		NSAssert((self.groupId !=nil), @"No groupId found for this user. Required for this test.");
		NSString *dataString = [roaApi getGroup:personId groupId:self.groupId queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getGroup: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getGroup Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) OpenSocial09_getSupportedMoods{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getSupportedMoods");
		NSString *dataString = [roaApi	getSupportedMoods:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getSupportedMoods: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getSupportedMoods Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getMoodStatus{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getMoodStatus");
		NSString *dataString = [roaApi	getPersonMoodStatus:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getMoodStatus: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getMoodStatus Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getTopFriendsMoodStatus{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getTopFriendsMoodStatus");
		NSMutableDictionary *params = [roaApi makeQueryDictionary:nil count:nil filterBy:@"@topfriends" filterOp:nil filterValue:nil format:nil statusId:nil postedDate:nil
													   startIndex:nil updatedSince:nil];
		NSString *dataString = [roaApi	getFriendsMoodStatus:self.meSelector includeHistory:TRUE queryParameters:params];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getTopFriendsMoodStatus: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getTopFriendsMoodStatus Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_updateMoodStatus{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_updateMoodStatus");
		NSString *dataString = [roaApi updatePersonMoodStatus:self.meSelector moodName:@"Excited" 
													   status:@"Just updated my status using the iPhone SDK!"
													 latitude:nil longitude:nil queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_updateMoodStatus: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_updateMoodStatus Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getMoodStatusComments{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSString *dataString = [roaApi	getPersonMoodStatus:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		SBJSON *json = [[SBJSON alloc] init];
		id jsonObj = [json objectWithString: dataString];
		NSAssert(([jsonObj objectForKey:@"statusId"] !=nil), @"'statusId' was expected in the Json object. Test cannot continue.");
		NSString *moodStatusId = [jsonObj objectForKey:@"statusId"];
		NSLog(@"Testing OpenSocial09_getMoodStatusComments");
		dataString = [roaApi getStatusMoodComments:self.meSelector statusId:moodStatusId queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		[json release];
		NSLog(@"HTTP Output for OpenSocial09_getMoodStatusComments: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getMoodStatusComments Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_updateMoodStatusComments{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSString *dataString = [roaApi	getPersonMoodStatus:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		SBJSON *json = [[SBJSON alloc] init];
		id jsonObj = [json objectWithString: dataString];
		NSAssert(([jsonObj objectForKey:@"statusId"] !=nil), @"'statusId' was expected in the Json object. Test cannot continue.");
		NSString *moodStatusId = [jsonObj objectForKey:@"statusId"];
		NSLog(@"Testing OpenSocial09_updateMoodStatusComments");
		dataString = [roaApi addStatusMoodComment:personId 
										 statusId:moodStatusId body:@"the status comment" queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_updateMoodStatusComments: %@", dataString);
		[json release];
		testResult = ([roaApi responseStatusCode] == 201 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_updateMoodStatusComments Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_sendNotification{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_sendNotification");
		NSArray *recipients = [NSArray arrayWithObject:personId];
		NSString *dataString = [roaApi sendNotification:self.meSelector recipientIds:recipients mediaItems:nil 
									 templateParameters:nil queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_sendNotification: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 201 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_sendNotification Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSocial09_getProfileComments{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRoaApi *roaApi = [MSRoaApi apiWithContext:context];		
		NSLog(@"Testing OpenSocial09_getProfileComments");
		NSString *dataString = [roaApi getProfileComments:self.meSelector queryParameters:nil];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([roaApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[roaApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[roaApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSocial09_getProfileComments: %@", dataString);
		testResult = ([roaApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getProfileComments Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

#pragma mark --OpenSearch Tests--
- (BOOL) OpenSearch_searchPeople{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSOpenSearchApi *searchApi = [MSOpenSearchApi apiWithContext:context];	
		NSLog(@"Testing OpenSearch_searchPeople");
		NSString *dataString = [searchApi searchPeople:@"donny mack"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([searchApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[searchApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[searchApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSearch_searchPeople: %@", dataString);
		testResult = ([searchApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSearch_searchPeople Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) OpenSearch_searchImages{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSOpenSearchApi *searchApi = [MSOpenSearchApi apiWithContext:context];		
		NSLog(@"Testing OpenSearch_searchImages");
		NSString *dataString = [searchApi searchImages:@"baseball"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([searchApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[searchApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[searchApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSearch_searchImages: %@", dataString);
		testResult = ([searchApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSearch_searchImages Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) OpenSearch_searchVideos{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSOpenSearchApi *searchApi = [MSOpenSearchApi apiWithContext:context];		
		NSLog(@"Testing OpenSearch_searchVideos");
		NSString *dataString = [searchApi searchVideos:@"football"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([searchApi responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[searchApi httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[searchApi httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for OpenSearch_searchVideos: %@", dataString);
		testResult = ([searchApi responseStatusCode] == 200 && dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSearch_searchVideos Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}


#pragma mark --V1 Tests--

- (BOOL) V1_getCurrentUser{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getCurrentUser");
		NSString *dataString = [v1Api getCurrentUser];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getCurrentUser: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"V1_getCurrentUser Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}
- (BOOL) V1_getFriendship{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getFriendship");
		NSString *dataString = [v1Api getFriendship:[personId intValue] friendIds:[NSArray arrayWithObject:@"6221"]];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getFriendship: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"V1_getFriendship Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) V1_getActivitiesApplicationInstalls{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesApplications");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_APPLICATION_INSTALLS extensions:@"subject" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesApplications: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesApplicationInstalls Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) V1_getActivitiesApplicationUse{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesApplications");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_APPLICATION_USE extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		
		NSLog(@"HTTP Output for V1_getActivitiesApplications: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesApplicationUse Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesEventHosting{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesEventHosting");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_EVENT_POST extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesEventHosting: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesEventHosting Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) V1_getActivitiesEventAttending{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesEventAttending");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_EVENT_ATTENDING extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesEventAttending: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesEventAttending Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesEventBandShow{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesEventBandShow");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_EVENT_BANDSHOWS extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesEventBandShow: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesEventBandShow Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesMusicSongPost{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesMusicSongPost");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_MUSIC_SONGPOST extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		NSLog(@"HTTP Output for V1_getActivitiesMusicSongPost: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
		
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesMusicSongPost Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	}
- (BOOL) V1_getActivitiesMusicProfileSongAdd{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesMusicProfileSongAdd");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_MUSIC_PROFILE_SONG_ADD extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesMusicProfileSongAdd: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesMusicProfileSongAdd Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesMusicPlaylistEdit{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesMusicPlaylistEdit");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_MUSIC_PLAYLIST_EDIT extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesMusicPlaylistEdit: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesMusicPlaylistEdit Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesNotesStatusUpdates{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesNotesStatusUpdates");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_NOTES_STATUS_UPDATES extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesNotesStatusUpdates: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesNotesStatusUpdates Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesNotesBlogPost{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesNotesBlogPost");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_NOTES_BLOG_POST extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesNotesBlogPost: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesNotesBlogPost Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesNotesForumPost{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesNotesForumPost");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_NOTES_FORUM_POST extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesNotesForumPost: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesNotesForumPost Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) V1_getActivitiesPersonFriendAdd{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesPersonFriendAdd");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_PEOPLE_FRIEND_ADD extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesPersonFriendAdd: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesPersonFriendAdd Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesPersonGroupJoin{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesPersonGroupJoin");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_PEOPLE_GROUP_JOIN extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesPersonGroupJoin: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesPersonGroupJoin Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}	
}
- (BOOL) V1_getActivitiesPersonFriendCategoryAdd{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesPersonFriendCategoryAdd");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_PEOPLE_FRIEND_CATEGORY_ADD extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesPersonFriendCategoryAdd: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"OpenSocial09_getAlbums Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
}

- (BOOL) V1_getActivitiesPhotoAdd{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesPhotoAdd");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_PHOTO_ADD extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesPhotoAdd: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesPhotoAdd Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) V1_getActivitiesPhotoTagged{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesPhotoTagged");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_PHOTO_TAGGED extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		
		NSLog(@"HTTP Output for V1_getActivitiesPhotoTagged: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesPhotoTagged Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) V1_getActivitiesVideoShared{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesVideoShared");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_VIDEO_SHARED extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesVideoShared: %@", dataString);
		
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesVideoShared Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}
- (BOOL) V1_getActivitiesVideoAdd{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesVideoAdd");
		NSString *dataString = [v1Api getActivities:personId activityTypes: MS_ACTIVITY_TYPE_VIDEO_ADD extensions:@"All" 
										  composite:nil culture:nil datetime:nil pageSize:@"1"];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesVideoAdd: %@", dataString);
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getActivitiesVideoAdd Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}

- (BOOL) V1_getIndicators{
	BOOL testResult = false;
	@try {
		MSSecurityContext *context = [self setupContext];
		MSRestV1 *v1Api = [MSRestV1 apiWithContext: context] ;
		NSLog(@"Testing V1_getActivitiesVideoAdd");
		NSAssert((self.personId != nil), @"personId is required for this Unit Test.");
		NSString *dataString  =[v1Api getIndicators:[personId intValue]];
		NSAssert((dataString !=nil), @"No data returned in request.");
		if([v1Api responseStatusCode] > 201) //Output Response headers if there was an error
		{
			NSLog(@"HTTP Response Headers");
			for (id key in [[v1Api httpResponse] allHeaderFields]) {
				
				NSLog(@"Header: %@, Value: %@", key, [[[v1Api httpResponse] allHeaderFields] objectForKey:key]);
			}
		}
		NSLog(@"HTTP Output for V1_getActivitiesVideoAdd: %@", dataString);
		
		testResult = ([v1Api responseStatusCode] == 200 || dataString);
	}
	@catch (NSException * e) {
		NSLog(@"V1_getIndicators Exception: %@", [e reason]);
		testResult = false;
		
	}
	@finally {
		return testResult;
	}
	
}


#pragma mark --UITable Methods--

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	NSString *key = [keys objectAtIndex:section];
	NSArray *nameSection = [frameworks objectForKey:key];
	return [nameSection count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [keys count];
}
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	NSString *key = [keys objectAtIndex:section];
	NSArray *nameSection = [frameworks objectForKey:key];
	NSString *unitTestName = [NSString stringWithFormat:@"%@_%@", key, [nameSection objectAtIndex:row]];

	static NSString *CellIdentifier = @"UnitTestTableViewCellIdentifier";
		
	UnitTestTableViewCell *cell = (UnitTestTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"UnitTestTableViewCell"
													 owner:self options:nil];
		cell = [nib objectAtIndex:0];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} 
	[cell.labelTestDescription setText:[nameSection objectAtIndex:row]];
	NSDictionary *progress = [unitTestProgress objectForKey:unitTestName];
	
	if ([progress valueForKey:@"active"] == @"true") {
		[cell.testActivity startAnimating];
	}
	else {
		if([cell.testActivity isAnimating])
			[cell.testActivity stopAnimating];
	}
	NSString *results = [progress valueForKey:@"results"];
	if ([results isEqualToString:@"Pass"])
		[cell.labelTestResults setTextColor:[UIColor greenColor]];
	else
		 [cell.labelTestResults setTextColor:[UIColor redColor]];
		 
	[cell.labelTestResults setText:results];

	
	return cell;
}

- (NSString *)tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
	NSString *key = [keys objectAtIndex:section];
	return key;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index{
	
	NSUInteger section = [index section];
	NSUInteger row = [index row];
	NSString *key = [keys objectAtIndex:section];
	NSArray *nameSection = [frameworks objectForKey:key];
	NSString *unitTestName = [NSString stringWithFormat:@"%@_%@", key, [nameSection objectAtIndex:row]];
	[self runUnitTest:unitTestName];
	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[table release];
	[buttonStart release];
	[frameworks release];
	[keys release];
	[unitTestProgress release];
	[albumId release];
	[photoId release];
	[personId release];
	[appId release];
	[groupId release];
	[meSelector release];
    [super dealloc];
}


@end
