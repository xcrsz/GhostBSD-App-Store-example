#import "AppDelegate.h"
#import "Package.h"
#import "PackageManager.h"
#import "PasswordPanel.h"
#import "PackageDetailWindow.h"
#import "CategoryWindow.h"
#import "SudoManager.h"

// FIXED: Remove duplicate property declarations - they're already in AppDelegate.h
@interface AppDelegate ()
// No property redeclarations needed - they're already in the header
@end

@implementation AppDelegate

@synthesize window, packageManager, passwordPanel, detailWindow, categoryWindow;
@synthesize installedPackages, currentCategory, isSearchMode, rowUpdateQueue, updateCoalescingTimer;

// Static cached authentication window for fast reuse (kept from original optimization)
static NSWindow *cachedAuthWindow = nil;
static NSSecureTextField *cachedPasswordField = nil;
static NSTextField *cachedStatusLabel = nil;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSLog(@"DEBUG: applicationDidFinishLaunching called");
    
    // NEW: Initialize tracking objects
    self.installedPackages = [[NSMutableSet alloc] init];
    self.currentCategory = @"";
    self.isSearchMode = NO;
    self.rowUpdateQueue = [[NSMutableDictionary alloc] init];
    
    // Initialize managers
    self.packageManager = [PackageManager sharedManager];
    self.passwordPanel = [[PasswordPanel alloc] init];
    self.detailWindow = [[PackageDetailWindow alloc] init];
    self.detailWindow.delegate = self;
    self.categoryWindow = [[CategoryWindow alloc] init];
    self.categoryWindow.delegate = self;
    
    // Initialize data
    packages = [[NSMutableArray alloc] init];
    updatesAvailable = NO;

    // Set up the main window but DON'T show it yet
    [self setupMainWindow];
    [self setupNavigationBar];
    [self setupSearchField];
    [self setupWelcomeMessage];
    [self setupTableView];
    [self setupProgressIndicators];
    
    // Show welcome message initially (when window becomes visible)
    [self showWelcomeMessage:YES];
    
    // CENTER the window but don't show it yet
    [window center];
    
    // PRE-WARM AUTHENTICATION SYSTEM for faster popup rendering
    [self preWarmAuthenticationSystem];
    
    NSLog(@"DEBUG: Main window prepared, showing authentication first");
    
    // Show authentication IMMEDIATELY - no delay
    [self showAuthenticationBeforeMainWindow];
}

// ADDED: Missing network-related method implementations
#pragma mark - Network Status Monitoring (Missing Implementations Added)

- (void)setupNetworkStatusBar
{
    NSLog(@"DEBUG: Setting up network status bar - placeholder implementation");
    // TODO: Implement network status bar if needed
}

- (void)startNetworkMonitoring
{
    NSLog(@"DEBUG: Starting network monitoring - placeholder implementation");
    // TODO: Implement network monitoring if needed
}

- (void)periodicNetworkCheck:(NSTimer *)timer
{
    NSLog(@"DEBUG: Periodic network check - placeholder implementation");
    // TODO: Implement periodic network checking if needed
}

- (void)checkNetworkStatusAndUpdate
{
    NSLog(@"DEBUG: Checking network status and updating - placeholder implementation");
    // TODO: Implement network status checking if needed
}

- (void)updateNetworkStatusUI:(BOOL)isReachable errorMessage:(NSString *)errorMessage
{
    NSLog(@"DEBUG: Updating network status UI - reachable: %@, error: %@", 
          isReachable ? @"YES" : @"NO", errorMessage);
    // TODO: Implement network status UI updates if needed
}

- (void)checkRepositoryStatusAndUpdate
{
    NSLog(@"DEBUG: Checking repository status and updating - placeholder implementation");
    // TODO: Implement repository status checking if needed
}

- (void)onNetworkRestored
{
    NSLog(@"DEBUG: Network restored - placeholder implementation");
    // TODO: Implement network restoration handling if needed
}

- (void)onNetworkLost
{
    NSLog(@"DEBUG: Network lost - placeholder implementation");
    // TODO: Implement network loss handling if needed
}

- (void)refreshCurrentCategory
{
    NSLog(@"DEBUG: Refreshing current category - placeholder implementation");
    // TODO: Implement category refresh if needed
}

- (void)retryNetworkOperation:(id)sender
{
    NSLog(@"DEBUG: Retrying network operation - placeholder implementation");
    // TODO: Implement network operation retry if needed
}

- (void)refreshRepository:(id)sender
{
    NSLog(@"DEBUG: Refreshing repository - placeholder implementation");
    // TODO: Implement repository refresh if needed
}

- (void)showNetworkLostAlert
{
    NSLog(@"DEBUG: Showing network lost alert - placeholder implementation");
    [self showErrorMessage:@"Network connection lost. Please check your internet connection."];
}

- (void)showEnhancedErrorMessage:(NSString *)message withRetryAction:(SEL)retryAction
{
    NSLog(@"DEBUG: Showing enhanced error message: %@", message);
    [self showErrorMessage:message];
    // TODO: Add retry button functionality if needed
}

// ADDED: Missing enhanced network recovery methods
- (void)handleInstallCompletionWithNetworkRecovery:(BOOL)success 
                                              error:(NSString *)errorMessage 
                                            package:(Package *)package 
                                       detailWindow:(PackageDetailWindow *)detailWindow
{
    // Delegate to existing method
    [self handleInstallCompletion:success error:errorMessage package:package detailWindow:detailWindow];
}

- (void)handleUninstallCompletionWithNetworkRecovery:(BOOL)success 
                                               error:(NSString *)errorMessage 
                                             package:(Package *)package 
                                        detailWindow:(PackageDetailWindow *)detailWindow
{
    // Delegate to existing method
    [self handleUninstallCompletion:success error:errorMessage package:package detailWindow:detailWindow];
}

- (void)handleInstallCompletionWithNetworkRecoveryFromDict:(NSDictionary *)info
{
    // Delegate to existing method
    [self handleInstallCompletionFromDict:info];
}

- (void)handleUninstallCompletionWithNetworkRecoveryFromDict:(NSDictionary *)info
{
    // Delegate to existing method
    [self handleUninstallCompletionFromDict:info];
}

