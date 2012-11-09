//
//  CSLDatePart.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLDatePart.h"

@implementation CSLDatePart

/*
 For "day", cs:date-part may carry the form attribute, with values:
 
 "numeric" - (default), e.g. "1"
 "numeric-leading-zeros" - e.g. "01"
 "ordinal" - e.g. "1st"
 Some languages, such as French, only use the "ordinal" form for the first day of the month ("1er janvier", "2 janvier", "3 janvier", etc.). Such output can be achieved with the "ordinal" form and use of the limit-day-ordinals-to-day-1 attribute (see Locale Options).
 
 "month"
 For "month", cs:date-part may carry the strip-periods and form attributes. In locale files, month abbreviations (the "short" form of the month terms) should be defined with periods if applicable (e.g. "Jan.", "Feb.", etc.). These periods can be removed by setting strip-periods to "true" ("false" is the default). The form attribute can be set to:
 
 "long" - (default), e.g. "January"
 "short" - e.g. "Jan."
 "numeric" - e.g. "1"
 "numeric-leading-zeros" - e.g. "01"
 "year"
 For "year", cs:date-part may carry the form attribute, with values:
 
 "long" - (default), e.g. "2005"
 "short" - e.g. "05"
 */

static const NSInteger DATE_PART_FORM_NUMERIC = 1;
static const NSInteger DATE_PART_FORM_NUMERIC_LEADING_ZEROS = 2;
static const NSInteger DATE_PART_FORM_ORDINAL = 3;
static const NSInteger DATE_PART_FORM_SHORT = 4;
static const NSInteger DATE_PART_FORM_LONG = 5;

static const NSInteger DATE_PART_DAY = 1;
static const NSInteger DATE_PART_MONTH = 2;
static const NSInteger DATE_PART_YEAR = 3;

static NSRegularExpression* REGEX_FIRST_FOUR_DIGIT_YEAR;
static NSRegularExpression* REGEX_MONTH;
static NSRegularExpression* REGEX_DAY;

static NSArray* MONTH_NAMES;

@synthesize variable;

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"form"]){
        if([attributeValue isEqualToString:@"numeric"]){
            form = DATE_PART_FORM_NUMERIC;
        }
        else if([attributeValue isEqualToString:@"ordinal"]){
            form = DATE_PART_FORM_ORDINAL;
        }
        else if([attributeValue isEqualToString:@"numeric-leading-zeros"]){
            form = DATE_PART_FORM_NUMERIC_LEADING_ZEROS;
        }
        else if([attributeValue isEqualToString:@"long"]){
            form = DATE_PART_FORM_LONG;
        }
        else if([attributeValue isEqualToString:@"short"]){
            form = DATE_PART_FORM_SHORT;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute form of element date-part",attributeValue];
        }
    }
    else if([attributeName isEqualToString:@"name"]){
        if([attributeValue isEqualToString:@"day"]){
            datePart = DATE_PART_DAY;
            if(form == 0) form = DATE_PART_FORM_NUMERIC;
        }
        else if([attributeValue isEqualToString:@"month"]){
            datePart = DATE_PART_MONTH;
            if(form == 0) form = DATE_PART_FORM_LONG;
        }
        else if([attributeValue isEqualToString:@"year"]){
            datePart = DATE_PART_YEAR;
            if(form == 0) form = DATE_PART_FORM_LONG;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute name of element date-part",attributeValue];
        }
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
}
-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation *)rootElement storeMacrosInDictionary:(NSMutableDictionary *)macros{
    NSString* dateValue = [fields objectForKey:self.variable];
    
    NSString* parsedValue = [self _parseDate:dateValue part:datePart];
    if(parsedValue!=NULL){
        return [self postProcessRenderedString:parsedValue];
    }
    else{
        return NULL;
    }
}
-(BOOL) containsVariablesFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter{
    return TRUE;
}
-(BOOL) allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter{
    NSString* dateValue = [fields objectForKey:self.variable];
    
    if(dateValue == NULL) return TRUE;
    
    return [self _parseDate:dateValue part:datePart] == NULL;
}

-(NSString*) _parseDate:(NSString*)dateValue part:(NSInteger)part{
    if(datePart == DATE_PART_YEAR){
        if(REGEX_FIRST_FOUR_DIGIT_YEAR == NULL){
            REGEX_FIRST_FOUR_DIGIT_YEAR = [NSRegularExpression regularExpressionWithPattern:@"[1-9][0-9][0-9][0-9]" options:0 error:NULL];
        }
        
        NSRange rangeOfFirstMatch = [REGEX_FIRST_FOUR_DIGIT_YEAR rangeOfFirstMatchInString:dateValue options:0 range:NSMakeRange(0, [dateValue length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [dateValue substringWithRange:rangeOfFirstMatch];
            return substringForFirstMatch;
            
        }
        else return dateValue;
    }
    else if(datePart == DATE_PART_MONTH){
        if(REGEX_MONTH == NULL){
            REGEX_MONTH = [NSRegularExpression regularExpressionWithPattern:@"-[0-1][0-9]-" options:0 error:NULL];
        }
        if(MONTH_NAMES == NULL){
            MONTH_NAMES = [NSArray arrayWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December", nil];
        }
        
        NSRange rangeOfFirstMatch = [REGEX_MONTH rangeOfFirstMatchInString:dateValue options:0 range:NSMakeRange(0, [dateValue length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [dateValue substringWithRange:NSMakeRange(rangeOfFirstMatch.location+1, 2)];
            return [MONTH_NAMES objectAtIndex:[substringForFirstMatch integerValue]-1];
            
        }
    }
    else if(datePart == DATE_PART_DAY){
        if(REGEX_DAY == NULL){
            REGEX_DAY = [NSRegularExpression regularExpressionWithPattern:@"-[0-3][0-9] " options:0 error:NULL];
        }
        NSRange rangeOfFirstMatch = [REGEX_DAY rangeOfFirstMatchInString:dateValue options:0 range:NSMakeRange(0, [dateValue length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [dateValue substringWithRange:NSMakeRange(rangeOfFirstMatch.location+1, 2)];
            
            if([substringForFirstMatch hasPrefix:@"0"]){
                return [substringForFirstMatch substringFromIndex:1];
            }
            else{
                return substringForFirstMatch;
            }
        }
    }
    
    return NULL;
    
}

@end