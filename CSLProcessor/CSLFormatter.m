//
//  CSLFormatter.m
//  CSLParser
//
//  Created by Rönkkö Mikko on 9/14/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLFormatter.h"
#import "TouchXML.h"


#pragma mark - Locale elements

static NSDictionary* nameSpaceMapping;

static const NSInteger FORM_LONG = 0;
static const NSInteger FORM_SHORT = 1;
static const NSInteger FORM_VERB = 2;
static const NSInteger FORM_VERB_SHORT = 3;
static const NSInteger FORM_SYMBOL = 4;


@interface CSLLocaleTerm : NSObject{
}

@property (retain, nonatomic) NSString* single;
@property (retain, nonatomic) NSString* multiple;
@property (retain, nonatomic) CSLLocaleTerm* shortForm;
@property (retain, nonatomic) CSLLocaleTerm* symbolForm;
@property (retain, nonatomic) CSLLocaleTerm* verbForm;
@property (retain, nonatomic) CSLLocaleTerm* verbShortForm;

-(id)initWithXMLElement:(CXMLElement*)element;

@end

@implementation CSLLocaleTerm

@synthesize single, multiple, shortForm, symbolForm, verbForm, verbShortForm;

-(id)initWithXMLElement:(CXMLElement*)element{
    self = [super init];
    if([element childCount]>1){
        for(CXMLNode* child in element.children){
            if([child isKindOfClass:[CXMLElement class]]){
                CXMLElement* childElement = (CXMLElement*) child;
                if([childElement.name isEqualToString:@"single"]){
                    self.single = childElement.stringValue;
                }
                else if([childElement.name isEqualToString:@"multiple"]){
                    self.multiple = childElement.stringValue;
                }
            }
        }
    }
    else{
        self.single = [element stringValue];
        self.multiple = self.single;
    }
    return self;
}

@end


@interface CSLLocale : NSObject{
    NSDictionary* terms;
}

-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter;
-(void)addTermsFromElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter;

-(NSString*)localizedStringForTerm:(NSString*)term plural:(BOOL)plural form:(NSInteger)form;
@end



#pragma mark - Rendered elements - declarations

// Base class for rendering elements

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

//Base class for all elements which have rendering elements as children

@interface CSLRenderingElementContainer : CSLRenderingElement{
    NSArray* childElements;
    NSString* delimiter;
}
-(NSArray*)childElements;

@end

// Class for bibliography and citation elements

@interface CSLBibliographyOrCitation : CSLRenderingElement{
    CSLRenderingElement* child;
}

@property (assign, nonatomic) NSInteger etAlUseFirst;
@property (assign, nonatomic) BOOL etAlUseLast;

@end

@interface CSLChoose : CSLRenderingElement{
    NSArray* conditions;
}

@end

@interface CSLIfElseCondition : CSLRenderingElementContainer{
    NSString* typeFieldName;
    NSInteger matchType;
    NSInteger matchCriterion;
    NSArray* matchValues;
    BOOL isElse;
}
-(BOOL) matchesWithFields:(NSDictionary*) fields;
@end

@interface CSLGroup : CSLRenderingElementContainer{

}
@end;

@interface CSLDate : CSLRenderingElementContainer{
    NSString* variable;
}
@end;

@interface CSLDatePart : CSLRenderingElement{
    NSInteger form;
    NSInteger datePart;
}
-(NSString*) _parseDate:(NSString*)dateValue part:(NSInteger)part;

@property (retain, nonatomic) NSString* variable;

@end

@interface CSLText : CSLRenderingElement{
    NSInteger textCase;
    NSInteger type;
    BOOL plural;
    NSInteger form;
    NSString* value;
    BOOL stripPeriods;
    NSInteger fontStyle;
    BOOL quotes;
    CSLRenderingElementContainer* macroObject;
}
@end

@interface CSLLabel : CSLText{
    
}
@property (assign) BOOL plural;
@property (retain, nonatomic) NSString* variable;

@end

@interface CSLNumber: CSLText{
    NSInteger numberForm;
}

@end

