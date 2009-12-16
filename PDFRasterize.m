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
		pages = nil;
		
		bitmapFormatUTIs = [[NSMutableDictionary alloc] initWithCapacity:6];
		[bitmapFormatUTIs setObject:(id)kUTTypeJPEG              forKey:@"jpg"];
		[bitmapFormatUTIs setObject:(id)kUTTypeJPEG2000          forKey:@"jp2"];
		[bitmapFormatUTIs setObject:(id)kUTTypeTIFF              forKey:@"tiff"];
		[bitmapFormatUTIs setObject:(id)kUTTypeGIF               forKey:@"gif"];
		[bitmapFormatUTIs setObject:(id)kUTTypePNG               forKey:@"png"];
		[bitmapFormatUTIs setObject:(id)kUTTypeBMP               forKey:@"bmp"];
		[bitmapFormatUTIs setObject:@"com.adobe.photoshop-image" forKey:@"psd"];
		[bitmapFormatUTIs setObject:@"com.sgi.sgi-image"         forKey:@"sgi"];
		[bitmapFormatUTIs setObject:@"com.truevision.tga-image"  forKey:@"tga"];
	}
	return self;
}

- (NSArray *) supportedFormats
{
	return [[bitmapFormatUTIs allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *) transparentFormats
{
	return [NSArray arrayWithObjects:@"png", @"psd", @"sgi", @"tga", @"tiff", nil];
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
	    {@"pages",       'p',    DDGetoptRequiredArgument},
	    {nil,             0,     0},
	};
	[optionsParser addOptionsFromTable:optionTable];
}

- (void) setFormat:(NSString *)theFormat
{
	NSString *formatId = [theFormat lowercaseString];
	NSArray *supportedFormats = [self supportedFormats];
	if ([supportedFormats containsObject:formatId]) {
		format = [formatId copy]; // leaked, but we don't care
	} else {
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"Unknown format: %@. Supported formats are %@", formatId, [supportedFormats componentsJoinedByString:@"/"]] exitCode:EX_USAGE];
	}
}

- (void) setScale:(NSString *)theScaleFactor
{
	NSScanner *scanner = [NSScanner scannerWithString:theScaleFactor];
	BOOL validFloat = [scanner scanFloat:&scale];
	if (!(validFloat && scale > 0 && [scanner isAtEnd])	) {
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"Invalid scale factor: %@", theScaleFactor] exitCode:EX_USAGE];
	}
}

- (void) setPages:(NSString *)thePages
{	
	if (!pages) {
		pages = [[NSMutableSet alloc] init];
	}
	[pages removeAllObjects];
	
	NSArray *ranges = [thePages componentsSeparatedByString:@","];
	for (unsigned i = 0; i < [ranges count]; i++) {
		NSString *range = [ranges objectAtIndex:i];
		DDCliParseException *invalidPageRangesException = [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"Invalid page range: %@", [range length] > 0 ? range : @"<empty>"] exitCode:EX_USAGE];
		NSScanner *scanner = [NSScanner scannerWithString:range];
		int first, last;
		
		BOOL validFirst = [scanner scanInt:&first];
		if (!(validFirst && first >= 1)) {
			@throw invalidPageRangesException;
		}
		last = first;
		if (![scanner isAtEnd]) {
			BOOL validSeparator = [scanner scanString:@"-" intoString:NULL];
			if (!validSeparator || [scanner isAtEnd]) {
				@throw invalidPageRangesException;
			}
			BOOL validLast = [scanner scanInt:&last];
			if (!(validLast && last >= 1 && [scanner isAtEnd])) {
				@throw invalidPageRangesException;
			}
			if (!(last > first)) {
				@throw invalidPageRangesException;
			}
		}
		
		for (int p = first; p <= last; p++) {
			[pages addObject:[NSNumber numberWithInt:p]];
		}
	}
}

- (void) setOutputDir:(NSString *)theOutputDir
{
	BOOL isDirectory;
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:theOutputDir isDirectory:&isDirectory];
	
	if (fileExists) {
		if (isDirectory) {
			if (![[NSFileManager defaultManager] isWritableFileAtPath:theOutputDir]) {
				@throw [DDCliParseException parseExceptionWithReason:@"Output directory is not writable" exitCode:EX_CANTCREAT];
			}
			outputDir = [theOutputDir copy]; // leaked, but we don't care
		} else {
			@throw [DDCliParseException parseExceptionWithReason:@"Invalid output directory" exitCode:EX_USAGE];
		}
	} else {
		@throw [DDCliParseException parseExceptionWithReason:@"Output directory does not exist" exitCode:EX_USAGE];
	}
}

// MARK: CLI handling

- (void) printUsage:(FILE *)stream;
{
	ddfprintf(stream, @"Usage: %@ [options] file\n", DDCliApp);
}

- (void) printHelp:(FILE *)stream;
{
	[self printUsage:stream];
	ddfprintf(stream, @"Options:\n"
	          @"    -o, --output-dir DIR          Rasterized files go into DIR -- Default is current working directory\n"
	          @"    -f, --format FORMAT           Output format (%@) -- Default is png\n"
	          @"    -t, --transparent             Draw a transparent background instead of white (%@ formats only)\n"
	          @"    -s, --scale FACTOR            Scale factor, must be positive -- Default is 1.0\n"
	          @"    -p, --pages RANGE             Comma separated ranges of pages (e.g. 1,3-5,7) -- Default is all pages\n"
	          @"    -h, --help                    Display this help and exit\n",
	          [[self supportedFormats] componentsJoinedByString:@"/"],
	          [[self transparentFormats] componentsJoinedByString:@"/"]);
}

