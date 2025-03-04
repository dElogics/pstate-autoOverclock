This script will automatically reduces the CPU frequency using the pstate driver in case it reaches a certain threshold temperature.

Will monitor a specified file specified by it's unix path as command line arguments --temp-file, which has values in millicelsius and in case it reaches exceeds a certain threshold temperature (specified by argument --crit-temp, value in millicelsius), it'll reduce the integer value in another file (specified by command line argument --perf-file) which is also specified as command line argument as a unix path. The values in the performance file ranges from 0 to 100 and must be a whole number. The program will take another input argument '--correlation' which specifies by how much to reduce the value in --perf-file in case it exceeds the --crit-temp; for each celsius increase over the --crit-temp, the value in the --perf-file will be reduced by --correlation amount. --correlation takes in values as floating point value (i.e. it can be less than 0). If the --temp-file's value is found less than --crit-temp, the difference between the --crit-temp and the current temperature will be taken and for each celsius difference, the value in the --perf-file will be increased by --correlation. The program will run continuously, monitoring --temp-file within an interval as specified by the commandline switch -t and taking the specified action. This is written for Linux platform.
 -t default value is 5
 --crit-temp default value is 80
 --correlation default value is 0.5.

This is how you run the program -- 
pstate-autoOverclock.rb --crit-temp 80000 --perf-file /sys/devices/system/cpu/intel_pstate/max_perf_pct --correlation 0.5 --temp-file /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input

you've to search for the --temp-file. look for files /sys/devices/platform/coretemp.*/hwmon/hwmon*/temp*_input. one of them should match your CPU's 'Package id 0' temperature which you must be reading (since its the highest among all cores).

To checkout 'Package id 0' value, checkout the sensors command.
