#import <AppKit/AppKit.h>
#import "NetworkManager.h"

typedef NS_ENUM(NSInteger, ErrorRecoveryType) {
    ErrorRecoveryTypeNetwork = 0,
    ErrorRecoveryTypeRepository,
    ErrorRecoveryTypeAuthentication,
    ErrorRecoveryTypePackage,
    ErrorRecoveryTypeGeneric
};

typedef void (^ErrorRecoveryCompletion)(BOOL shouldRetry, BOOL shouldChangeSettings);

@interface ErrorRecoveryPanel : NSObject

@property (nonatomic, retain) NSPanel *panel;
@property (nonatomic, retain) NSTextField *titleLabel;
@property (nonatomic, retain) NSTextField *descriptionLabel;
@property (nonatomic, retain) NSTextField *technicalDetailsLabel;
@property (nonatomic, retain) NSButton *retryButton;
@property (nonatomic, retain) NSButton *settingsButton;
@property (nonatomic, retain) NSButton *cancelButton;
@property (nonatomic, retain) NSButton *diagnosticsButton;
@property (nonatomic, retain) NSProgressIndicator *recoveryProgress;
@property (nonatomic, retain) NSTextField *recoveryStatusLabel;
@property (nonatomic, copy) ErrorRecoveryCompletion completion;

// Show error recovery panel
- (void)showErrorRecoveryForType:(ErrorRecoveryType)errorType
                           title:(NSString *)title
                         message:(NSString *)message
                technicalDetails:(NSString *)technicalDetails
                      completion:(ErrorRecoveryCompletion)completion;

// Automated recovery attempts
- (void)attemptAutomaticRecovery:(ErrorRecoveryType)errorType;

// Diagnostic tools
- (void)runNetworkDiagnostics:(void (^)(NSString *diagnosticResults))completion;
- (void)runRepositoryDiagnostics:(void (^)(NSString *diagnosticResults))completion;

// Recovery suggestions
- (NSArray *)getRecoverySuggestionsForType:(ErrorRecoveryType)errorType error:(NSString *)errorMessage;

@end
