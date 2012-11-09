//
//  CSLIfElseCondition.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLIfElseCondition.h"

@implementation CSLIfElseCondition


/*
 "all" - (default), element only tests "true" when all conditions test "true" for all given test values
 "any" - element tests "true" when any condition tests "true" for any given test value
 "none" - element only tests "true" when none of the conditions test "true" for any given test value
 */

static NSInteger MATCH_ALL = 0;
static NSInteger MATCH_ANY = 1;
static NSInteger MATCH_NONE = 2;

static NSInteger CRITERION_VARIABLE = 0;
static NSInteger CRITERION_TYPE = 1;

-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    
    self = [super initWithXMLElement:element formatter:formatter];
    
    isElse = [[element name] isEqualToString:@"else"];
    typeFieldName = @"type";
    return self;
}

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    
    if([attributeName isEqualToString:@"type"]){
        matchCriterion = CRITERION_TYPE;
        
        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for(NSString* var in [attributeValue componentsSeparatedByString:@" "]){
            [temp addObject:var];
        }
        matchValues = [NSArray arrayWithArray:temp];
    }
    else if([attributeName isEqualToString:@"variable"]){
        matchCriterion = CRITERION_VARIABLE;
        
        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for(NSString* var in [attributeValue componentsSeparatedByString:@" "]){
            [temp addObject:var];
        }
        matchValues = [NSArray arrayWithArray:temp];
    }
    else if([attributeName isEqualToString:@"match"]){
        if([attributeValue isEqualToString:@"all"]){
            matchType=MATCH_ALL;
        }
        else if([attributeValue isEqualToString:@"any"]){
            matchType=MATCH_ANY;
        }
        else if([attributeValue isEqualToString:@"none"]){
            matchType=MATCH_NONE;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Match type '%@' is not implemented for 'if' nodes",attributeValue];
        }
    }
}

-(BOOL) matchesWithFields:(NSDictionary*) fields{
    
    if(isElse){
        return TRUE;
    }
    else{
        if(matchCriterion == CRITERION_TYPE){
            NSString* type = [fields objectForKey:typeFieldName];
            if(type == NULL){
                [NSException raise:@"Item type cannot be null" format:@""];
            }
            if(matchType==MATCH_NONE){
                return ! [matchValues containsObject:type];
            }
            else{
                return [matchValues containsObject:type];
            }
        }
        else if(matchCriterion == CRITERION_VARIABLE){
            
            for(NSString* variable in matchValues){
                BOOL match;
                
                NSObject* valueObject = [fields objectForKey:variable];
                if(valueObject == NULL) match=false;
                else if ([valueObject isKindOfClass:[NSString class]])
                    match = ! [(NSString*)valueObject isEqualToString:@""];
                else match = [(NSArray*) valueObject count] > 0;
                
                if(matchType == MATCH_ANY && match) return TRUE;
                else if (matchType == MATCH_ALL && ! match) return FALSE;
                else if (matchType == MATCH_NONE && match) return FALSE;
            }
            
            return matchType != MATCH_ANY;
        }
        else{
            [NSException raise:@"Internal consistency exception" format:@"Internal consistency exception"];
            return FALSE;
        }
        
    }
}

@end
