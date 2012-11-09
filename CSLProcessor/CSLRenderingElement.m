//
//  CSLRenderingElement.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElement.h"
#import "CSLBibliographyOrCitation.h"

@implementation CSLRenderingElement


-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    self = [super init];
    
    elementForDebuggingOnly = element;
    elementAsStringForDebuggingOnly = [NSString stringWithFormat:@"%@",element];
    for(CXMLNode* attribute in element.attributes){
        [self configureWithAttribute:attribute.name value:attribute.stringValue formatter:formatter];
    }
    
    return self;
}

-(void)configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"suffix"]){
        suffix = attributeValue;
    }
    else if([attributeName isEqualToString:@"prefix"]){
        prefix = attributeValue;
    }
    else{
        [NSException raise:@"Not implemented" format:@"Attribute %@ has not been implemented. Found in %@",attributeName, elementForDebuggingOnly ];
    }
}

-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary*) macros{
    [NSException raise:@"Not implemented" format:@"Not implemented"];
    return FALSE;
}

-(NSString*) postProcessRenderedString:(NSString*) renderedString{
    
    if(prefix != NULL){
        renderedString = [prefix stringByAppendingString:renderedString];
    }
    
    if(suffix != NULL){
        renderedString = [renderedString stringByAppendingString:suffix];
    }
    
    return renderedString;
}

-(BOOL) containsVariablesFields:(NSMutableDictionary*)fields formatter:(CSLFormatter*)formatter{
    [NSException raise:@"Not implemented" format:@"Not implemented"];
    return FALSE;
}
-(BOOL) allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter;
{
    [NSException raise:@"Not implemented" format:@"Not implemented"];
    return FALSE;
}

@end
