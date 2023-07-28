#!/bin/bash

# Load the current counter value from the file
counter=$(cat ./deployment_counter.txt)
# Increment the counter by 1
new_counter=$((counter + 1))
# Update the counter value in the file
echo "$new_counter" > deployment_counter.txt
# Store the new counter value as an output
echo "::set-output name=counter_value::$new_counter"
