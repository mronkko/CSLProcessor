//
//  CSLNumber.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLNumber.h"


@implementation CSLNumber

/*
 "numeric" - (default), e.g. "1", "2", "3"
 "ordinal" - e.g. "1st", "2nd", "3rd". Ordinal suffixes are defined with terms (see Ordinal Suffixes).
 "long-ordinal" - e.g. "first", "second", "third". Long ordinals are defined with the terms "long-ordinal-01" to "long-ordinal-10", which are used for the numbers 1 through 10. For other numbers "long-ordinal" falls back to "ordinal".
 "roman" - e.g. "i", "ii", "iii"
 
 */

static const NSInteger NUMBER_FORM_NUMERIC = 0;
static const NSInteger NUMBER_FORM_ORDINAL = 1;
static const NSInteger NUMBER_FORM_LONG_ORDINAL = 2;
static const NSInteger NUMBER_FORM_ROMAN = 3;

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"form"]){
        if([attributeValue isEqualToString:@"numeric"]){
            numberForm = NUMBER_FORM_NUMERIC;
        }
        else if([attributeValue isEqualToString:@"ordinal"]){
            numberForm = NUMBER_FORM_ORDINAL;
        }
        else if([attributeValue isEqualToString:@"long-ordinal"]){
            numberForm = NUMBER_FORM_LONG_ORDINAL;
        }
        else if([attributeValue isEqualToString:@"roman"]){
            numberForm = NUMBER_FORM_ROMAN;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute form of element number",attributeValue];
        }
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
}

@end