// ADDED: Missing enhanced navigation methods
- (void)showFeaturedWithErrorHandling:(id)sender
{
    // Delegate to existing method
    [self showFeatured:sender];
}

- (void)showUpdatesWithErrorHandling:(id)sender
{
    // Delegate to existing method
    [self showUpdates:sender];
}

- (void)performSearchWithErrorHandling:(NSTimer *)timer
{
    // Delegate to existing method
    [self performSearch:timer];
}

#pragma mark - NEW: Package Name Cleaning

// NEW: Add this method to AppDelegate.m for cleaning package names
- (NSString *)cleanPackageNameForInstallation:(NSString *)rawName
{
    if (!rawName || [rawName length] == 0) {
        return @"";
    }
    
    // Remove any whitespace and newlines
    NSString *cleaned = [rawName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // If the name contains multiple spaces or tabs, take only the first part (the actual package name)
    NSArray *components = [cleaned componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([components count] > 0) {
        NSString *firstName = [components objectAtIndex:0];
        // Additional validation - package names shouldn't contain spaces, and should be reasonable length
        if ([firstName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location == NSNotFound && 
            [firstName length] > 0 && [firstName length] < 100) {
            return firstName;
        }
    }
    
    // If we can't clean it properly, return empty string to avoid bad installations
    NSLog(@"WARNING: Could not clean package name: %@", rawName);
    return @"";
}

#pragma mark - Debug Threading Helper

// NEW: Add this method to help debug threading issues
- (void)debugCheckMainThread:(NSString *)methodName
{
    if (![NSThread isMainThread]) {
        NSLog(@"WARNING: %@ called from background thread! Thread: %@", methodName, [NSThread currentThread]);
    } else {
        NSLog(@"DEBUG: %@ correctly called from main thread", methodName);
    }
}

#pragma mark - NEW: GNUstep-Compatible Threading Fixes

// FIXED: Use performSelectorOnMainThread instead of NSOperationQueue for alerts
- (void)performBlockOnMainThread:(void (^)(void))block
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        // For GNUstep compatibility, use a different approach for UI operations
        [self performSelectorOnMainThread:@selector(executeBlockOnMainThread:) 
                               withObject:[block copy] 
                            waitUntilDone:NO];
    }
}

// NEW: Helper method to execute blocks on main thread
- (void)executeBlockOnMainThread:(void (^)(void))block
{
    if (block) {
        block();
        [block release]; // Release the copied block
    }
}

// MISSING: Thread-safe utility method
- (void)performOnMainThread:(SEL)selector withObject:(id)object
{
    if ([NSThread isMainThread]) {
        [self performSelector:selector withObject:object];
    } else {
        [self performSelectorOnMainThread:selector withObject:object waitUntilDone:NO];
    }
}

#pragma mark - Authentication First Startup (NEW SECTION)

// NEW: Method to show authentication before main window
- (void)showAuthenticationBeforeMainWindow
{
    NSLog(@"DEBUG: Showing authentication before main window");
    
    if (!cachedAuthWindow) {
        [self createCachedAuthenticationWindow];
    }
    
    // Clear any previous state
    [cachedPasswordField setStringValue:@""];
    [cachedStatusLabel setStringValue:@"Authentication required to start the application"];
    [cachedStatusLabel setTextColor:[NSColor darkGrayColor]];
    
    // Center the auth window
    NSPoint centerPoint = [self cachedCenterPointForSize:[cachedAuthWindow frame].size];
    [cachedAuthWindow setFrameOrigin:centerPoint];
    
    // Show auth window and make it key
    [cachedAuthWindow makeFirstResponder:cachedPasswordField];
    [cachedAuthWindow orderFrontRegardless];
    [cachedAuthWindow makeKeyWindow];
    
    NSLog(@"DEBUG: Authentication window displayed, waiting for user input");
}

// NEW: Method to show main window after successful authentication
- (void)showMainWindowAfterAuth:(NSTimer *)timer
{
    NSLog(@"DEBUG: Showing main window after successful authentication");
    
    // Close the auth window
    if (cachedAuthWindow) {
        [cachedAuthWindow orderOut:nil];
    }
    
    // Now show the main window
    [window makeKeyAndOrderFront:nil];
    
    NSLog(@"DEBUG: Main window is now visible and ready");
}

// NEW: Add method to handle authentication cancellation
- (void)handleAuthenticationCancel:(id)sender
{
    NSLog(@"DEBUG: User cancelled authentication");
    
    NSInteger result = NSRunAlertPanel(@"Authentication Required", 
                                      @"Authentication is required to use this application.\n\nWould you like to try again or quit?", 
                                      @"Try Again", @"Quit", nil);
    
    if (result == NSAlertDefaultReturn) {
        // Try again - clear the field and refocus
        [cachedPasswordField setStringValue:@""];
        [cachedStatusLabel setStringValue:@"Please enter your password"];
        [cachedStatusLabel setTextColor:[NSColor darkGrayColor]];
        [cachedPasswordField becomeFirstResponder];
    } else {
        // User chose to quit
        NSLog(@"DEBUG: User chose to quit application");
        [NSApp terminate:nil];
    }
}

#pragma mark - Optimized Authentication System (Enhanced)

- (void)preWarmAuthenticationSystem
{
    NSLog(@"DEBUG: Pre-warming authentication system for faster rendering");
    [self createCachedAuthenticationWindow];
    if (cachedAuthWindow) {
        [cachedAuthWindow orderOut:nil];
    }
}

- (void)createCachedAuthenticationWindow
{
    if (cachedAuthWindow) {
        return; // Already created
    }
    
    NSLog(@"DEBUG: Creating cached authentication window");
    
    // NEW: Use autorelease pool for bulk UI creation
    NSAutoreleasePool *uiPool = [[NSAutoreleasePool alloc] init];
    
    // Make window slightly larger to accommodate cancel button
    cachedAuthWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 500, 200)
                                                  styleMask:NSTitledWindowMask
                                                    backing:NSBackingStoreBuffered
                                                      defer:YES];
    
    [cachedAuthWindow setTitle:@"GhostBSD App Store - Authentication Required"];
    [cachedAuthWindow setLevel:NSFloatingWindowLevel];
    [cachedAuthWindow setHidesOnDeactivate:NO];
    [cachedAuthWindow setReleasedWhenClosed:NO];
    
    NSView *containerView = [cachedAuthWindow contentView];
    
    // Pre-calculated frames for faster layout (adjusted for new layout)
    struct {
        NSRect message;
        NSRect passwordLabel;
        NSRect passwordField;
        NSRect status;
        NSRect loginButton;
        NSRect cancelButton;
    } frames = {
        .message = NSMakeRect(20, 150, 460, 30),
        .passwordLabel = NSMakeRect(20, 110, 80, 20),
        .passwordField = NSMakeRect(100, 110, 300, 24),
        .status = NSMakeRect(20, 80, 460, 20),
        .loginButton = NSMakeRect(300, 30, 80, 30),
        .cancelButton = NSMakeRect(200, 30, 80, 30)
    };
    
    // Create all views efficiently
    NSTextField *messageLabel = [[NSTextField alloc] initWithFrame:frames.message];
    [messageLabel setStringValue:@"Administrator privileges are required to manage packages."];
    [messageLabel setBezeled:NO];
    [messageLabel setDrawsBackground:NO];
    [messageLabel setEditable:NO];
    [messageLabel setFont:[NSFont systemFontOfSize:14]];
    
    NSTextField *passwordLabel = [[NSTextField alloc] initWithFrame:frames.passwordLabel];
    [passwordLabel setStringValue:@"Password:"];
    [passwordLabel setBezeled:NO];
    [passwordLabel setDrawsBackground:NO];
    [passwordLabel setEditable:NO];
    
    cachedPasswordField = [[NSSecureTextField alloc] initWithFrame:frames.passwordField];
    
    cachedStatusLabel = [[NSTextField alloc] initWithFrame:frames.status];
    [cachedStatusLabel setStringValue:@"Please enter your password to continue"];
    [cachedStatusLabel setBezeled:NO];
    [cachedStatusLabel setDrawsBackground:NO];
    [cachedStatusLabel setEditable:NO];
    [cachedStatusLabel setTextColor:[NSColor darkGrayColor]];
    
    NSButton *loginButton = [[NSButton alloc] initWithFrame:frames.loginButton];
    [loginButton setTitle:@"Login"];
    [loginButton setBezelStyle:NSRoundedBezelStyle];
    [loginButton setTarget:self];
    [loginButton setAction:@selector(handleOptimizedLogin:)];
    [loginButton setKeyEquivalent:@"\r"];
    
    // NEW: Add cancel button
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:frames.cancelButton];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setBezelStyle:NSRoundedBezelStyle];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(handleAuthenticationCancel:)];
    [cancelButton setKeyEquivalent:@"\033"]; // Escape key
    
    // Batch add subviews
    NSArray *subviews = @[messageLabel, passwordLabel, cachedPasswordField, cachedStatusLabel, loginButton, cancelButton];
    for (NSView *view in subviews) {
        [containerView addSubview:view];
    }
    
    [messageLabel release];
    [passwordLabel release];
    [loginButton release];
    [cancelButton release];
    
    [uiPool release];
}

