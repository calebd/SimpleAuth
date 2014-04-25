//
//  SimpleAuthFunctions.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 4/25/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFunctions.h"

@import ObjectiveC.runtime;

#pragma mark - Private

BOOL SimpleAuthClassIsSubclassOfClass(Class classOne, Class classTwo) {
    Class classThree = class_getSuperclass(classOne);
    if (classThree == classTwo) {
        return YES;
    }
    else if (classThree == Nil) {
        return NO;
    }
    else {
        return SimpleAuthClassIsSubclassOfClass(classThree, classTwo);
    }
}


#pragma mark - Public

void SimpleAuthEnumerateAllRegisteredClasses(void (^block) (Class, BOOL *)) {
    int numberOfClasses = objc_getClassList(NULL, 0);
    Class classes[numberOfClasses];
    objc_getClassList(classes, numberOfClasses);
    for (int i = 0; i < numberOfClasses; i++) {
        Class klass = classes[i];
        BOOL stop = NO;
        block(klass, &stop);
        if (stop) {
            return;
        }
    }
}


void SimpleAuthEnumerateAllSubclassesOfClass(Class klassOne, void (^block) (Class, BOOL *)) {
    SimpleAuthEnumerateAllRegisteredClasses(^(Class klassTwo, BOOL *stop) {
        if (SimpleAuthClassIsSubclassOfClass(klassTwo, klassOne)) {
            block(klassTwo, stop);
        }
    });
}


void SimpleAuthEnumerateAllClassesConformingToProtocol(Protocol *protocol, void (^block) (Class, BOOL *)) {
    SimpleAuthEnumerateAllRegisteredClasses(^(Class klass, BOOL *stop) {
        if (class_conformsToProtocol(klass, protocol)) {
            block(klass, stop);
        }
    });
}
