#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>

@interface CoderObject : NSObject <NSCoding> {
    NSString *mString;
    NSNumber *mNumber;
    NSData *mData;
    int count;
    int *intp;
    char *cString;
    char chr;
    long lnum;
    long *lptr;
    double dnum;
    float fnum;
}
@property (copy,nonatomic) NSString *string;
@property (copy,nonatomic) NSNumber *number;
@property (copy,nonatomic) NSData *data;
@end

@implementation CoderObject
-(NSString*) description
{
    return [NSString stringWithFormat:@"<%@ %p>: %@, %@, %@", [self className], self, mString, mNumber, mData];
}

@synthesize string=mString;
@synthesize number=mNumber;
@synthesize data=mData;

id getObjectForType(char *type, id inObj)
{
    switch (*type) {
        case '@':
            outObj = curObject;
            break;
        case '*':
            // treat all pointers as char *. This is the best we can do
            return [NSString stringWithUTF8String:(char*)inObj];
            break;
        case '^':
            // follow all pointers. probably not the best idea, but hey, what else can we do?
            return getObjectForType(*(type+1), *inObj);
            break;
        case 'i':
            return [NSNumber numberWithInt:(int)inObj];
            break;
        case 'l':
            return [NSNumber numberWithLong:(long)inObj];
            break;
        case 'd':
            return [NSNumber numberWithDouble:(double)inObj];
            break;
        case 'f':
            return [NSNumber numberWithFloat:(float)inObj];
            break;
        case 'c':
            return [NSNumber numberWithChar:(char)inObj];
            break;
        default:
            NSLog(@"unknown data type passed to getObjectForType");
            return curObject;
            break;
    }
    return nil;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    Ivar *ivarList;
    unsigned int ivarCount;
    ivarList = class_copyIvarList([self class], &ivarCount);
    int ii;
    for (ii = 0; ii < ivarCount; ii++) {
        Ivar curIvar = *(ivarList + ii);
        id curObject = object_getIvar(self, curIvar);
        id objectToEncode = nil;
        NSString *ivarKey = [NSString stringWithFormat:@"%sKey", ivar_getName(curIvar)];
        const char *type = ivar_getTypeEncoding(curIvar);

        [coder encodeObject:objectToEncode forKey:ivarKey];
    }
}

- (id) initWithCoder:(NSCoder *)coder
{
    if ((self = [super init])) {
        Ivar *ivarList;
        unsigned int ivarCount;
        ivarList = class_copyIvarList([self class], &ivarCount);
        int ii;
        for (ii = 0; ii < ivarCount; ii++) {
            Ivar curIvar = *(ivarList + ii);
            NSString *ivarKey = [NSString stringWithFormat:@"%sKey", ivar_getName(curIvar)];
            id curObject = [coder decodeObjectForKey:ivarKey];
            if (curObject) {
                [(id)curObject retain];
                object_setIvar(self, curIvar, (id)curObject);
            }
        }
    }
    return self;
}
@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    CoderObject *coder = [[CoderObject alloc] init];
    coder.string = @"Blah blah blah";
    coder.number = [NSNumber numberWithInt:42];
    coder.data = [NSData data];
    NSLog(@"Coder: %@", coder);
    NSData *coderData = [NSKeyedArchiver archivedDataWithRootObject:coder];
    [coder release];
    
    CoderObject *coder2 = [NSKeyedUnarchiver unarchiveObjectWithData:coderData];
    NSLog(@"Coder 2: %@", coder2);
    
    
    [pool drain];
    return 0;
}
