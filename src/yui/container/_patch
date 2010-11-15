(function () {

	var Overlay = YAHOO.widget.Overlay,
		Prototype = Overlay.prototype,
		Dom = YAHOO.util.Dom;
	

    Prototype.getConstrainedX = function (x) {

		var oOverlay = this,
			oOverlayEl = oOverlay.element,
			nOverlayOffsetWidth = oOverlayEl.offsetWidth,

			nViewportOffset = Overlay.VIEWPORT_OFFSET,
			viewPortWidth = Dom.getViewportWidth(),
			scrollX = Dom.getDocumentScrollLeft(),

			bCanConstrain = (nOverlayOffsetWidth + nViewportOffset < viewPortWidth),

			aContext = this.cfg.getProperty("context"),
			oContextEl,
			nContextElX,
			nContextElWidth,

			bFlipped = false,

			nLeftRegionWidth,
			nRightRegionWidth,

			leftConstraint = scrollX + nViewportOffset,
			rightConstraint = scrollX + viewPortWidth - nOverlayOffsetWidth - nViewportOffset,

			xNew = x,

			oOverlapPositions = {

				"tltr": true,
				"blbr": true,
				"brbl": true,
				"trtl": true
			
			};


		var flipHorizontal = function () {
		
			var nNewX;
		
			if ((oOverlay.cfg.getProperty("x") - scrollX) > nContextElX) {
				nNewX = (nContextElX - nOverlayOffsetWidth);
			}
			else {
				nNewX = (nContextElX + nContextElWidth);
			}
			

			oOverlay.cfg.setProperty("x", (nNewX + scrollX), true);

			return nNewX;

		};



		/*
			 Uses the context element's position to calculate the availble width 
			 to the right and left of it to display its corresponding Overlay.
		*/

		var getDisplayRegionWidth = function () {

			// The Overlay is to the right of the context element

			if ((oOverlay.cfg.getProperty("x") - scrollX) > nContextElX) {
				return (nRightRegionWidth - nViewportOffset);
			}
			else {	// The Overlay is to the left of the context element
				return (nLeftRegionWidth - nViewportOffset);
			}
		
		};


		/*
			Positions the Overlay to the left or right of the context element so that it remains 
			inside the viewport.
		*/

		var setHorizontalPosition = function () {
		
			var nDisplayRegionWidth = getDisplayRegionWidth(),
				fnReturnVal;

			if (nOverlayOffsetWidth > nDisplayRegionWidth) {
	
				if (bFlipped) {
	
					/*
						 All possible positions and values have been 
						 tried, but none were successful, so fall back 
						 to the original size and position.
					*/

					flipHorizontal();
					
				}
				else {
	
					flipHorizontal();

					bFlipped = true;
	
					fnReturnVal = setHorizontalPosition();
	
				}
			
			}
	
			return fnReturnVal;
		
		};


		// Determine if the current value for the Overlay's "x" configuration property will
		// result in the Overlay being positioned outside the boundaries of the viewport
		
		if (x < leftConstraint || x > rightConstraint) {

			// The current value for the Overlay's "x" configuration property WILL
			// result in the Overlay being positioned outside the boundaries of the viewport

			if (bCanConstrain) {

				//	If the "preventcontextoverlap" configuration property is set to "true", 
				//	try to flip the Overlay to both keep it inside the boundaries of the 
				//	viewport AND from overlaping its context element.

				if (this.cfg.getProperty("preventcontextoverlap") && aContext && 
					oOverlapPositions[(aContext[1] + aContext[2])]) {
	
					oContextEl = aContext[0];
					nContextElX = Dom.getX(oContextEl) - scrollX;
					nContextElWidth = oContextEl.offsetWidth;
					nLeftRegionWidth = nContextElX;
					nRightRegionWidth = (viewPortWidth - (nContextElX + nContextElWidth));
	
					setHorizontalPosition();
					
					xNew = this.cfg.getProperty("x");
				
				}
				else {

					if (x < leftConstraint) {
						xNew = leftConstraint;
					} else if (x > rightConstraint) {
						xNew = rightConstraint;
					}

				}

			} else {
				//	The "x" configuration property cannot be set to a value that will keep
				//	entire Overlay inside the boundary of the viewport.  Therefore, set  
				//	the "x" configuration property to scrollY to keep as much of the 
				//	Overlay inside the viewport as possible.                
				xNew = nViewportOffset + scrollX;
			}

		}

		return xNew;
	
	};



	Prototype.getConstrainedY = function (y) {

		var oOverlay = this,
			oOverlayEl = oOverlay.element,
			nOverlayOffsetHeight = oOverlayEl.offsetHeight,
		
			nViewportOffset = Overlay.VIEWPORT_OFFSET,
			viewPortHeight = Dom.getViewportHeight(),
			scrollY = Dom.getDocumentScrollTop(),

			bCanConstrain = (nOverlayOffsetHeight + nViewportOffset < viewPortHeight),

			aContext = this.cfg.getProperty("context"),
			oContextEl,
			nContextElY,
			nContextElHeight,

			bFlipped = false,

			nTopRegionHeight,
			nBottomRegionHeight,

			topConstraint = scrollY + nViewportOffset,
			bottomConstraint = scrollY + viewPortHeight - nOverlayOffsetHeight - nViewportOffset,

			yNew = y,
			
			oOverlapPositions = {
				"trbr": true,
				"tlbl": true,
				"bltl": true,
				"brtr": true
			};


		var flipVertical = function () {

			var nNewY;
		
			// The Overlay is below the context element, flip it above
			if ((oOverlay.cfg.getProperty("y") - scrollY) > nContextElY) { 
				nNewY = (nContextElY - nOverlayOffsetHeight);
			}
			else {	// The Overlay is above the context element, flip it below
				nNewY = (nContextElY + nContextElHeight);
			}

			oOverlay.cfg.setProperty("y", (nNewY + scrollY), true);
			
			return nNewY;
		
		};


		/*
			 Uses the context element's position to calculate the availble height 
			 above and below it to display its corresponding Overlay.
		*/

		var getDisplayRegionHeight = function () {

			// The Overlay is below the context element
			if ((oOverlay.cfg.getProperty("y") - scrollY) > nContextElY) {
				return (nBottomRegionHeight - nViewportOffset);				
			}
			else {	// The Overlay is above the context element
				return (nTopRegionHeight - nViewportOffset);				
			}
	
		};


		/*
			Trys to place the Overlay in the best possible position (either above or 
			below its corresponding context element).
		*/
	
		var setVerticalPosition = function () {
	
			var nDisplayRegionHeight = getDisplayRegionHeight(),
				fnReturnVal;
				

			if (nOverlayOffsetHeight > nDisplayRegionHeight) {
			   
				if (bFlipped) {
	
					/*
						 All possible positions and values for the 
						 "maxheight" configuration property have been 
						 tried, but none were successful, so fall back 
						 to the original size and position.
					*/

					flipVertical();
					
				}
				else {
	
					flipVertical();

					bFlipped = true;
	
					fnReturnVal = setVerticalPosition();
	
				}
			
			}
	
			return fnReturnVal;
	
		};


		// Determine if the current value for the Overlay's "y" configuration property will
		// result in the Overlay being positioned outside the boundaries of the viewport

		if (y < topConstraint || y  > bottomConstraint) {
	
			// The current value for the Overlay's "y" configuration property WILL
			// result in the Overlay being positioned outside the boundaries of the viewport

			if (bCanConstrain) {	

				//	If the "preventcontextoverlap" configuration property is set to "true", 
				//	try to flip the Overlay to both keep it inside the boundaries of the 
				//	viewport AND from overlaping its context element.
	
				if (this.cfg.getProperty("preventcontextoverlap") && aContext && 
					oOverlapPositions[(aContext[1] + aContext[2])]) {
	
					oContextEl = aContext[0];
					nContextElHeight = oContextEl.offsetHeight;
					nContextElY = (Dom.getY(oContextEl) - scrollY);
	
					nTopRegionHeight = nContextElY;
					nBottomRegionHeight = (viewPortHeight - (nContextElY + nContextElHeight));
	
					setVerticalPosition();
	
					yNew = oOverlay.cfg.getProperty("y");
	
				}
				else {

					if (y < topConstraint) {
						yNew  = topConstraint;
					} else if (y  > bottomConstraint) {
						yNew  = bottomConstraint;
					}
				
				}
			
			}
			else {
			
				//	The "y" configuration property cannot be set to a value that will keep
				//	entire Overlay inside the boundary of the viewport.  Therefore, set  
				//	the "y" configuration property to scrollY to keep as much of the 
				//	Overlay inside the viewport as possible.
			
				yNew = nViewportOffset + scrollY;
			}
	
		}

		return yNew;
	};

}());