- (void)showOptimizedAuthenticationPanel
{
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    if (!cachedAuthWindow) {
        [self createCachedAuthenticationWindow];
    }
    
    [cachedPasswordField setStringValue:@""];
    [cachedStatusLabel setStringValue:@""];
    [cachedStatusLabel setTextColor:[NSColor redColor]];
    
    NSPoint centerPoint = [self cachedCenterPointForSize:[cachedAuthWindow frame].size];
    [cachedAuthWindow setFrameOrigin:centerPoint];
    
    [cachedAuthWindow makeFirstResponder:cachedPasswordField];
    [cachedAuthWindow orderFrontRegardless];
    
    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval renderTime = (endTime - startTime) * 1000;
    
    NSLog(@"DEBUG: Optimized authentication window displayed in %.2f ms", renderTime);
}

- (NSPoint)cachedCenterPointForSize:(NSSize)windowSize
{
    static NSRect cachedScreenFrame = {{0,0},{0,0}};
    static NSTimeInterval lastCacheTime = 0;
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    if (currentTime - lastCacheTime > 5.0) {
        cachedScreenFrame = [[NSScreen mainScreen] visibleFrame];
        lastCacheTime = currentTime;
    }
    
    return NSMakePoint(
        cachedScreenFrame.origin.x + (cachedScreenFrame.size.width - windowSize.width) / 2,
        cachedScreenFrame.origin.y + (cachedScreenFrame.size.height - windowSize.height) / 2
    );
}

// MODIFIED: Enhanced login handler to show main window on success
- (void)handleOptimizedLogin:(id)sender
{
    NSLog(@"DEBUG: Optimized login button clicked");
    
    if (cachedPasswordField && cachedStatusLabel) {
        NSString *password = [cachedPasswordField stringValue];
        NSLog(@"DEBUG: Password entered, length: %lu", (unsigned long)[password length]);
        
        if ([password length] > 0) {
            [cachedStatusLabel setStringValue:@"Validating..."];
            [cachedStatusLabel setTextColor:[NSColor blueColor]];
            
            SudoManager *sudoManager = [SudoManager sharedManager];
            NSString *authError = nil;
            
            if ([sudoManager validateSudoWithPassword:password error:&authError]) {
                NSLog(@"DEBUG: Authentication successful - showing main window");
                [cachedStatusLabel setStringValue:@"Authentication successful!"];
                [cachedStatusLabel setTextColor:[NSColor greenColor]];
                
                // Close auth window and show main window after short delay
                [NSTimer scheduledTimerWithTimeInterval:1.0
                                               target:self
                                             selector:@selector(showMainWindowAfterAuth:)
                                             userInfo:nil
                                              repeats:NO];
                
                [self setupUpdateTimer];
                [self updateStatusText:@"Ready"];
                
            } else {
                NSLog(@"DEBUG: Authentication failed: %@", authError);
                [cachedStatusLabel setStringValue:authError ?: @"Authentication failed"];
                [cachedStatusLabel setTextColor:[NSColor redColor]];
                [cachedPasswordField setStringValue:@""];
                
                // Give user another chance - don't close the window
                [cachedPasswordField becomeFirstResponder];
            }
        } else {
            [cachedStatusLabel setStringValue:@"Please enter a password"];
            [cachedStatusLabel setTextColor:[NSColor redColor]];
        }
    }
}

