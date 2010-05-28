//
//  UnitTestTableViewCell.m
//  MySpaceID.Demo
//
//  Copyright MySpace, Inc. 2010. All rights reserved.
//

#import "UnitTestTableViewCell.h"


@implementation UnitTestTableViewCell
@synthesize labelTestResults;
@synthesize labelTestDescription;
@synthesize testActivity;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {

	[labelTestResults release];
	[labelTestDescription release];
	[testActivity release];
    [super dealloc];
}


@end
