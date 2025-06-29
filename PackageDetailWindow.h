#import <AppKit/AppKit.h>

@class Package;

@protocol PackageDetailWindowDelegate;

@interface PackageDetailWindow : NSObject

@property (nonatomic, retain) NSWindow *window;
@property (nonatomic, retain) NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) NSTextField *descriptionField;
@property (nonatomic, retain) Package *package;
@property (nonatomic, assign) id<PackageDetailWindowDelegate> delegate;

- (void)showDetailsForPackage:(Package *)package;
- (void)updateProgress:(double)progress;
- (void)hideProgress;
- (void)refreshPackageState;

@end

@protocol PackageDetailWindowDelegate <NSObject>

- (void)packageDetailWindow:(PackageDetailWindow *)window 
         requestInstallFor:(Package *)package;

- (void)packageDetailWindow:(PackageDetailWindow *)window 
       requestUninstallFor:(Package *)package;

@end
