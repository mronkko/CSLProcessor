//
//  CSLFormatter.m
//  CSLParser
//
//  Created by Rönkkö Mikko on 9/14/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLFormatter.h"
#import "CSLLocale.h"
#import "CSLLocaleTerm.h"
#import "CSLBibliographyOrCitation.h"
#import "CSLRenderingElementContainer.h"
#import "CSLMacro.h"

@interface CSLFormatter(){

    CSLLocale* _currentLocale;
    NSDictionary* _macros;
    CSLBibliographyOrCitation* _bibliography;
}

@end


#pragma mark - Main class


@implementation CSLFormatter

-(id) initWithCSLFile:(NSString*)cslPath localeFile:(NSString *)localePath fieldMapFile:(NSString *)fieldMapPath{

    if(![[NSFileManager defaultManager] fileExistsAtPath:cslPath]){
        [NSException raise:@"File not found" format:@"CSL style file not found: %@",cslPath];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:localePath]){
        [NSException raise:@"File not found" format:@"CSL locale file not found: %@",localePath];
    }

    self = [super init];
    
    NSDictionary* nameSpaceMapping = [NSDictionary dictionaryWithObject:@"http://purl.org/net/xbiblio/csl" forKey:@"ns"];
    
    if(fieldMapPath!=NULL){
        //Field mapping between Zotero and CSL fields
        
        NSData* fieldMapData   = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"typeMap" ofType: @"xml"]];
        
        CXMLDocument* fieldMapDoc = [[CXMLDocument alloc] initWithData:fieldMapData options:0 error:nil];
        
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        
        for(CXMLElement* element in [fieldMapDoc nodesForXPath:@"//fieldMap | //creatorMap" error:NULL]){
            NSString* key = [(CXMLNode*) [[element attributes] objectAtIndex:0] stringValue];
            NSString* value = [(CXMLNode*) [[element attributes] objectAtIndex:1] stringValue];

            NSArray* array = [dict objectForKey:key];
            
            if(array==NULL){
                [dict setObject:[NSArray arrayWithObject:value]
                         forKey:key];
            }
            else{
                [dict setObject:[array arrayByAddingObject:value]
                         forKey:key];
            }

        }
        
        [dict setObject:[NSArray arrayWithObject:@"type"] forKey:@"itemType"];
        
        //Set the field maps based on type map entries e.g.
        //<field value="websiteTitle" baseField="publicationTitle" />
        
        
        for(CXMLElement* element in [fieldMapDoc nodesForXPath:@"//field[@baseField]" error:NULL]){
            NSString* key = [(CXMLNode*) [[element attributes] objectAtIndex:0] stringValue];
            NSString* valueKey = [(CXMLNode*) [[element attributes] objectAtIndex:1] stringValue];
            
/*
            if([dict objectForKey:key]){
                [NSException raise:@"Not implemented" format:@""];
            }
 */
            [dict setObject:[dict objectForKey:valueKey]
                     forKey:key];
        }
        
        fieldMap = [NSDictionary dictionaryWithDictionary:dict];

        
        NSData* typeMapData   = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"typeMap" ofType: @"xml"]];
        
        CXMLDocument* typeMapDoc = [[CXMLDocument alloc] initWithData:typeMapData options:0 error:nil];
        
        [dict removeAllObjects];
        
        for(CXMLElement* element in [typeMapDoc nodesForXPath:@"//typeMap" error:NULL]){
            
            NSString* key = [(CXMLNode*) [[element attributes] objectAtIndex:0] stringValue];
            NSString* value = [(CXMLNode*) [[element attributes] objectAtIndex:1] stringValue];
            
            [dict setObject:value
                     forKey:key];
        }
        typeMap = [NSDictionary dictionaryWithDictionary:dict];
    }

    
    // Init locale

    NSData* XMLData   = [NSData dataWithContentsOfFile:localePath];
    
    CXMLDocument* doc = [[CXMLDocument alloc] initWithData:XMLData options:0 error:nil];

    //<locale xmlns="http://purl.org/net/xbiblio/csl" version="1.0" xml:lang="en-US">
    
    CXMLElement* localeElement =[[doc nodesForXPath:@"//ns:locale" namespaceMappings:nameSpaceMapping  error:NULL] objectAtIndex:0];
    NSString* localeName = [[localeElement attributeForName:@"xml:lang"] stringValue];

    _currentLocale = [[CSLLocale alloc] initWithXMLElement:localeElement formatter:self];
    
        
    // Init with the CSL file
    
    
    XMLData   = [NSData dataWithContentsOfFile:cslPath];

    doc = [[CXMLDocument alloc] initWithData:XMLData options:0 error:nil];
    
    //Modifications to locale based on the CSL file
    
    for(CXMLElement* element in [doc nodesForXPath:@"//ns:locale" namespaceMappings:nameSpaceMapping  error:NULL]){
        NSString* name = [[element attributeForName:@"lang"] stringValue];
        if([localeName hasPrefix:name]){
            
        }
    }
    

    
    //Macros
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    for(CXMLElement* element in [doc nodesForXPath:@"//ns:macro" namespaceMappings:nameSpaceMapping  error:NULL]){
        [dict setObject:[[CSLMacro alloc] initWithXMLElement:element formatter:self] forKey:[[element attributeForName:@"name"] stringValue]];
    }

    _macros = dict;
    
    //Bibliography
    NSArray* nodes =  [doc nodesForXPath:@"//ns:bibliography" namespaceMappings:nameSpaceMapping  error:NULL];
    
    _bibliography = [[CSLBibliographyOrCitation alloc] initWithXMLElement:[nodes objectAtIndex:0] formatter:self];

    
      
    return self;
}