@interface CSLNames : CSLRenderingElement{
    NSArray* variables;
    CSLRenderingElementContainer* substitutes;
    NSString* delimiter;
    NSString* initializeWith;
    NSInteger andMode;
    NSString* nameDelimiter;
    NSInteger nameAsSortOrder;
    NSString* sortSeparator;
    NSInteger delimiterPrecedesLast;
    NSInteger nameForm;
    CSLLabel* label;
}

@end

@interface CSLMacro : CSLRenderingElementContainer{
    NSString* name;
}

@end

@interface CSLFormatter(){
    CSLLocale* _currentLocale;
    NSDictionary* _macros;
    CSLBibliographyOrCitation* _bibliography;
}

-(CSLRenderingElementContainer*) macroWithName:(NSString*)name;
-(NSString*) localizedStringForTerm:(NSString*)term plural:(BOOL)plural form:(NSInteger)form;
+(NSInteger) _formAsInteger:(NSString*)form;
@end

#pragma -mark Locale implementations

@implementation CSLLocale


-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    self = [super init];
    terms = [[NSDictionary alloc] init];
    [self addTermsFromElement:element formatter:formatter];
    return self;
}

-(void)addTermsFromElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:terms];
    
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

#pragma mark - Rendered elements - implementations

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

@implementation CSLIfElseCondition


/*
 "all" - (default), element only tests "true" when all conditions test "true" for all given test values
 "any" - element tests "true" when any condition tests "true" for any given test value
 "none" - element only tests "true" when none of the conditions test "true" for any given test value
 */

static NSInteger MATCH_ALL = 0;
static NSInteger MATCH_ANY = 1;
static NSInteger MATCH_NONE = 2;

static NSInteger CRITERION_VARIABLE = 0;
static NSInteger CRITERION_TYPE = 1;

-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter{

    self = [super initWithXMLElement:element formatter:formatter];
    
    isElse = [[element name] isEqualToString:@"else"];
    typeFieldName = @"type";
    return self;
}

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{

    if([attributeName isEqualToString:@"type"]){
        matchCriterion = CRITERION_TYPE;

        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for(NSString* var in [attributeValue componentsSeparatedByString:@" "]){
            [temp addObject:var];
        }
        matchValues = [NSArray arrayWithArray:temp];
    }
    else if([attributeName isEqualToString:@"variable"]){
        matchCriterion = CRITERION_VARIABLE;

        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for(NSString* var in [attributeValue componentsSeparatedByString:@" "]){
            [temp addObject:var];
        }
        matchValues = [NSArray arrayWithArray:temp];
    }
    else if([attributeName isEqualToString:@"match"]){
        if([attributeValue isEqualToString:@"all"]){
            matchType=MATCH_ALL;
        }
        else if([attributeValue isEqualToString:@"any"]){
            matchType=MATCH_ANY;
        }
        else if([attributeValue isEqualToString:@"none"]){
            matchType=MATCH_NONE;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Match type '%@' is not implemented for 'if' nodes",attributeValue];
        }
    }
}

-(BOOL) matchesWithFields:(NSDictionary*) fields{

    if(isElse){
        return TRUE;
    }
    else{
        if(matchCriterion == CRITERION_TYPE){
           NSString* type = [fields objectForKey:typeFieldName];
            if(type == NULL){
                [NSException raise:@"Item type cannot be null" format:@""];
            }
            if(matchType==MATCH_NONE){
                return ! [matchValues containsObject:type];
            }
            else{
                return [matchValues containsObject:type];
            }
        }
        else if(matchCriterion == CRITERION_VARIABLE){

            for(NSString* variable in matchValues){
                BOOL match;
                
                NSObject* valueObject = [fields objectForKey:variable];
                if(valueObject == NULL) match=false;
                else if ([valueObject isKindOfClass:[NSString class]])
                    match = ! [(NSString*)valueObject isEqualToString:@""];
                else match = [(NSArray*) valueObject count] > 0;

                if(matchType == MATCH_ANY && match) return TRUE;
                else if (matchType == MATCH_ALL && ! match) return FALSE;
                else if (matchType == MATCH_NONE && match) return FALSE;
            }
            
            return matchType != MATCH_ANY;
        }
        else{
            [NSException raise:@"Internal consistency exception" format:@"Internal consistency exception"];
            return FALSE;
        }

    }
}

