#!/bin/bash
# house_keeping v0.2
# empty_circle - 2023
# house_keeping is a script meant to spruce up your log files for the sake of privacy. It creates a reference file,
# modifies logs to automatically remove the ips and hosts found through the ip addr command,
# then produces a log of which files it changed.

# log reference variables
reference_file="log_reference.txt"
modified_logs="modified_logs.txt"

# search func
search_logs() {
    find / -type f -iname "*.log" 2>/dev/null > "$reference_file"
}

# ref func
in_reference() {
    grep -q -F "$1" "$reference_file"
}

# check ref and search
if [ ! -f "$reference_file" ]; then
    search_logs
fi

# grep 'ip addr'
ips_and_hosts=$(ip addr | grep -Eo 'inet\s[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $2}' | sort | uniq)
ips_and_hosts+=" "$(hostname)

# nix old mod list
if [ -f "$modified_logs" ]; then
    rm "$modified_logs"
fi

# read ref file and mod
while read -r log_file; do
    if [ -f "$log_file" ]; then
        temp_file="${log_file}.tmp"
        cp "$log_file" "$temp_file"

        for ip_or_host in $ips_and_hosts; do
            sed -i "s/${ip_or_host}/REDACTED/g" "$temp_file"
        done

        if ! cmp -s "$log_file" "$temp_file"; then
            mv "$temp_file" "$log_file"
            echo "$log_file" >> "$modified_logs"
        else
            rm "$temp_file"
        fi
    else
        # Update the reference file if a log file is not found
        if ! in_reference "$log_file"; then
            search_logs
        fi
    fi
done < "$reference_file"

# results
if [ -s "$modified_logs" ]; then
    echo "The following logs have been modified:"
    cat "$modified_logs"
else
    echo "No logs were modified."
fi
