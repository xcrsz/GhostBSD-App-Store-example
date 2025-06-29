#import "PackageDetailWindow.h"
#import "Package.h"
#import "PackageManager.h"

@implementation PackageDetailWindow

@synthesize window, progressIndicator, descriptionField, package, delegate;

- (void)showDetailsForPackage:(Package *)pkg
{
    self.package = pkg;
    
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(200, 200, 400, 300)
                                            styleMask:NSTitledWindowMask | NSClosableWindowMask
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
    [self.window setTitle:pkg.name];
    
    // Icon
    NSImageView *iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(20, 200, 64, 64)];
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:pkg.iconPath];
    [iconView setImage:icon ?: [NSImage imageNamed:@"NSApplicationIcon"]];
    [[self.window contentView] addSubview:iconView];
    
    // Package name
    NSTextField *nameLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(90, 240, 290, 24)];
    [nameLabel setStringValue:pkg.name];
    [nameLabel setBezeled:NO];
    [nameLabel setDrawsBackground:NO];
    [nameLabel setFont:[NSFont boldSystemFontOfSize:16]];
    [[self.window contentView] addSubview:nameLabel];
    
    // Description field
    self.descriptionField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 60, 360, 130)];
    [self.descriptionField setStringValue:@"Loading description..."];
    [self.descriptionField setBezeled:NO];
    [self.descriptionField setDrawsBackground:NO];
    [[self.window contentView] addSubview:self.descriptionField];
    
    // Progress indicator
    self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 30, 240, 20)];
    [self.progressIndicator setStyle:NSProgressIndicatorBarStyle];
    [self.progressIndicator setMinValue:0];
    [self.progressIndicator setMaxValue:100];
    [self.progressIndicator setHidden:YES];
    [[self.window contentView] addSubview:self.progressIndicator];
    
    // Install button
    NSButton *installButton = [[NSButton alloc] initWithFrame:NSMakeRect(280, 20, 100, 30)];
    [installButton setTitle:pkg.installed ? @"Uninstall" : @"Install"];
    [installButton setBezelStyle:NSRoundedBezelStyle];
    [installButton setTarget:self];
    [installButton setAction:pkg.installed ? @selector(uninstallClicked:) : @selector(installClicked:)];
    [[self.window contentView] addSubview:installButton];
    
    // FIXED: Load package description with proper main thread UI updates
    [[PackageManager sharedManager] getPackageInfo:pkg.name completion:^(NSString *info, NSString *errorMessage) {
        // FIXED: Ensure UI updates happen on main thread
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (info) {
                [self.descriptionField setStringValue:pkg.packageDescription ?: info];
            } else {
                [self.descriptionField setStringValue:errorMessage ?: @"Package details not available."];
            }
        }];
    }];
    
    [self.window makeKeyAndOrderFront:nil];
    
    [iconView release];
    [icon release];
    [nameLabel release];
    [installButton release];
}

- (void)installClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(packageDetailWindow:requestInstallFor:)]) {
        [self.delegate packageDetailWindow:self requestInstallFor:self.package];
    }
}

- (void)uninstallClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(packageDetailWindow:requestUninstallFor:)]) {
        [self.delegate packageDetailWindow:self requestUninstallFor:self.package];
    }
}

- (void)updateProgress:(double)progress
{
    // FIXED: Ensure progress updates happen on main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator setHidden:NO];
        [self.progressIndicator setDoubleValue:progress];
    }];
}

- (void)hideProgress
{
    // FIXED: Ensure UI updates happen on main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator setHidden:YES];
    }];
}

- (void)refreshPackageState
{
    // FIXED: Ensure UI updates happen on main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        // Find and update the install/uninstall button based on current package state
        if (!self.window || !self.package) {
            return;
        }
        
        // Find the install/uninstall button in the window
        NSArray *subviews = [[self.window contentView] subviews];
        for (NSView *view in subviews) {
            if ([view isKindOfClass:[NSButton class]]) {
                NSButton *button = (NSButton *)view;
                NSString *currentTitle = [button title];
                
                // Check if this is our install/uninstall button
                if ([currentTitle isEqualToString:@"Install"] || 
                    [currentTitle isEqualToString:@"Uninstall"] ||
                    [currentTitle isEqualToString:@"Installed"]) {
                    
                    // Update button based on package state
                    if (self.package.installed) {
                        [button setTitle:@"Uninstall"];
                        [button setAction:@selector(uninstallClicked:)];
                    } else {
                        [button setTitle:@"Install"];
                        [button setAction:@selector(installClicked:)];
                    }
                    break;
                }
            }
        }
        
        NSLog(@"DEBUG: Package state refreshed for %@ (installed: %@)", 
              self.package.name, self.package.installed ? @"YES" : @"NO");
    }];
}

- (void)dealloc
{
    [window release];
    [progressIndicator release];
    [descriptionField release];
    [package release];
    [super dealloc];
}

@end
