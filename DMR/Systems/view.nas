###############################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		Motorcycles for Flightgear September 2016
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
	var driverview = driverpos;
	driverview = (driverview == 0) ? -0.5 : driverview;	
	
	if (omm){
		if(cvnr == 0){
			setprop("/sim/current-view/x-offset-m", math.sin(position*1.6)*(1.32+driverpos/5));
			setprop("/sim/current-view/y-offset-m", math.cos(position*1.9)*(1.32+driverpos/4));
			setprop("/sim/current-view/z-offset-m",driverview);	
		} 
	}else{
		if(cvnr == 0){
			var godown = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
			var lookup = getprop("/controls/gear/brake-right") or 0;
			interpolate("/sim/current-view/x-offset-m", math.sin(position*0.4)*(0.4+driverpos/5),0.1);
			interpolate("/sim/current-view/y-offset-m", math.cos(position*0.4)*(0.9 - godown/1500 + lookup*lookup*lookup/30 + driverpos/4),0.1);
			setprop("/sim/current-view/z-offset-m",driverview);	
		}    
	}
});