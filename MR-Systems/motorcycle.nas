###############################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		Motorcycles for Flightgear September 2016
#		This file is licenced under the terms of the GNU General Public Licence V2 or later
###############################################################################################
var config_dlg = gui.Dialog.new("/sim/gui/dialogs/config/dialog", getprop("/sim/aircraft-dir")~"/MR-Systems/config.xml");
var ratio_dlg = gui.Dialog.new("/sim/gui/dialogs/ratio/dialog", getprop("/sim/aircraft-dir")~"/MR-Systems/ratio.xml");
var analysis_dlg = gui.Dialog.new("/sim/gui/dialogs/analysis/dialog", getprop("/sim/aircraft-dir")~"/MR-Systems/analysis.xml");
var elecsettings_dlg = gui.Dialog.new("/sim/gui/dialogs/elecsettings/dialog", getprop("/sim/aircraft-dir")~"/MR-Systems/elecsettings.xml");
var hangoffspeed = props.globals.initNode("/controls/hang-off-speed",0,"DOUBLE");
var hangoffhdg = props.globals.initNode("/controls/hang-off-hdg",0,"DOUBLE");
var hangoffviewdeg = props.globals.initNode("/controls/hang-off-view-deg",0,"DOUBLE");
var steeringdamper = props.globals.initNode("/controls/steering-damper",1,"DOUBLE");
var waiting = props.globals.initNode("/controls/waiting",0,"DOUBLE");

################## Little Help Window on bottom of screen #################
var help_win = screen.window.new( 0, 0, 1, 5 );
help_win.fg = [1,1,1,1];

var messenger = func{
help_win.write(arg[0]);
}

var help_win_red = screen.window.new( 768, 512, 10, 5 );
help_win_red.fg = [1,0,0,1];

var messenger_red = func{
help_win_red.write(arg[0]);
}

#----- gear to zero at startup ----
setprop("/sim/flaps/current-setting",6);

#----- view correction and steering helper ------
# loop for fork control
setprop("/controls/flight/fork",0.0);
var f = props.globals.getNode("/controls/flight/fork");

var forkcontrol = func{
    var r = getprop("/controls/flight/rudder") or 0;
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	var bl = getprop("/controls/gear/brake-left") or 0;
	var bs = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
	if (ms == 1) {
		if(getprop("/devices/status/mice/mouse/button")==1){
			f.setValue(r);
		}
	}else{
		var sensibility_fork = steeringdamper.getValue()*0.03;
		sensibility_fork = (sensibility_fork < 0.1)? 0.1 : sensibility_fork;
		interpolate("/controls/flight/fork", r, sensibility_fork);
	}
	if(bs > 38){
		setprop("/controls/gear/brake-front", bl);
	}else{
		setprop("/controls/gear/brake-front", 0);
	}
	
	# shoulder view helper
	var cv = getprop("sim/current-view/view-number") or 0;
	var apos = getprop("/devices/status/keyboard/event/key") or 0;
	var press = getprop("/devices/status/keyboard/event/pressed") or 0;
	var du = getprop("/controls/Motorcycle/driver-up") or 0;
	#helper turn shoulder to look back
	if(cv == 0 and !du){
		if(apos == 49 and press){
			setprop("/sim/current-view/heading-offset-deg", 155);
			setprop("/controls/Motorcycle/driver-looks-back",1);
		}else if(apos == 50 and press){
			setprop("/sim/current-view/heading-offset-deg", -155);
			setprop("/controls/Motorcycle/driver-looks-back-right",1);
		}else{
			var hdgpos = 0;
		    var posi = getprop("/controls/flight/aileron-manual") or 0;
			var sceneryposi = posi*45;
			if(sceneryposi > 0){
				sceneryposi = (sceneryposi > 18) ? 18 : sceneryposi;
			}else{
				sceneryposi = (sceneryposi < -18) ? -18 : sceneryposi;
			}
			
		  	if(posi > 0.0001 and getprop("/controls/hangoff") == 1){
				hdgpos = 360 - 60*posi;
				hdgpos = (hdgpos < (360 - hangoffviewdeg.getValue())) ? 360 - hangoffviewdeg.getValue() : hdgpos;
				#help_win.write(sprintf("Blickwinkel: %.2f", hdgpos));
		  		setprop("/sim/current-view/goal-heading-offset-deg", hdgpos);
				setprop("/sim/current-view/goal-roll-offset-deg", sceneryposi);
		  	}else if (posi < -0.0001 and getprop("/controls/hangoff") == 1){
				hdgpos = 60*abs(posi);
				hdgpos = (hdgpos > hangoffviewdeg.getValue()) ? hangoffviewdeg.getValue() : hdgpos;
				#help_win.write(sprintf("Blickwinkel: %.2f", hdgpos));
		  		setprop("/sim/current-view/goal-heading-offset-deg", hdgpos);
				setprop("/sim/current-view/goal-roll-offset-deg", sceneryposi);
			}else if (posi > 0 and posi < 0.0001 and getprop("/controls/hangoff") == 1){
				setprop("/sim/current-view/goal-heading-offset-deg", 360);
				setprop("/sim/current-view/goal-roll-offset-deg", 0);
			}else{
				setprop("/sim/current-view/goal-heading-offset-deg", 0);
				setprop("/sim/current-view/goal-roll-offset-deg", 0);
			}
			setprop("/controls/Motorcycle/driver-looks-back",0);
			setprop("/controls/Motorcycle/driver-looks-back-right",0);
		}
	}
	
	# distance calculator helper
	if(getprop("/instrumentation/Motorcycle/speed-indicator/selection")){
		setprop("/instrumentation/Motorcycle/distance-calculator/miles", getprop("/instrumentation/Motorcycle/distance-calculator/mzaehler")*0.621371192); # miles on bike
		setprop("/instrumentation/Motorcycle/distance-calculator/dmiles", getprop("/instrumentation/Motorcycle/distance-calculator/dmzaehler")*0.621371192); # miles a day
	}else{
		setprop("/instrumentation/Motorcycle/distance-calculator/miles", getprop("/instrumentation/Motorcycle/distance-calculator/mzaehler")); # km on bike
		setprop("/instrumentation/Motorcycle/distance-calculator/dmiles", getprop("/instrumentation/Motorcycle/distance-calculator/dmzaehler")); # km a day
	}
	
	settimer(forkcontrol, 0);
};

