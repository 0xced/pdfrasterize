//
//  PDFRasterize.m
//  pdfrasterize
//
//  Created by Cédric Luthi on 14.12.09.
//  Copyright 2009 Cédric Luthi. All rights reserved.
//

#import "PDFRasterize.h"

@implementation PDFRasterize

// MARK: Options handling

- (id) init
{
	self = [super init];
	if (self != nil) {
		help = NO;
		outputDir = @".";
	}
	return self;
}

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

- (void) setOutputDir:(NSString *)theOutputDir
{
	BOOL isDirectory;
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:theOutputDir isDirectory:&isDirectory];
	
	if (fileExists) {
		if (isDirectory) {
			outputDir = [theOutputDir copy];
		} else {
			@throw [DDCliParseException parseExceptionWithReason:@"Invalid output directory" exitCode:ENOENT];
		}
	} else {
		@throw [DDCliParseException parseExceptionWithReason:@"Output directory does not exist" exitCode:ENOENT];
	}
}

- (void) printUsage:(FILE *)stream;
{
	ddfprintf(stream, @"Usage: %@ [options] file\n", DDCliApp);
}

- (int) application:(DDCliApplication *)app runWithArguments:(NSArray *)arguments;
{
	if ([arguments count] < 1) {
		ddfprintf(stderr, @"%@: At least one pdf file is required\n", DDCliApp);
		[self printUsage:stderr];
		return EX_USAGE;
	}
	
	NSString *pdfPath = [arguments objectAtIndex:0];
	if (![[NSFileManager defaultManager] fileExistsAtPath:pdfPath]) {
		ddfprintf(stderr, @"%@: %@: No such file\n", DDCliApp, pdfPath);
		return ENOENT;
	}
	
	return [self rasterize:pdfPath];
}

- (int) rasterize:(NSString *)pdfPath
{
	return EXIT_SUCCESS;
}

@end
