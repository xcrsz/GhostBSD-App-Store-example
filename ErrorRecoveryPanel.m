#import "ErrorRecoveryPanel.h"
#import <Foundation/NSTask.h>

@interface ErrorRecoveryPanel ()
@property (nonatomic, assign) ErrorRecoveryType currentErrorType;
@property (nonatomic, retain) NSString *currentTechnicalDetails;
@property (nonatomic, retain) NetworkManager *networkManager;
@property (nonatomic, retain) NSScrollView *suggestionScrollView;
@property (nonatomic, retain) NSTextView *suggestionTextView;
@property (nonatomic, assign) BOOL isRunningDiagnostics;
@end

@implementation ErrorRecoveryPanel

@synthesize panel, titleLabel, descriptionLabel, technicalDetailsLabel;
@synthesize retryButton, settingsButton, cancelButton, diagnosticsButton;
@synthesize recoveryProgress, recoveryStatusLabel, completion;
@synthesize currentErrorType, currentTechnicalDetails, networkManager;
@synthesize suggestionScrollView, suggestionTextView, isRunningDiagnostics;

- (id)init
{
    self = [super init];
    if (self) {
        self.networkManager = [NetworkManager sharedManager];
        self.isRunningDiagnostics = NO;
    }
    return self;
}

- (void)showErrorRecoveryForType:(ErrorRecoveryType)errorType
                           title:(NSString *)title
                         message:(NSString *)message
                technicalDetails:(NSString *)technicalDetails
                      completion:(ErrorRecoveryCompletion)completionBlock
{
    self.currentErrorType = errorType;
    self.currentTechnicalDetails = technicalDetails;
    self.completion = completionBlock;
    
    [self createErrorRecoveryPanel];
    [self configureForErrorType:errorType title:title message:message technicalDetails:technicalDetails];
    [self showRecoverySuggestions];
    
    [self.panel center];
    [self.panel makeKeyAndOrderFront:nil];
}

- (void)createErrorRecoveryPanel
{
    if (self.panel) {
        [self.panel orderOut:nil];
        [self.panel release];
    }
    
    self.panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 600, 500)
                                           styleMask:NSTitledWindowMask | NSClosableWindowMask
                                             backing:NSBackingStoreBuffered
                                               defer:NO];
    [self.panel setTitle:@"Error Recovery Assistant"];
    [self.panel setLevel:NSFloatingWindowLevel];
    
    [self createPanelContent];
}

- (void)createPanelContent
{
    NSView *contentView = [self.panel contentView];
    
    // Title label (large, bold)
    self.titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 450, 560, 30)];
    [self.titleLabel setBezeled:NO];
    [self.titleLabel setDrawsBackground:NO];
    [self.titleLabel setEditable:NO];
    [self.titleLabel setFont:[NSFont boldSystemFontOfSize:16]];
    [self.titleLabel setTextColor:[NSColor redColor]];
    [contentView addSubview:self.titleLabel];
    
    // Description label (main message)
    self.descriptionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 380, 560, 60)];
    [self.descriptionLabel setBezeled:NO];
    [self.descriptionLabel setDrawsBackground:NO];
    [self.descriptionLabel setEditable:NO];
    [self.descriptionLabel setFont:[NSFont systemFontOfSize:12]];
    [[self.descriptionLabel cell] setWraps:YES];
    [[self.descriptionLabel cell] setScrollable:NO];
    [contentView addSubview:self.descriptionLabel];
    
    // Recovery suggestions area
    self.suggestionScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 150, 560, 220)];
    [self.suggestionScrollView setHasVerticalScroller:YES];
    [self.suggestionScrollView setHasHorizontalScroller:NO];
    [self.suggestionScrollView setBorderType:NSBezelBorder];
    
    self.suggestionTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 560, 220)];
    [self.suggestionTextView setEditable:NO];
    [self.suggestionTextView setFont:[NSFont systemFontOfSize:11]];
    [self.suggestionScrollView setDocumentView:self.suggestionTextView];
    [contentView addSubview:self.suggestionScrollView];
    
    // Progress indicator for recovery operations
    self.recoveryProgress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 120, 400, 20)];
    [self.recoveryProgress setStyle:NSProgressIndicatorBarStyle];
    [self.recoveryProgress setIndeterminate:YES];
    [self.recoveryProgress setHidden:YES];
    [contentView addSubview:self.recoveryProgress];
    
    // Status label for recovery operations
    self.recoveryStatusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 95, 560, 20)];
    [self.recoveryStatusLabel setBezeled:NO];
    [self.recoveryStatusLabel setDrawsBackground:NO];
    [self.recoveryStatusLabel setEditable:NO];
    [self.recoveryStatusLabel setFont:[NSFont systemFontOfSize:10]];
    [self.recoveryStatusLabel setTextColor:[NSColor grayColor]];
    [self.recoveryStatusLabel setStringValue:@""];
    [contentView addSubview:self.recoveryStatusLabel];
    
    // Technical details (collapsible)
    self.technicalDetailsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 55, 560, 35)];
    [self.technicalDetailsLabel setBezeled:YES];
    [self.technicalDetailsLabel setDrawsBackground:YES];
    [self.technicalDetailsLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [self.technicalDetailsLabel setEditable:NO];
    [self.technicalDetailsLabel setFont:[NSFont fontWithName:@"Monaco" size:9]];
    [[self.technicalDetailsLabel cell] setWraps:YES];
    [[self.technicalDetailsLabel cell] setScrollable:NO];
    [contentView addSubview:self.technicalDetailsLabel];
    
    // Buttons
    [self createActionButtons:contentView];
}