forkcontrol();

# --- Help window for steering damper setting ---
setlistener("/controls/steering-damper", func (sd){
	help_win.write(sprintf("Steering damper setting: %.0f clicks", sd.getValue()));
},1,0);

# --- Temperature calculation --
var temp_fake_calc = func{

	var et = getprop("/engines/engine[0]/engine-temperatur") or 0;
    var ek = getprop("/engines/engine/killed") or 0;
	var eat = getprop("/environment/temperature-degc") or 0;
	var eru = getprop("engines/engine/running") or 0;
	var erp = getprop("engines/engine/rpm") or 0;
	var net = 0;
	if(eru){
		if (ek > 0) {
			net = et * ek + et;
			net = (net > 125)? net + eat/3 : net;
		}else{
			net = eat + 74 + erp/990;
			net = (net > 125)? net - eat/3 : net;
		}
	}else{
		net = eat;
	}

	interpolate("/engines/engine[0]/engine-temperatur", net, 40);
	settimer(temp_fake_calc, 40);
};

temp_fake_calc();

setlistener("/devices/status/mice/mouse/button", func (state){
    var state = state.getBoolValue();
	# helper for the steering
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1 and state == 1) {
		controls.flapsDown(-1);
	}
},0,1);

setlistener("/devices/status/mice/mouse/button[2]", func (state){
    var state = state.getBoolValue();
	# helper for the steering
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1 and state == 1) {
		controls.flapsDown(1);
	}
},0,1);


setlistener("/controls/flight/aileron", func (position){
    var position = position.getValue();
	# helper for the steering
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1) {
		if(getprop("/devices/status/mice/mouse/button")==1){
			setprop("/controls/flight/aileron-manual",position*3);
		}else{
			f.setValue(position*0.65);
			setprop("/controls/flight/aileron-manual", position*0.75);
		}
		
	}else{
		var joyst = getprop("/input/joysticks/js/id") or '';
		if(joyst == 'Arduino Leonardo'){
			var np = math.round(position*100);
			np = np/100;
			interpolate("/controls/flight/aileron-manual", np,0.1);
		}else{
			var np = math.round(position*position*position*100);
			np = np/100;
			#print("NP: ", np);
			# the *0.04 is the calculation number for the 16clicks Oehlins steering damper
			var sensibility = (np == 0 or abs(np) < steeringdamper.getValue()*0.0625) ? steeringdamper.getValue()*0.04 : abs(np);
			sensibility = (sensibility < 0.07)? 0.07 : sensibility;
			interpolate("/controls/flight/aileron-manual", np, sensibility);
		}
	}
});


