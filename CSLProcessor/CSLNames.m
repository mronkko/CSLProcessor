//
//  CSLNames.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLNames.h"
#import "CSLBibliographyOrCitation.h"
#import "CSLLocaleTerm.h"

@interface CSLNames ()

-(NSString*) _renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary *)macros nameVariables:(NSArray*)nameVariables;

@end


@implementation CSLNames

static const NSInteger AND_MODE_NONE = 0;
static const NSInteger AND_MODE_TEXT = 1;
static const NSInteger AND_MODE_SYMBOL = 2;

static const NSInteger NAME_AS_SORT_ORDER_NONE = 0;
static const NSInteger NAME_AS_SORT_ORDER_FIRST = 1;
static const NSInteger NAME_AS_SORT_ORDER_ALL = 2;

static const NSInteger DELIMITER_PRECEEDS_LAST_CONTEXTUAL = 0;
static const NSInteger DELIMITER_PRECEEDS_LAST_AFTER_INVERTED_NAME = 1;
static const NSInteger DELIMITER_PRECEEDS_LAST_ALWAYS = 2;
static const NSInteger DELIMITER_PRECEEDS_LAST_NEVER = 3;

static const NSInteger NAME_FORM_LONG=0;
static const NSInteger NAME_FORM_SHORT=1;
static const NSInteger NAME_FORM_COUNT=2;

static NSRegularExpression* REGEX_ROMANESQUE;

-(id) initWithXMLElement:(CXMLElement *)element formatter:(CSLFormatter *)formatter{
    self = [super initWithXMLElement:element formatter:formatter];
    
    //Default values
    delimiter=@", ";
    
    for(CXMLElement* childElement in [element children]){
        if(childElement.kind == XML_ELEMENT_NODE){
            if([childElement.name isEqualToString:@"name"]){
                for(CXMLNode* attribute in childElement.attributes){
                    if([attribute.name isEqualToString:@"and"]){
                        if([attribute.stringValue isEqualToString:@"text"]){
                            andMode = AND_MODE_TEXT;
                        }
                        else if([attribute.stringValue isEqualToString:@"symbol"]){
                            andMode = AND_MODE_SYMBOL;
                        }
                        else{
                            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute and of element name",attribute.stringValue];
                        }
                        
                    }
                    else if([attribute.name isEqualToString:@"initialize-with"]){
                        initializeWith = attribute.stringValue;
                    }
                    else if([attribute.name isEqualToString:@"delimiter"]){
                        nameDelimiter = attribute.stringValue;
                    }
                    else if([attribute.name isEqualToString:@"name-as-sort-order"]){
                        if([attribute.stringValue isEqualToString:@"all"]){
                            nameAsSortOrder = NAME_AS_SORT_ORDER_ALL;
                        }
                        else if([attribute.stringValue isEqualToString:@"first"]){
                            nameAsSortOrder = NAME_AS_SORT_ORDER_FIRST;
                        }
                        else{
                            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute name-as-sort-order of element name",attribute.stringValue];
                        }
                        
                    }
                    else if([attribute.name isEqualToString:@"sort-separator"]){
                        sortSeparator = attribute.stringValue;
                    }
                    else if([attribute.name isEqualToString:@"delimiter-precedes-last"]){
                        if([attribute.stringValue isEqualToString:@"always"]){
                            delimiterPrecedesLast = DELIMITER_PRECEEDS_LAST_ALWAYS;
                        }
                        else if([attribute.stringValue isEqualToString:@"never"]){
                            delimiterPrecedesLast = DELIMITER_PRECEEDS_LAST_NEVER;
                        }
                        else if([attribute.stringValue isEqualToString:@"contextual"]){
                            delimiterPrecedesLast = DELIMITER_PRECEEDS_LAST_CONTEXTUAL;
                        }
                        else if([attribute.stringValue isEqualToString:@"after-inverted-name"]){
                            delimiterPrecedesLast = DELIMITER_PRECEEDS_LAST_AFTER_INVERTED_NAME;
                        }
                        else{
                            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute delimiter-precedes-last of element name",attribute.stringValue];
                        }
                        
                    }
                    else if([attribute.name isEqualToString:@"form"]){
                        
                        if([attribute.stringValue isEqualToString:@"short"]){
                            nameForm = NAME_FORM_SHORT;
                        }
                        else if([attribute.stringValue isEqualToString:@"long"]){
                            nameForm = NAME_FORM_LONG;
                        }
                        else if([attribute.stringValue isEqualToString:@"count"]){
                            nameForm = NAME_FORM_COUNT;
                        }
                        else{
                            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute form of element name",attribute.stringValue];
                        }
                        
                    }
                    else{
                        [NSException raise:@"Not implemented" format:@"Attribute %@ has not been implemented for element name",attribute.name];
                    }
                }
            }
            else if([childElement.name isEqualToString:@"label"]){
                label = [[CSLLabel alloc] initWithXMLElement:childElement formatter:formatter];
            }
            else if([childElement.name isEqualToString:@"substitute"]){
                substitutes = [[CSLRenderingElementContainer alloc] initWithXMLElement:childElement formatter:formatter];
            }
            else{
                [NSException raise:@"Not implemented" format:@"Child node type %@ has not been implemented for element names",childElement.name];
            }
            
        }
    }
    
    return self;
}
-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"variable"]){
        
        NSMutableArray* vars = [[NSMutableArray alloc]init];
        for(NSString* variable in [attributeValue componentsSeparatedByString:@" "]){
            [vars addObject:variable];
        }
        variables = [NSArray arrayWithArray:vars];
        
    }
    else if([attributeName isEqualToString:@"delimiter"]){
        delimiter = attributeValue;
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
    
}

