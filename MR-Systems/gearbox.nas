###################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		Motorcycle-Racing for Flightgear December 2016
#		This file is licenced under the terms of the GNU General Public Licence V2 or later
###########################################################################################

var fuel = props.globals.getNode("consumables/fuel/tank/level-m3");
var fuel_lev = 0;
var fuel_weight = props.globals.getNode("consumables/fuel/total-fuel-lbs"); # max 31lbs
var running = props.globals.getNode("/engines/engine/running");
var ratio = props.globals.getNode("/controls/Motorcycle/gearbox/").getChildren("gear");
var gear = props.globals.getNode("/engines/engine/gear");
var gearsound = props.globals.getNode("/engines/engine/gear-sound");
var fastcircuit = props.globals.getNode("/controls/flight/flaps");
var clutch = props.globals.getNode("/engines/engine/clutch");
var secclutchcontrol = props.globals.getNode("/devices/status/keyboard/ctrl");
var killed = props.globals.getNode("/engines/engine/killed");
var rpm = props.globals.getNode("/engines/engine/rpm");
var propulsion = props.globals.getNode("/engines/engine/propulsion");
var throttle = props.globals.getNode("/controls/flight/throttle-on-elev-axis");
var lastthrottle = 0;
var lastgear = 0;
var lastfastcircuit = 0;
var engine_brake = props.globals.getNode("/engines/engine[0]/brake-engine");
var engine_rpm_regulation = props.globals.getNode("/engines/engine[0]/rpm_regulation");
var weight = props.globals.getNode("/sim/weight/weight-lb"); # max. 230 lbs
var inertia = 0;
var vmax = 0;
var looptime = 0.1;
var lastrpm = 0;
var transmissionpower = 0;
var minrpm = props.globals.getNode("/controls/Motorcycle/minrpm");
var maxrpm = props.globals.getNode("/controls/Motorcycle/maxrpm");
var newrpm = 0;
var clutchrpm = 0;
var maxhealth = 40; # for the engine killing, higher is longer live while overspeed rpm
var speedlimiter = props.globals.getNode("/instrumentation/Motorcycle/speed-indicator/speed-limiter");
var speedlimstate = props.globals.getNode("/instrumentation/Motorcycle/speed-indicator/speed-limiter-switch");
var speed = 0;
var gspeed = 0;
var akrapovic = props.globals.initNode("/controls/Motorcycle/Akrapovic/fit",0,"BOOL");
var ascon = props.globals.initNode("/controls/Motorcycle/ASC/on-off",0,"BOOL");
var abson = props.globals.initNode("/controls/Motorcycle/ABS/on-off",0,"BOOL");
var wcon = props.globals.initNode("/controls/Motorcycle/WC/on-off",0,"BOOL");

###########################################################################

