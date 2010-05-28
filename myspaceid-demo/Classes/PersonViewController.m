//
//  PersonViewController.m
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import "PersonViewController.h"
#import "MSApi.h"
#import "SBJSON.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "MSApi.h"
#import "MSConstants.h"

@implementation PersonViewController
@synthesize personId;
@synthesize profileImageView;
@synthesize statusLabel;
@synthesize statusTextField;
@synthesize loginButton;
@synthesize mySpace;
@synthesize videoURL;
@synthesize albumId;
@synthesize imagePickerController;
@synthesize btnStatus;
@synthesize btnMedia;
@synthesize lblLogin;

- (void) loadStatus{
	
	[mySpace getPersonMoodStatus:personId queryParameters:nil];
		
}

////**********************************************************************
//NEED TO UPDATE THIS METHOD BEFORE RUNNING
////**********************************************************************
- (void)viewDidLoad {
    [super viewDidLoad];
	NSString *consumerKey = @"a94b8e4544394d54bd04c03d0a9c77f6";
	NSString *consumerSecret = @"77b6cac8889c41dd840dd80bb04f1b0e1322cda7927d4b8ab3e24e5138f28586";

	self.mySpace = [MSApi sdkWith:consumerKey consumerSecret:consumerSecret 
						  accessKey:nil accessSecret:nil isOnsite:false urlScheme:@"myspaceid" delegate:self];
	
	NSString *access_token_key = mySpace.accessKey;
	NSString *access_token_secret = mySpace.accessSecret;
	
	NSLog(@"AccessTokenKey %@ AccessTokenSecret %@", access_token_key, access_token_secret);
	
	NSString *returnUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
	
	if(returnUrl)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[mySpace getAccessToken];
	}
	
	if([mySpace isLoggedIn])
	{
		self.loginButton.leftBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithTitle:@"Logout" 
											   style:UIBarButtonItemStylePlain 
											   target:self 
											   action:@selector(logOut)] autorelease];
		
		[mySpace getPerson:MS_SELECTOR_ME queryParameters:nil];

		statusTextField.hidden = false;
		profileImageView.hidden = false;
		statusLabel.hidden = false;
		btnMedia.hidden = false;
		btnStatus.hidden = false;
		lblLogin.hidden = true;
	}
	else
	{
		// Add a left button
		self.loginButton.leftBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithTitle:@"Login" 
											   style:UIBarButtonItemStylePlain 
											   target:self 
											   action:@selector(logIn)] autorelease];
		statusTextField.hidden = true;
		profileImageView.hidden = true;
		statusLabel.hidden = true;
		btnMedia.hidden = true;
		btnStatus.hidden = true;
		lblLogin.hidden = false;
	}
}

- (IBAction) updateAction: (id) sender{
	//update status code here.
	NSString *newStatus = self.statusTextField.text;
	[mySpace updatePersonMoodStatus:self.personId moodName:nil status:newStatus latitude:nil longitude:nil queryParameters:nil];
	
	[statusTextField resignFirstResponder];
	
}

- (IBAction) uploadMedia : (id) sender{
	
	imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.delegate = self;
	imagePickerController.sourceType = 
	UIImagePickerControllerSourceTypePhotoLibrary;
	imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePickerController.sourceType];
	[self presentModalViewController:imagePickerController animated:YES];
}



#pragma mark -
#pragma mark Authentication

-(void) logIn
{
	[mySpace getRequestToken];
	
}

-(void) logOut
{
	[mySpace endSession];
	
	for(UIView *view in self.view.subviews)
	{
		if(![view isKindOfClass:[UINavigationBar class]])
			[view removeFromSuperview];
		
	}
	// Add a left buttonˆ
	self.loginButton.leftBarButtonItem = [[[UIBarButtonItem alloc]
										   initWithTitle:@"Login" 
										   style:UIBarButtonItemStylePlain 
										   target:self 
										   action:@selector(logIn)] autorelease];
}

