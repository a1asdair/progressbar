
//  progressbar.ado 
//  Alasdair Rutherford
//  27th March 2017

//  Creates a progress bar for looping tasks
//  User can sepcify a start, end, step and current position
//  Start is optional (default 1)
//  Step is optional (default 1)
//  loud prevents the command from clearing the screen

// v0.4

// Usage
// Prior to a set of nested loops, -progressbar- must be called with all options specified.
// This calculated the total iterations in the nested loops, and sets up the counters.
// After this, -progressbar- should be called once at the deepest level of nested loops
// when the progress bar will then be displayed.  This call increments the progress, so 
// there should only be one call.

// If the progress bar needs to be displayed at another time, the option noinc can be specified.
// This displays the bar without incrementing the counter.


// Note: -progressbar- uses two global macros, and so will malfunction if these macro names
// are used elsewhere in Stata

// Initialisation Options

// init
// Specify init before the loop begins.  All other option must then be specified/
// If init is omitted then all other options, except for loud, are ignored

// type()
// There are two types of loop supported:
//		v	forvalues
// 		e 	foreach
// Specify in order the types of nested loop e.g. "e v v"
// Any number of forvalues loops are supported; up to 10 nested foreach loops are supported

// start()
// list the starting values for each of the forvalues loops
// e.g. 1 1 3

// end()
// list the ending value for each of the forvalues loops
// e.g. 10 100 6

// step()
// Specify the step values for each of the forvalue loops
// If they are all 1, then this option can be omitted, otheriwse it must be specified
// e.g. 2 1 1

// list#()
// Include the list for each of the foreach loops in turn
// -progressbar- supports up to 10 nested foreach loops

// width()
// allows the user to specify the width of the bar displayed in characters.
// The default is 80 characters.

// Looping Options

// loud
// This option prevents the -progressbar- from clearing the screen, allowing the output to be preserved

// display
// This option displays the progress bar without incrementing the counter

// time
// This option needs to be sepcified in both the initiation and looping commands.
// It estimates the remaining time for the loop, assuming constant runtimes.


capture prog drop progressbar

program progressbar,

version 11
syntax , [init] [start(string)] [end(string)] [step(string)] [type(string)] [list1(namelist) list2(namelist) list3(namelist) list4(namelist) list5(namelist) list6(namelist) list7(namelist) list8(namelist) list9(namelist) list10(namelist)] [time width(integer 80) display] [loud] [debug] 


// When the command is initiated, claculate the total length of the loops

	if "`init'"=="init" {


		local nestnum = wordcount("`type'",1)

		di "`nestnum'"
	
		local l = 0
	
		forvalues ii = 1(1)`nestnum' {
		
			if word("`type'",`ii') == "v" {
	
				local nv =`nv' + 1
				if "`step'"=="" {
					local step`nv'=1
				}
				else {
					local step`nv' = real((word("`step'",`nv')))
				}

				local length`ii' = round( (real(word("`end'",`nv')) - real(word("`start'",`nv'))) / `step`nv'' ,1) + 1
				// di "length`ii' is `length`ii''"
			}
		

	
			if word("`type'",`ii') == "e" {
		
				local ne =`ne' + 1
	
				local length`ii' = wordcount("`list`ne''",1)
				// di "length`ii' is `length`ii''"
			}
			
			
		}
		
		* Error checking on list types
		
		//if word("`type'",`ii') != ("e" | "v") {
			//di "Invalid loop type - must be e or v"
			//exit
		// }
		
	
		forvalues ii = 1(1)`nestnum' {		
			
			if `ii'==1 {			
				local multiply = `length1'
			}
			else {
				local multiply = `multiply' * `length`ii'' 	
			}	
		}	
		
		
		
		
			
		global progressbarlength = `multiply'
		global progressbarposition = 0

		if "`time'"=="time" {
			global progressbarstarttime = clock("$S_TIME", "hms")
		}
		
		if "`debug'"=="debug" {
			di $progressbarlength
		}
		
		
	}

	else {
	
// When the command is called in a loop, display the progress bar comparing
// distance travelled to the length

	
		if $progressbarposition < $progressbarlength {

			if "`display'"!="display" {
				// di "`display'"
				global progressbarposition = $progressbarposition + 1
			}

			local barwidth = `width' - 6
		
			local percent = $progressbarposition / $progressbarlength
			local print = round(`percent' * `barwidth',1)
			
			if "`debug'"=="debug" {
				di "Progress bar width is `barwidth'"
				di "Printing `print'"
			}
	
	

			
			if ("`loud'"!="loud") {	
				set more off	
				cls
			}
		
	
			local printbar = "|"
	
			quietly forvalues ii = 1(1)`print' {	
				local printbar = "`printbar'" + "="		
			}

			if `print'<`barwidth' {
				local emptyprint = `print'+1
				quietly forvalues ii = `emptyprint'(1)`barwidth' {	
					local emptybar = "`emptybar'" + "."		
				}
			}
			
			if ("`loud'"!="loud") {	
				cls
			}
	
			local printpercent = round(`percent'*100,1)

			if `printpercent'>=10 {
				local space = "~"
			}
			if `printpercent'>=100 {
				local space=""
			}

			if `printpercent'<10 {
				local space = "~~"
			}
	
			* Display the completed progress bar
			di "`printbar'" "`emptybar'" "|" "`space'" "`printpercent'" "%"

			
				// global progressbarnowtime = clock("$S_TIME", "hms")
			if "`time'"=="time" {
				local elapsedtime = (clock("$S_TIME", "hms") - $progressbarstarttime)/60000
				// local remainingtime = round((`elapsedtime'/`percent') - `elapsedtime',.01)
				local remainingtime = (`elapsedtime'/`percent') - `elapsedtime'
	

				if `elapsedtime'>1 & `elapsedtime'<=60 {
					local elapsedtime = round(`elapsedtime',0.1)
					local units1 = "mins"
				}
				
				if `elapsedtime'>60 & `elapsedtime'<=1440 {
					local elapsedtime = round(`elapsedtime'/60,0.1)
					local units1 = "hours"
				}
				
				if `elapsedtime'>1440 {
					local elapsedtime = round(`elapsedtime'/1440,0.1)
					local units1 = "days"
				}
				
				if `elapsedtime'<=1 {
					local elapsedtime = round(`elapsedtime'*60,1)
					local units1 = " secs"
				}		
				
				if `remainingtime'>1 & `remainingtime'<=60 {
					local remainingtime = round(`remainingtime',0.1)
					local units2 = "mins."
				}
				
				if `remainingtime'>60 & `remainingtime'<=1440 {
					local remainingtime = round(`remainingtime'/60,0.1)
					local units2 = "hours."
				}
				
				if `remainingtime'>1440 {
					local remainingtime = round(`remainingtime'/1440,0.1)
					local units2 = "days."
				}	
				
				if `remainingtime'<=1 {
					local remainingtime = round(`remainingtime'*60,1)
					local units2 = "secs."
				}
							
				
				di "Time elapsed " "`elapsedtime'" " `units1'" ", estimated time remaining " "`remainingtime'" " `units2'"
			}


		}
		else {
			di "Your progress has exceeded 100% - perhaps you need to initialise a new progressbar?"
		}
					
}
	
end

