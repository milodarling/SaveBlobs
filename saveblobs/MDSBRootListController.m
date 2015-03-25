#include "MDSBRootListController.h"

@implementation MDSBRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)viewDidLoad {
	[super viewDidLoad];
	UIImage *steven = [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:grategod options:0]];
	UIImageView *iHateSnow = [[UIImageView alloc] initWithImage:steven];
	iHateSnow.center = CGPointMake([self rootController].view.frame.size.width/2, -150);
	[self.table addSubview:iHateSnow];
}

@end