- (void)closeOptimizedAuthWindow:(NSTimer *)timer
{
    if (cachedAuthWindow) {
        [cachedAuthWindow orderOut:nil];
    }
}

- (void)reauthenticateIfNeeded
{
    SudoManager *sudoManager = [SudoManager sharedManager];
    if ([sudoManager hasCachedSudoAccess]) {
        return;
    }
    [self showOptimizedAuthenticationPanel];
}

// Legacy compatibility methods
- (void)showNonModalPasswordPanel { [self showOptimizedAuthenticationPanel]; }
- (void)handleLogin:(id)sender { [self handleOptimizedLogin:sender]; }
- (void)closeAuthWindow:(NSTimer *)timer { [self closeOptimizedAuthWindow:timer]; }

#pragma mark - Window and UI Setup (Optimized)

- (void)setupMainWindow
{
    window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 1366, 768)
                                        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
    [window setTitle:@"GhostBSD App Store"];
    [window setMinSize:NSMakeSize(1366, 768)];
    [window setMaxSize:NSMakeSize(1366, 768)];
}

- (void)setupNavigationBar
{
    // NEW: Create buttons with autorelease pool for batch allocation
    NSAutoreleasePool *navPool = [[NSAutoreleasePool alloc] init];
    
    struct {
        NSRect featured;
        NSRect categories;
        NSRect updates;
        NSRect categoryLabel;
    } navFrames = {
        .featured = NSMakeRect(20, 700, 120, 30),
        .categories = NSMakeRect(150, 700, 120, 30),
        .updates = NSMakeRect(280, 700, 120, 30),
        .categoryLabel = NSMakeRect(20, 670, 400, 20)
    };
    
    featuredButton = [[NSButton alloc] initWithFrame:navFrames.featured];
    [featuredButton setTitle:@"Featured"];
    [featuredButton setBezelStyle:NSRoundedBezelStyle];
    [featuredButton setTarget:self];
    [featuredButton setAction:@selector(showFeatured:)];
    [[window contentView] addSubview:featuredButton];

    categoriesButton = [[NSButton alloc] initWithFrame:navFrames.categories];
    [categoriesButton setTitle:@"Categories"];
    [categoriesButton setBezelStyle:NSRoundedBezelStyle];
    [categoriesButton setTarget:self];
    [categoriesButton setAction:@selector(showCategories:)];
    [[window contentView] addSubview:categoriesButton];

    updatesButton = [[NSButton alloc] initWithFrame:navFrames.updates];
    [updatesButton setTitle:@"Updates"];
    [updatesButton setBezelStyle:NSRoundedBezelStyle];
    [updatesButton setTarget:self];
    [updatesButton setAction:@selector(showUpdates:)];
    [[window contentView] addSubview:updatesButton];
    
    categoryLabel = [[NSTextField alloc] initWithFrame:navFrames.categoryLabel];
    [categoryLabel setStringValue:@""];
    [categoryLabel setBezeled:NO];
    [categoryLabel setDrawsBackground:NO];
    [categoryLabel setEditable:NO];
    [categoryLabel setFont:[NSFont systemFontOfSize:12]];
    [categoryLabel setTextColor:[NSColor grayColor]];
    [[window contentView] addSubview:categoryLabel];
    
    [navPool release];
}

- (void)setupSearchField
{
    searchField = [[NSTextField alloc] initWithFrame:NSMakeRect(1150, 700, 200, 24)];
    [searchField setPlaceholderString:@"Search Apps"];
    [searchField setDelegate:self];
    [[searchField cell] setSendsActionOnEndEditing:NO];
    [searchField setTarget:self];
    [searchField setAction:@selector(searchPackages:)];
    [[window contentView] addSubview:searchField];
}

- (void)setupWelcomeMessage
{
    NSAutoreleasePool *welcomePool = [[NSAutoreleasePool alloc] init];
    
    NSTextField *welcomeTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(483, 450, 400, 40)];
    [welcomeTitle setStringValue:@"Welcome to the GhostBSD App Store"];
    [welcomeTitle setBezeled:NO];
    [welcomeTitle setDrawsBackground:NO];
    [welcomeTitle setEditable:NO];
    [welcomeTitle setFont:[NSFont boldSystemFontOfSize:18]];
    [welcomeTitle setTextColor:[NSColor blackColor]];
    [welcomeTitle setAlignment:NSCenterTextAlignment];
    [[window contentView] addSubview:welcomeTitle];
    
    NSTextField *welcomeSubtitle = [[NSTextField alloc] initWithFrame:NSMakeRect(433, 350, 500, 80)];
    [welcomeSubtitle setStringValue:@"Discover and install applications for your GhostBSD system.\n\n• Click Featured to browse popular applications\n• Use Categories to explore software by type\n• Search for specific packages using the search box"];
    [welcomeSubtitle setBezeled:NO];
    [welcomeSubtitle setDrawsBackground:NO];
    [welcomeSubtitle setEditable:NO];
    [welcomeSubtitle setFont:[NSFont systemFontOfSize:14]];
    [welcomeSubtitle setTextColor:[NSColor darkGrayColor]];
    [welcomeSubtitle setAlignment:NSCenterTextAlignment];
    
    NSTextFieldCell *subtitleCell = [welcomeSubtitle cell];
    [subtitleCell setWraps:YES];
    [subtitleCell setScrollable:NO];
    [[window contentView] addSubview:welcomeSubtitle];
    
    welcomeElements = [[NSMutableArray alloc] initWithObjects:welcomeTitle, welcomeSubtitle, nil];
    welcomeLabel = welcomeTitle;
    [welcomeTitle retain];
    [welcomeSubtitle release];
    
    [welcomePool release];
}

