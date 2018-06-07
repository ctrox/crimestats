#!/bin/bash

function check_command {
  local command=$1
  # Checks if command $1 is installed
  if ! [ -x "$(command -v ${command})" ]; then
    echo "Error: ${command} is not installed." >&2
    exit 1
  fi
}

function check_csv_file {
  # Checks if the variable is set
  if [ -z $1 ]; then
    echo "Error: CSV file not supplied"
    exit 1
  fi
  # checks if the file exists
  if [ ! -f $1 ]; then
    echo "Error: CSV file ${1} does not exist"
    exit 1
  fi
}

function structure {
  local csvfile=$1
  echo
  echo "--- File structure ---"
  # Display column names
  csvstat --names $csvfile
  # Display row count
  csvstat --count $csvfile
  echo
}

function crime_frequency {
  local csvfile=$1
  echo
  echo "--- Crime frequency ---"
  # Select case and total columns, sort in reverse and display
  csvcut -c "Case Incident Type",Total $csvfile | csvsort -c Total -r | csvlook
  echo
}

function crime_frequency_by_city {
  local csvfile=$1
  echo "Enter one of the following cities:"
  csvstat --names $csvfile | head -n -1 | tail -n +2
  echo
  read city
  echo
  echo "--- Crime frequency by city ---"
  # Select case and city columns, sort in reverse and display the first
  csvcut -c "Case Incident Type",$city crime.csv | csvsort -c $city -r | head -n 2 | csvlook
  echo
}

function least_crime_city {
  local csvfile=$1
  echo
  echo "--- City with the lowest crime rate ---"
  # select city columns, csvstat calculates the sums
  # cut only the sums, sort and display the first
  csvstat -c 2,3,4,5,6,7,8,9,10 --csv crime.csv | csvcut -c column_name,sum | csvsort -c sum | head -n 2 | tail -n 1
  echo
}

function menu {
  # Menu title
  echo "--- CRIMESTATS MENU ---"
  # set the prompt
  PS3='Please enter your choice: '
  # All the options
  options=(
    "File Structure"
    "Crime frequency"
    "Crime frequency by city"
    "City lowest crime rate"
    "Quit"
  )
  # select options
  select opt in "${options[@]}"
  do
    case $opt in
      "File Structure")
        structure $1
        menu $1
        ;;
      "Crime frequency")
        crime_frequency $1
        menu $1
        ;;
      "Crime frequency by city")
        crime_frequency_by_city $1
        menu $1
        ;;
      "City lowest crime rate")
        least_crime_city $1
        menu $1
        ;;
      "Quit")
        break
        ;;
      *) echo "invalid option $REPLY";;
    esac
  done
}

# Check if csvkit commands are installed
check_command "csvstat"
check_command "csvcut"
check_command "csvsort"
check_command "csvlook"

# Display usage
usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
# Display usage if no arguments are supplied
[ $# -eq 0 ] && usage

while getopts ":hsd:" arg; do
  case $arg in
    d) # Input CSV file to analyse
      csvfile=$OPTARG
      check_csv_file $csvfile
      menu $csvfile
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done
