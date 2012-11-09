//
//  CSLMacro.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLMacro.h"

@implementation CSLMacro

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"name"]){
        name = attributeValue;
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue  formatter:formatter];
    }
}

@end