- (void)createActionButtons:(NSView *)contentView
{
    // Retry button
    self.retryButton = [[NSButton alloc] initWithFrame:NSMakeRect(500, 15, 80, 30)];
    [self.retryButton setTitle:@"Retry"];
    [self.retryButton setBezelStyle:NSRoundedBezelStyle];
    [self.retryButton setTarget:self];
    [self.retryButton setAction:@selector(retryAction:)];
    [self.retryButton setKeyEquivalent:@"\r"];
    [contentView addSubview:self.retryButton];
    
    // Diagnostics button
    self.diagnosticsButton = [[NSButton alloc] initWithFrame:NSMakeRect(400, 15, 90, 30)];
    [self.diagnosticsButton setTitle:@"Diagnose"];
    [self.diagnosticsButton setBezelStyle:NSRoundedBezelStyle];
    [self.diagnosticsButton setTarget:self];
    [self.diagnosticsButton setAction:@selector(runDiagnostics:)];
    [contentView addSubview:self.diagnosticsButton];
    
    // Settings button
    self.settingsButton = [[NSButton alloc] initWithFrame:NSMakeRect(300, 15, 90, 30)];
    [self.settingsButton setTitle:@"Settings"];
    [self.settingsButton setBezelStyle:NSRoundedBezelStyle];
    [self.settingsButton setTarget:self];
    [self.settingsButton setAction:@selector(openSettings:)];
    [contentView addSubview:self.settingsButton];
    
    // Cancel button
    self.cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(200, 15, 80, 30)];
    [self.cancelButton setTitle:@"Cancel"];
    [self.cancelButton setBezelStyle:NSRoundedBezelStyle];
    [self.cancelButton setTarget:self];
    [self.cancelButton setAction:@selector(cancelAction:)];
    [self.cancelButton setKeyEquivalent:@"\033"];
    [contentView addSubview:self.cancelButton];
}

- (void)configureForErrorType:(ErrorRecoveryType)errorType
                        title:(NSString *)title
                      message:(NSString *)message
             technicalDetails:(NSString *)technicalDetails
{
    [self.titleLabel setStringValue:title];
    [self.descriptionLabel setStringValue:message];
    [self.technicalDetailsLabel setStringValue:technicalDetails ?: @"No technical details available"];
    
    // Configure colors and icons based on error type
    switch (errorType) {
        case ErrorRecoveryTypeNetwork:
            [self.titleLabel setTextColor:[NSColor redColor]];
            [self.retryButton setTitle:@"Test Network"];
            break;
            
        case ErrorRecoveryTypeRepository:
            [self.titleLabel setTextColor:[NSColor orangeColor]];
            [self.retryButton setTitle:@"Refresh Repo"];
            break;
            
        case ErrorRecoveryTypeAuthentication:
            [self.titleLabel setTextColor:[NSColor purpleColor]];
            [self.retryButton setTitle:@"Re-authenticate"];
            break;
            
        case ErrorRecoveryTypePackage:
            [self.titleLabel setTextColor:[NSColor blueColor]];
            [self.retryButton setTitle:@"Retry Install"];
            break;
            
        default:
            [self.titleLabel setTextColor:[NSColor darkGrayColor]];
            [self.retryButton setTitle:@"Retry"];
            break;
    }
}

