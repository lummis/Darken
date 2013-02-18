

#import "CCArray+Replace.h"

@implementation CCArray (Replace)

/***
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
        //[data->arr[index] release];
    data->arr[index] = anObject;
    
}
 ***/

-(void) replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
	[self removeObjectAtIndex:index];
	[self insertObject:anObject atIndex:index];
}

@end