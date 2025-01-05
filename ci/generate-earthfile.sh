#!/bin/bash

# Input and output file paths
INPUT_FILE="./input.yaml"
EARTHFILE_PATH="Earthfile"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file not found at $INPUT_FILE"
  exit 1
fi

# Extract the merge section using yq 3.x
MERGE_CONTENT=$(yq -r -j '.ci.merge' "$INPUT_FILE") # Convert to JSON for easy parsing

# Initialize Earthfile content
EARTHFILE_CONTENT="VERSION 0.8\n"
FUNCTIONS=()

# Process the JSON using jq to flatten the structure
TASKS=$(echo "$MERGE_CONTENT" | jq -r 'to_entries[] | .key as $key | .value | to_entries[] | select(.value == "yes") | "\($key)-\(.key)"')

# Iterate over the tasks
for TASK in $TASKS; do
  FUNCTION_NAME=$(echo "$TASK" | sed 's/-/-/g') # Replace '-' with '_' for valid function names
  FUNCTIONS+=("$FUNCTION_NAME")
  EARTHFILE_CONTENT+="$FUNCTION_NAME:\n  LOCALLY\n  RUN echo \"$FUNCTION_NAME Completed\" \n\n"
done

# Add the "all" function
EARTHFILE_CONTENT+="all:\n"
for FUNCTION in "${FUNCTIONS[@]}"; do
  EARTHFILE_CONTENT+=" BUILD +$FUNCTION\n"
done

# Write the Earthfile content to the output file
echo -e "$EARTHFILE_CONTENT" > "$EARTHFILE_PATH"

if [ $? -eq 0 ]; then
  echo "Earthfile has been generated at $EARTHFILE_PATH"
else
  echo "Error: Failed to generate Earthfile"
  exit 1
fi