@end

@interface CSLChoose()

-(CSLIfElseCondition*) _elementToRenderBasedOnFields:(NSMutableDictionary*)fields;

@end


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

@implementation CSLText


/*
 variable - renders the text contents of a variable. Attribute value must be one of the standard variables. May be accompanied by the form attribute to select the "long" (default) or "short" form of a variable (e.g. the full or short title). If the "short" form is selected but unavailable, the "long" form is rendered instead.
 macro - renders the text output of a macro. Attribute value must match the value of the name attribute of a cs:macro element (see Macro).
 term - renders a term. Attribute value must be one of the terms listed in Appendix II - Terms. May be accompanied by the plural attribute to select the singular ("false", default) or plural ("true") variant of a term, and by the form attribute to select the "long" (default), "short", "verb", "verb-short" or "symbol" form variant (see also Terms).
 value - renders the attribute value itself.

 "lowercase": renders text in lowercase
 "uppercase": renders text in uppercase
 "capitalize-first": capitalizes the first character of the first word, if the word is lowercase
 "capitalize-all": capitalizes the first character of every lowercase word
 "sentence": renders text in sentence case
 "title": renders text in title case
 
 "long" (default), "short", "verb", "verb-short" or "symbol" form 
 
 */

static const NSInteger TYPE_VARIABLE = 1;
static const NSInteger TYPE_MACRO = 2;
static const NSInteger TYPE_TERM = 3;
static const NSInteger TYPE_VALUE = 4;

static const NSInteger CASE_LOWERCASE = 1;
static const NSInteger CASE_UPPERCASE = 2;
static const NSInteger CASE_CAPITALIZE_FIRST = 3;
static const NSInteger CASE_CAPITALIZE_ALL = 4;
static const NSInteger CASE_SENTENCE = 5;
static const NSInteger CASE_TITLE = 6;

static const NSInteger FONT_STYLE_NORMAL = 0;
static const NSInteger FONT_STYLE_ITALIC = 1;
static const NSInteger FONT_STYLE_OBLIQUE = 2;

-(void) configureWithAttribute:(NSString *)key value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    
    
    if([key isEqualToString:@"variable"]){
        type = TYPE_VARIABLE;
        value = attributeValue;
    }
    else if([key isEqualToString:@"macro"]){
        type = TYPE_MACRO;
        value = attributeValue;
    }
    else if([key isEqualToString:@"term"]){
        type = TYPE_TERM;
        value = attributeValue;
    }
    else if([key isEqualToString:@"value"]){
        type = TYPE_VARIABLE;
        value = attributeValue;
    }
    else if([key isEqualToString:@"plural"]){
        plural = [attributeValue isEqualToString:@"true"];
    }
    else if([key isEqualToString:@"text-case"]){
        if([attributeValue isEqualToString:@"lowercase"]){
            textCase = CASE_LOWERCASE;
        }
        else if([attributeValue isEqualToString:@"uppercase"]){
            textCase = CASE_UPPERCASE;
        }
        else if([attributeValue isEqualToString:@"capitalize-first"]){
            textCase = CASE_CAPITALIZE_FIRST;
        }
        else if([attributeValue isEqualToString:@"capitalize-all"]){
            textCase = CASE_CAPITALIZE_ALL;
        }
        else if([attributeValue isEqualToString:@"sentence"]){
            textCase = CASE_SENTENCE;
        }
        else if([attributeValue isEqualToString:@"title"]){
            textCase = CASE_TITLE;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Not implemented"];
        }
    }
    else if([key isEqualToString:@"font-style"]){
        if([attributeValue isEqualToString:@"normal"]){
            fontStyle = FONT_STYLE_NORMAL;
        }
        else if([attributeValue isEqualToString:@"italic"]){
            fontStyle = FONT_STYLE_ITALIC;
        }
        else if([attributeValue isEqualToString:@"oblique"]){
            fontStyle = FONT_STYLE_OBLIQUE;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Not implemented"];
        }
    }
    else if([key isEqualToString:@"strip-periods"] && [attributeValue isEqualToString:@"true"] ){
        stripPeriods =TRUE;
    }
    else if([key isEqualToString:@"form"]){
        form = [CSLFormatter _formAsInteger:attributeValue];
    }
    else if([key isEqualToString:@"quotes"]){
        quotes = [value isEqualToString:@"true"];
    }

    else{
        [super configureWithAttribute:key value:attributeValue formatter:formatter];
    }
}
-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary*) macros{

    NSString* mainContent;
    
    switch (type) {
        case TYPE_MACRO:
            if(macroObject == NULL){
                macroObject = [formatter macroWithName:value];
            }
            mainContent = [macroObject renderContentForFields:fields formatter:formatter rootElement:rootElement storeMacrosInDictionary:macros];

            //Store the macro value so that it is available in the output
            if(macros!=NULL && mainContent != NULL) [macros setObject:mainContent forKey:value];
            
            break;
        case TYPE_VALUE:
            mainContent = value;
            break;
        case TYPE_TERM:
            //This could be optimized by keeping a reference to the CSLTerm object in the CSLText object.
            mainContent = [formatter localizedStringForTerm:value plural:plural form:form];
            break;
        case TYPE_VARIABLE:
            mainContent = [fields objectForKey:value];
            break;
            
        default:
            [NSException raise:@"Not implemented" format:@"Not implemented"];
            break;
    }
    if(mainContent!=NULL && ! [mainContent isEqualToString:@""]) return [self postProcessRenderedString:mainContent];
    else return NULL;
}

