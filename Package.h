#import <Foundation/Foundation.h>

@interface Package : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *packageDescription;
@property (nonatomic, retain) NSString *iconPath;
@property (nonatomic, assign) BOOL installed;
@property (nonatomic, retain) NSString *category;
@property (nonatomic, retain) NSString *version;

- (id)initWithName:(NSString *)name 
       description:(NSString *)description 
          iconPath:(NSString *)iconPath 
         installed:(BOOL)installed;

- (NSDictionary *)toDictionary;
+ (Package *)packageFromDictionary:(NSDictionary *)dict;

// NEW: Package name cleaning method
- (NSString *)cleanPackageName:(NSString *)rawName;

@end
