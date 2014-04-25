//
//  SimpleAuthFunctions.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 4/25/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

/**
 Enumerate all registered classes.
 */
void SimpleAuthEnumerateAllRegisteredClasses(void (^block) (Class klass, BOOL *stop));

/**
 Enumerate all subclasses of the given class.
 */
void SimpleAuthEnumerateAllSubclassesOfClass(Class klass, void (^block) (Class klass, BOOL *stop));

/**
 Enumerate all classes that conform to the given protocol.
 */
void SimpleAuthEnumerateAllClassesConformingToProtocol(Protocol *protocol, void (^block) (Class klass, BOOL *stop));

//BOOL SimpleAuthClassIsSubclassOfClass(Class classOne, Class classTwo);
