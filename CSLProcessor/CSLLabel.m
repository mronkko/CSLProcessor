//
//  CSLLabel.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLLabel.h"
#import "CSLBibliographyOrCitation.h"
#import "CSLFormatter.h"

@implementation CSLLabel

@synthesize variable;

-(BOOL) plural{
    return plural;
}
-(void) setPlural:(BOOL)newplural{
    plural = newplural;
}

-(NSString*)renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation *)rootElement storeMacrosInDictionary:(NSMutableDictionary *)macros{
    NSString* ret = [formatter localizedStringForTerm:self.variable plural:self.plural form:form];
    if(ret == NULL){
        return NULL;
    }
    else{
        return [self postProcessRenderedString:ret];
    }
}

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"variable"]){
        self.variable = attributeValue;
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue  formatter:formatter];
    }
}

@end
