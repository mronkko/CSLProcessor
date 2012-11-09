//
//  CSLFormatter.h
//  CSLParser
//
//  Created by Rönkkö Mikko on 9/14/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface CSLFormatter : NSObject{
    NSDictionary* fieldMap;
    NSDictionary* typeMap;
}

/*

 Initializes the formatter
 
 @param cslPath path to a csl file
 @param localePath path to a locale file
 @param fieldMap path to an XML file containing field mapping.
 
 */

-(id) initWithCSLFile:(NSString*)cslPath localeFile:(NSString*)localePath fieldMapFile:(NSString*)fieldMapPath;

/*

 Returns a formatted bibliography item.
 
 @param creators an array of dictionaries created from Zotero server response
 @param fields a dictionary of fields created from Zotero server response
 
 */

-(NSString*) formatBibliographyItemUsingVariables:(NSDictionary*)variables;
-(NSString*) formatBibliographyItemUsingVariables:(NSDictionary*)variables storeMacrosInDictionary:(NSMutableDictionary*) macros;


//Used internally (refactor so that these are not declared here)

-(NSString*) localizedStringForTerm:(NSString*)term plural:(BOOL)plural form:(NSInteger)form;
+(NSInteger) formAsInteger:(NSString*)form;


@end