- (void)setupTableView
{
    scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 45, 1326, 595)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:NO];
    [scrollView setBorderType:NSBezelBorder];
    
    packageTable = [[NSTableView alloc] initWithFrame:[scrollView bounds]];
    [packageTable setAllowsMultipleSelection:NO];
    [packageTable setAllowsEmptySelection:YES];
    [packageTable setAllowsColumnSelection:NO];
    [packageTable setAllowsColumnReordering:NO];
    [packageTable setAllowsColumnResizing:YES];
    [packageTable setUsesAlternatingRowBackgroundColors:YES];
    [packageTable setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
    
    // Create columns
    NSTableColumn *iconColumn = [[NSTableColumn alloc] initWithIdentifier:@"icon"];
    [iconColumn setWidth:60];
    [iconColumn setTitle:@"Icon"];
    
    NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
    [nameColumn setWidth:200];
    [nameColumn setTitle:@"Name"];
    
    NSTableColumn *descColumn = [[NSTableColumn alloc] initWithIdentifier:@"desc"];
    [descColumn setWidth:800];
    [descColumn setTitle:@"Description"];
    
    NSTableColumn *installColumn = [[NSTableColumn alloc] initWithIdentifier:@"install"];
    [installColumn setWidth:100];
    [installColumn setTitle:@"Install"];
    
    NSTableColumn *uninstallColumn = [[NSTableColumn alloc] initWithIdentifier:@"uninstall"];
    [uninstallColumn setWidth:100];
    [uninstallColumn setTitle:@"Remove"];
    
    [packageTable addTableColumn:iconColumn];
    [packageTable addTableColumn:nameColumn];
    [packageTable addTableColumn:descColumn];
    [packageTable addTableColumn:installColumn];
    [packageTable addTableColumn:uninstallColumn];
    
    [iconColumn release];
    [nameColumn release];
    [descColumn release];
    [installColumn release];
    [uninstallColumn release];
    
    [packageTable setHeaderView:nil];
    [packageTable setDataSource:self];
    [packageTable setDelegate:self];
    [packageTable setDoubleAction:@selector(showDetails:)];
    
    [scrollView setDocumentView:packageTable];
    [scrollView setHidden:YES];
    [[window contentView] addSubview:scrollView];
}

- (void)setupProgressIndicators
{
    searchProgress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(1120, 700, 24, 24)];
    [searchProgress setStyle:NSProgressIndicatorSpinningStyle];
    [searchProgress setHidden:YES];
    [[window contentView] addSubview:searchProgress];

    updateProgress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(1000, 700, 100, 20)];
    [updateProgress setStyle:NSProgressIndicatorBarStyle];
    [updateProgress setMinValue:0];
    [updateProgress setMaxValue:100];
    [updateProgress setHidden:YES];
    [[window contentView] addSubview:updateProgress];

    updateStatus = [[NSTextField alloc] initWithFrame:NSMakeRect(850, 700, 120, 30)];
    [updateStatus setStringValue:@""];
    [updateStatus setBezeled:NO];
    [updateStatus setDrawsBackground:NO];
    [updateStatus setEditable:NO];
    [[window contentView] addSubview:updateStatus];
}

- (void)setupUpdateTimer
{
    updateCheckTimer = [NSTimer scheduledTimerWithTimeInterval:3600
                                                       target:self
                                                     selector:@selector(performUpdateCheck:)
                                                     userInfo:nil
                                                      repeats:YES];
}

#pragma mark - Navigation Actions

- (void)showFeatured:(id)sender
{
    [self showWelcomeMessage:NO];
    self.currentCategory = @"Featured";
    self.isSearchMode = NO;
    [self updateCategoryLabel:@"Featured Applications"];
    
    [self.packageManager getFeaturedPackagesWithCompletion:^(NSArray *packageList, NSString *errorMessage) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (packageList) {
                [self reloadPackageList:packageList];
            } else if (errorMessage) {
                [self showErrorMessage:errorMessage];
            }
        }];
    }];
}

- (void)showCategories:(id)sender
{
    [self showWelcomeMessage:NO];
    [self.categoryWindow showCategoryWindow];
}

- (void)showUpdates:(id)sender
{
    [self showWelcomeMessage:NO];
    self.currentCategory = @"Updates";
    self.isSearchMode = NO;
    [self updateCategoryLabel:@"Available Updates"];
    [updateProgress setHidden:NO];
    [updateProgress startAnimation:nil];
    
    [self.packageManager getAvailableUpdatesWithCompletion:^(NSArray *packageList, NSString *errorMessage) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [updateProgress stopAnimation:nil];
            [updateProgress setHidden:YES];
            
            if (packageList) {
                updatesAvailable = [packageList count] > 0;
                [self reloadPackageList:packageList];
                [self updateStatusText:updatesAvailable ? @"Updates Available" : @""];
            } else if (errorMessage) {
                [self showErrorMessage:errorMessage];
            }
        }];
    }];
}

#pragma mark - Search Functionality

- (void)searchPackages:(id)sender
{
    if (suggestionsMenu) {
        [suggestionsMenu removeFromSuperview];
        suggestionsMenu = nil;
    }
    if (searchTimer) {
        [searchTimer invalidate];
        searchTimer = nil;
    }
    searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                  target:self
                                                selector:@selector(performSearch:)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)performSearch:(NSTimer *)timer
{
    NSString *searchTerm = [[searchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([searchTerm length] == 0) {
        [self showWelcomeMessage:YES];
        return;
    }

    [self showWelcomeMessage:NO];
    self.isSearchMode = YES;
    [self updateCategoryLabel:[NSString stringWithFormat:@"Search Results for: %@", searchTerm]];
    [self showSearchProgress:YES];
    
    [self.packageManager searchPackagesWithTerm:searchTerm completion:^(NSArray *packageList, NSString *errorMessage) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showSearchProgress:NO];
            
            if (packageList) {
                [self reloadPackageList:packageList];
            } else if (errorMessage) {
                [self showErrorMessage:errorMessage];
            }
        }];
    }];
}

- (void)selectSuggestion:(id)sender
{
    [searchField setStringValue:[suggestionsMenu titleOfSelectedItem]];
    [self searchPackages:nil];
}

- (void)controlTextDidChange:(NSNotification *)notification
{
    if ([notification object] == searchField) {
        NSString *searchTerm = [[searchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([searchTerm length] == 0) {
            if (searchTimer) {
                [searchTimer invalidate];
                searchTimer = nil;
            }
            [self showWelcomeMessage:YES];
        }
    }
}

#pragma mark - Update Checking

- (void)performUpdateCheck:(NSTimer *)timer
{
    [self.packageManager checkForUpdatesWithCompletion:^(BOOL hasUpdates) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            updatesAvailable = hasUpdates;
            [self updateStatusText:updatesAvailable ? @"Updates Available" : @""];
        }];
    }];
}

#pragma mark - UI Updates