setlistener("/controls/flight/elevator", func (position){
    var position = position.getValue();
	# helper for braking
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1 and position < 0) {
		setprop("/controls/gear/brake-left", abs(position));
		setprop("/controls/gear/brake-right", abs(position));
	}
	if (ms == 1 and position > 0) {
		setprop("/controls/gear/brake-left", 0);
		setprop("/controls/gear/brake-right", 0);
	}
	
	# helper for throtte on throttle axis or elevator
	var se = getprop("/controls/flight/select-throttle-input") or 0;
	if (ms == 0){
		if(se == 1 and position >= 0) setprop("/controls/flight/throttle-input", position);
		if(se == 0){
			position = (position < 0) ? abs(position) : 0;
			vortrieb = getprop("/engines/engine/propulsion") or 0;
			setprop("/sim/weight[1]/weight-lb", position*400*vortrieb);
		}
	} 
	if (ms == 1 and position >= 0) setprop("/controls/flight/throttle-input", position*4);
	
},0,1);


setlistener("/controls/engines/engine[0]/throttle", func (position){
    var position = position.getValue();
	
	# helper for throtte on throttle axis or elevator
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	var se = getprop("/controls/flight/select-throttle-input") or 0;
	if (ms == 0 and se == 0 and position >= 0) setprop("/controls/flight/throttle-input", position*position);
},0,1);

#----- speed meter selection ------

setlistener("/gear/gear[1]/rollspeed-ms", func (speed){
	var speed = speed.getValue();
	var crnw = getprop("/sim/crashed") or 0;
    # only for manipulate the reset m function 
	if (speed > 20 and !crnw) setprop("/controls/waiting", 1);
	# speedmeter function
	if(getprop("/instrumentation/Motorcycle/speed-indicator/selection")){
		if(speed > 0.1){
			setprop("/instrumentation/Motorcycle/speed-indicator/speed-meter", speed*3600/1000*0.621371); # mph
		}else{
			setprop("/instrumentation/Motorcycle/speed-indicator/speed-meter", 0);
		}
	}else{
		if(speed > 0.1){
			setprop("/instrumentation/Motorcycle/speed-indicator/speed-meter", speed*3600/1000); # km/h
		}else{
			setprop("/instrumentation/Motorcycle/speed-indicator/speed-meter", 0);
		}
	}
});


setlistener("/instrumentation/Motorcycle/speed-indicator/speed-limiter", func (sl){
	help_win.write(sprintf("Speed Limit: %.0f", sl.getValue()));
},1,0);

#----- brake and holder control ------

setlistener("/controls/gear/brake-parking", func (pb){
    var pb = pb.getBoolValue();
	
    if (pb != nil and pb){
		setprop("/controls/gear/gear-down", 1);
		setprop("/controls/gear/ready-to-race", 0);
	}else{
		setprop("/controls/gear/gear-down", 0);
		setprop("/controls/gear/ready-to-race", 1);
	}
});

setlistener("/controls/gear/gear-down", func (gd){
    var gd = gd.getBoolValue();
	
    if (gd != nil and gd){
		setprop("/controls/gear/brake-parking", 1);
		setprop("/controls/gear/ready-to-race", 0);
	}else{
		setprop("/controls/gear/brake-parking", 0);
		setprop("/controls/gear/ready-to-race", 1);
	}
});

var show_performance = func {
	var perf = getprop("engines/engine/killed")*100;
	perf = math.round(100 - perf);
	help_win.write("Engine performance: "~perf~"%");
}

#----- AUTOSTART  ------

