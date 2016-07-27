#import "SEGFirebaseIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>


@implementation SEGFirebaseIntegration

- (id)initWithSettings:(NSDictionary *)settings
{
    if (self = [super init]) {
        [FIRApp configure];
        SEGLog(@"[FIRApp Configure]");
    }
    return self;
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    
}

- (void)track:(SEGTrackPayload *)payload
{
    
}

@end