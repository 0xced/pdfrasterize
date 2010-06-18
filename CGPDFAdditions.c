/*
 *  CGPDFAdditions.c
 *  pdfrasterize
 *
 *  Created by Cédric Luthi on 2010-06-18
 *  Copyright 2010 Cédric Luthi. All rights reserved.
 *
 */

#import "CGPDFAdditions.h"

int PDFPageGetRotation(CGPDFPageRef page)
{
	/* From the PDF Reference:
	 * /Rotate: The number of degrees by which the page should be rotated clockwise when
	 *          displayed or printed. The value must be a multiple of 90.
	 */
	int rotationAngle = CGPDFPageGetRotationAngle(page);
	if (rotationAngle % 90 != 0)
		return 0;
	else
		return (4 + ((rotationAngle / 90) % 4)) % 4;
}
