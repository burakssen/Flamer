#!/bin/bash

# Function to display a spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Create a samples directory
samples_dir="flamegraph_samples"
mkdir -p "$samples_dir"
echo "Created samples directory: $samples_dir"

# Get the process name from user input
echo "Enter the process name:"
read process_name

# Find the PID of the process
echo "Searching for process..."
pid=$(pgrep -f "$process_name")
if [ -z "$pid" ]; then
    echo "Process not found. Exiting."
    exit 1
fi
echo "Found process $process_name with PID $pid"

# Get sampling time from user input
echo "Enter sampling time in seconds (default is 30):"
read sampling_time
sampling_time=${sampling_time:-30}  # Use 30 if no input is provided

# Create a timestamp for unique directory name
timestamp=$(date +"%Y%m%d_%H%M%S")

# Create a directory for output files inside the samples directory
output_dir="${samples_dir}/flamegraph_${process_name}_${timestamp}"
mkdir -p "$output_dir"
echo "Output files will be saved in: $output_dir"

# Sample the process for the specified time
echo "Sampling process for ${sampling_time} seconds..."
sample "$pid" "$sampling_time" -f "${output_dir}/${process_name}_profile.txt" &
spinner $!
echo "Sampling complete."

# Convert to folded format
echo "Converting to folded format..."
stackcollapse-sample.awk "${output_dir}/${process_name}_profile.txt" > "${output_dir}/${process_name}_folded.txt" &
spinner $!
echo "Conversion complete."

# Generate flame graph
echo "Generating flame graph..."
flamegraph.pl "${output_dir}/${process_name}_folded.txt" > "${output_dir}/${process_name}_flamegraph.svg" &
spinner $!
echo "Flame graph generation complete."

echo "All steps completed. Files are located in: $output_dir"