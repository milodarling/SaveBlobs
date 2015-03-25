#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>

#if __cplusplus
extern "C" {
#endif
    CFPropertyListRef MGCopyAnswer(CFStringRef property);
#if __cplusplus
}
#endif

@interface MDSBListener : NSObject <LAListener> {
	BOOL overwrite;
	NSString *saveDir;
}
-(void)loadPrefs;
@end

MDSBListener *myListener;

NSString *const kMDSBOverwriteKey = @"overwrite";
NSString *const kMDSBSaveDirectoryKey = @"savedir";
HBPreferences *prefs;