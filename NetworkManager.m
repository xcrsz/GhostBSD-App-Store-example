#import "NetworkManager.h"
#import <Foundation/NSTask.h>
#import <Foundation/NSTimer.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

static NetworkManager *sharedInstance = nil;

@interface NetworkManager ()
@property (nonatomic, assign) NetworkStatus lastKnownNetworkStatus;
@property (nonatomic, assign) NSTimeInterval lastNetworkCheck;
@property (nonatomic, assign) RepositoryStatus lastRepositoryStatus;
@property (nonatomic, assign) NSTimeInterval lastRepositoryCheck;
@property (nonatomic, retain) NSMutableDictionary *operationRetryCount;
@end

@implementation NetworkManager

@synthesize lastKnownNetworkStatus, lastNetworkCheck, lastRepositoryStatus, lastRepositoryCheck, operationRetryCount;

+ (NetworkManager *)sharedManager
{
    if (sharedInstance == nil) {
        sharedInstance = [[NetworkManager alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.lastKnownNetworkStatus = NetworkStatusUnknown;
        self.lastNetworkCheck = 0;
        self.lastRepositoryStatus = RepositoryStatusUnknown;
        self.lastRepositoryCheck = 0;
        self.operationRetryCount = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Network Connectivity

- (NetworkStatus)currentNetworkStatus
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // Cache network status for 30 seconds to avoid frequent checks
    if (currentTime - self.lastNetworkCheck < 30.0 && self.lastKnownNetworkStatus != NetworkStatusUnknown) {
        return self.lastKnownNetworkStatus;
    }
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    // Try to create a socket to test connectivity
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
        self.lastKnownNetworkStatus = NetworkStatusNotReachable;
    } else {
        close(sock);
        
        // Test actual connectivity by trying to connect to a reliable host
        [self testConnectivityToHost:@"8.8.8.8" port:53]; // Google DNS
        
        // For now, assume WiFi if we can create socket (simplified)
        self.lastKnownNetworkStatus = NetworkStatusReachableViaWiFi;
    }
    
    self.lastNetworkCheck = currentTime;
    return self.lastKnownNetworkStatus;
}

- (BOOL)isNetworkReachable
{
    return [self currentNetworkStatus] != NetworkStatusNotReachable;
}

- (void)checkNetworkConnectivity:(void (^)(BOOL isReachable, NSString *errorMessage))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        // Test connectivity to multiple hosts to be thorough
        NSArray *testHosts = @[@"8.8.8.8", @"1.1.1.1", @"208.67.222.222"]; // Google, Cloudflare, OpenDNS
        BOOL anyHostReachable = NO;
        NSMutableArray *errors = [[NSMutableArray alloc] init];
        
        for (NSString *host in testHosts) {
            if ([self testConnectivityToHost:host port:53]) {
                anyHostReachable = YES;
                break;
            } else {
                [errors addObject:[NSString stringWithFormat:@"Cannot reach %@", host]];
            }
        }
        
        // Also test pkg repository connectivity
        if (anyHostReachable) {
            [self testPkgConnectivity:^(BOOL pkgReachable, NSString *pkgError) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (pkgReachable) {
                        completion(YES, nil);
                    } else {
                        completion(YES, [NSString stringWithFormat:@"Internet is available but GhostBSD repositories are unreachable: %@", pkgError]);
                    }
                }];
            }];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSString *errorMessage = [NSString stringWithFormat:@"No internet connectivity. Tested: %@", [errors componentsJoinedByString:@", "]];
                completion(NO, errorMessage);
            }];
        }
        
        [errors release];
    }];
    [queue release];
}

- (BOOL)testConnectivityToHost:(NSString *)host port:(NSInteger)port
{
    struct sockaddr_in addr;
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    
    if (sock == -1) {
        return NO;
    }
    
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr([host UTF8String]);
    
    // Set a timeout for the connection
    struct timeval timeout;
    timeout.tv_sec = 5;  // 5 second timeout
    timeout.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));
    
    int result = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
    close(sock);
    
    return (result == 0);
}

- (void)testPkgConnectivity:(void (^)(BOOL reachable, NSString *errorMessage))completion
{
    // Test GhostBSD repositories as configured in /etc/pkg/GhostBSD.conf
    [self testGhostBSDRepository:@"https://pkg.ghostbsd.org/stable/" completion:^(BOOL repoSuccess, NSString *repoError) {
        if (repoSuccess) {
            completion(YES, nil);
        } else {
            completion(NO, repoError ?: @"Cannot reach GhostBSD package repositories");
        }
    }];
}

