//
//  CSLBibliographyOrCitation.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLBibliographyOrCitation.h"
#import "CSLRenderingElementContainer.h"

@implementation CSLBibliographyOrCitation

@synthesize etAlUseFirst, etAlUseLast;


-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    
    self = [super initWithXMLElement:element formatter:formatter];
    
    for(CXMLElement* childElement in element.children){
        if(childElement.kind == XML_ELEMENT_NODE && [childElement.name isEqualToString:@"layout"]){
            child = [[CSLRenderingElementContainer alloc] initWithXMLElement:childElement formatter:formatter];
            
        }
    }
    
    return self;
}

-(void)configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"et-al-use-first"]){
        self.etAlUseFirst = [attributeValue integerValue];
    }
    else if([attributeName isEqualToString:@"et-al-use-last"]){
        self.etAlUseLast = [attributeValue isEqualToString:@"true"];
    }
    
    
    //TODO: Implement rest of the attributes and call super class.
}

-(NSString*)renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation *)rootElement storeMacrosInDictionary:(NSMutableDictionary*) macro{
    return [child renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macro];
}

@end
