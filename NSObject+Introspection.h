////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///
///		NSObject+Introspection.h
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


#import <Foundation/Foundation.h>

void
PointerReadFailedHandler(int signum);

BOOL 
KRIsPointerAnObject(const void *testPointer, 
					BOOL *allocatedLargeEnough);

@interface NSObject (Introspection)
- (NSArray *)___objectIvars;
- (NSArray *)___objectIvarKeysConformingToClass:(Class)class;
+ (NSArray *)___classMethods;

@end