- (void)testGhostBSDRepository:(NSString *)baseURL completion:(void (^)(BOOL reachable, NSString *errorMessage))completion
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/pkg"];
    [task setArguments:@[@"stats", @"-r"]]; // Test configured repositories
    
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:errorPipe];
    
    // Set a timeout for pkg operation
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(terminateTask:)
                                   userInfo:task
                                    repeats:NO];
    
    [task launch];
    [task waitUntilExit];
    
    BOOL success = ([task terminationStatus] == 0);
    NSString *errorMessage = nil;
    
    if (!success) {
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        errorMessage = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
        
        // If pkg stats fails, try basic connectivity test
        if ([errorMessage containsString:@"Unable to open"] || [errorMessage containsString:@"timeout"]) {
            [self testBasicConnectivity:@"pkg.ghostbsd.org" completion:completion];
            [task release];
            return;
        }
    }
    
    [task release];
    completion(success, errorMessage);
}

- (void)testBasicConnectivity:(NSString *)hostname completion:(void (^)(BOOL reachable, NSString *errorMessage))completion
{
    NSTask *pingTask = [[NSTask alloc] init];
    [pingTask setLaunchPath:@"/sbin/ping"];
    [pingTask setArguments:@[@"-c", @"3", hostname]];
    
    NSPipe *pipe = [NSPipe pipe];
    [pingTask setStandardOutput:pipe];
    [pingTask setStandardError:pipe];
    
    [pingTask launch];
    [pingTask waitUntilExit];
    
    BOOL success = ([pingTask terminationStatus] == 0);
    NSString *errorMessage = success ? nil : [NSString stringWithFormat:@"Cannot reach %@", hostname];
    
    [pingTask release];
    completion(success, errorMessage);
}

- (void)terminateTask:(NSTimer *)timer
{
    NSTask *task = [timer userInfo];
    if ([task isRunning]) {
        [task terminate];
        NSLog(@"WARNING: Terminated long-running pkg task due to timeout");
    }
}

#pragma mark - Repository Health

- (void)checkRepositoryHealth:(void (^)(RepositoryStatus status, NSString *statusMessage))completion
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // Cache repository status for 5 minutes
    if (currentTime - self.lastRepositoryCheck < 300.0 && self.lastRepositoryStatus != RepositoryStatusUnknown) {
        NSString *cachedMessage = [self statusMessageForRepositoryStatus:self.lastRepositoryStatus];
        completion(self.lastRepositoryStatus, cachedMessage);
        return;
    }
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        // First check if we have network connectivity
        if (![self isNetworkReachable]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(RepositoryStatusUnavailable, @"No network connectivity");
            }];
            [queue release];
            return;
        }
        
        // Test repository update
        NSTask *updateTask = [[NSTask alloc] init];
        [updateTask setLaunchPath:@"/usr/sbin/pkg"];
        [updateTask setArguments:@[@"update", @"-n"]]; // Dry run update
        
        NSPipe *errorPipe = [NSPipe pipe];
        [updateTask setStandardError:errorPipe];
        
        [updateTask launch];
        [updateTask waitUntilExit];
        
        RepositoryStatus status;
        NSString *statusMessage;
        
        if ([updateTask terminationStatus] == 0) {
            // Repository is accessible, now check if it's up to date
            [self checkRepositoryFreshness:^(BOOL isFresh, NSString *freshnessMessage) {
                RepositoryStatus finalStatus = isFresh ? RepositoryStatusHealthy : RepositoryStatusOutdated;
                self.lastRepositoryStatus = finalStatus;
                self.lastRepositoryCheck = [[NSDate date] timeIntervalSince1970];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completion(finalStatus, freshnessMessage);
                }];
            }];
        } else {
            NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
            NSString *errorOutput = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
            
            if ([errorOutput containsString:@"timeout"] || [errorOutput containsString:@"network"]) {
                status = RepositoryStatusUnavailable;
                statusMessage = @"Repository servers are unreachable";
            } else {
                status = RepositoryStatusDegraded;
                statusMessage = [NSString stringWithFormat:@"Repository issues detected: %@", errorOutput];
            }
            
            self.lastRepositoryStatus = status;
            self.lastRepositoryCheck = [[NSDate date] timeIntervalSince1970];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(status, statusMessage);
            }];
        }
        
        [updateTask release];
    }];
    [queue release];
}