# startup/shutdown functions
var startup = func
 {
	setprop("/controls/engines/engine/starter", 1);
	setprop("/engines/engine/cranking", 1);
 	settimer( func{
 	  if(getprop("/controls/engines/engine/starter") == 1){
	 		setprop("/controls/engines/engine/magnetos", 3);
	 		setprop("/controls/engines/engine/running", 1);
			setprop("/controls/engines/engine/starter", 0);
			setprop("/engines/engine/running", 1);
			setprop("/engines/engine/rpm", 2500);
			setprop("/engines/engine/cranking", 0);
		}
	}, 1);
 };
 
 var shutdown = func
  {
 	setprop("/controls/engines/engine/starter", 0);
	setprop("/controls/engines/engine/magnetos", 0);
	setprop("/controls/engines/engine/running", 0);
	interpolate("engines/engine/rpm", 0, 3);
	setprop("/engines/engine/magnetos", 0);
	setprop("/engines/engine/running", 0);
  };

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func()
 {
 var run1 = getprop("/engines/engine/running") or 0;
 
 if (run1 == 0)
  {
  	startup();
  }
 else
  {
  	shutdown();
  }
 }, 0, 0);
 
 #--------------------- Driver goes up and down smoothly ----------------
 setlistener("/controls/gear/brake-parking", func(p)
  {
 
  if (p.getValue() == 1)
   {
		setprop("/controls/flight/throttle-input", 0);
   		interpolate("/controls/Motorcycle/driver-up", 1, 0.8);
   }
  else
   {
   		interpolate("/controls/Motorcycle/driver-up", 0, 0.8);
   }
  }, 1, 0);
  
 #--------------------- Replace bike after crash ----------------
 setlistener("/devices/status/mice/mouse/button", func(b)
  {
  	var c = getprop("/sim/crashed") or 0;
	var p = getprop("/devices/status/keyboard/event/key/pressed") or 0;
	var k = getprop("/devices/status/keyboard/event/key") or 0;
 
  if (!b.getBoolValue() and k == 109)
   {
   		if( !waiting.getValue() ){
			setprop("/controls/waiting", 1);
			setprop("/sim/presets/parkpos","");
			setprop("/sim/presets/heading-deg", getprop("/orientation/heading-deg"));
			setprop("/devices/status/keyboard/event/key",60); # overwrite the key event
			setprop("sim/current-view/view-number", 1);
			shutdown();
			setprop("/sim/presets/latitude-deg",getprop("/sim/input/click/latitude-deg"));
			setprop("/sim/presets/longitude-deg", getprop("/sim/input/click/longitude-deg"));
			setprop("/sim/presets/altitude-ft", getprop("/sim/input/click/elevation-ft"));
			setprop("/controls/gear/gear-down", 1);
			setprop("/surface-positions/left-aileron-pos-norm", 0);
			setprop("/surface-positions/right-aileron-pos-norm", 0);
			setprop("sim/current-view/view-number", 0);
	
			fgcommand("reposition");

			# after restart set level
			settimer(func{setprop("consumables/fuel/tank/level-m3", getprop("/controls/fuel/remember-level"))},0.1);

			help_win_red.write("Is everything ok with you?");
		}else{
			help_win_red.write("5 SECONDS WAITING FOR REPLACEMENT!");
			settimer(func{setprop("/controls/waiting", 0)}, 1);
		}
   }
  }, 1, 1);
  
  #-------------------------- Gearbox settings --------------------------
  var recalc_gearbox = func{
	if(getprop("controls/Motorcycle/gearbox/gear[0]/gearteeth[0]")){
		var wgbdef = props.globals.getNode("controls/Motorcycle/gearbox/").getChildren("gear");
		var tt = size(wgbdef);
		var zahn1 = 0;
		var zahn2 = 0;
		var zahn1default = 0;
		var zahn2default = 0;
		var defaultratio = 0.0;
		var ratio = 0.0;
		var vmaxnew = 0.0;
		
		for(var i = 0; i < tt; i += 1) {
		
			zahn1 = getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteeth[0]");
			zahn2 = getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteeth[1]");
			zahn1default = getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteethdefault[0]");
			zahn2default = getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteethdefault[1]");
			defaultratio = zahn1default/zahn2default;	
			
			if(abs(zahn1default - zahn1) > 3){
				screen.log.write("You fitted your gearbox with wrong gears - was reset to default!", 1.0, 0.0, 0.0);
				setprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteeth[0]",getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteethdefault[0]"));
			}
			if(abs(zahn2default - zahn2) > 3){
				setprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteeth[1]",getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteethdefault[1]"));
				screen.log.write("You fitted your gearbox with wrong gears - was reset to default!", 1.0, 0.0, 0.0);
			}
		    
			ratio = getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteeth[0]")/getprop("controls/Motorcycle/gearbox/gear["~i~"]/gearteeth[1]");
			
			setprop("controls/Motorcycle/gearbox/gear["~i~"]/ratio", ratio);
			vmaxnew = getprop("controls/Motorcycle/gearbox/gear["~i~"]/vmaxdefault")/ratio*defaultratio;
			setprop("controls/Motorcycle/gearbox/gear["~i~"]/vmax", vmaxnew);
			
		}
	 }  
  }
  
  var set_default_gearbox = func(gearnr=0){
	if(getprop("controls/Motorcycle/gearbox/gear["~gearnr~"]/gearteeth[0]")){
		setprop("controls/Motorcycle/gearbox/gear["~gearnr~"]/gearteeth[0]", getprop("controls/Motorcycle/gearbox/gear["~gearnr~"]/gearteethdefault[0]") or 0);
		setprop("controls/Motorcycle/gearbox/gear["~gearnr~"]/gearteeth[1]", getprop("controls/Motorcycle/gearbox/gear["~gearnr~"]/gearteethdefault[1]") or 0);
		setprop("controls/Motorcycle/gearbox/gear["~gearnr~"]/vmax", getprop("controls/Motorcycle/gearbox/gear["~gearnr~"]/vmaxdefault") or 0);
		recalc_gearbox();
	}
  }

  recalc_gearbox();  