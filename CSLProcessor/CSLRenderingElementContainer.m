//
//  CSLRenderingElementContainer.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElementContainer.h"
#import "CSLBibliographyOrCitation.h"
#import "CSLChoose.h"
#import "CSLText.h"
#import "CSLNames.h"
#import "CSLGroup.h"
#import "CSLDate.h"
#import "CSLDatePart.h"
#import "CSLNumber.h"
#import "CSLLabel.h"


@implementation CSLRenderingElementContainer


-(NSArray*)childElements{
    return childElements;
}


-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    self = [super initWithXMLElement:element formatter:formatter];
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    for(CXMLElement* childElement in element.children){
        if(childElement.kind == XML_ELEMENT_NODE){
            NSString* name = [childElement name];
            if([name isEqualToString:@"choose"]){
                [array addObject:[[CSLChoose alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            else if([name isEqualToString:@"text"]){
                [array addObject:[[CSLText alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            else if([name isEqualToString:@"names"]){
                [array addObject:[[CSLNames alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            else if([name isEqualToString:@"group"]){
                [array addObject:[[CSLGroup alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            else if([name isEqualToString:@"date"]){
                [array addObject:[[CSLDate alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            else if([name isEqualToString:@"date-part"]){
                [array addObject:[[CSLDatePart alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            else if([name isEqualToString:@"number"]){
                [array addObject:[[CSLNumber alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            else if([name isEqualToString:@"label"]){
                [array addObject:[[CSLLabel alloc] initWithXMLElement:childElement formatter:formatter]];
            }
            
            else{
                [NSException raise:@"Element type not implemented" format:@"Element type '%@' has not been implemented",name];
            }
        }
    }
    childElements = [NSArray arrayWithArray:array];
    
    return self;
}

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"delimiter"]){
        delimiter = attributeValue;
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
    
}

-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary*) macros{
    
    NSMutableString* contentString;
    for(CSLRenderingElement* element in childElements){
        NSString* content = [element renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macros];
        if(content!=NULL){
            if(contentString == NULL){
                contentString = [NSMutableString stringWithString:content];
            }
            else{
                [contentString appendString:content];
            }
        }
    }
    
    return [self postProcessRenderedString:contentString];
}

-(BOOL) containsVariablesFields:(NSMutableDictionary*)fields formatter:(CSLFormatter*)formatter{
    for(CSLRenderingElement* element in childElements){
        if([element containsVariablesFields:fields formatter:formatter]) return TRUE;
    }
    return FALSE;
}

-(BOOL) allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter;
{
    for(CSLRenderingElement* element in childElements){
        if([element containsVariablesFields:fields formatter:formatter] &&
           ! [element allVariablesAreEmptyWithFields:fields formatter:formatter]) return FALSE;
    }
    return TRUE;
}


@end