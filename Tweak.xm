#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>

#if __cplusplus
extern "C" {
#endif
    CFPropertyListRef MGCopyAnswer(CFStringRef property);
#if __cplusplus
}
#endif

@interface MDSBListener : NSObject <LAListener> {
    UIImage *dankMeme;
}
@end

MDSBListener *myListener;

@implementation MDSBListener

-(id)init {
    if (self=[super init]) {
    	/*
        listenerCount = 0;
        prefs = [[HBPreferences alloc] initWithIdentifier:bundleIdentifier];
    	[prefs registerDefaults:@{
        	@"listenerCount": @1,
    	}];
    	*/
        [[LAActivator sharedInstance] registerListener:self forName:@"me.milodarling.saveblobs"];
    }
    return self;
}
//trigger listener
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
    [event setHandled:YES];
    NSString *device = @"iPhone6,2";
    NSString *ecid = [(__bridge NSNumber *)MGCopyAnswer(CFSTR("UniqueChipID")) stringValue];
	NSURL *firmwaresURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.ineal.me/tss/%@/includebeta", device]];
    NSError *jsonDataError = nil;
    NSData *jsonData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:firmwaresURL] returningResponse:nil error:&jsonDataError];
    if (jsonDataError) {
        NSLog(@"Error :(");
            return;
    }
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
    NSLog(@"JSON: %@", json);
    if (jsonError) {
        NSLog(@"JSON Error: %@", jsonError);
        return;
    }
    NSDictionary *deviceInfo = json[device];
    NSString *board = deviceInfo[@"board"];
    NSString *model = deviceInfo[@"model"];
    NSString *cpid = deviceInfo[@"cpid"];
    NSString *bdid = deviceInfo[@"bdid"];
    NSArray *firmwares = deviceInfo[@"firmwares"];
    [deviceInfo writeToFile:@"/var/mobile/Documents/testblobs.plist" atomically:YES];
    NSLog(@"firmwares: %@", firmwares);
    for (NSDictionary *firmware in firmwares) {
        NSString *build = firmware[@"build"];
        NSString *savePath = [[NSHomeDirectory() stringByAppendingPathComponent:@".shsh"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@_%@-%@.shsh", ecid, model, firmware[@"version"], firmware[@"build"]]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:savePath])
            continue;
        NSString *manifestURL = [[@"http://api.ineal.me/tss/manifest/" stringByAppendingPathComponent:board] stringByAppendingPathComponent:build];
        NSError *downloadError = nil;
        NSData *manifestData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:manifestURL]] returningResponse:nil error:&jsonDataError];
        if (downloadError) {
            NSLog(@"Error :(");
            return;
        }
        NSString *manifest = [[[NSString alloc] initWithData:manifestData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"<string>$ECID$</string>" withString:[NSString stringWithFormat:@"<integer>%@</integer>", ecid]];
        NSLog(@"Manifest: %@", manifest);

        NSURL *appleURL = [NSURL URLWithString:@"http://gs.apple.com/TSS/controller?action=2"];
        NSData *postData = [manifest dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%ld", (unsigned long)[postData length]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:appleURL];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        NSError *appleError = nil;
        NSData *appleResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&appleError];
        NSString *responseString = [[NSString alloc] initWithData:appleResponse encoding:NSUTF8StringEncoding];

        NSMutableDictionary *response = [NSMutableDictionary new];
        NSArray *responseComponents = [responseString componentsSeparatedByString:@"&"];
        for (NSString *component in responseComponents) {
            NSArray *parts = [component componentsSeparatedByString:@"="];
            NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
            for (int i=1; i<parts.count; i++) {
                [result appendString:parts[i]];
            }
            [response setObject:result forKey:parts[0]];
        }
        if ([response[@"STATUS"] intValue] == 0) {
            [[response[@"REQUEST_STRING"] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] writeToFile:savePath atomically:YES];
        }
    }
}
//group
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"Save Blobs";
}
//title
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    return @"Save Blobs";
}
//description
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    return @"Save those SHSH blobs";
}
//compatibility with modes
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}
//duplicate assignment
- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:nil]; //compatibility
}
//icon
- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
    //icon
    return nil;
}

@end

%ctor {
    myListener = [[MDSBListener alloc] init];
}