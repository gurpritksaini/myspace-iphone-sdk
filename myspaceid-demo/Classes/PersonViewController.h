//
//  PersonViewController.h
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSApi.h"

@interface PersonViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, MSRequest> {

	NSString *personId;
	NSString *albumId;
	NSURL *videoURL;
	MSApi *mySpace;
	IBOutlet UIImageView *profileImageView;
	IBOutlet UITextField *statusTextField;
	IBOutlet UILabel *statusLabel;
	IBOutlet UILabel *lblLogin;
	IBOutlet UINavigationItem *loginButton;
	IBOutlet UIButton *btnStatus;
	IBOutlet UIButton *btnMedia;
	UIImagePickerController *imagePickerController;
}

- (IBAction) updateAction: (id) sender;

@property (nonatomic,retain) NSString *personId;
@property (nonatomic, retain) MSApi *mySpace;
@property (nonatomic, retain) IBOutlet UIImageView *profileImageView;
@property (nonatomic, retain) IBOutlet UITextField *statusTextField;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UINavigationItem *loginButton;
@property (nonatomic, retain) IBOutlet UIButton *btnStatus;
@property (nonatomic, retain) IBOutlet UIButton *btnMedia;
@property (nonatomic, retain)	IBOutlet UILabel *lblLogin;
@property (nonatomic, retain) NSString *albumId;
@property (nonatomic, retain) NSURL *videoURL;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;

- (IBAction) uploadMedia : (id) sender;

#pragma mark --
#pragma mark UIImagePickerController Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

@end
