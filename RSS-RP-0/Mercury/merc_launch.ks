set ship:control:pilotmainthrottle to 0.
{
set ship:control:pilotmainthrottle to 0.
set TrgH to 15e4.
set tollerance to TrgH*.04.
Lock Myspeed to Verticalspeed.
set phaseiii_pitch to 45.
set pit_PID to PID_Init(0.03, 0.001, 0.0003, -phaseiii_pitch, phaseiii_pitch).
set pit_noneg_PID to PID_Init(0.81, 0.0, 0.03, -15, 15).
set phasei_pitch to 15.
set pit_PID_p1 to PID_Init(0.0018, 0.001, 0.005, -phasei_pitch, 3).
set aim_down_pid to PID_init(1,0.25,0.1,-45,45).
Clearscreen.
set curT to 0.
Lock throttle to curT.
set curS TO Heading(90,90).
LOCK Steering to curS.
set n to 3.
global mercury is lex(
	"sequence", list (
	"Init wait",phys_wait@,
//	"Inclination wait",rel_Incl@,
	"Presys_checks", presys_checks@,
	"Countdown", Countdown@,
	"Pitchcontrol", Pitchcontrol@,
	"Phasei",Phasei@,
	"phaseii", Phaseii@,
	"Finalizing", Finalizing@
	), 
	"events", Lex()
	).
Function phys_wait {
Parameter mission.
print "Physics settling in."at(0,1).
wait 5.
mission["next"]().
}
Function rel_Incl { 
Parameter mission.
	set Dol to relativeInc(ship,target).
	wait 0.
	set Dac to relativeInc(ship,target).
	if Dol > Dac and relativeInc(ship,target) < 15 and relativeInc(ship,target) > 3.5 {
		if kuniverse:timewarp:warp <> 3 {
			set  kuniverse:timewarp:warp to 3.
		}
	}
	if Dol > Dac and relativeInc(ship,target) < 3.5 and relativeInc(ship,target) > 2 {
		if kuniverse:timewarp:warp <> 2 {
			set  kuniverse:timewarp:warp to 2.
		}
	}
		if Dol > Dac and relativeInc(ship,target) < 2 {
		if kuniverse:timewarp:warp <> 1 {
			set  kuniverse:timewarp:warp to 1.
		}
	}
	if Dol < Dac or (Dol > Dac and relativeInc(ship,target) > 10) {
		if kuniverse:timewarp:warp <> 4 {
			set  kuniverse:timewarp:warp to 4.
		}
	}
	If relativeInc(ship,target) < 1.2 and Dol > Dac {
	set kuniverse:timewarp:warp to 0.
	set ship:control:pilotmainthrottle to 0.
	mission["next"]().
	}
}

Function Presys_checks{
	Parameter mission.
	if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:issettled {
	set ship:control:pilotmainthrottle to 0.
	set curT to 1.
	Notify ("Flightcomputer is running",2).
	wait 2.
	stage.
	mission["next"]().
	}
}
Function  Countdown {
	Parameter mission.
	FROM {local x is n.} UNTIL x = 0 STEP {set x to x-1.} DO {
		NOTIFY("T - "+ x +" Seconds", 1).
		wait 1.
	}
	NOTIFY("Liftoff", 1).
	wait 1.
	stage.
	staging_logic().
	dvcalc().
	mission["next"]().
}
Function Pitchcontrol { 
	Parameter mission.
		If myspeed < 100 {
			set curS to Heading(90,90).
		}
		set curS to heading(90, MAX(90 * (constant:e ^ (-1.789e-5 * apoapsis )),13)).  
		If apoapsis > (TrgH + (tollerance * .5)) {
			mission["next"]().
		}
}
Function Phasei {
	Parameter mission.
	set curS to heading(compass_of_vel(ship:velocity:orbit),PID_Seek(Pit_PID_p1, (TrgH + tollerance), Apoapsis)).
	If Periapsis < -1e6 and Periapsis > -4e6{
		mission["next"]().
	}
}
Function Phaseii {
	Parameter mission.
	if eta:Apoapsis < eta:Periapsis {
		set curS to heading(compass_of_vel(ship:velocity:orbit),PID_Seek(Pit_PID_p1, (TrgH + tollerance), Apoapsis)).
	}
	if myspeed < 20 {
			set curS to heading(compass_of_vel(ship:velocity:orbit),PID_Seek(Pit_noneg_PID, 5, myspeed)).
	}
	If Periapsis > -7e5 {
		mission["next"]().
	}
}
Function Finalizing {
	Parameter mission.
	lock aim_down_accel to PID_Seek(aim_down_pid, 0, myspeed).
	print "aim_down_accel " + round(aim_down_accel,2) +"        "at(0,16).
	if ship:availablethrust > 0 {
		set aim_down_angle to arcsin(max(-1,min(1,aim_down_accel / (ship:availablethrust / ship:mass))) ).
	print "aim_down_angle " + round(aim_down_angle,2) +"        "at(0,17).
	} 
	else { 
		set aim_down_angle to 0.
	}
	set side_vec to VCRS(ship:up:vector, ship:velocity:surface).
	set aim_vec to angleaxis(-aim_down_angle,side_vec) * ship:velocity:surface.
	set curs to aim_vec. 
	If Periapsis > TrgH or (Periapsis > body:atm:height and apoapsis > TrgH + constant:pi*tollerance) {	
		set curt to 0.
		mission["terminate"]().
	}
}

}