#import <Foundation/Foundation.h>

@class Package;

typedef void (^PackageOperationCompletion)(BOOL success, NSString *errorMessage);
typedef void (^PackageSearchCompletion)(NSArray *packages, NSString *errorMessage);
typedef void (^ProgressUpdateBlock)(double progress);
typedef void (^ImprovedProgressUpdateBlock)(double progress, NSString *status);

@interface PackageManager : NSObject

+ (PackageManager *)sharedManager;

// Search operations
- (void)searchPackagesWithTerm:(NSString *)searchTerm 
                    completion:(PackageSearchCompletion)completion;

- (void)getFeaturedPackagesWithCompletion:(PackageSearchCompletion)completion;

- (void)getPackagesByCategory:(NSString *)category 
                   completion:(PackageSearchCompletion)completion;

- (void)getAvailableUpdatesWithCompletion:(PackageSearchCompletion)completion;

// Package operations (original methods with password)
- (void)installPackage:(NSString *)packageName 
              password:(NSString *)password
              progress:(ProgressUpdateBlock)progressBlock
            completion:(PackageOperationCompletion)completion;

- (void)uninstallPackage:(NSString *)packageName 
                password:(NSString *)password
                progress:(ProgressUpdateBlock)progressBlock
              completion:(PackageOperationCompletion)completion;

- (void)upgradeAllPackagesWithPassword:(NSString *)password
                              progress:(ProgressUpdateBlock)progressBlock
                            completion:(PackageOperationCompletion)completion;

// Improved package operations (use cached authentication)
- (void)installPackageWithoutPassword:(NSString *)packageName
                             progress:(ImprovedProgressUpdateBlock)progressBlock
                           completion:(PackageOperationCompletion)completion;

- (void)uninstallPackageWithoutPassword:(NSString *)packageName
                               progress:(ImprovedProgressUpdateBlock)progressBlock
                             completion:(PackageOperationCompletion)completion;

// Package info
- (void)getPackageInfo:(NSString *)packageName 
            completion:(void (^)(NSString *info, NSString *errorMessage))completion;

// Update checking
- (void)checkForUpdatesWithCompletion:(void (^)(BOOL updatesAvailable))completion;

@end
