using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time.Gregorian;

class BooleanWatchfaceView extends WatchUi.WatchFace {
	const sixtyAngle = 360/60;
	const twelveAngle = 360/12;
	const hrTick = 360 / (12 * 60);
	const minSizeSec = 0.8;
	const minSizeNoSec = 1.0;
	const hrSizeSec = 0.55;
	const hrSizeNoSec = 0.6;
	const centerSize = 0.25;
	const dotRadius = 0.87;
	const degConv = 57.2958;
	
	const accentSize = 3;
	const handSize = 2;
	var showSecs = 0.0;
	var needsFullUpdate = true;
	
	var dotCoords = [[]];

    function initialize() {
        WatchFace.initialize();
        onShow();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	needsFullUpdate = true;
    	dotCoords = [[]];
    	for(var angle = 0; angle < 360; angle += sixtyAngle){
    		dotCoords.add([(Math.sin(angle / degConv)), -(Math.cos(angle / degConv))]);
    	}
    	dotCoords = dotCoords.slice(1, 61);
    }

    // Perform a full update of the view.
    function onUpdate(dc) {
        // Get and show the current time
        callDraw(dc);
        

        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
    }
    
    // Perform a partial update on the screen
    function onPartialUpdate(dc){
    	callDraw(dc);
    }
    
    
    function callDraw(dc){
    	// Get the current time and format it correctly
        var clockTime = System.getClockTime();
        // Only update the screen on the minute mark
        if(clockTime.sec == 0 || needsFullUpdate){
        	var hour = clockTime.hour;
        	var min = clockTime.min;
        	var sec = clockTime.sec;
        
        	// Get angles for all hands
        	var hrAngle = ((hour + (min / 60.0)) * twelveAngle);
        	if(hrAngle >= 359.7){
        		hrAngle = hrAngle - 360;
        	}
        	var minAngle = min * sixtyAngle;
        	if(minAngle >= 359.7){
        		minAngle = minAngle - 360;
       		}
       	 
        	// Get clockwise / counterclockwise for all parts
        	var hrClockwise = ((hour % 24 >= 12) != (hour%2 == 0)) != (minAngle > hrAngle + 0.2);
        	
        	var minClockwise = (hour % 2 == 1);
			
        	// Update the view
        	if(needsFullUpdate || hour == 0){
        		dc.clearClip();
        		drawFromScratch(dc, hrSizeNoSec, minAngle, hrAngle, minClockwise, hrClockwise);
        		needsFullUpdate = false;
        	}else{
        		//setClip(dc, min, hrSizeNoSec, false);
        		drawPartial(dc, hrSizeNoSec, minAngle, hrAngle, minClockwise, hrClockwise);
        	}
        	drawAccents(dc);
        }
    }
    
    function drawFromScratch(dc, hrSize, minAngle, hrAngle, minClockwise, hrClockwise){
    	var displayRad = dc.getWidth() / 2;
    	var rad;
    	dc.setColor(dc.COLOR_BLACK, dc.COLOR_BLACK);
    	dc.clear();
        // Draw minutes
        dc.setColor(dc.COLOR_WHITE, dc.COLOR_WHITE);
        rad = (1 + hrSize) * displayRad / 2;
        dc.setPenWidth((1 - hrSize) * displayRad+0.5);
        handArc(dc, displayRad, rad, minClockwise, 0, minAngle);
        
        // Draw hours
        rad = (hrSize + centerSize) * displayRad / 2;
        dc.setPenWidth((hrSize - centerSize) * displayRad+0.5);
        handArc(dc, displayRad, rad, hrClockwise, minAngle, hrAngle);
        
    }
    
    function drawPartial(dc, hrSize, minAngle, hrAngle, minClockwise, hrClockwise){
    	var displayRad = dc.getWidth() / 2;
    	var rad;
		// Prepare pen for minute area
		rad = (1 + hrSize) * displayRad / 2;
    	dc.setPenWidth((1.0 - hrSize) * displayRad + 0.5);
    	// Forward minute hand in minute area
    	if(minClockwise != (minAngle == 0)){
    		dc.setColor(dc.COLOR_WHITE, dc.COLOR_WHITE);
    	}else{
    		dc.setColor(dc.COLOR_BLACK, dc.COLOR_BLACK);
    	}
    	handArc(dc, displayRad, rad, true, minAngle-sixtyAngle, minAngle);
    	
    	// Prepare pen for hour area
    	rad = (hrSize + centerSize) * displayRad / 2;
    	dc.setPenWidth((hrSize - centerSize) * displayRad + 0.5);
    	// Forward minute hand in hour area
    	if(hrClockwise){
    		dc.setColor(dc.COLOR_BLACK, dc.COLOR_BLACK);
    	}else{
    		dc.setColor(dc.COLOR_WHITE, dc.COLOR_WHITE);
    	}
    	handArc(dc, displayRad, rad, true, minAngle - sixtyAngle, minAngle);
    	
    	// Forward hour hand in hour area
    	if(hrClockwise){
    		dc.setColor(dc.COLOR_WHITE, dc.COLOR_WHITE);
    	}else{
    		dc.setColor(dc.COLOR_BLACK, dc.COLOR_BLACK);
    	}
    	
    	if(((minAngle > hrAngle) != ((minAngle - hrAngle).abs() > 180)) && (deltaTheta(minAngle, hrAngle) < sixtyAngle)){
    		handArc(dc, displayRad, rad, true, minAngle-sixtyAngle, hrAngle);
    	}else{
    		handArc(dc, displayRad, rad, true, hrAngle-sixtyAngle, hrAngle);
    	}
    	
    }
    
