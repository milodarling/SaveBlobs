#import "MDSBListener.h"

@implementation MDSBListener

-(id)init {
    if (self=[super init]) {
        prefs = [[HBPreferences alloc] initWithIdentifier:@"me.milodarling.saveblobs"];
        [[LAActivator sharedInstance] registerListener:self forName:@"me.milodarling.saveblobs"];
        [self loadPrefs];
    }
    return self;
}
//trigger listener
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName 
{
    [event setHandled:YES];

    NSString *device = (__bridge NSString *)MGCopyAnswer(CFSTR("ProductType"));
    NSLog(@"Device: %@", device);
    NSString *ecid = [(__bridge NSNumber *)MGCopyAnswer(CFSTR("UniqueChipID")) stringValue];

	NSURL *firmwaresURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.ineal.me/tss/%@/includebeta", device]];
    NSError *firmwaresError = nil;
    NSData *firmwaresForDevice = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:firmwaresURL] returningResponse:nil error:&firmwaresError];
    if (firmwaresError) {
        NSLog(@"Error :(");
            return;
    }
    NSError *jsonError = nil;
    NSDictionary *firmwaresDict = [NSJSONSerialization JSONObjectWithData:firmwaresForDevice options:0 error:&jsonError];
    if (jsonError) {
        NSLog(@"JSON Error: %@", jsonError);
        return;
    }
    NSDictionary *deviceInfo = firmwaresDict[device];
    NSString *board = deviceInfo[@"board"];
    NSString *model = deviceInfo[@"model"];
    //NSString *cpid = deviceInfo[@"cpid"];
    //NSString *bdid = deviceInfo[@"bdid"];
    NSArray *firmwares = deviceInfo[@"firmwares"];
    [deviceInfo writeToFile:@"/var/mobile/Documents/testblobs.plist" atomically:YES];
    for (NSDictionary *firmware in firmwares) {
        NSString *build = firmware[@"build"];
        NSString *savePath = [saveDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@_%@-%@.shsh", ecid, model, firmware[@"version"], firmware[@"build"]]];
        NSLog(@"saveDir (pref): %@, savePath: %@", saveDir, savePath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
            if (overwrite)
                [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];
            else
                continue;
        }
        NSString *manifestURL = [[@"http://api.ineal.me/tss/manifest/" stringByAppendingPathComponent:board] stringByAppendingPathComponent:build];
        NSError *downloadError = nil;
        NSData *manifestData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:manifestURL]] returningResponse:nil error:&downloadError];
        if (downloadError) {
            NSLog(@"Error :(");
            return;
        }
        NSString *manifest = [[[NSString alloc] initWithData:manifestData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"<string>$ECID$</string>" withString:[NSString stringWithFormat:@"<integer>%@</integer>", ecid]];

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
        } else {
            NSLog(@"Error. Status %@, message: %@", response[@"STATUS"], response[@"MESSAGE"]);
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

-(void)loadPrefs {
    overwrite = [prefs boolForKey:kMDSBOverwriteKey default:NO];
    saveDir = [prefs objectForKey:kMDSBSaveDirectoryKey default:@"/var/mobile/.shsh/"];
}

@end

static void loadPrefs() {
    [myListener loadPrefs];
}

%ctor {
    myListener = [[MDSBListener alloc] init];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("me.milodarling.saveblobs/ReloadPrefs"), NULL, 0);
}