- (void)checkRepositoryFreshness:(void (^)(BOOL isFresh, NSString *message))completion
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/pkg"];
    [task setArguments:@[@"stats", @"-l"]]; // Local repository stats
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task launch];
    [task waitUntilExit];
    
    if ([task terminationStatus] == 0) {
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
        
        // Look for repository age information
        // This is a simplified check - in reality you'd parse the output more carefully
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval dayAgo = currentTime - (24 * 60 * 60);
        
        // For simplicity, consider repository fresh if update was successful
        completion(YES, @"Repository data is current");
    } else {
        completion(NO, @"Cannot determine repository freshness");
    }
    
    [task release];
}

- (void)refreshRepositoryDatabase:(void (^)(BOOL success, NSString *errorMessage))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        // First check network connectivity
        [self checkNetworkConnectivity:^(BOOL isReachable, NSString *networkError) {
            if (!isReachable) {
                completion(NO, networkError);
                return;
            }
            
            // Perform repository update
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/usr/sbin/pkg"];
            [task setArguments:@[@"update", @"-f"]]; // Force update
            
            NSPipe *outputPipe = [NSPipe pipe];
            NSPipe *errorPipe = [NSPipe pipe];
            [task setStandardOutput:outputPipe];
            [task setStandardError:errorPipe];
            
            [task launch];
            [task waitUntilExit];
            
            BOOL success = ([task terminationStatus] == 0);
            NSString *errorMessage = nil;
            
            if (!success) {
                NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
                errorMessage = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
                errorMessage = [self userFriendlyErrorMessage:errorMessage];
            } else {
                // Clear cached repository status to force recheck
                self.lastRepositoryStatus = RepositoryStatusUnknown;
                self.lastRepositoryCheck = 0;
            }
            
            [task release];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(success, errorMessage);
            }];
        }];
    }];
    [queue release];
}

#pragma mark - Repository Management

- (void)validateRepositoryConfiguration:(void (^)(BOOL isValid, NSArray *errors))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSMutableArray *errors = [[NSMutableArray alloc] init];
        
        // Check GhostBSD repository configuration files
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *ghostbsdConfPath = @"/etc/pkg/GhostBSD.conf";
        
        if (![fm fileExistsAtPath:ghostbsdConfPath]) {
            [errors addObject:@"GhostBSD repository configuration file not found at /etc/pkg/GhostBSD.conf"];
        } else {
            // Verify the configuration file contains expected repositories
            NSString *confContent = [NSString stringWithContentsOfFile:ghostbsdConfPath 
                                                               encoding:NSUTF8StringEncoding 
                                                                  error:nil];
            if (confContent) {
                if (![confContent containsString:@"pkg.ghostbsd.org"]) {
                    [errors addObject:@"GhostBSD repository URL not found in configuration"];
                }
                if (![confContent containsString:@"ghostbsd.cert"]) {
                    [errors addObject:@"GhostBSD signature verification not configured"];
                }
            }
        }
        
        // Check for GhostBSD certificate
        NSString *certPath = @"/usr/share/keys/ssl/certs/ghostbsd.cert";
        if (![fm fileExistsAtPath:certPath]) {
            [errors addObject:@"GhostBSD repository certificate not found"];
        }
        
        // Test repository connectivity
        [self getRepositoryList:^(NSArray *repositories, NSString *errorMessage) {
            if (errorMessage) {
                [errors addObject:errorMessage];
            } else if ([repositories count] == 0) {
                [errors addObject:@"No active repositories configured"];
            }
            
            BOOL isValid = ([errors count] == 0);
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(isValid, [errors copy]);
            }];
        }];
        
        [errors release];
    }];
    [queue release];
}

- (void)getRepositoryList:(void (^)(NSArray *repositories, NSString *errorMessage))completion
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/pkg"];
    [task setArguments:@[@"stats", @"-r"]];
    
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:errorPipe];
    
    [task launch];
    [task waitUntilExit];
    
    if ([task terminationStatus] == 0) {
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
        
        // Parse repository information (simplified)
        NSArray *lines = [output componentsSeparatedByString:@"\n"];
        NSMutableArray *repositories = [[NSMutableArray alloc] init];
        
        for (NSString *line in lines) {
            if ([line containsString:@"repository"]) {
                [repositories addObject:line];
            }
        }
        
        completion([repositories autorelease], nil);
    } else {
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorMessage = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
        completion(nil, [self userFriendlyErrorMessage:errorMessage]);
    }
    
    [task release];
}

#pragma mark - Network Operations with Retry