- (void)showRecoverySuggestions
{
    NSArray *suggestions = [self getRecoverySuggestionsForType:self.currentErrorType 
                                                         error:self.currentTechnicalDetails];
    
    NSMutableString *suggestionText = [[NSMutableString alloc] init];
    [suggestionText appendString:@"Recovery Suggestions:\n\n"];
    
    for (NSInteger i = 0; i < [suggestions count]; i++) {
        [suggestionText appendFormat:@"%ld. %@\n\n", (long)(i + 1), [suggestions objectAtIndex:i]];
    }
    
    [self.suggestionTextView setString:suggestionText];
    [suggestionText release];
}

- (NSArray *)getRecoverySuggestionsForType:(ErrorRecoveryType)errorType error:(NSString *)errorMessage
{
    switch (errorType) {
        case ErrorRecoveryTypeNetwork:
            return [self getNetworkRecoverySuggestions:errorMessage];
            
        case ErrorRecoveryTypeRepository:
            return [self getRepositoryRecoverySuggestions:errorMessage];
            
        case ErrorRecoveryTypeAuthentication:
            return [self getAuthenticationRecoverySuggestions:errorMessage];
            
        case ErrorRecoveryTypePackage:
            return [self getPackageRecoverySuggestions:errorMessage];
            
        default:
            return @[@"Try the operation again after a short wait",
                    @"Check your internet connection",
                    @"Restart the application if problems persist"];
    }
}

- (NSArray *)getNetworkRecoverySuggestions:(NSString *)errorMessage
{
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    [suggestions addObject:@"Check your internet connection by opening a web browser"];
    [suggestions addObject:@"Verify that your network cables are properly connected"];
    [suggestions addObject:@"Try disabling and re-enabling your network connection"];
    [suggestions addObject:@"Check if other network applications are working"];
    [suggestions addObject:@"Contact your network administrator if you're on a corporate network"];
    
    if ([errorMessage containsString:@"DNS"] || [errorMessage containsString:@"resolve"]) {
        [suggestions addObject:@"Try changing your DNS servers to 8.8.8.8 and 8.8.4.4"];
        [suggestions addObject:@"Flush your DNS cache by running: sudo dscacheutil -flushcache"];
    }
    
    if ([errorMessage containsString:@"timeout"]) {
        [suggestions addObject:@"Your connection may be slow - try again in a few minutes"];
        [suggestions addObject:@"Check if your firewall is blocking the application"];
    }
    
    return [suggestions autorelease];
}

- (NSArray *)getRepositoryRecoverySuggestions:(NSString *)errorMessage
{
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    [suggestions addObject:@"Try refreshing the package repository database"];
    [suggestions addObject:@"Check if GhostBSD package servers are experiencing issues"];
    [suggestions addObject:@"Verify your repository configuration in /etc/pkg/GhostBSD.conf"];
    
    if ([errorMessage containsString:@"certificate"] || [errorMessage containsString:@"SSL"]) {
        [suggestions addObject:@"Check system date and time - SSL errors can be caused by incorrect time"];
        [suggestions addObject:@"Update your system's CA certificates"];
    }
    
    if ([errorMessage containsString:@"No packages available"]) {
        [suggestions addObject:@"The package may have been renamed or removed from repositories"];
        [suggestions addObject:@"Try searching for similar package names"];
        [suggestions addObject:@"Check the GhostBSD website for package availability"];
    }
    
    [suggestions addObject:@"Run 'sudo pkg update -f' in a terminal to force repository refresh"];
    
    return [suggestions autorelease];
}

- (NSArray *)getAuthenticationRecoverySuggestions:(NSString *)errorMessage
{
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    [suggestions addObject:@"Verify that your user account has sudo privileges"];
    [suggestions addObject:@"Check that you're entering the correct password"];
    [suggestions addObject:@"Make sure your user is in the 'wheel' group"];
    
    if ([errorMessage containsString:@"not in sudoers"]) {
        [suggestions addObject:@"Contact your system administrator to add your user to sudoers"];
        [suggestions addObject:@"Check /usr/local/etc/sudoers configuration"];
    }
    
    [suggestions addObject:@"Try logging out and logging back in"];
    [suggestions addObject:@"Restart the application to clear cached credentials"];
    
    return [suggestions autorelease];
}

