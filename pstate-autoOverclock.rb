#! /usr/bin/ruby
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