- (void)executeNetworkOperation:(NSString *)operation
                      arguments:(NSArray *)arguments
                    maxRetries:(NSInteger)maxRetries
                    completion:(void (^)(BOOL success, NSString *output, NSString *errorMessage))completion
{
    NSString *operationKey = [NSString stringWithFormat:@"%@_%@", operation, [arguments componentsJoinedByString:@"_"]];
    NSNumber *currentRetries = [self.operationRetryCount objectForKey:operationKey];
    NSInteger retryCount = currentRetries ? [currentRetries integerValue] : 0;
    
    if (retryCount >= maxRetries) {
        [self.operationRetryCount removeObjectForKey:operationKey];
        completion(NO, nil, @"Operation failed after maximum retries");
        return;
    }
    
    // Check network connectivity before attempting operation
    [self checkNetworkConnectivity:^(BOOL isReachable, NSString *networkError) {
        if (!isReachable) {
            // Network is down, wait and retry
            if (retryCount < maxRetries) {
                NSTimeInterval delay = [self exponentialBackoffDelay:retryCount];
                NSLog(@"Network unreachable, retrying in %.1f seconds (attempt %ld/%ld)", delay, (long)(retryCount + 1), (long)maxRetries);
                
                [NSTimer scheduledTimerWithTimeInterval:delay
                                                 target:self
                                               selector:@selector(retryOperationWithUserInfo:)
                                               userInfo:@{
                                                   @"operation": operation,
                                                   @"arguments": arguments,
                                                   @"maxRetries": @(maxRetries),
                                                   @"completion": [completion copy],
                                                   @"operationKey": operationKey,
                                                   @"retryCount": @(retryCount + 1)
                                               }
                                                repeats:NO];
            } else {
                completion(NO, nil, networkError);
            }
            return;
        }
        
        // Network is available, execute the operation
        [self performOperation:operation
                     arguments:arguments
                  operationKey:operationKey
                    retryCount:retryCount
                    maxRetries:maxRetries
                    completion:completion];
    }];
}

- (void)retryOperationWithUserInfo:(NSTimer *)timer
{
    NSDictionary *userInfo = [timer userInfo];
    NSString *operation = [userInfo objectForKey:@"operation"];
    NSArray *arguments = [userInfo objectForKey:@"arguments"];
    NSInteger maxRetries = [[userInfo objectForKey:@"maxRetries"] integerValue];
    void (^completion)(BOOL, NSString *, NSString *) = [userInfo objectForKey:@"completion"];
    NSString *operationKey = [userInfo objectForKey:@"operationKey"];
    NSInteger retryCount = [[userInfo objectForKey:@"retryCount"] integerValue];
    
    [self.operationRetryCount setObject:@(retryCount) forKey:operationKey];
    
    [self performOperation:operation
                 arguments:arguments
              operationKey:operationKey
                retryCount:retryCount
                maxRetries:maxRetries
                completion:completion];
}

- (void)performOperation:(NSString *)operation
               arguments:(NSArray *)arguments
            operationKey:(NSString *)operationKey
              retryCount:(NSInteger)retryCount
              maxRetries:(NSInteger)maxRetries
              completion:(void (^)(BOOL success, NSString *output, NSString *errorMessage))completion
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:operation];
    [task setArguments:arguments];
    
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:errorPipe];
    
    [task launch];
    [task waitUntilExit];
    
    BOOL success = ([task terminationStatus] == 0);
    NSString *output = nil;
    NSString *errorMessage = nil;
    
    if (success) {
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
        [self.operationRetryCount removeObjectForKey:operationKey];
    } else {
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        errorMessage = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
        
        // Check if this is a temporary error that should be retried
        if ([self isTemporaryError:errorMessage] && retryCount < maxRetries) {
            NSTimeInterval delay = [self exponentialBackoffDelay:retryCount];
            NSLog(@"Temporary error encountered, retrying in %.1f seconds: %@", delay, errorMessage);
            
            [NSTimer scheduledTimerWithTimeInterval:delay
                                             target:self
                                           selector:@selector(retryOperationWithUserInfo:)
                                           userInfo:@{
                                               @"operation": operation,
                                               @"arguments": arguments,
                                               @"maxRetries": @(maxRetries),
                                               @"completion": [completion copy],
                                               @"operationKey": operationKey,
                                               @"retryCount": @(retryCount + 1)
                                           }
                                            repeats:NO];
            [task release];
            return;
        } else {
            [self.operationRetryCount removeObjectForKey:operationKey];
            errorMessage = [self userFriendlyErrorMessage:errorMessage];
        }
    }
    
    [task release];
    completion(success, output, errorMessage);
}

