#import "Package.h"

@implementation Package

@synthesize name, packageDescription, iconPath, installed, category, version;

- (id)initWithName:(NSString *)packageName 
       description:(NSString *)description 
          iconPath:(NSString *)icon 
         installed:(BOOL)isInstalled
{
    self = [super init];
    if (self) {
        // FIXED: Clean the package name to remove any description contamination
        self.name = [self cleanPackageName:packageName];
        self.packageDescription = description;
        self.iconPath = icon;
        self.installed = isInstalled;
    }
    return self;
}

// NEW: Method to clean package names
- (NSString *)cleanPackageName:(NSString *)rawName
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
        // Additional validation - package names shouldn't contain spaces
        if ([firstName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location == NSNotFound) {
            return firstName;
        }
    }
    
    return cleaned;
}

- (NSDictionary *)toDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.name ?: @"", @"name",
            self.packageDescription ?: @"", @"desc",
            self.iconPath ?: @"", @"icon",
            [NSNumber numberWithBool:self.installed], @"installed",
            nil];
}

+ (Package *)packageFromDictionary:(NSDictionary *)dict
{
    Package *package = [[Package alloc] init];
    
    // FIXED: Ensure clean package name from dictionary
    NSString *rawName = [dict objectForKey:@"name"];
    package.name = [package cleanPackageName:rawName];
    package.packageDescription = [dict objectForKey:@"desc"];
    package.iconPath = [dict objectForKey:@"icon"];
    package.installed = [[dict objectForKey:@"installed"] boolValue];
    return [package autorelease];
}

- (void)dealloc
{
    [name release];
    [packageDescription release];
    [iconPath release];
    [category release];
    [version release];
    [super dealloc];
}

@end
