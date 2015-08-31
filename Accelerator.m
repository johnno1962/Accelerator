//
//  Accelerator.m
//  Accelerator
//
//  Created by John Holdsworth on 29/08/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#ifdef DEBUG
#import <Foundation/Foundation.h>
#import <dlfcn.h>

@implementation NSObject(Inline)

+ (void)load {
    static int addr;
    Dl_info info;
    dladdr( &addr, &info );
    NSLog( @"Accelerator: Loaded substitute %s.framework", strrchr( info.dli_fname, '/' )+1 );
}

@end
#endif
