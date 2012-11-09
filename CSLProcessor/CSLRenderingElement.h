//
//  CSLRenderingElement.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSLFormatter.h"
#import "TouchXML.h"

@class CSLBibliographyOrCitation;

@interface CSLRenderingElement : NSObject{
    
    //The element field is used for debugging only
    CXMLElement* elementForDebuggingOnly;
    NSString* elementAsStringForDebuggingOnly;
    NSString* prefix;
    NSString* suffix;
}

//Configuring
-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter;
-(void) configureWithAttribute:(NSString*) attributeName value:(NSString*)attributeValue formatter:(CSLFormatter*) formatter;

//Rendering
-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary*) macros;
-(NSString*) postProcessRenderedString:(NSString*) renderedString;

-(BOOL) containsVariablesFields:(NSMutableDictionary*)fields formatter:(CSLFormatter*)formatter;
-(BOOL) allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter;

@end
