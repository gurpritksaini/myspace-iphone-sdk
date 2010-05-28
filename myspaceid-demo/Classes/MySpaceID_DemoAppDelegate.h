//
//  MySpaceID_DemoAppDelegate.h
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MySpaceID_DemoViewController;

@interface MySpaceID_DemoAppDelegate : NSObject <UIApplicationDelegate> {
    IBOutlet UIWindow *window;
	IBOutlet UITabBarController *rootController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *rootController;

@end