- (void)reloadPackageList:(NSArray *)packageList
{
    [packages removeAllObjects];
    
    for (id packageItem in packageList) {
        if ([packageItem isKindOfClass:[NSDictionary class]]) {
            [packages addObject:packageItem];
        } else if ([packageItem isKindOfClass:[Package class]]) {
            [packages addObject:[(Package *)packageItem toDictionary]];
        }
    }
    
    [packageTable reloadData];
}

- (void)showSearchProgress:(BOOL)show
{
    if (show) {
        [searchProgress setHidden:NO];
        [searchProgress startAnimation:nil];
    } else {
        [searchProgress stopAnimation:nil];
        [searchProgress setHidden:YES];
    }
}

- (void)updateStatusText:(NSString *)status
{
    [updateStatus setStringValue:status ?: @""];
}

- (void)updateCategoryLabel:(NSString *)categoryName
{
    [categoryLabel setStringValue:categoryName ?: @""];
}

- (void)showWelcomeMessage:(BOOL)show
{
    for (NSTextField *element in welcomeElements) {
        [element setHidden:!show];
    }
    [scrollView setHidden:show];
    
    if (show) {
        [self updateCategoryLabel:@""];
        [packages removeAllObjects];
        [packageTable reloadData];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [packages count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < 0 || row >= [packages count]) {
        return @"";
    }
    
    NSDictionary *package = [packages objectAtIndex:row];
    NSString *packageName = [package objectForKey:@"name"];
    NSString *columnId = [tableColumn identifier];
    
    if ([columnId isEqualToString:@"name"]) {
        if ([packageName hasPrefix:@"_HEADER_"] || [packageName hasPrefix:@"_CATEGORY_"]) {
            return @"";
        }
        return packageName;
    } else if ([columnId isEqualToString:@"desc"]) {
        return [package objectForKey:@"desc"];
    } else if ([columnId isEqualToString:@"install"]) {
        if ([packageName hasPrefix:@"_HEADER_"] || [packageName hasPrefix:@"_CATEGORY_"]) {
            return @"";
        }
        return [[package objectForKey:@"installed"] boolValue] ? @"Installed" : @"Install";
    } else if ([columnId isEqualToString:@"uninstall"]) {
        if ([packageName hasPrefix:@"_HEADER_"] || [packageName hasPrefix:@"_CATEGORY_"]) {
            return @"";
        }
        return [[package objectForKey:@"installed"] boolValue] ? @"Uninstall" : @"-";
    }
    
    return [package objectForKey:columnId];
}

- (void)showDetails:(id)sender
{
    NSInteger selectedRow = [packageTable selectedRow];
    if (selectedRow < 0 || selectedRow >= [packages count]) return;
    
    NSDictionary *packageDict = [packages objectAtIndex:selectedRow];
    NSString *packageName = [packageDict objectForKey:@"name"];
    
    if ([packageName hasPrefix:@"_HEADER_"] || [packageName hasPrefix:@"_CATEGORY_"]) {
        return;
    }
    
    Package *package = [Package packageFromDictionary:packageDict];
    [self.detailWindow showDetailsForPackage:package];
}

#pragma mark - Button Handlers

- (void)installButtonClicked:(id)sender
{
    NSInteger clickedRow = [packageTable clickedRow];
    if (clickedRow < 0 || clickedRow >= [packages count]) {
        return;
    }
    
    NSDictionary *packageDict = [packages objectAtIndex:clickedRow];
    NSString *packageName = [packageDict objectForKey:@"name"];
    
    if ([packageName hasPrefix:@"_HEADER_"] || [packageName hasPrefix:@"_CATEGORY_"]) {
        return;
    }
    
    NSString *cleanName = [self cleanPackageNameForInstallation:packageName];
    if ([cleanName length] == 0) {
        [self showErrorMessage:@"Invalid package name"];
        return;
    }
    
    Package *package = [Package packageFromDictionary:packageDict];
    package.name = cleanName;
    
    if (!package.installed) {
        [self requestInstallFor:package];
    }
}

- (void)uninstallButtonClicked:(id)sender
{
    NSInteger clickedRow = [packageTable clickedRow];
    if (clickedRow < 0 || clickedRow >= [packages count]) {
        return;
    }
    
    NSDictionary *packageDict = [packages objectAtIndex:clickedRow];
    NSString *packageName = [packageDict objectForKey:@"name"];
    
    if ([packageName hasPrefix:@"_HEADER_"] || [packageName hasPrefix:@"_CATEGORY_"]) {
        return;
    }
    
    NSString *cleanName = [self cleanPackageNameForInstallation:packageName];
    if ([cleanName length] == 0) {
        [self showErrorMessage:@"Invalid package name"];
        return;
    }
    
    Package *package = [Package packageFromDictionary:packageDict];
    package.name = cleanName;
    
    if (package.installed) {
        [self requestUninstallFor:package];
    }
}

#pragma mark - Package Operations

- (void)requestInstallFor:(Package *)package
{
    SudoManager *sudoManager = [SudoManager sharedManager];
    if (![sudoManager hasCachedSudoAccess]) {
        [self reauthenticateIfNeeded];
        return;
    }
    
    [self installPackageWithProgress:package detailWindow:nil];
}

- (void)requestUninstallFor:(Package *)package
{
    SudoManager *sudoManager = [SudoManager sharedManager];
    if (![sudoManager hasCachedSudoAccess]) {
        [self reauthenticateIfNeeded];
        return;
    }
    
    NSInteger result = NSRunAlertPanel(@"Confirm Uninstall", 
                                      [NSString stringWithFormat:@"Are you sure you want to uninstall %@?", package.name], 
                                      @"Uninstall", @"Cancel", nil);
    
    if (result == NSAlertDefaultReturn) {
        [self uninstallPackageWithProgress:package detailWindow:nil];
    }
}

- (void)installPackageWithProgress:(Package *)package detailWindow:(PackageDetailWindow *)detailWin
{
    if (detailWin) {
        [detailWin updateProgress:0];
    }
    
    [self.packageManager installPackageWithoutPassword:package.name
                                               progress:^(double progress, NSString *status) {
                                                   if ([NSThread isMainThread]) {
                                                       if (detailWin) {
                                                           [detailWin updateProgress:progress];
                                                       }
                                                   } else {
                                                       [detailWin performSelectorOnMainThread:@selector(updateProgress:) 
                                                                                    withObject:[NSNumber numberWithDouble:progress] 
                                                                                 waitUntilDone:NO];
                                                   }
                                               }
                                             completion:^(BOOL success, NSString *errorMessage) {
                                                 if ([NSThread isMainThread]) {
                                                     [self handleInstallCompletion:success 
                                                                              error:errorMessage 
                                                                            package:package 
                                                                       detailWindow:detailWin];
                                                 } else {
                                                     NSDictionary *info = @{
                                                         @"success": [NSNumber numberWithBool:success],
                                                         @"error": errorMessage ?: @"",
                                                         @"package": package,
                                                         @"detailWindow": detailWin ?: [NSNull null]
                                                     };
                                                     [self performSelectorOnMainThread:@selector(handleInstallCompletionFromDict:) 
                                                                            withObject:info 
                                                                         waitUntilDone:NO];
                                                 }
                                             }];
}

- (void)uninstallPackageWithProgress:(Package *)package detailWindow:(PackageDetailWindow *)detailWin
{
    if (detailWin) {
        [detailWin updateProgress:0];
    }
    
    [self.packageManager uninstallPackageWithoutPassword:package.name
                                                 progress:^(double progress, NSString *status) {
                                                     if ([NSThread isMainThread]) {
                                                         if (detailWin) {
                                                             [detailWin updateProgress:progress];
                                                         }
                                                     } else {
                                                         [detailWin performSelectorOnMainThread:@selector(updateProgress:) 
                                                                                      withObject:[NSNumber numberWithDouble:progress] 
                                                                                   waitUntilDone:NO];
                                                     }
                                                 }
                                               completion:^(BOOL success, NSString *errorMessage) {
                                                   if ([NSThread isMainThread]) {
                                                       [self handleUninstallCompletion:success 
                                                                                  error:errorMessage 
                                                                                package:package 
                                                                           detailWindow:detailWin];
                                                   } else {
                                                       NSDictionary *info = @{
                                                           @"success": [NSNumber numberWithBool:success],
                                                           @"error": errorMessage ?: @"",
                                                           @"package": package,
                                                           @"detailWindow": detailWin ?: [NSNull null]
                                                       };
                                                       [self performSelectorOnMainThread:@selector(handleUninstallCompletionFromDict:) 
                                                                              withObject:info 
                                                                           waitUntilDone:NO];
                                                   }
                                               }];
}

- (void)handleInstallCompletion:(BOOL)success 
                          error:(NSString *)errorMessage 
                        package:(Package *)package 
                   detailWindow:(PackageDetailWindow *)packageDetailWin
{
    [self showInstallProgress:NO withMessage:nil];
    
    if (success) {
        [self showSuccessMessage:[NSString stringWithFormat:@"Successfully installed %@", package.name]];
        package.installed = YES;
        [self updatePackageInTable:package];
        
        if (packageDetailWin) {
            [packageDetailWin refreshPackageState];
            [packageDetailWin hideProgress];
        }
    } else {
        [self showErrorMessage:errorMessage ?: @"Installation failed"];
        if (packageDetailWin) {
            [packageDetailWin hideProgress];
        }
    }
}

- (void)handleUninstallCompletion:(BOOL)success 
                            error:(NSString *)errorMessage 
                          package:(Package *)package 
                     detailWindow:(PackageDetailWindow *)packageDetailWin
{
    [self showInstallProgress:NO withMessage:nil];
    
    if (success) {
        [self showSuccessMessage:[NSString stringWithFormat:@"Successfully uninstalled %@", package.name]];
        package.installed = NO;
        [self updatePackageInTable:package];
        
        if (packageDetailWin) {
            [packageDetailWin refreshPackageState];
            [packageDetailWin hideProgress];
        }
    } else {
        [self showErrorMessage:errorMessage ?: @"Uninstallation failed"];
        if (packageDetailWin) {
            [packageDetailWin hideProgress];
        }
    }
}

- (void)handleInstallCompletionFromDict:(NSDictionary *)info
{
    BOOL success = [[info objectForKey:@"success"] boolValue];
    NSString *errorMessage = [info objectForKey:@"error"];
    Package *package = [info objectForKey:@"package"];
    PackageDetailWindow *packageDetailWin = [info objectForKey:@"detailWindow"];
    
    if ([packageDetailWin isKindOfClass:[NSNull class]]) {
        packageDetailWin = nil;
    }
    
    [self handleInstallCompletion:success 
                            error:errorMessage 
                          package:package 
                     detailWindow:packageDetailWin];
}

- (void)handleUninstallCompletionFromDict:(NSDictionary *)info
{
    BOOL success = [[info objectForKey:@"success"] boolValue];
    NSString *errorMessage = [info objectForKey:@"error"];
    Package *package = [info objectForKey:@"package"];
    PackageDetailWindow *packageDetailWin = [info objectForKey:@"detailWindow"];
    
    if ([packageDetailWin isKindOfClass:[NSNull class]]) {
        packageDetailWin = nil;
    }
    
    [self handleUninstallCompletion:success 
                              error:errorMessage 
                            package:package 
                       detailWindow:packageDetailWin];
}

- (void)updatePackageInTable:(Package *)package
{
    for (NSInteger i = 0; i < [packages count]; i++) {
        NSDictionary *packageDict = [packages objectAtIndex:i];
        if ([[packageDict objectForKey:@"name"] isEqualToString:package.name]) {
            NSMutableDictionary *mutableDict = [packageDict mutableCopy];
            [mutableDict setObject:[NSNumber numberWithBool:package.installed] forKey:@"installed"];
            [packages replaceObjectAtIndex:i withObject:mutableDict];
            [mutableDict release];
            
            [packageTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:i] 
                                    columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[packageTable tableColumns] count])]];
            break;
        }
    }
}