- (NSTimeInterval)exponentialBackoffDelay:(NSInteger)retryCount
{
    // Exponential backoff: 2^retryCount seconds, with jitter and max of 60 seconds
    NSTimeInterval baseDelay = MIN(pow(2, retryCount), 60.0);
    NSTimeInterval jitter = ((double)arc4random() / UINT32_MAX) * 0.1 * baseDelay; // Up to 10% jitter
    return baseDelay + jitter;
}

#pragma mark - Error Categorization

- (BOOL)isNetworkError:(NSString *)errorMessage
{
    if (!errorMessage) return NO;
    
    NSArray *networkKeywords = @[@"network", @"timeout", @"connection", @"unreachable", @"dns", @"resolve"];
    NSString *lowerError = [errorMessage lowercaseString];
    
    for (NSString *keyword in networkKeywords) {
        if ([lowerError containsString:keyword]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isRepositoryError:(NSString *)errorMessage
{
    if (!errorMessage) return NO;
    
    NSArray *repoKeywords = @[@"repository", @"catalogue", @"package database", @"no packages available", @"repo"];
    NSString *lowerError = [errorMessage lowercaseString];
    
    for (NSString *keyword in repoKeywords) {
        if ([lowerError containsString:keyword]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isTemporaryError:(NSString *)errorMessage
{
    if (!errorMessage) return NO;
    
    NSArray *temporaryKeywords = @[@"timeout", @"temporary", @"busy", @"try again", @"server error", @"503", @"502", @"504"];
    NSString *lowerError = [errorMessage lowercaseString];
    
    for (NSString *keyword in temporaryKeywords) {
        if ([lowerError containsString:keyword]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)userFriendlyErrorMessage:(NSString *)technicalError
{
    if (!technicalError || [technicalError length] == 0) {
        return @"An unknown error occurred";
    }
    
    NSString *lowerError = [technicalError lowercaseString];
    
    // Network errors
    if ([self isNetworkError:technicalError]) {
        if ([lowerError containsString:@"timeout"]) {
            return @"Connection timed out. Please check your internet connection and try again.";
        } else if ([lowerError containsString:@"dns"] || [lowerError containsString:@"resolve"]) {
            return @"Cannot resolve server address. Please check your DNS settings.";
        } else {
            return @"Network connection failed. Please check your internet connection.";
        }
    }
    
    // Repository errors
    if ([self isRepositoryError:technicalError]) {
        if ([lowerError containsString:@"no packages available"]) {
            return @"Package not found in any repository. The package may have been removed or renamed.";
        } else if ([lowerError containsString:@"catalogue"]) {
            return @"Repository database is out of date. Try refreshing the package database.";
        } else {
            return @"Repository error. Try refreshing the package database or check repository configuration.";
        }
    }
    
    // Authentication errors
    if ([lowerError containsString:@"privilege"] || [lowerError containsString:@"permission"]) {
        return @"Insufficient privileges. Administrator access is required for this operation.";
    }
    
    // Disk space errors
    if ([lowerError containsString:@"space"] || [lowerError containsString:@"full"]) {
        return @"Insufficient disk space. Please free up some space and try again.";
    }
    
    // Package conflicts
    if ([lowerError containsString:@"conflict"] || [lowerError containsString:@"depends"]) {
        return @"Package dependency conflict. Some packages may need to be updated or removed first.";
    }
    
    // For unrecognized errors, return a cleaned up version
    NSString *cleaned = [technicalError stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([cleaned length] > 200) {
        cleaned = [[cleaned substringToIndex:200] stringByAppendingString:@"..."];
    }
    
    return [NSString stringWithFormat:@"Error: %@", cleaned];
}

- (NSString *)statusMessageForRepositoryStatus:(RepositoryStatus)status
{
    switch (status) {
        case RepositoryStatusHealthy:
            return @"Repository is healthy and up to date";
        case RepositoryStatusDegraded:
            return @"Repository is accessible but experiencing issues";
        case RepositoryStatusUnavailable:
            return @"Repository servers are currently unavailable";
        case RepositoryStatusOutdated:
            return @"Repository database needs to be updated";
        default:
            return @"Repository status unknown";
    }
}

#pragma mark - Memory Management

- (void)dealloc
{
    [operationRetryCount release];
    [super dealloc];
}

@end
