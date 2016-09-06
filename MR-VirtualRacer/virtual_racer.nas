###############################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		Motorcylces for Flightgear September 2016
#		This file is licenced under the terms of the GNU General Public Licence V2 or later
############################################################################################### 
var wprec = props.globals.initNode("/virtual-racer/recording",0,"BOOL");
var wpplay = props.globals.initNode("/virtual-racer/play",0,"BOOL");
var wpvr = props.globals.initNode("/virtual-racer/wp",-1,"INT");
var time_stamp = props.globals.initNode("/virtual-racer/last-timestamp",0,"DOUBLE");
var ready = props.globals.initNode("/virtual-racer/ready",0,"BOOL");

var replaywp = 0;
var foo = 0;

# var racelap set in laptimes.nas
# var thissector set in laptimes.nas
# var sector set in laptimes.nas

setlistener("/virtual-racer/recording", func (r){
    var r = r.getBoolValue();
    if (r != nil and r == 1){
		virtual_racebikes_rec();
	}
});

setlistener("/virtual-racer/play", func (p){
    var p = p.getBoolValue();
    if (p != nil and p == 1){
		var points = props.globals.getNode("/virtual-racer/way").getChildren("point");
		wpvr.setValue(size(points)-1);
		virtual_racebikes_play();
	}
});

var virtual_racebikes_rec =  func{

	if (wprec.getBoolValue() == 1){
		#print(size(sectors));
		wpplay.setBoolValue(0);
		if (racelap.getValue() > 0){ 
			wpvr.setValue(wpvr.getValue()+1);
			setprop("/virtual-racer/way/point["~wpvr.getValue()~"]/lat", getprop("/position/latitude-deg") or 0);
			setprop("/virtual-racer/way/point["~wpvr.getValue()~"]/lon", getprop("/position/longitude-deg") or 0);
			setprop("/virtual-racer/way/point["~wpvr.getValue()~"]/elev-m", getprop("/position/ground-elev-m") or 0);
			setprop("/virtual-racer/way/point["~wpvr.getValue()~"]/hdg", getprop("/orientation/heading-deg") or 0);
			setprop("/virtual-racer/way/point["~wpvr.getValue()~"]/pitch", getprop("/orientation/pitch-deg") or 0);
			setprop("/virtual-racer/way/point["~wpvr.getValue()~"]/roll", getprop("/surface-positions/left-aileron-pos-norm") or 0);
			setprop("/virtual-racer/way/point["~wpvr.getValue()~"]/duration-sec", 
			getprop("/sim/time/elapsed-sec")-time_stamp.getValue());
			time_stamp.setValue(getprop("/sim/time/elapsed-sec"));
			help_win.write("RECORDING")
		}
		settimer(virtual_racebikes_rec, 0.1);
	}		
}

var virtual_racebikes_play =  func{
		if(wpvr.getValue() >= 0 and wpplay.getBoolValue()) {
			wprec.setBoolValue(0);
			help_win.write("VIRTUAL RACER ON THE TRACK");
			if(replaywp <= wpvr.getValue()){
			 if (foo != 0) foo.remove();
			 foo = geo.put_model("/Aircraft/Motorcycle-Racing/MR-VirtualRacer/BMW.xml", getprop("/virtual-racer/way/point["~replaywp~"]/lat"), getprop("/virtual-racer/way/point["~replaywp~"]/lon"), getprop("/virtual-racer/way/point["~replaywp~"]/elev-m") + 0.2, getprop("/virtual-racer/way/point["~replaywp~"]/hdg"), getprop("/virtual-racer/way/point["~replaywp~"]/pitch"), getprop("/virtual-racer/way/point["~replaywp~"]/roll")*80);
			  #print(replaywp);
			  replaywp += 1;
			  if(replaywp > wpvr.getValue()) replaywp = 0;
			}
		}
		settimer(virtual_racebikes_play, 0.1);
}	
	