###########################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		KTM-RC16 for Flightgear September 2016
#		This file is licenced under the terms of the GNU General Public Licence V2 or later
###########################################################################################
var menu = props.globals.initNode("/controls/Motorcycle/menu",0,"DOUBLE");

###########################################################################################

setlistener("/controls/Motorcycle/butMenu", func (state){
	var menustate = menu.getValue();
	# helper for the Menu
	if (state.getBoolValue() == 1) {
	menustate = menustate+1 ;
	menustate = (menustate > 2) ? 0 : menustate;
		menu.setValue(menustate);
	}
	settimer(func{state.setBoolValue(0)},0.4);
},0,1);

setlistener("/controls/Motorcycle/butRun", func (state){
	# helper for the Menu
	if (state.getBoolValue() == 1) {
		startup();
	}
	settimer(func{state.setBoolValue(0)},2.2);
},0,1);

setlistener("/controls/Motorcycle/butOff", func (state){
	# helper for the Menu
	if (state.getBoolValue() == 1) {
		shutdown();
	}
	settimer(func{state.setBoolValue(0)},0.6);
},0,1);

setlistener("/controls/Motorcycle/butUp", func (state){
	var go = 0;
	# helper for the Menu
	if (state.getBoolValue() == 1) {
		if (menu.getValue() == 1) {
			go = getprop("/instrumentation/Motorcycle/speed-indicator/speed-limiter") or 0;
			go = (go > 340) ? 350 : go +10 ;
			setprop("/instrumentation/Motorcycle/speed-indicator/speed-limiter", go);
		}
		if (menu.getValue() == 2) {
			go = getprop("/controls/steering-damper") or 0;
			go = (go > 15) ? 16 : go +1 ;
			setprop("/controls/steering-damper", go);
		}
	}
	
	settimer(func{state.setBoolValue(0)},0.4);
},0,1);

setlistener("/controls/Motorcycle/butDown", func (state){
	var go = 0;
	# helper for the Menu
	if (state.getBoolValue() == 1) {
		if (menu.getValue() == 1) {
			go = getprop("/instrumentation/Motorcycle/speed-indicator/speed-limiter") or 0;
			go = (go < 10) ? 0 : go -10 ;
			setprop("/instrumentation/Motorcycle/speed-indicator/speed-limiter", go);
		}
		if (menu.getValue() == 2) {
			go = getprop("/controls/steering-damper") or 0;
			go = (go < 1) ? 0 : go -1 ;
			setprop("/controls/steering-damper", go);
		}
	}
	
	settimer(func{state.setBoolValue(0)},0.4);
},0,1);