- (NSArray *)getPackageRecoverySuggestions:(NSString *)errorMessage
{
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    [suggestions addObject:@"Ensure you have sufficient disk space for the installation"];
    [suggestions addObject:@"Check that no other package operations are running"];
    
    if ([errorMessage containsString:@"conflict"] || [errorMessage containsString:@"depends"]) {
        [suggestions addObject:@"Resolve package conflicts by updating dependencies first"];
        [suggestions addObject:@"Try installing required dependencies manually"];
        [suggestions addObject:@"Consider using 'pkg autoremove' to clean up orphaned packages"];
    }
    
    if ([errorMessage containsString:@"locked"]) {
        [suggestions addObject:@"Wait for any running package operations to complete"];
        [suggestions addObject:@"Check if another package manager instance is running"];
        [suggestions addObject:@"Try running 'sudo pkg unlock' if the lock is stale"];
    }
    
    [suggestions addObject:@"Update your package database and try again"];
    [suggestions addObject:@"Try installing the package from a terminal for more detailed error messages"];
    
    return [suggestions autorelease];
}

#pragma mark - Action Methods

- (void)retryAction:(id)sender
{
    [self.recoveryProgress setHidden:NO];
    [self.recoveryProgress startAnimation:nil];
    [self.recoveryStatusLabel setStringValue:@"Attempting recovery..."];
    
    [self attemptAutomaticRecovery:self.currentErrorType];
}

- (void)runDiagnostics:(id)sender
{
    if (self.isRunningDiagnostics) {
        return;
    }
    
    self.isRunningDiagnostics = YES;
    [self.diagnosticsButton setTitle:@"Running..."];
    [self.diagnosticsButton setEnabled:NO];
    [self.recoveryProgress setHidden:NO];
    [self.recoveryProgress startAnimation:nil];
    [self.recoveryStatusLabel setStringValue:@"Running diagnostics..."];
    
    switch (self.currentErrorType) {
        case ErrorRecoveryTypeNetwork:
            [self runNetworkDiagnostics:^(NSString *results) {
                [self displayDiagnosticResults:results];
            }];
            break;
            
        case ErrorRecoveryTypeRepository:
            [self runRepositoryDiagnostics:^(NSString *results) {
                [self displayDiagnosticResults:results];
            }];
            break;
            
        default:
            [self runGeneralDiagnostics:^(NSString *results) {
                [self displayDiagnosticResults:results];
            }];
            break;
    }
}

- (void)openSettings:(id)sender
{
    [self closePanel];
    if (self.completion) {
        self.completion(NO, YES); // Don't retry, but open settings
    }
}

- (void)cancelAction:(id)sender
{
    [self closePanel];
    if (self.completion) {
        self.completion(NO, NO);
    }
}

#pragma mark - Recovery Methods

- (void)attemptAutomaticRecovery:(ErrorRecoveryType)errorType
{
    switch (errorType) {
        case ErrorRecoveryTypeNetwork:
            [self attemptNetworkRecovery];
            break;
            
        case ErrorRecoveryTypeRepository:
            [self attemptRepositoryRecovery];
            break;
            
        case ErrorRecoveryTypeAuthentication:
            [self attemptAuthenticationRecovery];
            break;
            
        default:
            [self completeRecoveryAttempt:NO message:@"No automatic recovery available for this error type"];
            break;
    }
}

- (void)attemptNetworkRecovery
{
    [self.networkManager checkNetworkConnectivity:^(BOOL isReachable, NSString *errorMessage) {
        if (isReachable) {
            [self completeRecoveryAttempt:YES message:@"Network connection restored!"];
        } else {
            [self completeRecoveryAttempt:NO message:[NSString stringWithFormat:@"Network still unavailable: %@", errorMessage]];
        }
    }];
}

- (void)attemptRepositoryRecovery
{
    [self.networkManager refreshRepositoryDatabase:^(BOOL success, NSString *errorMessage) {
        if (success) {
            [self completeRecoveryAttempt:YES message:@"Repository database refreshed successfully!"];
        } else {
            [self completeRecoveryAttempt:NO message:[NSString stringWithFormat:@"Repository refresh failed: %@", errorMessage]];
        }
    }];
}

