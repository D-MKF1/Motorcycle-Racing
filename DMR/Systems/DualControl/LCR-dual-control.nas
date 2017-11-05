###############################################################################
##  Nasal for dual control of the Common-Spruce CS 1 over the multiplayer network.
##
##  Copyright (C) 2007 - 2008  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license version 2 or later.
##
##  For the DMR-F2, written in Octobre 2014 by Marc Kraus
##
###############################################################################

## Renaming (almost :)
var DCT = dual_control_tools;

## Pilot/copilot aircraft identifiers. Used by dual_control.
var pilot_type   = "Aircraft/Motorcycle-Racing/DMR/Models/DMR-F2.xml";
var copilot_type = "Aircraft/Motorcycle-Racing/DMR/Models/DMR-P.xml";

############################ PROPERTIES MP ###########################

var TDM_mpp     = "sim/multiplay/generic/string[1]";

var speed		= 	["instrumentation/DMR/speed-indicator/speed-limiter-switch",
					 "instrumentation/DMR/speed-indicator/speed-limiter",
					 "instrumentation/DMR/speed-indicator/speed-meter",
					 "instrumentation/DMR/speed-indicator/selection"];		 
var eng			= 	["engines/engine/gear"];

var l_dual_control    = "dual-control/active";
var i_am_the_driver    = "dual-control/driver";

######################################################################
###### Used by dual_control to set up the mappings for the pilot #####
######################## PILOT TO COPILOT ############################
######################################################################

var pilot_connect_copilot = func (copilot) {
  # Make sure dual-control is activated in the FDM FCS.
  # print("Pilot section");
  setprop(l_dual_control, 1);
  setprop(i_am_the_driver, 1);

  return [
      ##################################################
      # Map copilot properties to buffer properties

      # copilot to pilot
      DCT.TDMEncoder.new
        ([
          props.globals.getNode(speed[0]),
          props.globals.getNode(speed[1]),
          props.globals.getNode(speed[2]),
          props.globals.getNode(speed[3]),
          props.globals.getNode(eng[0])
         ], props.globals.getNode(TDM_mpp)),
  ];
}

##############
var pilot_disconnect_copilot = func {
  setprop(l_dual_control, 0);
  setprop(i_am_the_driver, 0);
}

######################################################################
##### Used by dual_control to set up the mappings for the copilot ####
######################## COPILOT TO PILOT ############################
######################################################################

var copilot_connect_pilot = func (pilot) {
  # Make sure dual-control is activated in the FDM FCS.
  # print("Copilot section");
  setprop(l_dual_control, 1);
  setprop(i_am_the_driver, 0);
  

  return [

      ##################################################
      # Map pilot properties to buffer properties
	  
     DCT.Translator.new(pilot.getNode("sim/multiplay/generic/float[3]"),
                         props.globals.getNode("/controls/DMR/driver-up", 1),1),
						 			 
     DCT.TDMDecoder.new
       (pilot.getNode(TDM_mpp), 
       [func(v){pilot.getNode(speed[0], 1).setValue(v); props.globals.getNode("dual-control/pilot/"~speed[0], 1).setValue(v);},
        func(v){pilot.getNode(speed[1], 1).setValue(v); props.globals.getNode("dual-control/pilot/"~speed[1], 1).setValue(v);},
        func(v){pilot.getNode(speed[2], 1).setValue(v); props.globals.getNode("dual-control/pilot/"~speed[2], 1).setValue(v);},
        func(v){pilot.getNode(speed[3], 1).setValue(v); props.globals.getNode("dual-control/pilot/"~speed[3], 1).setValue(v);},
        func(v){pilot.getNode(eng[0], 1).setValue(v); props.globals.getNode("dual-control/pilot/"~eng[0], 1).setValue(v);}
       ]),

       # from TDM_mpp
       DCT.MostRecentSelector.new(props.globals.getNode("dual-control/pilot/"~speed[0], 1), props.globals.getNode(speed[0]), props.globals.getNode(speed[0]), 0.01),
       DCT.MostRecentSelector.new(props.globals.getNode("dual-control/pilot/"~speed[1], 1), props.globals.getNode(speed[1]), props.globals.getNode(speed[1]), 0.01),
       DCT.MostRecentSelector.new(props.globals.getNode("dual-control/pilot/"~speed[2], 1), props.globals.getNode(speed[2]), props.globals.getNode(speed[2]), 0.01),
       DCT.MostRecentSelector.new(props.globals.getNode("dual-control/pilot/"~speed[3], 1), props.globals.getNode(speed[3]), props.globals.getNode(speed[3]), 0.01),
       DCT.MostRecentSelector.new(props.globals.getNode("dual-control/pilot/"~eng[0], 1), props.globals.getNode(eng[0]), props.globals.getNode(eng[0]), 0.01)
  ];

}

var copilot_disconnect_pilot = func {
  setprop(l_dual_control, 0);
  setprop(i_am_the_driver, 0);
}
