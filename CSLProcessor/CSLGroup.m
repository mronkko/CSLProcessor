//
//  CSLGroup.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLGroup.h"
#import "CSLBibliographyOrCitation.h"

@implementation CSLGroup

-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary*) macros{
    
    NSMutableString* contentString = [[NSMutableString alloc] init];
    
    if(! [self containsVariablesFields:fields formatter:formatter] || !  [self allVariablesAreEmptyWithFields:fields formatter:formatter]){
        
        BOOL first = TRUE;
        for(CSLRenderingElement* element in childElements){
            NSString* content = [element renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macros];
            if(content!=NULL && [content length]>0){
                if(! first && delimiter != NULL){
                    //Be smart about spaces and punctuation
                    if([contentString hasSuffix:[delimiter substringToIndex:1]]){
                        [contentString appendString:[delimiter substringFromIndex:1]];
                    }
                    else{
                        [contentString appendString:delimiter];
                    }
                }
                
                //Be smart about spaces and punctuation
                if([contentString hasSuffix:[content substringToIndex:1]]){
                    [contentString appendString:[content substringFromIndex:1]];
                }
                else{
                    [contentString appendString:content];
                }
                first = FALSE;
            }
        }
        
        return [self postProcessRenderedString:contentString];
        
    }
    else{
        //empty group, no content
        return NULL;
    }
}

@end