static NSArray* stopWords;

-(NSString*) postProcessRenderedString:(NSString *)renderedString{
    
    switch (textCase) {
            
        case CASE_CAPITALIZE_ALL:
            renderedString = [renderedString capitalizedString];
            break;
            
        case CASE_CAPITALIZE_FIRST :
            renderedString = [renderedString stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[renderedString substringToIndex:1] uppercaseString]];
            break;
            
        case CASE_LOWERCASE:
            renderedString = [renderedString lowercaseString];
            break;
            
        case CASE_UPPERCASE:
            renderedString = [renderedString uppercaseString];
            break;
            
            
            /*
             For uppercase strings, the first character of the string remains capitalized. All other letters are lowercased.
             For lower or mixed case strings, the first character of the first word is capitalized if the word is lowercase. The case of all other words stays the same.
             */
            
        case CASE_SENTENCE:
            //All upper case
            if([[renderedString uppercaseString] isEqualToString:renderedString]){
                renderedString = [renderedString stringByReplacingCharactersInRange:NSMakeRange(1,[renderedString length]-1) withString:[[renderedString substringFromIndex:1] lowercaseString]];
            }
            else{
                renderedString = [renderedString stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[renderedString substringToIndex:1] uppercaseString]];
            }
            break;
            
            
            /*
             Title case conversion (with text-case set to "title") for English-language items is performed by:
             
             For uppercase strings, the first character of each word remains capitalized. All other letters are lowercased.
             For lower or mixed case strings, the first character of each lowercase word is capitalized. The case of words in mixed or uppercase stays the same.
             In both cases, stop words are lowercased, unless they are the first or last word in the string, or follow a colon. The stop words are "a", "an", "and", "as", "at", "but", "by", "down", "for", "from", "in", "into", "nor", "of", "on", "onto", "or", "over", "so", "the", "till", "to", "up", "via", "with", and "yet".
             
             TODO: implement non-english terms.
             
             Non-English Items
             
             As many languages do not use title case, title case conversion (with text-case set to "title") only affects English-language items.
             
             If the default-locale attribute on cs:style isn't set, or set to a locale code with a primary language tag of "en" (English), items are assumed to be English. An item is only considered to be non-English if its metadata contains a language field with a non-nil value that doesn't start with the "en" primary language tag.
             
             If default-locale is set to a locale code with a primary language tag other than "en", items are assumed to be non-English. An item is only considered to be English if the value of its language field starts with the "en" primary language tag.
             */
            
        case CASE_TITLE:

            if(stopWords== NULL){
                stopWords = [NSArray arrayWithObjects: @"a", @"an", @"and", @"as", @"at", @"but", @"by", @"down", @"for", @"from", @"in", @"into", @"nor", @"of", @"on", @"onto", @"or", @"over", @"so", @"the", @"till", @"to", @"up", @"via", @"with", @"yet", nil];
            }
            
        {
            NSArray* words = [renderedString componentsSeparatedByString:@" "];
            NSMutableArray* convertedWords = [[NSMutableArray alloc] initWithCapacity:[words count]];
            
            BOOL allUpper = [[renderedString uppercaseString] isEqualToString:renderedString];
            
            BOOL followColon = FALSE;
            BOOL first = TRUE;
            BOOL last = FALSE;
            
            NSInteger counter = 0;
            for(NSString* word in words){
            
                last = (++counter == [words count]);
                NSString* lowerCaseWord = [word lowercaseString];
                BOOL stopWord = [stopWords containsObject:lowerCaseWord];
                
                if(stopWord && ! first && ! last && ! followColon){
                    [convertedWords addObject:lowerCaseWord];
                }
                else if(allUpper){
                    [convertedWords addObject:[word stringByReplacingCharactersInRange:NSMakeRange(1,[word length]-1) withString:[[word substringFromIndex:1] lowercaseString]]];
                }
                else{
                    if([word isEqualToString:lowerCaseWord]){
                        [convertedWords addObject:[renderedString stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[renderedString substringToIndex:1] uppercaseString]]];
                    }
                    else{
                        [convertedWords addObject:word];
                    }
                }
                
                followColon = [word hasSuffix:@":"];
                first = FALSE;
            }
            
            renderedString = [convertedWords componentsJoinedByString:@" "];

        }
            break;
            
            
        default:
            break;
    }
    
    switch (fontStyle) {
        case FONT_STYLE_NORMAL:
            break;
            
        case FONT_STYLE_OBLIQUE:
            [NSException raise:@"Not implemented" format:@"Oblique font style has not been implemented"];
        
            break;
        case FONT_STYLE_ITALIC:
            renderedString = [NSString stringWithFormat:@"<i>%@</i>",renderedString];
            break;
        default:
            break;
    }
    
    if(stripPeriods){
        renderedString = [renderedString stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    
    return [super postProcessRenderedString:renderedString];
}
-(BOOL) containsVariablesFields:(NSMutableDictionary*)fields formatter:(CSLFormatter*)formatter{
    switch (type) {
        case TYPE_VARIABLE:
            return TRUE;
            break;
        
        case TYPE_MACRO:
            if(macroObject == NULL){
                macroObject = [formatter macroWithName:value];
            }
            return [macroObject containsVariablesFields:fields formatter:formatter];
            break;
        default:
            return FALSE;
            break;
    }
}
-(BOOL) allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter*)formatter;
{
    switch (type) {
        case TYPE_VARIABLE:
        {
            //Year-suffix is not implemented, but not suppress output
            if([value isEqualToString:@"year-suffix"]) return FALSE;
            
            NSObject* valueObject = [fields objectForKey:value];
            if(valueObject == NULL) return TRUE;
            else if ([valueObject isKindOfClass:[NSString class]])
                return [(NSString*)valueObject isEqualToString:@""];
            else return [(NSArray*)valueObject count] == 0;
        }
            break;
            
        case TYPE_MACRO:
            if(macroObject == NULL){
                macroObject = [formatter macroWithName:value];
            }
            return [macroObject allVariablesAreEmptyWithFields:fields formatter:formatter];
            break;
        default:
            [NSException raise:@"Internal consistency exception" format:@"Internal consistency exception"];
            return FALSE;
            break;
    }
    
}
@end

