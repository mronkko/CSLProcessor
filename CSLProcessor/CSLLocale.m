//
//  CSLLocale.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLLocale.h"
#import "CSLLocaleTerm.h"
#import "TouchXML.h"
#import "CSLFormatter.h"

@implementation CSLLocale


-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    self = [super init];
    terms = [[NSDictionary alloc] init];
    [self addTermsFromElement:element formatter:formatter];
    return self;
}

-(void)addTermsFromElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:terms];
    
    NSDictionary* nameSpaceMapping = [NSDictionary dictionaryWithObject:@"http://purl.org/net/xbiblio/csl" forKey:@"ns"];

    for(CXMLElement* termElement in [element nodesForXPath:@"//ns:terms/ns:term" namespaceMappings:nameSpaceMapping error:NULL]){
        NSString* attributeValue = [[termElement attributeForName:@"form"] stringValue];
        
        NSString* name = [[termElement attributeForName:@"name"] stringValue];
        
        if(attributeValue!=NULL && ![ attributeValue isEqualToString:@"long"]){
            CSLLocaleTerm* term= [dict objectForKey:name];
            CSLLocaleTerm* altenativeForm = [[CSLLocaleTerm alloc] initWithXMLElement:termElement];
            if([attributeValue isEqualToString:@"short"]){
                term.shortForm = altenativeForm;
            }
            else if([attributeValue isEqualToString:@"verb"]){
                term.verbForm = altenativeForm;
            }
            else if([attributeValue isEqualToString:@"verb-short"]){
                term.verbShortForm = altenativeForm;
            }
            else if([attributeValue isEqualToString:@"symbol"]){
                term.symbolForm = altenativeForm;
            }
        }
        else{
            [dict setObject:[[CSLLocaleTerm alloc] initWithXMLElement:termElement] forKey:name];
        }
    }
    terms = [NSDictionary dictionaryWithDictionary:dict];
    
}

-(NSString*)localizedStringForTerm:(NSString*)term plural:(BOOL)plural form:(NSInteger)form{
    
    CSLLocaleTerm* currentTerm = [terms objectForKey:term];
    
    if(form == FORM_SHORT){
        currentTerm = currentTerm.shortForm;
    }
    else if(form == FORM_SYMBOL){
        currentTerm = currentTerm.symbolForm;
    }
    else if(form == FORM_VERB){
        currentTerm = currentTerm.verbForm;
    }
    else if(form == FORM_VERB_SHORT){
        currentTerm = currentTerm.verbShortForm;
    }
    
    
    if(plural){
        return currentTerm.multiple;
    }
    else{
        return currentTerm.single;
    }
}


@end
