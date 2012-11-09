//
//  CSLMacro.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElementContainer.h"

@interface CSLMacro : CSLRenderingElementContainer{
    NSString* name;
}

@end

@interface CSLFormatter()

-(CSLRenderingElementContainer*) macroWithName:(NSString*)name;

@end