    function deltaTheta(a, b){
    	var delta = (a - b).abs();
    	if(delta > 180){
    		return 360-delta;
    	}
    	return delta;
    }
    
    function max(a, b){
    	if(a > b){
    		return a;
    	}
    	return b;
    }
    
    function minmax(list){
    	var min = list[0];
    	var max = list[0];
    	for(var i = 0; i < list.size(); i++){
    		if(list[i] < min){
    			min = list[i];
    		}else if(list[i] > max){
    			max = list[i];
    		}
    	}
    	return [min, max];
    }
    
    function setClip(dc, activeIndex, coreSize, topY){
    	var displayRad = dc.getWidth() / 2;
    	var prevIndex = (activeIndex - 1);
    	if(prevIndex < 0){
    		prevIndex = prevIndex + 60;
    	}
    	var prevX = dotCoords[prevIndex][0];
    	var prevY = dotCoords[prevIndex][1];
    	var currentX = dotCoords[activeIndex][0];
    	var currentY = dotCoords[activeIndex][1];
    	if(topY){
    		currentY = -1;
    	}
    	
    	var x = minmax([-coreSize, coreSize, prevX, currentX]);
    	var y = minmax([-coreSize, coreSize, prevY, currentY]);
    	x[0] = displayRad + (x[0] * displayRad) - 2;
    	x[1] = displayRad + (x[1] * displayRad) + 2;
    	y[0] = displayRad + (y[0] * displayRad) - 2;
    	y[1] = displayRad + (y[1] * displayRad) + 2;
    	
    	dc.setClip(x[0], y[0], x[1] - x[0], y[1] - y[0]);
    }
    
    function drawAccents(dc){
    	var dispRad = dc.getWidth() / 2;
    	var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    	var todayShort = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    	dc.setColor(dc.COLOR_RED, dc.COLOR_BLACK);
    	// Draw center area
    	dc.setPenWidth(accentSize);
    	dc.drawCircle(dispRad, dispRad, centerSize * dispRad);
    	
    	// Draw battery indicator
    	var diam = centerSize * dispRad;
    	dc.setPenWidth(diam);
    	var batteryAngle = 1.8 * System.getSystemStats().battery;
    	dc.drawArc(dispRad, dispRad, diam / 2, dc.ARC_CLOCKWISE, -90+batteryAngle, -90-batteryAngle);
    	
    	// Draw standard accent items
    	dc.setColor(dc.COLOR_RED, dc.COLOR_RED);
    	dc.setPenWidth(accentSize);
    	
    	for(var i = 0; i < 60; i++){
    		var x = dispRad + dotCoords[i][0] * dispRad * dotRadius;
    		var y = dispRad + dotCoords[i][1] * dispRad * dotRadius;
    		if(i%5 == 0){
    			// Hour dot
    			if(i / 5 == todayShort.month){
    				dc.fillCircle(x, y, Math.ceil(1.5 * accentSize));
    			}else{
    				dc.drawCircle(x, y, accentSize+1);
    			}
    		}else{
    			// Minute dot
    			dc.drawPoint(x, y);
    			//dc.fillCircle(x, y, accentSize / 2);
    		}
    		if(i == todayShort.day){
    			// Mark today
    			
    			var rad = (dispRad * dotRadius) + accentSize;
    			dc.drawLine(dispRad + dotCoords[i][0] * rad, dispRad + dotCoords[i][1] * rad,
    			dispRad + dotCoords[i][0] * dispRad, dispRad + dotCoords[i][1] * dispRad);
    		}
    		
    	}
    	// Draw text
    	dc.setColor(dc.COLOR_WHITE, dc.COLOR_TRANSPARENT);
    	dc.setPenWidth(1);
    	dc.drawText(dispRad, dispRad - 20, Graphics.FONT_SYSTEM_MEDIUM, today.day_of_week, Graphics.TEXT_JUSTIFY_CENTER);
    	
    }
    
    // Draws an arc centered around (displayRad, displayRad) with radius rad from a to b either clockwise or counterclockwise.
    // If a = b and counterclockwise, will draw a full circle.
    function handArc(dc, displayRad, rad, clockwise, a, b){
    	if(clockwise){
    		if(a == b){
    			//dc.drawCircle(displayRad, displayRad, rad);
    		}else{
        		dc.drawArc(displayRad, displayRad, rad, dc.ARC_CLOCKWISE, 90-a, 90-b);
        	}
        }else{
        	if(a == b){
        		dc.drawArc(displayRad, displayRad, rad, dc.ARC_CLOCKWISE, 0, 360);
        	}else{
        		dc.drawArc(displayRad, displayRad, rad, dc.ARC_COUNTER_CLOCKWISE, 90-a, 90-b);
        	}
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    	needsFullUpdate = true;
    	dotCoords = [[]];
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}