@implementation CSLMacro

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"name"]){
        name = attributeValue;
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue  formatter:formatter];
    }
}

@end

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

@implementation CSLNumber

/*
 "numeric" - (default), e.g. "1", "2", "3"
 "ordinal" - e.g. "1st", "2nd", "3rd". Ordinal suffixes are defined with terms (see Ordinal Suffixes).
 "long-ordinal" - e.g. "first", "second", "third". Long ordinals are defined with the terms "long-ordinal-01" to "long-ordinal-10", which are used for the numbers 1 through 10. For other numbers "long-ordinal" falls back to "ordinal".
 "roman" - e.g. "i", "ii", "iii"
 
 */

static const NSInteger NUMBER_FORM_NUMERIC = 0;
static const NSInteger NUMBER_FORM_ORDINAL = 1;
static const NSInteger NUMBER_FORM_LONG_ORDINAL = 2;
static const NSInteger NUMBER_FORM_ROMAN = 3;

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"form"]){
        if([attributeValue isEqualToString:@"numeric"]){
            numberForm = NUMBER_FORM_NUMERIC;
        }
        else if([attributeValue isEqualToString:@"ordinal"]){
            numberForm = NUMBER_FORM_ORDINAL;
        }
        else if([attributeValue isEqualToString:@"long-ordinal"]){
            numberForm = NUMBER_FORM_LONG_ORDINAL;
        }
        else if([attributeValue isEqualToString:@"roman"]){
            numberForm = NUMBER_FORM_ROMAN;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute form of element number",attributeValue];
        }
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
}

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
-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation*)rootElement storeMacrosInDictionary:(NSMutableDictionary *)macros{
    NSMutableString* namesString = [[NSMutableString alloc] init];

    BOOL hasNames = FALSE;
    
    for(NSString* nameVariable in variables){
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
                    [NSException raise:@"Not implemented" format:@"Rendering of non-personal names has not been implemented"];
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
    
    if(hasNames){
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

@implementation CSLDate

-(id) initWithXMLElement:(CXMLElement *)element formatter:(CSLFormatter *)formatter{
    self= [super initWithXMLElement:element formatter:formatter];

    for(CSLDatePart* child in childElements){
        child.variable = variable;
    }
    return self;
}
    
-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"variable"]){
        variable = attributeValue;
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
}

@end

@implementation CSLDatePart

/*
 For "day", cs:date-part may carry the form attribute, with values:
 
 "numeric" - (default), e.g. "1"
 "numeric-leading-zeros" - e.g. "01"
 "ordinal" - e.g. "1st"
 Some languages, such as French, only use the "ordinal" form for the first day of the month ("1er janvier", "2 janvier", "3 janvier", etc.). Such output can be achieved with the "ordinal" form and use of the limit-day-ordinals-to-day-1 attribute (see Locale Options).
 
 "month"
 For "month", cs:date-part may carry the strip-periods and form attributes. In locale files, month abbreviations (the "short" form of the month terms) should be defined with periods if applicable (e.g. "Jan.", "Feb.", etc.). These periods can be removed by setting strip-periods to "true" ("false" is the default). The form attribute can be set to:
 
 "long" - (default), e.g. "January"
 "short" - e.g. "Jan."
 "numeric" - e.g. "1"
 "numeric-leading-zeros" - e.g. "01"
 "year"
 For "year", cs:date-part may carry the form attribute, with values:
 
 "long" - (default), e.g. "2005"
 "short" - e.g. "05"
 */

static const NSInteger DATE_PART_FORM_NUMERIC = 1;
static const NSInteger DATE_PART_FORM_NUMERIC_LEADING_ZEROS = 2;
static const NSInteger DATE_PART_FORM_ORDINAL = 3;
static const NSInteger DATE_PART_FORM_SHORT = 4;
static const NSInteger DATE_PART_FORM_LONG = 5;

static const NSInteger DATE_PART_DAY = 1;
static const NSInteger DATE_PART_MONTH = 2;
static const NSInteger DATE_PART_YEAR = 3;

static NSRegularExpression* REGEX_FIRST_FOUR_DIGIT_YEAR;
static NSRegularExpression* REGEX_MONTH;
static NSRegularExpression* REGEX_DAY;

static NSArray* MONTH_NAMES;

@synthesize variable;

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"form"]){
        if([attributeValue isEqualToString:@"numeric"]){
            form = DATE_PART_FORM_NUMERIC;
        }
        else if([attributeValue isEqualToString:@"ordinal"]){
            form = DATE_PART_FORM_ORDINAL;
        }
        else if([attributeValue isEqualToString:@"numeric-leading-zeros"]){
            form = DATE_PART_FORM_NUMERIC_LEADING_ZEROS;
        }
        else if([attributeValue isEqualToString:@"long"]){
            form = DATE_PART_FORM_LONG;
        }
        else if([attributeValue isEqualToString:@"short"]){
            form = DATE_PART_FORM_SHORT;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute form of element date-part",attributeValue];
        }
    }
    else if([attributeName isEqualToString:@"name"]){
        if([attributeValue isEqualToString:@"day"]){
            datePart = DATE_PART_DAY;
            if(form == 0) form = DATE_PART_FORM_NUMERIC;
        }
        else if([attributeValue isEqualToString:@"month"]){
            datePart = DATE_PART_MONTH;
            if(form == 0) form = DATE_PART_FORM_LONG;
        }
        else if([attributeValue isEqualToString:@"year"]){
            datePart = DATE_PART_YEAR;
            if(form == 0) form = DATE_PART_FORM_LONG;
        }
        else{
            [NSException raise:@"Not implemented" format:@"Attribute value %@ has not been implemented for attribute name of element date-part",attributeValue];
        }
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
}
-(NSString*) renderContentForFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter rootElement:(CSLBibliographyOrCitation *)rootElement storeMacrosInDictionary:(NSMutableDictionary *)macros{
    NSString* dateValue = [fields objectForKey:self.variable];
    
    NSString* parsedValue = [self _parseDate:dateValue part:datePart];
    if(parsedValue!=NULL){
        return [self postProcessRenderedString:parsedValue];
    }
    else{
        return NULL;
    }
}
-(BOOL) containsVariablesFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter{
    return TRUE;
}
-(BOOL) allVariablesAreEmptyWithFields:(NSMutableDictionary *)fields formatter:(CSLFormatter *)formatter{
    NSString* dateValue = [fields objectForKey:self.variable];
    
    if(dateValue == NULL) return TRUE;
    
    return [self _parseDate:dateValue part:datePart] == NULL;
}

