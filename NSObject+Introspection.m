////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///
///		NSObject+Introspection.m
///
///		Easy runtime introspection of objects.
///		
///		Copyright (c) 2012 Kevin Ross. All rights reserved.
///
///		Mutator:		Mutated:		Mutation:
///		--------		--------		---------
///		Kross			10.19.11		Initial Version
///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#import "NSObject+Introspection.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Pointer Testing
///	http://cocoawithlove.com/2010/10/testing-if-arbitrary-pointer-is-valid.html
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static sigjmp_buf sigjmp_env;

void
PointerReadFailedHandler(int signum)
{
    siglongjmp (sigjmp_env, 1);
}

BOOL 
KRIsPointerAnObject(const void *testPointer, 
					BOOL *allocatedLargeEnough)
{
    *allocatedLargeEnough = NO;
	
    // Set up SIGSEGV and SIGBUS handlers
    struct sigaction new_segv_action, old_segv_action;
    struct sigaction new_bus_action, old_bus_action;
    new_segv_action.sa_handler = PointerReadFailedHandler;
    new_bus_action.sa_handler = PointerReadFailedHandler;
    sigemptyset(&new_segv_action.sa_mask);
    sigemptyset(&new_bus_action.sa_mask);
    new_segv_action.sa_flags = 0;
    new_bus_action.sa_flags = 0;
    sigaction (SIGSEGV, &new_segv_action, &old_segv_action);
    sigaction (SIGBUS, &new_bus_action, &old_bus_action);
	
    // The signal handler will return us to here if a signal is raised
    if (sigsetjmp(sigjmp_env, 1))
    {
        sigaction (SIGSEGV, &old_segv_action, NULL);
        sigaction (SIGBUS, &old_bus_action, NULL);
        return NO;
    }
	
    Class testPointerClass = *((Class *)testPointer);
	
    // Get the list of classes and look for testPointerClass
    BOOL isClass = NO;
    NSInteger numClasses = objc_getClassList(NULL, 0);
    Class *classesList = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classesList, (int)numClasses);
    for (int i = 0; i < numClasses; i++)
    {
        if (classesList[i] == testPointerClass)
        {
            isClass = YES;
            break;
        }
    }
    free(classesList);
	
    // We're done with the signal handlers (install the previous ones)
    sigaction (SIGSEGV, &old_segv_action, NULL);
    sigaction (SIGBUS, &old_bus_action, NULL);
	
    // Pointer does not point to a valid isa pointer
    if (!isClass)
    {
        return NO;
    }
	
    // Check the allocation size
    size_t allocated_size = malloc_size(testPointer);
    size_t instance_size = class_getInstanceSize(testPointerClass);
    if (allocated_size > instance_size)
    {
        *allocatedLargeEnough = YES;
    }
	
    return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




@implementation NSObject (Introspection)

- (NSArray *)___objectIvars;
{
	NSMutableArray *array = [NSMutableArray array];
	
	unsigned int ivarCount = 0;
	Ivar * ivars = class_copyIvarList([self class], &ivarCount);
	
	NSInteger i = 0;
	for (i = 0; i < ivarCount; i++)
	{
		NSString *typeEncoding = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivars[i])];
		NSString *name = [NSString stringWithUTF8String:ivar_getName(ivars[i])];
		
		NSDictionary *ivarInfo = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", typeEncoding, @"typeEncoding", nil];
		[array addObject:ivarInfo];
	}
	free(ivars);
	return [[array copy] autorelease];
}

- (NSArray *)___objectIvarKeysConformingToClass:(Class)class
{
	NSMutableArray *array = [NSMutableArray array];
	
	NSArray *ivarNames = [[self ___objectIvars] valueForKey:@"name"];
	for (NSString *name in ivarNames) 
	{
		if ([[self valueForKey:name] isKindOfClass:class]) 
		{
			[array addObject:name];
		}
	}
	
	return [[array copy] autorelease];
}


+ (NSArray *)___classMethods;
{
	NSMutableArray *array = [NSMutableArray array];
	
	Class metaClass = object_getClass(self);
	
	unsigned int methodCount = 0;
	Method * methods = class_copyMethodList(metaClass, &methodCount);
	
	NSInteger i = 0;
	for (i = 0; i < methodCount; i++)
	{
		NSString *typeEncoding = [NSString stringWithUTF8String:method_getTypeEncoding(methods[i])];
		NSString *name = NSStringFromSelector(method_getName(methods[i]));
		
		// Arguments
//		NSUInteger argCount = method_getNumberOfArguments(methods[i]);
		
		NSDictionary *ivarInfo = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", typeEncoding, @"typeEncoding", nil];
		[array addObject:ivarInfo];
	}
	free(methods);
	return [[array copy] autorelease];
}



@end
