//
//  CSLLabel.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//


#import "CSLText.h"

@interface CSLLabel : CSLText{
    
}
@property (assign) BOOL plural;
@property (retain, nonatomic) NSString* variable;

@end

