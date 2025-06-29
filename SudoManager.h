#import <Foundation/Foundation.h>

@interface SudoManager : NSObject

+ (SudoManager *)sharedManager;

// Validate and cache sudo credentials
- (BOOL)validateSudoWithPassword:(NSString *)password error:(NSString **)error;

// Check if we have valid cached sudo credentials
- (BOOL)hasCachedSudoAccess;

// Execute a command with sudo (using cached credentials)
- (BOOL)executeSudoCommand:(NSArray *)arguments 
                    output:(NSString **)output 
                     error:(NSString **)error;

// Clear cached sudo credentials
- (void)clearSudoCache;

// Get time remaining for sudo session (in seconds)
- (NSTimeInterval)timeRemaining;

@end
