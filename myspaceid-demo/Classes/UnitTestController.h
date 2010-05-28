//
//  UnitTestController.h
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSSecurityContext.h"



@interface UnitTestController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
	IBOutlet UITableView *table;
	IBOutlet UIButton *buttonStart;
	NSDictionary *frameworks;
	NSArray *keys;
	NSDictionary *unitTestProgress;
	NSString *personId;
	NSString *albumId;
	NSString *photoId;
	NSString *appId;
	NSString *groupId;
	NSString *meSelector;
}

@property(nonatomic, retain) IBOutlet UITableView *table;
@property(nonatomic, retain) IBOutlet UIButton *buttonStart;
@property(nonatomic, retain) NSDictionary *frameworks;
@property(nonatomic, retain) NSArray *keys;
@property(nonatomic, retain) NSDictionary *unitTestProgress;
@property(nonatomic, retain) NSString *personId;
@property(nonatomic, retain) NSString *albumId;
@property(nonatomic, retain) NSString *photoId;
@property(nonatomic, retain) NSString *appId;
@property(nonatomic, retain) NSString *groupId;
@property(nonatomic, retain) NSString *meSelector;
- (IBAction) butonClick : (id) sender;


@end
