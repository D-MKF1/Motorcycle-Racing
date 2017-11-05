#######################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		DMR-F2 for Flightgear Octobre 2014
#		This file is licenced under the terms of the GNU General Public Licence V2 or later
#######################################################################################
setprop("sim/current-view/view-number",8);

setlistener("sim/current-view/view-number", func (nr){
    var nr = nr.getValue();
	# do never show the view nr 0
	if(nr == 0){
		setprop("sim/current-view/view-number",1);
	}
},1,0);

setlistener("/controls/DMR/driver-up", func (position){
    var position = position.getValue();
	setprop("/controls/flight/aileron", getprop("/controls/flight/aileron") - 0.001);
},1,0);

# aileron control is view control for the passenger
setlistener("/controls/flight/aileron", func (position){
    var position = position.getValue();
	var vn = getprop("sim/current-view/view-number") or 0;
	var ws = getprop("/controls/DMR/driver-up") or 0;
	var offs = getprop("/controls/flight/elevator") or 0;

	if(vn == 8){
		var xpos = position*1.1-0.61;
		setprop("/sim/current-view/x-offset-m", xpos);
		setprop("/sim/current-view/z-offset-m", 0.18+ws*0.2);
		if(xpos > -0.65){
			setprop("/sim/current-view/y-offset-m", abs(position*0.4)+0.46+ws*0.7);
		}else if(xpos < -0.65){
			setprop("/sim/current-view/y-offset-m", abs(position*0.2)+0.1+ws*0.7);
			setprop("/sim/current-view/z-offset-m", 0.70);
		}else{
			setprop("/sim/current-view/y-offset-m", abs(position*0.6)+0.6+ws*0.7);
		}	
		
		if(offs > 0.2 ) setprop("/sim/current-view/y-offset-m", getprop("/sim/current-view/y-offset-m") + 0.1);
	}

},0,1);

setlistener("/controls/flight/rudder", func (rposition){
	var vn = getprop("sim/current-view/view-number") or 0;
	if(vn == 8){
    	var rposition = rposition.getValue();
		var par = rposition*-170;
		setprop("/sim/current-view/heading-offset-deg", par);
	}
});


