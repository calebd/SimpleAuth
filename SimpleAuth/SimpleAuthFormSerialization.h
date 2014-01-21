//
//  SimpleAuthFormSerialization.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/21/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

@interface SimpleAuthFormSerialization : NSObject

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)string;
+ (NSString *)formEncodedStringWithDictionary:(NSDictionary *)dictionary;

@end