- (void)attemptAuthenticationRecovery
{
    // For authentication recovery, we need to prompt for re-authentication
    [self completeRecoveryAttempt:NO message:@"Please re-authenticate using the main application"];
}

- (void)completeRecoveryAttempt:(BOOL)success message:(NSString *)message
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.recoveryProgress stopAnimation:nil];
        [self.recoveryProgress setHidden:YES];
        [self.recoveryStatusLabel setStringValue:message];
        [self.recoveryStatusLabel setTextColor:success ? [NSColor greenColor] : [NSColor redColor]];
        
        if (success) {
            // Auto-close and retry after successful recovery
            [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:self
                                           selector:@selector(autoRetryAfterRecovery:)
                                           userInfo:nil
                                            repeats:NO];
        }
    }];
}

- (void)autoRetryAfterRecovery:(NSTimer *)timer
{
    [self closePanel];
    if (self.completion) {
        self.completion(YES, NO); // Retry the original operation
    }
}

#pragma mark - Diagnostic Methods

- (void)runNetworkDiagnostics:(void (^)(NSString *diagnosticResults))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSMutableString *results = [[NSMutableString alloc] init];
        
        [results appendString:@"Network Diagnostic Results:\n\n"];
        
        // Test basic connectivity
        [results appendString:@"1. Testing basic connectivity...\n"];
        BOOL basicConnectivity = [self testBasicConnectivity];
        [results appendFormat:@"   Basic connectivity: %@\n\n", basicConnectivity ? @"OK" : @"FAILED"];
        
        // Test DNS resolution
        [results appendString:@"2. Testing DNS resolution...\n"];
        BOOL dnsWorking = [self testDNSResolution];
        [results appendFormat:@"   DNS resolution: %@\n\n", dnsWorking ? @"OK" : @"FAILED"];
        
        // Test GhostBSD repository connectivity
        [results appendString:@"3. Testing GhostBSD repository access...\n"];
        BOOL repoAccess = [self testRepositoryAccess];
        [results appendFormat:@"   Repository access: %@\n\n", repoAccess ? @"OK" : @"FAILED"];
        
        // Network interface information
        [results appendString:@"4. Network interface information:\n"];
        NSString *interfaceInfo = [self getNetworkInterfaceInfo];
        [results appendFormat:@"%@\n", interfaceInfo];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completion([results autorelease]);
        }];
    }];
    [queue release];
}

- (void)runRepositoryDiagnostics:(void (^)(NSString *diagnosticResults))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSMutableString *results = [[NSMutableString alloc] init];
        
        [results appendString:@"Repository Diagnostic Results:\n\n"];
        
        // Check repository configuration
        [results appendString:@"1. Repository configuration:\n"];
        NSString *repoConfig = [self getRepositoryConfiguration];
        [results appendFormat:@"%@\n\n", repoConfig];
        
        // Check repository accessibility
        [results appendString:@"2. Repository accessibility test:\n"];
        NSString *repoTest = [self testRepositoryConnectivity];
        [results appendFormat:@"%@\n\n", repoTest];
        
        // Package database status
        [results appendString:@"3. Package database status:\n"];
        NSString *dbStatus = [self getPackageDatabaseStatus];
        [results appendFormat:@"%@\n\n", dbStatus];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completion([results autorelease]);
        }];
    }];
    [queue release];
}

- (void)runGeneralDiagnostics:(void (^)(NSString *diagnosticResults))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSMutableString *results = [[NSMutableString alloc] init];
        
        [results appendString:@"General System Diagnostic Results:\n\n"];
        
        // System information
        [results appendString:@"1. System information:\n"];
        NSString *sysInfo = [self getSystemInformation];
        [results appendFormat:@"%@\n\n", sysInfo];
        
        // Disk space check
        [results appendString:@"2. Disk space check:\n"];
        NSString *diskInfo = [self getDiskSpaceInformation];
        [results appendFormat:@"%@\n\n", diskInfo];
        
        // Process information
        [results appendString:@"3. Related processes:\n"];
        NSString *processInfo = [self getRelatedProcesses];
        [results appendFormat:@"%@\n", processInfo];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completion([results autorelease]);
        }];
    }];
    [queue release];
}

#pragma mark - Diagnostic Helper Methods

- (BOOL)testBasicConnectivity
{
    // Simple test - try to create a socket
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock != -1) {
        close(sock);
        return YES;
    }
    return NO;
}