#pragma mark --
#pragma mark MySpaceDelegate Protocol
- (void)api:(id)sender didFinishMethod:(NSString*) methodName withValue:(NSString*) value  withStatusCode:(NSInteger)statusCode{
	if(statusCode >201) //Error Occurred. Output
	{
		NSLog(@"Method: %@. Value: %@. StatusCode: %d", methodName, value, statusCode);
	}
	if(methodName == @"getPerson")
	{
		SBJSON *json = [[SBJSON alloc] init];
		id jsonObj = [json objectWithString: value];
		NSDictionary *personObj	= [jsonObj objectForKey:@"person"];
		NSString *displayName = [personObj objectForKey:@"displayName"];
		NSString *profileImageUrl = [personObj objectForKey:@"thumbnailUrl"];
		self.personId = [personObj objectForKey:@"id"];
		NSURL *url = [NSURL URLWithString: profileImageUrl];
		UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
		[self.profileImageView setImage:img];
		[profileImageView setUserInteractionEnabled:NO];
		[self.loginButton setTitle: displayName];
		[json release];
		[self loadStatus];
	}
	else if(methodName == @"getPersonMoodStatus"){
		SBJSON *json = [[SBJSON alloc] init];
		id jsonObj = [json objectWithString: value];
		NSString *currentStatus = [jsonObj objectForKey:@"status"];
		self.statusLabel.text = currentStatus;
		
		[json release];
	
	}
	else if(methodName == @"updatePersonMoodStatus"){
	
		[self loadStatus];
	}
	else if(methodName == @"addPhoto"){
		
		NSLog(@"%@", @"Photo Upload complete");
	}
	else if(methodName == @"addVideo"){
		NSLog(@"%@", @"Video Upload complete");
	}
	else if(methodName == @"getSupportedVideoCategories"){
		NSLog(@"%@", @"getSupportedVideoCategories complete");
		SBJSON *json = [SBJSON new];
		id jsonObj = [json objectWithString:value];
		NSString *categoryId = [[jsonObj objectAtIndex:0] objectForKey:@"id"];
		
		NSData *webData = [NSData dataWithContentsOfURL:videoURL];
		NSArray *tags = [NSArray arrayWithObject:@"mobile-upload"];
		[mySpace addVideo:MS_SELECTOR_ME albumId:albumId caption:@"awesome video" videoData:webData 
				videoType:@"video/quicktime" description:@"check out my new video" tags:tags 
			 msCategories:categoryId language:nil queryParameters:nil];
		[json release];
	}
}

- (void)api:(id)sender didFailMethod:(NSString*) methodName withError:(NSError*) error{

	NSLog(@"Method %@ failed. Error: @%", methodName, [error localizedDescription]);
}

#pragma mark --
#pragma mark UIImagePickerController Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSString *data = [mySpace getAlbums:personId queryParameters:nil];
	SBJSON *json = [SBJSON new];
	id jsonObj = [json objectWithString:data];
	
	albumId = [[[[jsonObj objectForKey:@"entry"] objectAtIndex:0] objectForKey:@"album"] objectForKey:@"id"];	
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:@"public.image"]){
		UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
		NSLog(@"found an image");
		NSData *photoData = UIImageJPEGRepresentation(image, 1.0f);		
		[mySpace addPhoto:MS_SELECTOR_ME albumId:albumId caption:@"iPhone Pic" photoData:photoData imageType:@"image/jpg" queryParameters:nil];
	}
	else if ([mediaType isEqualToString:@"public.movie"]){
		
		videoURL = [[info objectForKey:UIImagePickerControllerMediaURL] retain];
		NSLog(@"found a video");
		[mySpace getSupportedVideoCategories:MS_SELECTOR_ME queryParameters:nil];
		
		
	}
	[json release];
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
	[personId release];
	[profileImageView release];
	[statusLabel release];
	[statusTextField release];
	[loginButton	release];
	[albumId release];
	[videoURL	 release];
	[imagePickerController release];
	[mySpace release];
    [super dealloc];
}


@end
