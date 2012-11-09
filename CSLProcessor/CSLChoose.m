//
//  CSLChoose.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLChoose.h"
#import "CSLBibliographyOrCitation.h"

@implementation CSLChoose

-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    self = [super initWithXMLElement:element formatter:formatter];
    
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for(CXMLElement* childElement in [element children]){
        if(childElement.kind == XML_ELEMENT_NODE){
            [array addObject:[[CSLIfElseCondition alloc] initWithXMLElement:childElement formatter:formatter]];
        }
    }
    conditions = array;
    return self;
}

-(CSLRenderingElement*) _elementToRenderBasedOnFields:(NSMutableDictionary*)fields{
    for(CSLIfElseCondition* condition in conditions){
        if([condition matchesWithFields:fields]){
            return condition;
        }
        else{
            //            NSLog(@"Condition does not match: %@",elementAsStringForDebuggingOnly);
        }
    }
    return NULL;
}

-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary*) macros{
    
    CSLIfElseCondition* condition = [self _elementToRenderBasedOnFields:fields];
    
    if(condition!=NULL){
        return [condition renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macros];
    }
    else{
        return @"";
    }
}

-(BOOL) allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter{
    CSLIfElseCondition* condition = [self _elementToRenderBasedOnFields:fields];
    
    if(condition!=NULL){
        return [condition allVariablesAreEmptyWithFields:fields formatter:formatter];
    }
    else{
        return FALSE;
    }
    
}

-(BOOL) containsVariablesFields:(NSMutableDictionary*)fields formatter:(CSLFormatter*)formatter{
    
    CSLIfElseCondition* condition = [self _elementToRenderBasedOnFields:fields];
    
    if(condition!=NULL){
        return [condition containsVariablesFields:fields formatter:formatter];
    }
    else{
        return FALSE;
    }
    
}

@end