var loop = func {

	var engine_brake_force = 20;
	var engine_brake_active = getprop("/controls/Motorcycle/elec-engine-brake/active") or 0;
	if(engine_brake_active){
		engine_brake_force = getprop("/controls/Motorcycle/elec-engine-brake/force") or 0;
		if(engine_brake_force > 80){
			engine_brake_force = 80.0;
		}
		if(engine_brake_force < 20){
			engine_brake_force = 20.0;
		}
	}
	engine_brake_force = (engine_brake_force > 0) ? engine_brake_force/100 : 0.2;

	var msec = getprop("/gear/gear/rollspeed-ms") or 0;
	var kmh = msec*3600/1000;
	var gefahrenem = getprop("/instrumentation/Motorcycle/distance-calculator/mzaehler") or 0;
	var tagesm = getprop("/instrumentation/Motorcycle/distance-calculator/dmzaehler") or 0;
	gefahrenem = gefahrenem + msec/8*1.16;  # 0.125 sec * 8 / 1.16 correction value for the wheel dimension
	tagesm = tagesm + msec/8*1.16;
	setprop("/instrumentation/Motorcycle/distance-calculator/mzaehler", gefahrenem);
	setprop("/instrumentation/Motorcycle/distance-calculator/dmzaehler", tagesm);

	# properties for ABS and SCS at the bottom of this script
	var comp_m = getprop("/gear/gear[1]/compression-m") or 0;
	var brake_ctrl_left = getprop("/controls/gear/brake-left") or 0;
	var brake_ctrl_right = getprop("/controls/gear/brake-right") or 0;
	
	# second possibility for clutch control backspace key is setting in the BMW-S-1000-RR-set.xml
	if(secclutchcontrol.getBoolValue()){
		clutch.setValue(1);
	}else{
		clutch.setValue(0);
	}
	
	#gspeed = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
	gspeed = getprop("/velocities/groundspeed-kt") or 0;
	var bwspeed = getprop("/gear/gear[1]/rollspeed-ms") or 0;
	bwspeed = bwspeed*2.23694; # meter per secondes to miles per hour
	
	# drive with gears
	# clutch control
	gearsound.setValue(0);
	if (lastfastcircuit != fastcircuit.getValue()){
			###### fastcircuit without clutch
			if(fastcircuit.getValue() == 0){
			    if(bwspeed < 2){
					gear.setValue(0);
				}else{
					gear.setValue(1);
				}
				gearsound.setValue(1);
			}else if(fastcircuit.getValue() > 0 and fastcircuit.getValue() < 0.11 ){
				gear.setValue(1);
				gearsound.setValue(1);
			}else if(fastcircuit.getValue() > 0.11 and fastcircuit.getValue() < 0.21){
				gear.setValue(2);
				gearsound.setValue(1);
			}else if(fastcircuit.getValue() > 0.21 and fastcircuit.getValue() < 0.31){
				gear.setValue(3);
				gearsound.setValue(1);
			}else if(fastcircuit.getValue() > 0.31 and fastcircuit.getValue() < 0.41){
				gear.setValue(4);
				gearsound.setValue(1);
			}else if(fastcircuit.getValue() > 0.41 and fastcircuit.getValue() < 0.51){
				gear.setValue(5);
				gearsound.setValue(1);
			}else if(fastcircuit.getValue() > 0.51 and fastcircuit.getValue() < 0.61){
				gear.setValue(6);
				gearsound.setValue(1);
			}
	} else if(gear.getValue() != lastgear and clutch.getValue() == 1){
		###### switch up and down with clutch
		gearsound.setValue(1);
	} else { 
		gear.setValue(lastgear);
	}
	lastgear = gear.getValue();

	# ----------- ENGINE IS RUNNING --------------
	if(running.getValue() == 1){

		# calculate the inertia
		#inertia = (fuel_weight.getValue() + weight.getValue())/245; # 245 max. weight and fuel
		
		# overspeed the engine
		if(rpm.getValue() > (maxrpm.getValue() - 500)){
			if(engine_rpm_regulation.getValue() < 1){
				killed.setValue(killed.getValue() + 1/maxhealth);
			}
			if(killed.getValue() >= 1)rpm.setValue(40000);
		}
		if(killed.getValue() >= 1){
			running.setValue(0);
			killed.setValue(1);
			propulsion.setValue(0);
			interpolate("/engines/engine/rpm" , 0, 3);
			engine_brake.setValue(0.7);
		}
		
		# max speed per gear in kts
		if (gear.getValue() == 0) {
			vmax = 0;
			fastcircuit.setValue(0);
		} else if (gear.getValue() == 1) {
			vmax = getprop("controls/Motorcycle/gearbox/gear[0]/vmax");
			fastcircuit.setValue(0.1);
		} else if (gear.getValue() == 2) {
			vmax =  getprop("controls/Motorcycle/gearbox/gear[1]/vmax");
			fastcircuit.setValue(0.2);
		} else if (gear.getValue() == 3) {
			vmax = getprop("controls/Motorcycle/gearbox/gear[2]/vmax");
			fastcircuit.setValue(0.3);
		} else if (gear.getValue() == 4) {
			vmax = getprop("controls/Motorcycle/gearbox/gear[3]/vmax");
			fastcircuit.setValue(0.4);
		} else if (gear.getValue() == 5) {
			vmax = getprop("controls/Motorcycle/gearbox/gear[4]/vmax");
			fastcircuit.setValue(0.5);
		} else if (gear.getValue() == 6) {
			vmax = getprop("controls/Motorcycle/gearbox/gear[5]/vmax");
			fastcircuit.setValue(0.6);
		}

		# everthing is ok - let him go
		if (gear.getValue() > 0 and clutch.getValue() == 0) {
			if(fastcircuit.getValue() == 0.1){
			  transmissionpower = throttle.getValue()*(ratio[0].getValue('ratio')-0.5);
			  if(wcon.getBoolValue()==0) {
			  	setprop("/sim/weight[1]/weight-lb", throttle.getValue()*300);
			  }else{
			  	setprop("/sim/weight[1]/weight-lb", 0);
			  }
			}else if(fastcircuit.getValue() == 0.2){
			  transmissionpower = (ratio[1].getValue('ratio')-0.5)*throttle.getValue()-propulsion.getValue()/maxrpm.getValue();
			  if(wcon.getBoolValue()==0) {
			  	setprop("/sim/weight[1]/weight-lb", throttle.getValue()*100);
			  }else{
			  	setprop("/sim/weight[1]/weight-lb", 0);
			  }
			}else if(fastcircuit.getValue() == 0.3){
			  transmissionpower = (ratio[2].getValue('ratio')-0.5)*throttle.getValue()-propulsion.getValue()/maxrpm.getValue();
			  setprop("/sim/weight[1]/weight-lb", 0);
			}else if(fastcircuit.getValue() == 0.4){
			  transmissionpower = (ratio[3].getValue('ratio')-0.5)*throttle.getValue()-propulsion.getValue()/maxrpm.getValue();
			}else if(fastcircuit.getValue() == 0.5){
			  transmissionpower = (ratio[4].getValue('ratio')-0.5)*throttle.getValue()-propulsion.getValue()/maxrpm.getValue();
			}else{
			  transmissionpower = (ratio[5].getValue('ratio')-0.5)*throttle.getValue()-propulsion.getValue()/maxrpm.getValue();
			}
			transmissionpower = transmissionpower * (1- killed.getValue());
			
			# First part of the Traction Control or BMW called it ASC (0.134 is a trial and error value)
			if((lastthrottle+0.134) < throttle.getValue()){
				if(ascon.getValue() == 0){
					transmissionpower -= transmissionpower/2;
					propulsion.setValue(transmissionpower);
					setprop("/controls/Motorcycle/ASC/ctrl-light", 1);
				}else{
					propulsion.setValue(transmissionpower);
					setprop("/controls/Motorcycle/ASC/ctrl-light", 0);
				}
			}else{
				propulsion.setValue(transmissionpower);
				setprop("/controls/Motorcycle/ASC/ctrl-light", 0);
			}
			
			
			if(bwspeed < 3 and gspeed < 30){
				newrpm = throttle.getValue()*(maxrpm.getValue());
				rpm.setValue(newrpm);
			}else{
				newrpm = (maxrpm.getValue()+minrpm.getValue())/vmax*gspeed;
				#newrpm = (newrpm < lastrpm) ? (lastrpm - newrpm)/2 + newrpm: newrpm;
				newrpm = (newrpm < minrpm.getValue()+ 1000) ? minrpm.getValue() + 1000 : newrpm;
				
				# second part of the Traction Control
				if(getprop("/controls/Motorcycle/ASC/ctrl-light")==1){
					newrpm = newrpm+3000;
					setprop("/controls/flight/aileron-manual",getprop("/controls/flight/aileron-manual")*4);
				}
				
				interpolate("/engines/engine/rpm",newrpm,0.125);
			}
			
			#help_win.write(sprintf("%.2fmph", bwspeed));
			
			# killing engine with the wrong gear
			if (gear.getValue() > 2 and gspeed < 4) {
						running.setValue(0);
						propulsion.setValue(0);
			}

		} else {
			newrpm = (newrpm < minrpm.getValue()) ? minrpm.getValue() : throttle.getValue()*(maxrpm.getValue()+minrpm.getValue());
			rpm.setValue(newrpm);
			propulsion.setValue(0);
		}
		
		# brake engine feeling at decrease throttle
		if(rpm.getValue() > 2000 and clutch.getValue() == 1){
			clutchrpm = lastrpm + 1000;
			rpm.setValue(clutchrpm);
		}
		
		speed = getprop("/instrumentation/Motorcycle/speed-indicator/speed-meter");
		
		if(speed > 5 and (lastthrottle > throttle.getValue() or throttle.getValue() <= 0) and clutch.getValue() == 0 and gear.getValue() > 0){ 
			propulsion.setValue(0);
			engine_brake.setValue(engine_brake_force);
		}else if(bwspeed > vmax or (speedlimiter.getValue() < speed and speedlimstate.getBoolValue() == 1)){
			propulsion.setValue(0);
			engine_brake.setValue(1);
		}else{
			engine_brake.setValue(0);
		}
		
		# Automatic RPM overspeed regulation
		if(rpm.getValue() > maxrpm.getValue()-730){
			if(engine_rpm_regulation.getValue() == 1 ){
				propulsion.setValue(0);
				if (speed > 20) engine_brake.setValue(0.8);
				rpm.setValue(maxrpm.getValue()-80);
				setprop("/controls/Motorcycle/ctrl-light-overspeed", 1);
			}else{
				setprop("/controls/Motorcycle/ctrl-light-overspeed", 1);
			}
			
		}else{
			setprop("/controls/Motorcycle/ctrl-light-overspeed", 0);
		}
		
		#help_win.write(sprintf("Leistung (in PS): %.2f", propulsion.getValue()*273.85));

	   	 if(rpm.getValue() < minrpm.getValue()) rpm.setValue(minrpm.getValue());  # place after the rpm calculation
	 
	   	 if (fuel.getValue() < 0.000002) {
	   	  running.setValue(0);
	   	  }
	   	 else {
	   	  fuel_lev = fuel.getValue();
		  setprop("/controls/fuel/remember-level", fuel.getValue()); # save it for restart
	   	  fuel.setValue(fuel_lev - (throttle.getValue()+0.1)*0.000001);
	   	 }
		
		#-------------- ENGINE RUNNING END --------------------
		
	} else{
	  if(rpm.getValue() > 2000){
	  	interpolate("/engines/engine/rpm" , 0, 3);
	  }
	  propulsion.setValue(0);
	}
	#-------------- ENGINE END --------------------
	
	# Anti - blog brake regulation
	if(brake_ctrl_right > 0.5 and brake_ctrl_left > 0.5 and gspeed > 30){
		if(abson.getValue() == 1){
			setprop("/controls/Motorcycle/ABS/ctrl-light", 0);		
		}else{
			setprop("/controls/Motorcycle/ABS/ctrl-light", 1);
			setprop("/controls/gear/brake-right", brake_ctrl_right*0.8);
			setprop("/controls/gear/brake-left", brake_ctrl_left*0.8);
		}			
	}else{
		setprop("/controls/Motorcycle/ABS/ctrl-light", 0);
		setprop("/controls/Motorcycle/ABS/brake-right", brake_ctrl_right);
		setprop("/controls/Motorcycle/ABS/brake-left", brake_ctrl_left);
	}
	
	lastthrottle = throttle.getValue();
	lastrpm = rpm.getValue();
	lastfastcircuit = fastcircuit.getValue();
	settimer (loop, 0.125);
}


loop();


