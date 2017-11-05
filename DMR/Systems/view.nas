###############################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		Motorcycles for Flightgear November 2017
#		This file is licenced under the terms of the GNU General Public Licence V2 or later
###############################################################################################
setlistener("/surface-positions/left-aileron-pos-norm", func{

	var cvnr = getprop("sim/current-view/view-number") or 0;
	var omm = getprop("/controls/Motorcycle/old-mens-mode") or 0;
    var position = getprop("/controls/flight/aileron-manual") or 0;
	if(position >= 0){
		position = (position > 0.4) ? 0.4 : position;
	}else{
		position = (position < -0.4) ? -0.4 : position;
	}
	
	var driverpos = getprop("/controls/Motorcycle/driver-up") or 0;
	var driverview = 0.6*driverpos;
	driverview = (driverview == 0) ? -0.1 : driverview;	

	if (omm){
		if(cvnr == 0){
			setprop("/sim/current-view/y-offset-m", 0.91);
		} 
	}else{
		if(cvnr == 0){
			var godown = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
			var lookup = getprop("/controls/gear/brake-right") or 0;
			setprop("/sim/current-view/y-offset-m", abs(position*0.05) + (driverpos/6) + 0.85 - lookup/3100);  	# up/down
			setprop("/sim/current-view/x-offset-m", position*0.1);  											# left/right	
		s	etprop("/sim/current-view/z-offset-m",driverview);	
		}    
	}
});