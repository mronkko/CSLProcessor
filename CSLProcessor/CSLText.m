//
//  CSLText.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLText.h"
#import "CSLFormatter.h"
#import "CSLMacro.h"

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
        form = [CSLFormatter formAsInteger:attributeValue];
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
