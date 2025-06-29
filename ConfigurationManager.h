#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NetworkPolicy) {
    NetworkPolicyAggressive = 0,  // Retry frequently, short timeouts
    NetworkPolicyBalanced = 1,    // Default behavior
    NetworkPolicyConservative = 2 // Long timeouts, fewer retries
};

typedef NS_ENUM(NSInteger, OfflineMode) {
    OfflineModeNever = 0,        // Always require network
    OfflineModeAuto = 1,         // Automatic fallback to cache
    OfflineModeAlways = 2        // Prefer cached content
};

@interface ConfigurationManager : NSObject

+ (ConfigurationManager *)sharedManager;

// Network settings
@property (nonatomic, assign) NetworkPolicy networkPolicy;
@property (nonatomic, assign) NSTimeInterval networkTimeout;
@property (nonatomic, assign) NSInteger maxRetryAttempts;
@property (nonatomic, assign) BOOL enableAutomaticRecovery;

// Offline settings
@property (nonatomic, assign) OfflineMode offlineMode;
@property (nonatomic, assign) NSTimeInterval cacheExpirationTime;
@property (nonatomic, assign) BOOL allowStaleCache;

// Repository settings
@property (nonatomic, retain) NSString *preferredMirror;
@property (nonatomic, assign) BOOL autoRefreshRepository;
@property (nonatomic, assign) NSTimeInterval repositoryRefreshInterval;

// Notification settings
@property (nonatomic, assign) BOOL showNetworkStatusNotifications;
@property (nonatomic, assign) BOOL showErrorRecoveryPanel;
@property (nonatomic, assign) BOOL enableBackgroundMonitoring;

// Debug settings
@property (nonatomic, assign) BOOL enableDebugLogging;
@property (nonatomic, assign) BOOL logNetworkOperations;
@property (nonatomic, retain) NSString *logFilePath;

// Configuration management
- (void)loadConfiguration;
- (void)saveConfiguration;
- (void)resetToDefaults;

// Convenience methods
- (NSTimeInterval)timeoutForOperation:(NSString *)operation;
- (NSInteger)maxRetriesForOperation:(NSString *)operation;
- (BOOL)shouldUseCache;
- (BOOL)shouldShowRecoveryUI;

// Settings UI
- (void)showConfigurationPanel:(NSWindow *)parentWindow;

@end
