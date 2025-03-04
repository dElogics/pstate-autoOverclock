#! /usr/bin/ruby
# Will monitor a specified file specified by it's unix path as command line arguments --temp-file, which has values in millicelsius and in case it reaches exceeds a certain threshold temperature (specified by argument --crit-temp, value in millicelsius), it'll reduce the integer value in another file (specified by command line argument --perf-file) which is also specified as command line argument as a unix path. The values in the performance file ranges from 0 to 100 and must be a whole number. The program will take another input argument '--correlation' which specifies by how much to reduce the value in --perf-file in case it exceeds the --crit-temp; for each celsius increase over the --crit-temp, the value in the --perf-file will be reduced by --correlation amount. --correlation takes in values as floating point value (i.e. it can be less than 0). If the --temp-file's value is found less than --crit-temp, the difference between the --crit-temp and the current temperature will be taken and for each celsius difference, the value in the --perf-file will be increased by --correlation. The program will run continuously, monitoring --temp-file within an interval as specified by the commandline switch -t and taking the specified action. This is written for Linux platform.
# -t default value is 5
# --crit-temp default value is 80
# --correlation default value is 0.5.
require 'optparse'

# Initialize the global hash for input swithces
$inputSwitches = {}

# Define the command-line options
OptionParser.new do |opts|
	opts.banner = "Usage: script.rb [options]"

	# --temp-file switch
	opts.on("--temp-file FILE", "Path to the temperature file") do |file|
		$inputSwitches[:'temp-file'] = file
	end

	# --crit-temp switch
	opts.on("--crit-temp TEMP", Integer, "Critical temperature threshold in millicelsius") do |temp|
		$inputSwitches[:'crit-temp'] = temp
	end

	# --perf-file switch
	opts.on("--perf-file FILE", "Path to the performance file") do |file|
		$inputSwitches[:'perf-file'] = file
	end

	# --correlation switch
	opts.on("--correlation VALUE", Float, "Correlation factor for adjusting performance") do |value|
		$inputSwitches[:correlation] = value
	end

	# -t switch
	opts.on("-t SECONDS", Integer, "Sleep interval in seconds") do |seconds|
		$inputSwitches[:sleepWait] = seconds
	end

	# Help message
	opts.on("-h", "--help", "Prints this help") do
		puts opts
		exit
	end
end.parse!

# Validate required switches
required_switches = [:'temp-file', :'perf-file']
missing_switches = required_switches - $inputSwitches.keys

if !missing_switches.empty?
  puts "Missing required switches: #{missing_switches.join(', ')}"
  exit 1
end

$inputSwitches[:sleepWait] = 5 if $inputSwitches[:sleepWait] == nil
$inputSwitches[:correlation] = 1 if $inputSwitches[:correlation] == nil
$inputSwitches[:'crit-temp'] = 80 if $inputSwitches[:'crit-temp'] == nil

# Next open all files and permanently store the IO object.
IOtemp_file = File.open($inputSwitches[:'temp-file'], "r")
IOperf_file = File.open($inputSwitches[:'perf-file'], "r+")

# function to read the file specified by the IO object as the 1st argument and rewind to the beginning of the file.
def rdFile(io_object)
	# Read the contents of the IO object
	contents = io_object.read
	# Rewind the IO object to the beginning of the stream
	io_object.rewind
	# Return the contents
	contents
end
# function to write the file specified by the IO object as the 1st argument and rewind to the beginning of the file. What has to be written is specified as the 2nd argument.
def wrFile(io_object, content)
	io_object.truncate(0)
	# Write the content to the file
	io_object.write(content)
	
	# Rewind the file pointer to the beginning of the file
	io_object.rewind
end

# we loop continuously from here.
while true
	if rdFile(IOtemp_file).to_i > $inputSwitches[:'crit-temp'].to_i
		oldPerf = rdFile(IOperf_file).to_i
		curTemp = rdFile(IOtemp_file).to_i
		newperf = oldPerf-((((curTemp - $inputSwitches[:'crit-temp'].to_i)/1000)*$inputSwitches[:correlation]).round)
	# 	Ensure it doesn't reduce to a negative value of perf.
		if newperf >= 0
			wrFile(IOperf_file, newperf)
		else
			wrFile(IOperf_file, 0)
		end
	# 	Do nothing if temp = critical temp.
	elsif rdFile(IOtemp_file).to_i < $inputSwitches[:'crit-temp'].to_i
		oldPerf = rdFile(IOperf_file).to_i
		curTemp = rdFile(IOtemp_file).to_i
		newperf = oldPerf+(((($inputSwitches[:'crit-temp'].to_i-curTemp)/1000)*$inputSwitches[:correlation]).round)
		# 	Ensure it doesn't increase to greater than 100
		if newperf > 100
			wrFile(IOperf_file, 100)
		else
			wrFile(IOperf_file, newperf)
		end
	end
	sleep $inputSwitches[:sleepWait]
end