-(NSString*) _parseDate:(NSString*)dateValue part:(NSInteger)part{
    if(datePart == DATE_PART_YEAR){
        if(REGEX_FIRST_FOUR_DIGIT_YEAR == NULL){
            REGEX_FIRST_FOUR_DIGIT_YEAR = [NSRegularExpression regularExpressionWithPattern:@"[1-9][0-9][0-9][0-9]" options:0 error:NULL];
        }
        
        NSRange rangeOfFirstMatch = [REGEX_FIRST_FOUR_DIGIT_YEAR rangeOfFirstMatchInString:dateValue options:0 range:NSMakeRange(0, [dateValue length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [dateValue substringWithRange:rangeOfFirstMatch];
            return substringForFirstMatch;
            
        }
        else return dateValue;
    }
    else if(datePart == DATE_PART_MONTH){
        if(REGEX_MONTH == NULL){
            REGEX_MONTH = [NSRegularExpression regularExpressionWithPattern:@"-[0-1][0-9]-" options:0 error:NULL];
        }
        if(MONTH_NAMES == NULL){
            MONTH_NAMES = [NSArray arrayWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December", nil];
        }

        NSRange rangeOfFirstMatch = [REGEX_MONTH rangeOfFirstMatchInString:dateValue options:0 range:NSMakeRange(0, [dateValue length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [dateValue substringWithRange:NSMakeRange(rangeOfFirstMatch.location+1, 2)];
            return [MONTH_NAMES objectAtIndex:[substringForFirstMatch integerValue]-1];
            
        }
    }
    else if(datePart == DATE_PART_DAY){
        if(REGEX_DAY == NULL){
            REGEX_DAY = [NSRegularExpression regularExpressionWithPattern:@"-[0-3][0-9] " options:0 error:NULL];
        }
        NSRange rangeOfFirstMatch = [REGEX_DAY rangeOfFirstMatchInString:dateValue options:0 range:NSMakeRange(0, [dateValue length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [dateValue substringWithRange:NSMakeRange(rangeOfFirstMatch.location+1, 2)];

            if([substringForFirstMatch hasPrefix:@"0"]){
                return [substringForFirstMatch substringFromIndex:1];
            }
            else{
                return substringForFirstMatch;
            }
        }
    }
    
    return NULL;

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
    
    nameSpaceMapping = [NSDictionary dictionaryWithObject:@"http://purl.org/net/xbiblio/csl" forKey:@"ns"];
    
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


+(NSInteger) _formAsInteger:(NSString*) attributeValue{
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
