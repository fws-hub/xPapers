(function () {

	var Overlay = YAHOO.widget.Overlay,
		Dom = YAHOO.util.Dom,

		// String constants
	
		_CONTEXT = "context",	
		_Y = "y",
		_MAX_HEIGHT = "maxheight",
		_MIN_SCROLL_HEIGHT = "minscrollheight",		
		_PREVENT_CONTEXT_OVERLAP = "preventcontextoverlap";


	YAHOO.widget.Menu.prototype.getConstrainedY = function (y) {
	
		var oMenu = this,
		
			aContext = oMenu.cfg.getProperty(_CONTEXT),
			nInitialMaxHeight = oMenu.cfg.getProperty(_MAX_HEIGHT),
	
			nMaxHeight,
	
			oOverlapPositions = {
	
				"trbr": true,
				"tlbl": true,
				"bltl": true,
				"brtr": true
	
			},
	
			bPotentialContextOverlap = (aContext && oOverlapPositions[aContext[1] + aContext[2]]),
		
			oMenuEl = oMenu.element,
			nMenuOffsetHeight = oMenuEl.offsetHeight,
		
			nViewportOffset = Overlay.VIEWPORT_OFFSET,
			viewPortHeight = Dom.getViewportHeight(),
			scrollY = Dom.getDocumentScrollTop(),
	
			bCanConstrain = 
				(oMenu.cfg.getProperty(_MIN_SCROLL_HEIGHT) + nViewportOffset < viewPortHeight),
	
			nAvailableHeight,
	
			oContextEl,
			nContextElY,
			nContextElHeight,
	
			bFlipped = false,
	
			nTopRegionHeight,
			nBottomRegionHeight,
	
			topConstraint = scrollY + nViewportOffset,
			bottomConstraint = scrollY + viewPortHeight - nMenuOffsetHeight - nViewportOffset,
	
			yNew = y;
			
	
		var flipVertical = function () {
	
			var nNewY;
		
			// The Menu is below the context element, flip it above
			if ((oMenu.cfg.getProperty(_Y) - scrollY) > nContextElY) { 
				nNewY = (nContextElY - nMenuOffsetHeight);
			}
			else {	// The Menu is above the context element, flip it below
				nNewY = (nContextElY + nContextElHeight);
			}
	
			oMenu.cfg.setProperty(_Y, (nNewY + scrollY), true);
			
			return nNewY;
		
		};
	
	
		/*
			 Uses the context element's position to calculate the availble height 
			 above and below it to display its corresponding Menu.
		*/
	
		var getDisplayRegionHeight = function () {
	
			// The Menu is below the context element
			if ((oMenu.cfg.getProperty(_Y) - scrollY) > nContextElY) {
				return (nBottomRegionHeight - nViewportOffset);				
			}
			else {	// The Menu is above the context element
				return (nTopRegionHeight - nViewportOffset);				
			}
	
		};
	
	
		/*
			Sets the Menu's "y" configuration property to the correct value based on its
			current orientation.
		*/ 
	
		var alignY = function () {
	
			var nNewY;
	
			if ((oMenu.cfg.getProperty(_Y) - scrollY) > nContextElY) { 
				nNewY = (nContextElY + nContextElHeight);
			}
			else {	
				nNewY = (nContextElY - oMenuEl.offsetHeight);
			}
	
			oMenu.cfg.setProperty(_Y, (nNewY + scrollY), true);
		
		};
	
	
		//	Resets the maxheight of the Menu to the value set by the user
	
		var resetMaxHeight = function () {
	
			oMenu._setScrollHeight(this.cfg.getProperty(_MAX_HEIGHT));
	
			oMenu.hideEvent.unsubscribe(resetMaxHeight);
		
		};
	
	
		/*
			Trys to place the Menu in the best possible position (either above or 
			below its corresponding context element).
		*/
	
		var setVerticalPosition = function () {
	
			var nDisplayRegionHeight = getDisplayRegionHeight(),
				bMenuHasItems = (oMenu.getItems().length > 0),
				nMenuMinScrollHeight,
				fnReturnVal,
				nNewY;
	
	
			if (nMenuOffsetHeight > nDisplayRegionHeight) {
	
				nMenuMinScrollHeight = 
					bMenuHasItems ? oMenu.cfg.getProperty(_MIN_SCROLL_HEIGHT) : nMenuOffsetHeight;
	
	
				if ((nDisplayRegionHeight > nMenuMinScrollHeight) && bMenuHasItems) {
					nMaxHeight = nDisplayRegionHeight;
				}
				else {
					nMaxHeight = nInitialMaxHeight;
				}
	
	
				oMenu._setScrollHeight(nMaxHeight);
				oMenu.hideEvent.subscribe(resetMaxHeight);
				
	
				// Re-align the Menu since its height has just changed
				// as a result of the setting of the maxheight property.
	
				alignY();
				
	
				if (nDisplayRegionHeight < nMenuMinScrollHeight) {
	
					if (bFlipped) {
		
						/*
							 All possible positions and values for the "maxheight" 
							 configuration property have been tried, but none were 
							 successful, so fall back to the original size and position.
						*/
	
						flipVertical();
						
					}
					else {
		
						flipVertical();
	
						bFlipped = true;
		
						fnReturnVal = setVerticalPosition();
		
					}
					
				}
			
			}
			else if (nMaxHeight && (nMaxHeight !== nInitialMaxHeight)) {
			
				oMenu._setScrollHeight(nInitialMaxHeight);
				oMenu.hideEvent.subscribe(resetMaxHeight);
	
				// Re-align the Menu since its height has just changed
				// as a result of the setting of the maxheight property.
	
				alignY();
			
			}
	
			return fnReturnVal;
	
		};
	
	
		// Determine if the current value for the Menu's "y" configuration property will
		// result in the Menu being positioned outside the boundaries of the viewport
	
		if (y < topConstraint || y  > bottomConstraint) {
	
			// The current value for the Menu's "y" configuration property WILL
			// result in the Menu being positioned outside the boundaries of the viewport
	
			if (bCanConstrain) {
	
				if (oMenu.cfg.getProperty(_PREVENT_CONTEXT_OVERLAP) && bPotentialContextOverlap) {
			
					//	SOLUTION #1:
					//	If the "preventcontextoverlap" configuration property is set to "true", 
					//	try to flip and/or scroll the Menu to both keep it inside the boundaries of the 
					//	viewport AND from overlaping its context element (MenuItem or MenuBarItem).
	
					oContextEl = aContext[0];
					nContextElHeight = oContextEl.offsetHeight;
					nContextElY = (Dom.getY(oContextEl) - scrollY);
		
					nTopRegionHeight = nContextElY;
					nBottomRegionHeight = (viewPortHeight - (nContextElY + nContextElHeight));
		
					setVerticalPosition();
					
					yNew = oMenu.cfg.getProperty(_Y);
			
				}
				else if (!(oMenu instanceof YAHOO.widget.MenuBar) && 
					nMenuOffsetHeight >= viewPortHeight) {
	
					//	SOLUTION #2:
					//	If the Menu exceeds the height of the viewport, introduce scroll bars
					//	to keep the Menu inside the boundaries of the viewport
	
					nAvailableHeight = (viewPortHeight - (nViewportOffset * 2));
			
					if (nAvailableHeight > oMenu.cfg.getProperty(_MIN_SCROLL_HEIGHT)) {
			
						oMenu._setScrollHeight(nAvailableHeight);
						oMenu.hideEvent.subscribe(resetMaxHeight);
			
						alignY();
						
						yNew = oMenu.cfg.getProperty(_Y);
					
					}
			
				}	
				else {
	
					//	SOLUTION #3:
				
					if (y < topConstraint) {
						yNew  = topConstraint;
					} else if (y  > bottomConstraint) {
						yNew  = bottomConstraint;
					}				
				
				}
	
			}
			else {
				//	The "y" configuration property cannot be set to a value that will keep
				//	entire Menu inside the boundary of the viewport.  Therefore, set  
				//	the "y" configuration property to scrollY to keep as much of the 
				//	Menu inside the viewport as possible.
				yNew = nViewportOffset + scrollY;
			}	
	
		}
	
		return yNew;
	
	};

}());