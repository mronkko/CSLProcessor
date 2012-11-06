//
//  main.m
//  CSLParser
//
//  Created by Rönkkö Mikko on 9/14/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../json-framework/Classes/SBJson.h"
#import "CSLFormatter.h"
#import "NSString+HTML.h"

int main(int argc, const char * argv[])
{
    
    NSLog(@"Started");
    NSString *path = [[NSBundle mainBundle] pathForResource: @"json" ofType: @"txt"];
    NSString *fileContents = [NSString stringWithContentsOfFile:path];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];

    
    NSString *citationsPath = [[NSBundle mainBundle] pathForResource: @"citations" ofType: @"txt"];
    NSString *citationsFileContents = [NSString stringWithContentsOfFile:citationsPath];
    NSArray *citationsLines = [citationsFileContents componentsSeparatedByString:@"\n"];

    CSLFormatter* formatter=[[CSLFormatter alloc] initWithCSLFile:[[NSBundle mainBundle] pathForResource: @"apa" ofType: @"csl"]
                                                           localeFile:[[NSBundle mainBundle] pathForResource: @"locales-en-US" ofType: @"xml"]
                                                         fieldMapFile:[[NSBundle mainBundle] pathForResource: @"typeMap" ofType: @"xml"]];

    NSInteger i = 0;
    for(NSString* line in lines){
        
        NSMutableDictionary* fields = [NSMutableDictionary dictionaryWithDictionary:[line JSONValue]];
        
        //Get creators as separate variables
        for(NSDictionary* creator in [fields objectForKey:@"creators"]){
            NSString* type = [creator objectForKey:@"creatorType"];
            
            NSMutableArray* creatorArray = [fields objectForKey:type];
            if(creatorArray == NULL){
                creatorArray = [[NSMutableArray alloc] init];
                [fields setObject:creatorArray forKey:type];
            }
            [creatorArray addObject:creator];
        }
        
        NSString* citation = [citationsLines objectAtIndex:i++];
        
        if(i>54){
            citation = [citation stringByDecodingHTMLEntities];
            
            NSMutableDictionary* macroDict = [[NSMutableDictionary alloc] init];
            NSString* generatedCitation = [formatter formatBibliographyItemUsingVariables:fields storeMacrosInDictionary:macroDict];
            
            generatedCitation = [generatedCitation stringByConvertingHTMLToPlainText];
            citation = [citation stringByConvertingHTMLToPlainText];
            
            if(! [generatedCitation isEqualToString:citation]){
                NSLog(@"\n%i\n%@\n\nGenerated: '%@'\nOriginal:  '%@'\n\n",i, line, generatedCitation,citation);
                
                NSInteger limit = MIN([generatedCitation length],[citation length]);
                
                for(NSInteger j=0;j<limit;++j){
                    unichar g = [generatedCitation characterAtIndex:j];
                    unichar o = [citation characterAtIndex:j];
                    
                    if(o!=g){
                        NSString* charString = [generatedCitation substringWithRange:NSMakeRange(j, 1)];
                        NSLog(@"Character at %i (%@) differs. Original: %i Generated: %i",j,charString,(NSInteger) o, (NSInteger) g);
                    }
                }
                
                break;
            }
        }
    }
    NSLog(@"Done");
        
    return 0;
}
