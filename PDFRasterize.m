//
//  PDFRasterize.m
//  pdfrasterize
//
//  Created by Cédric Luthi on 14.12.09.
//  Copyright 2009 Cédric Luthi. All rights reserved.
//

#import "PDFRasterize.h"

@implementation PDFRasterize

- (void) application:(DDCliApplication *)app willParseOptions:(DDGetoptLongParser *)optionsParser;
{
	DDGetoptOption optionTable[] = 
	{
	    // Long         Short   Argument options
	    {@"output-dir", 'o',    DDGetoptRequiredArgument},
	    {@"help",       'h',    DDGetoptNoArgument},
	    {nil,           0,      0},
	};
	[optionsParser addOptionsFromTable: optionTable];
}

- (int) application:(DDCliApplication *)app runWithArguments:(NSArray *)arguments;
{
	ddprintf(@"OutputDir: %@, help: %d\n", outputDir, help);
	ddprintf(@"Arguments: %@\n", arguments);
	return EXIT_SUCCESS;
}

@end
