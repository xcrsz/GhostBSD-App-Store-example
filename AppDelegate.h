#import <AppKit/AppKit.h>
#import "PackageDetailWindow.h"
#import "CategoryWindow.h"
#import "NetworkManager.h"
#import "ErrorRecoveryPanel.h"
#import "ConfigurationManager.h"

@class Package;
@class PackageManager;
@class PasswordPanel;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, PackageDetailWindowDelegate, CategoryWindowDelegate>
{
    NSWindow *window;
    NSButton *featuredButton;
    NSButton *categoriesButton;
    NSButton *updatesButton;
    NSTextField *searchField;
    NSPopUpButton *suggestionsMenu;
    NSTableView *packageTable;
    NSScrollView *scrollView;
    NSProgressIndicator *searchProgress;
    NSProgressIndicator *updateProgress;
    NSMutableArray *packages;
    NSTimer *searchTimer;
    NSTimer *updateCheckTimer;
    BOOL updatesAvailable;
    NSTextField *updateStatus;
    NSTextField *categoryLabel;
    NSTextField *welcomeLabel;
    NSMutableArray *welcomeElements;
    NSMutableArray *headerElements;
}

@property (nonatomic, retain) NSWindow *window;
@property (nonatomic, retain) PackageManager *packageManager;
@property (nonatomic, retain) PasswordPanel *passwordPanel;
@property (nonatomic, retain) PackageDetailWindow *detailWindow;
@property (nonatomic, retain) CategoryWindow *categoryWindow;

// NEW: Cached objects and state for efficiency
@property (nonatomic, retain) NSMutableSet *installedPackages;
@property (nonatomic, retain) NSString *currentCategory;
@property (nonatomic, assign) BOOL isSearchMode;
@property (nonatomic, retain) NSMutableDictionary *rowUpdateQueue;
@property (nonatomic, retain) NSTimer *updateCoalescingTimer;

// Lifecycle
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

// Navigation actions
- (void)showFeatured:(id)sender;
- (void)showCategories:(id)sender;
- (void)showUpdates:(id)sender;

// Search functionality
- (void)searchPackages:(id)sender;
- (void)performSearch:(NSTimer *)timer;
- (void)selectSuggestion:(id)sender;

// Update checking
- (void)performUpdateCheck:(NSTimer *)timer;

// UI updates
- (void)reloadPackageList:(NSArray *)packageList;
- (void)showSearchProgress:(BOOL)show;
- (void)updateStatusText:(NSString *)status;
- (void)updateCategoryLabel:(NSString *)categoryName;
- (void)showWelcomeMessage:(BOOL)show;

// Authentication
- (void)reauthenticateIfNeeded;
- (void)showNonModalPasswordPanel;
- (void)handleLogin:(id)sender;
- (void)closeAuthWindow:(NSTimer *)timer;

// Package operation helpers
- (void)showAuthenticationRequiredAlert;
- (void)showInstallProgress:(BOOL)show withMessage:(NSString *)message;
- (void)updateInstallStatus:(NSString *)status;
- (void)handleInstallResult:(BOOL)success error:(NSString *)errorMessage package:(Package *)package;
- (void)handleUninstallResult:(BOOL)success error:(NSString *)errorMessage package:(Package *)package;

// Context menu actions
- (void)contextMenuInstall:(id)sender;
- (void)contextMenuUninstall:(id)sender;
- (void)contextMenuShowDetails:(id)sender;

// Button click handlers for install/uninstall columns
- (void)installButtonClicked:(id)sender;
- (void)uninstallButtonClicked:(id)sender;

// NEW: Package Operations with Network Recovery
- (void)installPackageWithProgress:(Package *)package detailWindow:(PackageDetailWindow *)detailWindow;
- (void)uninstallPackageWithProgress:(Package *)package detailWindow:(PackageDetailWindow *)detailWindow;
- (void)handleInstallCompletion:(BOOL)success 
                          error:(NSString *)errorMessage 
                        package:(Package *)package 
                   detailWindow:(PackageDetailWindow *)detailWindow;
- (void)handleUninstallCompletion:(BOOL)success 
                            error:(NSString *)errorMessage 
                          package:(Package *)package 
                     detailWindow:(PackageDetailWindow *)detailWindow;
- (void)handleInstallCompletionFromDict:(NSDictionary *)info;
- (void)handleUninstallCompletionFromDict:(NSDictionary *)info;

// NEW: Thread-safe utility methods (GNUstep compatible)
- (void)performOnMainThread:(SEL)selector withObject:(id)object;
- (void)performBlockOnMainThread:(void (^)(void))block;

// NEW: Thread-safe alert methods
- (void)showSuccessMessage:(NSString *)message;
- (void)showErrorMessage:(NSString *)message;
- (void)showConfirmationDialog:(NSString *)title 
                       message:(NSString *)message 
                    completion:(void (^)(BOOL confirmed))completion;

// NEW: Package name cleaning
- (NSString *)cleanPackageNameForInstallation:(NSString *)rawName;

// NEW: GNUstep-compatible threading helpers
- (void)executeBlockOnMainThread:(void (^)(void))block;
- (void)showSuccessMessageOnMainThread:(NSString *)message;
- (void)showErrorMessageOnMainThread:(NSString *)message;
- (void)displaySuccessAlert:(NSTimer *)timer;
- (void)displayErrorAlert:(NSTimer *)timer;

// NEW: Package table updates
- (void)updatePackageInTable:(Package *)package;
- (void)performIntelligentTableUpdate;
- (void)queueRowUpdateForIndex:(NSInteger)rowIndex;
- (void)processPendingRowUpdates:(NSTimer *)timer;

// Simplified package actions
- (void)requestInstallFor:(Package *)package;
- (void)requestUninstallFor:(Package *)package;

// UI setup
- (void)setupStatusBar;

@end