#pragma mark - Alert Methods

- (void)showSuccessMessage:(NSString *)message
{
    if ([NSThread isMainThread]) {
        NSRunAlertPanel(@"Success", message, @"OK", nil, nil);
    } else {
        [self performSelectorOnMainThread:@selector(showSuccessMessageOnMainThread:) 
                               withObject:message 
                            waitUntilDone:NO];
    }
}

- (void)showErrorMessage:(NSString *)message
{
    if ([NSThread isMainThread]) {
        NSRunAlertPanel(@"Error", message, @"OK", nil, nil);
    } else {
        [self performSelectorOnMainThread:@selector(showErrorMessageOnMainThread:) 
                               withObject:message 
                            waitUntilDone:NO];
    }
}

- (void)showSuccessMessageOnMainThread:(NSString *)message
{
    [NSTimer scheduledTimerWithTimeInterval:0.01
                                     target:self
                                   selector:@selector(displaySuccessAlert:)
                                   userInfo:@{@"message": message}
                                    repeats:NO];
}

- (void)showErrorMessageOnMainThread:(NSString *)message
{
    [NSTimer scheduledTimerWithTimeInterval:0.01
                                     target:self
                                   selector:@selector(displayErrorAlert:)
                                   userInfo:@{@"message": message}
                                    repeats:NO];
}

