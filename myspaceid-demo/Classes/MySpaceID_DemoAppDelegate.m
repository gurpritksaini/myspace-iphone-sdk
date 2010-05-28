//
//  MySpaceID_DemoAppDelegate.m
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import "MySpaceID_DemoAppDelegate.h"

@implementation MySpaceID_DemoAppDelegate

@synthesize window;
@synthesize rootController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
	//UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[DemoViewController alloc] init]];
	[window addSubview:rootController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
	[rootController release];
	[window release];
	[super dealloc];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (!url) {  return NO; }
	
    NSString *URLString = [url absoluteString];
    [[NSUserDefaults standardUserDefaults] setObject:URLString forKey:@"url"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

@end
