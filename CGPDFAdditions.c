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

CGSize PDFPageGetSize(CGPDFPageRef page, CGPDFBox box)
{
	CGRect boxRect = CGPDFPageGetBoxRect(page, box);
	int rotation = PDFPageGetRotation(page);
	bool invertSize = (rotation % 2) == 1;
	
	CGFloat width = invertSize ? CGRectGetHeight(boxRect) : CGRectGetWidth(boxRect);
	CGFloat height = invertSize ? CGRectGetWidth(boxRect) : CGRectGetHeight(boxRect);
	
	return CGSizeMake(width, height);
}

CGAffineTransform PDFPageGetDrawingTransform(CGPDFPageRef page, CGPDFBox box, float scale)
{
	CGRect boxRect = CGPDFPageGetBoxRect(page, box);
	int rotation = PDFPageGetRotation(page);
	
	CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
	
	transform = CGAffineTransformRotate(transform, -(rotation * M_PI_2));
	
	switch (rotation)
	{
		case 1:
			transform = CGAffineTransformTranslate(transform, -CGRectGetWidth(boxRect), 0);
			break;
		case 2:
			transform = CGAffineTransformTranslate(transform, -CGRectGetWidth(boxRect), 0);
			transform = CGAffineTransformTranslate(transform, 0, -CGRectGetHeight(boxRect));
			break;
		case 3:
			transform = CGAffineTransformTranslate(transform, 0, -CGRectGetHeight(boxRect));
			break;
		default:
			break;
	}
	
	transform = CGAffineTransformTranslate(transform, -boxRect.origin.x, -boxRect.origin.y);
	
	return transform;
}