-(NSString*) formatBibliographyItemUsingVariables:(NSDictionary *)variables{
    return [self formatBibliographyItemUsingVariables:variables storeMacrosInDictionary:NULL];
}

-(NSString*) formatBibliographyItemUsingVariables:(NSDictionary*)variables storeMacrosInDictionary:(NSMutableDictionary*) macros{

    NSMutableDictionary* renderingDict = [[NSMutableDictionary alloc] initWithCapacity:[variables count]];
    for(NSString* key in variables){
        NSObject* value = [variables objectForKey:key];
        NSArray* newKeys = [fieldMap objectForKey:key];
        
        if(newKeys != NULL){
            for(NSString* newKey in newKeys){
                if([newKey isEqualToString:@"type"]){
                    value = [typeMap objectForKey:value];
                }
                else if([newKey isEqualToString:@"page"]){
                    value = [(NSString*) value stringByReplacingOccurrencesOfString:@"-" withString:@"\u2013"];
                }
                
                //Replace type write double quotes with normal quotes
                
                else if([value isKindOfClass:[NSString class]]){
                    NSScanner *scanner = [NSScanner scannerWithString:(NSString*)value];
                    [scanner setCharactersToBeSkipped:nil];
                    NSMutableString* newValue = [NSMutableString string];
                    BOOL foundQuote = YES;
                    int quoteIndex = 0;
                    
                    while (foundQuote) {
                        NSString *nextPart = @"";
                        [scanner scanUpToString:@"\"" intoString:&nextPart];
                        if (nextPart != nil) {
                            [newValue appendString:nextPart];
                        }
                        foundQuote = [scanner scanString:@"\"" intoString:nil];
                        if (foundQuote) {
                            [newValue appendString:((quoteIndex % 2) ? @"\u201D" : @"\u201C")];
                            quoteIndex++;
                        }
                    }
                    value = newValue;

                }
                [renderingDict setObject:value forKey:newKey];
            }
        }
    }
    return [_bibliography renderContentForFields:renderingDict formatter:self rootElement:_bibliography storeMacrosInDictionary:macros];
}

-(CSLRenderingElementContainer*) macroWithName:(NSString*)name{
    return [_macros objectForKey:name];
}

-(NSString*) localizedStringForTerm:(NSString*)term plural:(BOOL)plural form:(NSInteger)form{
    return [_currentLocale localizedStringForTerm:term plural:plural form:form];
}


+(NSInteger) formAsInteger:(NSString*) attributeValue{
    if([attributeValue isEqualToString:@"long"]){
        return FORM_LONG;
    }
    else if([attributeValue isEqualToString:@"short"]){
        return  FORM_SHORT;
    }
    else if([attributeValue isEqualToString:@"verb"]){
        return  FORM_VERB;
    }
    else if([attributeValue isEqualToString:@"verb-short"]){
        return  FORM_VERB_SHORT;
    }
    else if([attributeValue isEqualToString:@"symbol"]){
        return FORM_SYMBOL;
    }
    else{
        [NSException raise:@"Not implemented" format:@"Not implemented"];
        return -1;
    }

}
@end
