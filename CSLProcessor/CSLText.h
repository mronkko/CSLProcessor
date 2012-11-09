//
//  CSLText.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElement.h"
#import "CSLRenderingElementContainer.h"

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