-(NSString*) _renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary *)macros nameVariables:(NSArray*)nameVariables{

    NSMutableString* namesString = [[NSMutableString alloc] init];

    BOOL hasNames = FALSE;

    for(NSString* nameVariable in nameVariables){
        NSArray* namesObjects = [fields objectForKey:nameVariable];
        
        if(namesObjects != NULL){
            if(hasNames){
                [namesString appendString:delimiter];
            }
            else{
                hasNames = TRUE;
            }
            
            /*
             NSString* initializeWith;
             NSInteger andMode;
             NSString* nameDelimiter;
             NSInteger nameAsSortOrder;
             NSString* sortSeparator;
             NSInteger delimiterPrecedesLast;
             NSInteger nameForm;
             
             */
            //Names
            
            NSInteger counter = 0;
            
            for(NSDictionary* creator in namesObjects){
                
                BOOL invertNameOrder = (nameAsSortOrder == NAME_AS_SORT_ORDER_ALL || (nameAsSortOrder == NAME_AS_SORT_ORDER_FIRST && counter ==1));
                
                if(++counter > rootElement.etAlUseFirst){
                    break;
                }
                //Last name
                else if(counter > 1){
                    
                    if(delimiterPrecedesLast == DELIMITER_PRECEEDS_LAST_ALWAYS ||
                       (delimiterPrecedesLast == DELIMITER_PRECEEDS_LAST_AFTER_INVERTED_NAME && invertNameOrder) ||
                       (delimiterPrecedesLast == DELIMITER_PRECEEDS_LAST_CONTEXTUAL && [namesObjects count]>2)){
                        [namesString appendString:delimiter];
                    }
                    
                    //Last element
                    
                    if(counter == [namesObjects count] && andMode != AND_MODE_NONE){
                        NSString* and;
                        if(andMode == AND_MODE_TEXT){
                            and = [formatter localizedStringForTerm:@"and" plural:FALSE form:FORM_LONG];
                        }
                        else{
                            and = @"&";
                        }
                        if(and!=NULL){
                            [namesString appendString:@" "];
                            [namesString appendString:and];
                            [namesString appendString:@" "];
                        }
                    }
                }
                
                NSString* lastName = [creator objectForKey:@"lastName"];
                
                if(lastName != NULL){
                    
                    //TODO: Make [NSCharacterSet characterSetWithCharactersInString:@". "] a class variable:
                    NSString* firstNameData = [creator objectForKey:@"firstName"];
                    
                    if([firstNameData length]>0){
                        
                        NSMutableString* firstName = [[NSMutableString alloc] init];
                        
                        NSArray* parts = [firstNameData componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@". "]];
                        for(NSString* firstNamePart in parts){
                            
                            if(REGEX_ROMANESQUE == NULL){
                                //This might need to be fixed to include also other characters
                                REGEX_ROMANESQUE =[[NSRegularExpression alloc] initWithPattern:@"[a-zA-Z]" options:NULL error:NULL];
                            }
                            
                            if([REGEX_ROMANESQUE rangeOfFirstMatchInString:firstNamePart options:NULL range:NSMakeRange(0, [firstNamePart length])].location != NSNotFound ){
                                //Support for hyphens
                                NSString* firstNamePartCleaned = [firstNamePart stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@". "]];
                                
                                if([firstNamePartCleaned length]>0){
                                    NSArray* subParts = [firstNamePartCleaned componentsSeparatedByString:@"-"];
                                    NSInteger counter =0;
                                    for(NSString* firstNameSubPart in subParts){
                                        
                                        //If we have firstnames that start or end with -, this will produce empty parts
                                        if(! [firstNameSubPart isEqualToString:@""]){
                                            [firstName appendString:[[firstNameSubPart substringToIndex:1] uppercaseString]];
                                            if(++counter<[subParts count]){
                                                [firstName appendString:[initializeWith stringByReplacingOccurrencesOfString:@" " withString:@""]];
                                                [firstName appendString:@"-"];
                                            }
                                            else{
                                                [firstName appendString:initializeWith];
                                            }
                                        }
                                    }
                                }
                            }
                            else{
                                [firstName appendString:firstNamePart];
                            }
                        }
                        
                        if(invertNameOrder){
                            [namesString appendString:lastName];
                            [namesString appendString:sortSeparator];
                            if([firstName hasSuffix:@" "]){
                                [namesString appendString:[firstName substringToIndex:[firstName length]-1]];
                            }
                            else{
                                [namesString appendString:firstName];
                            }
                        }
                        else{
                            [namesString appendString:firstName];
                            [namesString appendString:lastName];
                        }
                    }
                    // No first name
                    else{
                        [namesString appendString:lastName];
                    }
                }
                else{
                    [namesString appendString:[creator objectForKey:@"name"]];
                }
            }
            
            // Et al.
            if([namesObjects count]>rootElement.etAlUseFirst){
                
            }
            
            // Label
            if(label != NULL){
                label.plural = [namesObjects count]>1;
                label.variable = nameVariable;
                NSString* labelString = [label renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macros];
                if(labelString != NULL){
                    [namesString appendString:labelString];
                }
            }
            
        }
    }
    return namesString;
}

-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary *)macros{
    
    NSString* namesString = [self _renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macros nameVariables:variables];

    if(namesString != NULL){
        return [self postProcessRenderedString:namesString];
    }
    //Return substitute
    else{
        for(CSLRenderingElement* substitute in substitutes.childElements){
            NSString* substituteString = [substitute renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macros];
            if(! [substituteString isEqualToString:@""]) return [self postProcessRenderedString:substituteString];
        }
        return NULL;
    }
}

-(BOOL) containsVariablesFields:(NSMutableDictionary*)fields formatter:(CSLFormatter*)formatter{
    return TRUE;
}
-(BOOL)allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter{
    
    for(NSString* variable in variables){
        if([fields objectForKey:variable] != NULL) return FALSE;
    }
    
    return TRUE;
}

@end