- (void)displaySuccessAlert:(NSTimer *)timer
{
    NSString *message = [[timer userInfo] objectForKey:@"message"];
    NSRunAlertPanel(@"Success", message, @"OK", nil, nil);
}

- (void)displayErrorAlert:(NSTimer *)timer
{
    NSString *message = [[timer userInfo] objectForKey:@"message"];
    NSRunAlertPanel(@"Error", message, @"OK", nil, nil);
}

- (void)showConfirmationDialog:(NSString *)title 
                       message:(NSString *)message 
                    completion:(void (^)(BOOL confirmed))completion
{
    [self performBlockOnMainThread:^{
        NSInteger result = NSRunAlertPanel(title, message, @"Yes", @"No", nil);
        if (completion) {
            completion(result == NSAlertDefaultReturn);
        }
    }];
}

#pragma mark - Package Detail Window Delegate

- (void)packageDetailWindow:(PackageDetailWindow *)detailWin requestInstallFor:(Package *)package
{
    [self requestInstallFor:package];
}

- (void)packageDetailWindow:(PackageDetailWindow *)detailWin requestUninstallFor:(Package *)package
{
    [self requestUninstallFor:package];
}

#pragma mark - Category Window Delegate

- (void)categoryWindow:(CategoryWindow *)catWindow didSelectCategory:(NSString *)category
{
    [self showWelcomeMessage:NO];
    
    self.currentCategory = category;
    self.isSearchMode = NO;
    
    NSString *displayName = [self displayNameForCategory:category];
    [self updateCategoryLabel:[NSString stringWithFormat:@"Category: %@", displayName]];
    
    [self showSearchProgress:YES];
    
    [self.packageManager getPackagesByCategory:category completion:^(NSArray *packageList, NSString *errorMessage) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showSearchProgress:NO];
            
            if (packageList) {
                [self reloadPackageList:packageList];
                
                if ([packageList count] == 0) {
                    [self showErrorMessage:[NSString stringWithFormat:@"No packages found in the %@ category.", displayName]];
                }
            } else if (errorMessage) {
                [self showErrorMessage:errorMessage];
            }
        }];
    }];
}

- (NSString *)displayNameForCategory:(NSString *)category
{
    static NSDictionary *categoryMap = nil;
    if (!categoryMap) {
        categoryMap = [@{
            @"multimedia": @"Multimedia",
            @"www": @"Web Browsers", 
            @"editors": @"Text Editors",
            @"graphics": @"Graphics",
            @"games": @"Games",
            @"devel": @"Development",
            @"sysutils": @"System Utilities",
            @"security": @"Security",
            @"net": @"Network",
            @"math": @"Mathematics",
            @"science": @"Science",
            @"databases": @"Databases",
            @"archivers": @"Archivers",
            @"emulators": @"Emulators",
            @"finance": @"Finance",
            @"ftp": @"FTP",
            @"irc": @"Chat/IRC",
            @"mail": @"Email",
            @"news": @"News",
            @"print": @"Printing"
        } retain];
    }
    
    return [categoryMap objectForKey:category] ?: [category capitalizedString];
}

#pragma mark - Placeholder Methods

- (void)performIntelligentTableUpdate { [packageTable reloadData]; }
- (void)queueRowUpdateForIndex:(NSInteger)rowIndex { /* placeholder */ }
- (void)processPendingRowUpdates:(NSTimer *)timer { /* placeholder */ }
- (void)contextMenuInstall:(id)sender { /* placeholder */ }
- (void)contextMenuUninstall:(id)sender { /* placeholder */ }
- (void)contextMenuShowDetails:(id)sender { /* placeholder */ }
- (void)showAuthenticationRequiredAlert { [self showErrorMessage:@"Authentication required"]; }
- (void)showInstallProgress:(BOOL)show withMessage:(NSString *)message { /* placeholder */ }
- (void)updateInstallStatus:(NSString *)status { /* placeholder */ }
- (void)handleInstallResult:(BOOL)success error:(NSString *)errorMessage package:(Package *)package { /* placeholder */ }
- (void)handleUninstallResult:(BOOL)success error:(NSString *)errorMessage package:(Package *)package { /* placeholder */ }
- (void)setupStatusBar { /* placeholder */ }

#pragma mark - Memory Management

- (void)dealloc
{
    [installedPackages release];
    [currentCategory release];
    [rowUpdateQueue release];
    if (updateCoalescingTimer) {
        [updateCoalescingTimer invalidate];
    }
    
    if (cachedAuthWindow) {
        [cachedAuthWindow release];
        cachedAuthWindow = nil;
    }
    if (cachedPasswordField) {
        [cachedPasswordField release];
        cachedPasswordField = nil;
    }
    if (cachedStatusLabel) {
        [cachedStatusLabel release];
        cachedStatusLabel = nil;
    }
    
    [window release];
    [featuredButton release];
    [categoriesButton release];
    [updatesButton release];
    [searchField release];
    [suggestionsMenu release];
    [packageTable release];
    [scrollView release];
    [searchProgress release];
    [updateProgress release];
    [packages release];
    [searchTimer release];
    [updateCheckTimer release];
    [updateStatus release];
    [categoryLabel release];
    [welcomeLabel release];
    [welcomeElements release];
    [headerElements release];
    [packageManager release];
    [passwordPanel release];
    [detailWindow release];
    [categoryWindow release];
    [super dealloc];
}

@end