- (BOOL)testDNSResolution
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/nslookup"];
    [task setArguments:@[@"google.com"]];
    [task launch];
    [task waitUntilExit];
    
    BOOL success = ([task terminationStatus] == 0);
    [task release];
    return success;
}

- (BOOL)testRepositoryAccess
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/pkg"];
    [task setArguments:@[@"stats", @"-r"]];
    [task launch];
    [task waitUntilExit];
    
    BOOL success = ([task terminationStatus] == 0);
    [task release];
    return success;
}

- (NSString *)getNetworkInterfaceInfo
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/sbin/ifconfig"];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    [task release];
    return output ?: @"Unable to retrieve network interface information";
}

- (NSString *)getRepositoryConfiguration
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *repoPath = @"/etc/pkg/GhostBSD.conf";
    
    if (![fm fileExistsAtPath:repoPath]) {
        return @"GhostBSD repository configuration file not found";
    }
    
    NSString *content = [NSString stringWithContentsOfFile:repoPath encoding:NSUTF8StringEncoding error:nil];
    return content ?: @"Could not read repository configuration";
}

- (NSString *)testRepositoryConnectivity
{
    // Test GhostBSD repository connectivity using actual configuration
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/ping"];
    [task setArguments:@[@"-c", @"3", @"pkg.ghostbsd.org"]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    
    BOOL success = ([task terminationStatus] == 0);
    [task release];
    
    if (success) {
        // Also test if pkg can actually access the repositories
        NSTask *pkgTask = [[NSTask alloc] init];
        [pkgTask setLaunchPath:@"/usr/sbin/pkg"];
        [pkgTask setArguments:@[@"stats", @"-r"]];
        [pkgTask launch];
        [pkgTask waitUntilExit];
        
        BOOL pkgSuccess = ([pkgTask terminationStatus] == 0);
        [pkgTask release];
        
        if (pkgSuccess) {
            return @"GhostBSD repositories (pkg.ghostbsd.org) are fully accessible";
        } else {
            return @"Can reach pkg.ghostbsd.org but pkg access failed - check repository configuration";
        }
    }
    
    return @"Cannot reach GhostBSD repository server (pkg.ghostbsd.org)";
}

- (NSString *)getPackageDatabaseStatus
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/pkg"];
    [task setArguments:@[@"stats", @"-l"]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    [task release];
    return output ?: @"Unable to retrieve package database status";
}

- (NSString *)getSystemInformation
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/uname"];
    [task setArguments:@[@"-a"]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    [task release];
    return output ?: @"Unable to retrieve system information";
}

- (NSString *)getDiskSpaceInformation
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/df"];
    [task setArguments:@[@"-h", @"/"]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    [task release];
    return output ?: @"Unable to retrieve disk space information";
}

- (NSString *)getRelatedProcesses
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/ps"];
    [task setArguments:@[@"aux"]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    // Filter for pkg-related processes
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    NSMutableString *filtered = [[NSMutableString alloc] init];
    
    for (NSString *line in lines) {
        if ([line containsString:@"pkg"] || [line containsString:@"GhostBSD"]) {
            [filtered appendFormat:@"%@\n", line];
        }
    }
    
    [task release];
    return [filtered autorelease];
}

- (void)displayDiagnosticResults:(NSString *)results
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.recoveryProgress stopAnimation:nil];
        [self.recoveryProgress setHidden:YES];
        [self.recoveryStatusLabel setStringValue:@"Diagnostics complete"];
        [self.diagnosticsButton setTitle:@"Diagnose"];
        [self.diagnosticsButton setEnabled:YES];
        self.isRunningDiagnostics = NO;
        
        // Display results in suggestion text view
        [self.suggestionTextView setString:results];
    }];
}

- (void)closePanel
{
    if (self.panel) {
        [self.panel orderOut:nil];
    }
}

#pragma mark - Memory Management

- (void)dealloc
{
    [panel release];
    [titleLabel release];
    [descriptionLabel release];
    [technicalDetailsLabel release];
    [retryButton release];
    [settingsButton release];
    [cancelButton release];
    [diagnosticsButton release];
    [recoveryProgress release];
    [recoveryStatusLabel release];
    [completion release];
    [currentTechnicalDetails release];
    [networkManager release];
    [suggestionScrollView release];
    [suggestionTextView release];
    [super dealloc];
}

@end
