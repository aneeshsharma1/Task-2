#!/bin/bash

VERSION="v0.1.0"

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                usage
                exit 0
                ;;
            -v | --version)
                echo "internsctl $VERSION"
                exit 0
                ;;
            cpu)
                if [ "$2" == "getinfo" ]; then
                    # Get and format CPU information similar to lscpu
                    cpu_info=$(lscpu)
                    echo "CPU Information:"
                    echo "$cpu_info"
                else
                    echo "Error: Unknown argument for 'cpu' command."
                    usage
                    exit 1
                fi
                shift 2
                ;;
            memory)
                if [ "$2" == "getinfo" ]; then
                    # Get and format memory information similar to free command
                    memory_info=$(free -m)
                    echo "Memory Information:"
                    echo "$memory_info"
                else
                    echo "Error: Unknown argument for 'memory' command."
                    usage
                    exit 1
                fi
                shift 2
                ;;
            user)
                case "$2" in
                    create)
                        create_user "$3"
                        shift 3
                        ;;
                    list)
                        list_users "$3"
                        shift 3
                        ;;
                    *)
                        echo "Error: Unknown argument for 'user' command."
                        usage
                        exit 1
                        ;;
                esac
                ;;
            file)
                if [ "$2" == "getinfo" ]; then
                    shift 2
                    file_getinfo "$@"
                else
                    echo "Error: Unknown argument for 'file' command."
                    usage
                    exit 1
                fi
                ;;
            *)
                echo "Error: Unknown option or argument: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

create_user() {
    local username="$1"
    if [ -z "$username" ]; then
        echo "Error: Missing username. Usage: internsctl user create <username>"
        return
    fi

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "Error: User '$username' already exists."
    else
        # Create the user and assign a home directory
        useradd -m "$username"
        echo "User '$username' created."
    fi
}

list_users() {
    local sudo_only="$1"
    echo "User List:"
    if [ -n "$sudo_only" ] && [ "$sudo_only" == "--sudo-only" ]; then
        # List users with sudo permissions
        grep -Po '^sudo.*:\K.*$' /etc/group | tr ',' '\n'
    else
        # List all users
        getent passwd | cut -d: -f1
    fi
}

file_getinfo() {
    local size_option=""
    local permissions_option=""
    local owner_option=""
    local last_modified_option=""
    local filename=""

    # Parse options and arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --size | -s)
                size_option="true"
                ;;
            --permissions | -p)
                permissions_option="true"
                ;;
            --owner | -o)
                owner_option="true"
                ;;
            --last-modified | -m)
                last_modified_option="true"
                ;;
            *)
                # Assume any other arguments are the filename
                filename="$1"
                ;;
        esac
        shift
    done

    if [ -z "$filename" ]; then
        echo "Error: Missing file name. Usage: internsctl file getinfo [options] <file-name>"
        return
    fi

    if [ -f "$filename" ]; then
        # Get file information and format it based on options
        if [ -n "$size_option" ]; then
            # If --size option is provided, only print the file size
            file_size=$(stat -c %s "$filename")
            echo "$file_size"
        elif [ -n "$permissions_option" ]; then
            # If --permissions option is provided, only print the file permissions
            file_permissions=$(stat -c %A "$filename")
            echo "$file_permissions"
        elif [ -n "$owner_option" ]; then
            # If --owner option is provided, only print the file owner
            file_owner=$(stat -c %U "$filename")
            echo "$file_owner"
        elif [ -n "$last_modified_option" ]; then
            # If --last-modified option is provided, only print the last modified time
            file_last_modified=$(stat -c %y "$filename")
            echo "$file_last_modified"
        else
            # Print full file information
            file_access=$(stat -c %A "$filename")
            file_size=$(stat -c %s "$filename")
            file_owner=$(stat -c %U "$filename")
            file_modify_time=$(stat -c %y "$filename")
            echo "File: $filename"
            echo "Access: $file_access"
            echo "Size(B): $file_size"
            echo "Owner: $file_owner"
            echo "Modify: $file_modify_time"
        fi
    else
        echo "Error: File '$filename' does not exist."
    fi
}

usage() {
    echo "Usage: internsctl [options] [command] [arguments]"
    echo "Options:"
    echo "  -h, --help       Display this help message."
    echo "  -v, --version    Display the version of internsctl."
    echo "Commands:"
    echo "  cpu getinfo      Retrieve CPU information."
    echo "  memory getinfo   Retrieve Memory information."
    echo "  user create      Create a new user with a home directory."
    echo "  user list        List users on the system."
    echo "  file getinfo     Get information about a file."
    # Add more commands and usage information as needed.
}

main "$@"