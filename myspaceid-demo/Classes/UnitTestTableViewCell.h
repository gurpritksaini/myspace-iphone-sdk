//
//  UnitTestTableViewCell.h
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UnitTestTableViewCell : UITableViewCell {
	IBOutlet UILabel *labelTestDescription;
	IBOutlet UILabel *labelTestResults;
	IBOutlet UIActivityIndicatorView *testActivity;
}

@property (nonatomic, retain) IBOutlet UILabel *labelTestDescription;
@property (nonatomic, retain) IBOutlet UILabel *labelTestResults;
@property (nonatomic, retain) IBOutlet  UIActivityIndicatorView *testActivity;

@end
