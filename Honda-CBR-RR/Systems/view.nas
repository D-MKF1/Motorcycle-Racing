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
			setprop("/sim/current-view/x-offset-m", math.sin(position*1.6)*(1.3+driverpos/5));
			setprop("/sim/current-view/y-offset-m", math.cos(position*1.9)*(1.3+driverpos/4));
			setprop("/sim/current-view/z-offset-m",driverview);	
		} 
	}else{
		if(cvnr == 0){
			var godown = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
			var onwork = getprop("/controls/hangoff") or 0;
			if(godown < hangoffspeed.getValue()){
				var factor = (position <= 0)? -0.6 : 0.6;
				factor = (abs(factor) > abs(position)) ? position : factor;
				if(onwork == 0){
					settimer(func{setprop("/controls/hangoff",1)},0.1);
					interpolate("/sim/current-view/x-offset-m", math.sin(factor*1.8)*(1.28+driverpos/5),0.1);
					interpolate("/sim/current-view/y-offset-m", math.cos(factor*2.1)*(1.3 - godown/1300 + driverpos/4),0.1);
				}else{
					setprop("/sim/current-view/x-offset-m", math.sin(factor*1.8)*(1.28+driverpos/5));
					setprop("/sim/current-view/y-offset-m", math.cos(factor*2.1)*(1.3 - godown/1300 + driverpos/4));
				}
			}else{
				if(onwork == 1){
					interpolate("/sim/current-view/x-offset-m", math.sin(position*1.6)*(1.24+driverpos/5),0.1);
					interpolate("/sim/current-view/y-offset-m", math.cos(position*1.9)*(1.3 - godown/1500 + driverpos/4),0.1);
					settimer(func{setprop("/controls/hangoff",0)},0.1);
				}else{
					setprop("/sim/current-view/x-offset-m", math.sin(position*1.6)*(1.24+driverpos/5));
					setprop("/sim/current-view/y-offset-m", math.cos(position*1.9)*(1.3 - godown/1500 + driverpos/4));
				}
			}
			setprop("/sim/current-view/z-offset-m",driverview);	
		}    
	}
});