#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NetworkStatus) {
    NetworkStatusUnknown = -1,
    NetworkStatusNotReachable = 0,
    NetworkStatusReachableViaWiFi = 1,
    NetworkStatusReachableViaWWAN = 2
};

typedef NS_ENUM(NSInteger, RepositoryStatus) {
    RepositoryStatusUnknown = -1,
    RepositoryStatusHealthy = 0,
    RepositoryStatusDegraded = 1,
    RepositoryStatusUnavailable = 2,
    RepositoryStatusOutdated = 3
};

@interface NetworkManager : NSObject

+ (NetworkManager *)sharedManager;

// Network connectivity
- (NetworkStatus)currentNetworkStatus;
- (BOOL)isNetworkReachable;
- (void)checkNetworkConnectivity:(void (^)(BOOL isReachable, NSString *errorMessage))completion;

// Repository health
- (void)checkRepositoryHealth:(void (^)(RepositoryStatus status, NSString *statusMessage))completion;
- (void)refreshRepositoryDatabase:(void (^)(BOOL success, NSString *errorMessage))completion;

// Repository management
- (void)validateRepositoryConfiguration:(void (^)(BOOL isValid, NSArray *errors))completion;
- (void)getRepositoryList:(void (^)(NSArray *repositories, NSString *errorMessage))completion;

// Network operations with retry
- (void)executeNetworkOperation:(NSString *)operation
                      arguments:(NSArray *)arguments
                    maxRetries:(NSInteger)maxRetries
                    completion:(void (^)(BOOL success, NSString *output, NSString *errorMessage))completion;

// GhostBSD specific repository testing
- (void)testGhostBSDRepository:(NSString *)baseURL completion:(void (^)(BOOL reachable, NSString *errorMessage))completion;

// Error categorization
- (BOOL)isNetworkError:(NSString *)errorMessage;
- (BOOL)isRepositoryError:(NSString *)errorMessage;
- (BOOL)isTemporaryError:(NSString *)errorMessage;
- (NSString *)userFriendlyErrorMessage:(NSString *)technicalError;

@end
