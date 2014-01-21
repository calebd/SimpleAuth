//
//  SimpleAuthFormSerialization.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/21/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFormSerialization.h"

@interface NSString (SimpleAuthAdditions)

- (NSString *)SimpleAuth_stringByAddingEscapes;
- (NSString *)Simpleauth_stringByRemovingEscapes;

@end

@implementation SimpleAuthFormSerialization

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)string {
    if (!string) {
        return nil;
    }
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSArray *pairs = [string componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        if ([pair length] == 0) {
            continue;
        }
        
        NSRange range = [pair rangeOfString:@"="];
        NSString *key;
        NSString *value;
        
        if (range.location == NSNotFound) {
            key = [pair Simpleauth_stringByRemovingEscapes];
            value = @"";
        } else {
            key = [pair substringToIndex:range.location];
            key = [key Simpleauth_stringByRemovingEscapes];
            
            value = [pair substringFromIndex:(range.location + range.length)];
            value = [key Simpleauth_stringByRemovingEscapes];
        }
        
        if (!key || !value) {
            continue;
        }
        
        result[key] = value;
    }
    
    return result;
}


+ (NSString *)formEncodedStringWithDictionary:(NSDictionary *)dictionary {
    NSMutableArray *pairs = [NSMutableArray arrayWithCapacity:[dictionary count]];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        NSString *string = [NSString stringWithFormat:@"%@=%@",
                            [key SimpleAuth_stringByAddingEscapes],
                            [value SimpleAuth_stringByAddingEscapes]];
        [pairs addObject:string];
    }];
    return [pairs componentsJoinedByString:@"&"];
}

@end

@implementation NSString (SimpleAuthAdditions)

- (NSString *)SimpleAuth_stringByAddingEscapes {
    CFStringRef string = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                 (CFStringRef)self,
                                                                 NULL,
                                                                 CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
    return (NSString *)CFBridgingRelease(string);
}


- (NSString *)Simpleauth_stringByRemovingEscapes {
    return [self stringByRemovingPercentEncoding];
}

@end