- (int) application:(DDCliApplication *)app runWithArguments:(NSArray *)arguments;
{
	if (help || [arguments count] < 1) {
		[self printHelp:help ? stdout : stderr];
		return help ? EX_OK : EX_USAGE;
	}
	
	BOOL supportsAlpha = [[self transparentFormats] containsObject:format];
	if (transparent && !supportsAlpha) {
		ddfprintf(stderr, @"%@: The %@ format does not support transparency\n", DDCliApp, format);
		return EX_USAGE;
	}
	
	NSString *pdfPath = [arguments objectAtIndex:0];
	if (![[NSFileManager defaultManager] fileExistsAtPath:pdfPath]) {
		ddfprintf(stderr, @"%@: %@: No such file\n", DDCliApp, pdfPath);
		return EX_NOINPUT;
	}
	
	NSURL *pdfURL = [NSURL fileURLWithPath:pdfPath];
	CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
	
	if (!pdfDocument) {
		ddfprintf(stderr, @"%@: %@: Invalid PDF file\n", DDCliApp, pdfPath);
		return EX_DATAERR;
	}
	
	size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
	
	if (!pages) {
		pages = [[NSMutableSet alloc] init];
		for (size_t i = 1; i <= pageCount; i++) {
			[pages addObject:[NSNumber numberWithInt:i]];
		}
	}
	
	NSNumber *lastPageNumber = [[[pages allObjects] sortedArrayUsingSelector:@selector(compare:)] lastObject];
	if ([lastPageNumber intValue] > pageCount) {
		ddfprintf(stderr, @"%@: Document has no page %@ (last page is %d)\n", DDCliApp, lastPageNumber, pageCount);
		return EX_USAGE;
	}
	
	NSString *baseName = [[pdfPath lastPathComponent] stringByDeletingPathExtension];
	bool success = [self rasterize:pdfDocument baseName:baseName];
	
	return success ? EX_OK : EX_SOFTWARE;
}

// MARK: Rasterization

- (BOOL) rasterize:(CGPDFDocumentRef)pdfDocument baseName:(NSString *)baseName
{
	bool success = true;
	
	size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
	NSArray *sortedPages = [[pages allObjects] sortedArrayUsingSelector:@selector(compare:)];
	for (unsigned i = 0; i < [pages count]; i++)
	{
		size_t pageNumber = [[sortedPages objectAtIndex:i] intValue];
		CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocument, pageNumber);
		CGRect boxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
		
		size_t width = roundf(boxRect.size.width * scale);
		size_t height = roundf(boxRect.size.height * scale);
		size_t bytesPerLine = width * 4;
		uint64_t size = (uint64_t)height * (uint64_t)bytesPerLine;
		void *bitmapData = malloc(size);
		if (!bitmapData || (size > SIZE_MAX)) {
			ddfprintf(stderr, @"%@: Out of memory, try to reduce the scale factor\n", DDCliApp);
			exit(EX_OSERR);
		}
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		
		CGContextRef context = CGBitmapContextCreate(bitmapData, width, height, 8, bytesPerLine, colorSpace, kCGImageAlphaPremultipliedFirst);
		
		if (transparent) {
			CGContextClearRect(context, CGRectMake(0, 0, width, height));
		} else {
			CGContextSetRGBFillColor(context, 1, 1, 1, 1); // white
			CGContextFillRect(context, CGRectMake(0, 0, width, height));
		}
		
		// CGPDFPageGetDrawingTransform unfortunately does not upscale, see http://lists.apple.com/archives/quartz-dev/2005/Mar/msg00112.html
		CGContextRotateCTM(context, CGPDFPageGetRotationAngle(page));
		CGContextScaleCTM(context, scale, scale);
		CGContextTranslateCTM(context, -boxRect.origin.x, -boxRect.origin.y);
		
		CGContextDrawPDFPage(context, page);
		
		CGImageRef pdfImage = CGBitmapContextCreateImage(context);
		if (!pdfImage) {
			// May happen when scale is very low, and width/height becomes 0.
			exit(EX_SOFTWARE);
		}
		
		NSString *outputFormat = [NSString stringWithFormat:@"%%@-%%0%.0fd", floorf(log10f(pageCount)) + 1];
		NSString *outputName = [NSString stringWithFormat:outputFormat, baseName, pageNumber];
		NSString *outputPath = [[outputDir stringByAppendingPathComponent:outputName] stringByAppendingPathExtension:format];
		NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
		
		CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)outputURL, (CFStringRef)[bitmapFormatUTIs objectForKey:format], 1, NULL);
		if (!destination) {
			// CGImageDestinationCreateWithURL is not documented it may return NULL,
			// but it does if the output url points to a non writable directory
			exit(EX_SOFTWARE);
		}
		CGImageDestinationAddImage(destination, pdfImage, NULL);
		success = success && CGImageDestinationFinalize(destination);
		
		CFRelease(destination);
		CGImageRelease(pdfImage);
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
	}
	
	return success;
}

@end
