//
//  SimpleAuth.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 2/22/15.
//  Copyright (c) 2013-2015 Caleb Davenport. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Called when authentication completes with a response or fails with an error.
 Should an error occur, response object will be nil.

 @param responseObject The authorization response, or nil if an error occurred.
 @param error An error.
 */
typedef void (^SimpleAuthRequestHandler) (id responseObject, NSError *error);
