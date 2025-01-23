#!/bin/bash

IMAP_SERVER="imap://127.0.0.1:143/INBOX"
USERNAME="bob"
PASSWORD="secret"
EML_DIRECTORY="emls"  # Path to the directory containing .eml files

SUCCESS_COUNT=0
ERROR_COUNT=0

# Check if the directory exists
if [[ ! -d "$EML_DIRECTORY" ]]; then
    echo "Error: The directory $EML_DIRECTORY does not exist."
    exit 1
fi

# Iterate over the .eml files in the directory
for FILE in "$EML_DIRECTORY"/*.eml; do
    # Check if the file exists
    if [[ ! -f "$FILE" ]]; then
        echo "No .eml files found in $EML_DIRECTORY."
        exit 0
    fi

    echo "Processing file: $FILE"

    # Use curl to perform the APPEND
    curl -u "$USERNAME:$PASSWORD" \
        --url "$IMAP_SERVER" \
        -T "$FILE"

    # Check the status of the curl command
    if [[ $? -eq 0 ]]; then
        echo "APPEND successful for $FILE"
        ((SUCCESS_COUNT++))
    else
        echo "Error during APPEND for $FILE"
        ((ERROR_COUNT++))
    fi
done

echo -e "\nUpload complete. Successfully uploaded: $SUCCESS_COUNT, Errors: $ERROR_COUNT"
