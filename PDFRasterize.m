//
//  PDFRasterize.m
//  pdfrasterize
//
//  Created by Cédric Luthi on 14.12.09.
//  Copyright 2009 Cédric Luthi. All rights reserved.
//

#import "PDFRasterize.h"

@implementation PDFRasterize

- (id) init
{
	self = [super init];
	if (self != nil) {
		help = NO;
		outputDir = @".";
		format = @"png";
		transparent = NO;
		scale = 1.0;
		
		bitmapFormatUTIs = [[NSMutableDictionary alloc] initWithCapacity:6];
		[bitmapFormatUTIs setObject:(id)kUTTypeJPEG     forKey:@"jpg"];
		[bitmapFormatUTIs setObject:(id)kUTTypeJPEG2000 forKey:@"jp2"];
		[bitmapFormatUTIs setObject:(id)kUTTypeTIFF     forKey:@"tiff"];
		[bitmapFormatUTIs setObject:(id)kUTTypeGIF      forKey:@"gif"];
		[bitmapFormatUTIs setObject:(id)kUTTypePNG      forKey:@"png"];
		[bitmapFormatUTIs setObject:(id)kUTTypeBMP      forKey:@"bmp"];
	}
	return self;
}

// MARK: Options handling

- (void) application:(DDCliApplication *)app willParseOptions:(DDGetoptLongParser *)optionsParser;
{
	DDGetoptOption optionTable[] = 
	{
	    // Long          Short   Argument options
	    {@"help",        'h',    DDGetoptNoArgument},
	    {@"output-dir",  'o',    DDGetoptRequiredArgument},
	    {@"format",      'f',    DDGetoptRequiredArgument},
	    {@"transparent", 't',    DDGetoptNoArgument},
	    {@"scale",       's',    DDGetoptRequiredArgument},
	    {nil,             0,     0},
	};
	[optionsParser addOptionsFromTable:optionTable];
}

- (void) setFormat:(NSString *)theFormat
{
	NSString *formatId = [theFormat lowercaseString];
	if ([[bitmapFormatUTIs allKeys] containsObject:formatId]) {
		format = [formatId copy]; // leaked, but we don't care
	} else {
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"Unknown format: %@", formatId] exitCode:EX_USAGE];
	}
}

- (void) setScale:(NSString *)theScaleFactor
{
	NSScanner *scanner = [NSScanner scannerWithString:theScaleFactor];
	BOOL validFloat = [scanner scanFloat:&scale];
	if (!(validFloat && [scanner isAtEnd])) {
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"Invalid scale factor: %@", theScaleFactor] exitCode:EX_USAGE];
	}
}

- (void) setOutputDir:(NSString *)theOutputDir
{
	BOOL isDirectory;
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:theOutputDir isDirectory:&isDirectory];
	
	if (fileExists) {
		if (isDirectory) {
			outputDir = [theOutputDir copy]; // leaked, but we don't care
		} else {
			@throw [DDCliParseException parseExceptionWithReason:@"Invalid output directory" exitCode:ENOENT];
		}
	} else {
		@throw [DDCliParseException parseExceptionWithReason:@"Output directory does not exist" exitCode:ENOENT];
	}
}

// MARK: CLI handling

- (void) printUsage:(FILE *)stream;
{
	ddfprintf(stream, @"Usage: %@ [options] file\n", DDCliApp);
}

- (void) printHelp
{
	[self printUsage:stdout];
	ddprintf(@"Options:\n"
	         @"    -o, --output-dir DIR          Rasterized files go into DIR -- Default is current working directory\n"
	         @"    -f, --format FORMAT           Output format (%@) -- Default is png\n"
	         @"    -t, --transparent             Draw a transparent background instead of white (png and tiff formats only)\n"
	         @"    -s, --scale FACTOR            Scale factor, must be positive -- Default is 1.0\n"
	         @"    -h, --help                    Display this help and exit\n",
	         [[[bitmapFormatUTIs allKeys] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"/"]);
}

- (int) application:(DDCliApplication *)app runWithArguments:(NSArray *)arguments;
{
	if (help) {
		[self printHelp];
		return EXIT_SUCCESS;
	}
	
	BOOL supportsAlpha = [format isEqualToString:@"png"] || [format isEqualToString:@"tiff"];
	if (transparent && !supportsAlpha) {
		// TODO: Report error or silently ignore?
		transparent = NO;
	}
	
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

// MARK: Rasterization

- (int) rasterize:(NSString *)pdfPath
{
	bool success = true;
	NSURL *pdfURL = [NSURL fileURLWithPath:pdfPath];
	CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
	
	size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
	
	for (size_t pageNumber = 1; pageNumber <= pageCount; pageNumber++)
	{
		CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocument, pageNumber);
		CGRect boxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
		
		size_t width = roundf(boxRect.size.width * scale);
		size_t height = roundf(boxRect.size.height * scale);
		size_t bytesPerLine = width * 4;
		void *bitmapData = calloc(height * bytesPerLine, 1);
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		
		CGContextRef context = CGBitmapContextCreate(bitmapData, width, height, 8, bytesPerLine, colorSpace, kCGImageAlphaPremultipliedFirst);
		
		if (transparent) {
			CGContextClearRect(context, CGRectMake(0, 0, width, height));
		} else {
			CGContextSetRGBFillColor(context, 1, 1, 1, 1); // white
			CGContextFillRect(context, CGRectMake(0, 0, width, height));
		}
		
		CGContextScaleCTM(context, scale, scale);
		
		CGContextDrawPDFPage(context, page);
		
		CGImageRef pdfImage = CGBitmapContextCreateImage(context);
		
		NSString *baseName = [[pdfPath lastPathComponent] stringByDeletingPathExtension];
		NSString *outputFormat = [NSString stringWithFormat:@"%%@-%%0%.0fd", floorf(log10f(pageCount)) + 1];
		NSString *outputName = [NSString stringWithFormat:outputFormat, baseName, pageNumber];
		NSString *outputPath = [[outputDir stringByAppendingPathComponent:outputName] stringByAppendingPathExtension:format];
		NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
		
		CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)outputURL, (CFStringRef)[bitmapFormatUTIs objectForKey:format], 1, NULL);
		CGImageDestinationAddImage(destination, pdfImage, NULL);
		success = success && CGImageDestinationFinalize(destination);
		
		CFRelease(destination);
		CGImageRelease(pdfImage);
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
	}
	
	CGPDFDocumentRelease(pdfDocument);
	
	return success ? EXIT_SUCCESS : EXIT_FAILURE;
}

@end
