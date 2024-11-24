#!/usr/bin/env python3
import json, requests, yaml

#
# read_config function
#
# Basic config reader, opens and reads a yaml file and return the content as a Dict with configuration information.
#
def read_config(config):
    try:
        with open(config) as fh:
            config_yaml = yaml.safe_load(fh.read())
    except Exception as err:
        print(str(err))
        exit(2)

    return(config_yaml)

#
# Set the config flle and read it, ready for use
#
config_file = "pd_config.yaml"
config_dict = read_config(config_file)

#
# Setup api_token, endpoint target and headers for communication with PD
#
api_token = config_dict["api_token"]
schedule_endpoint = config_dict["pd_schedule_uri"]

headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": f"Token token={api_token}",
}

#
# Retrieve the schedules from the configuration
#
with open(config_file) as fh:
    config_dict = yaml.safe_load(fh.read())

#
# Prepare and apply the configured schedules, skipping any already existing.
#
for schedule in config_dict["schedules"]:
    try:
        response = requests.post(schedule_endpoint, headers=headers, json=schedule)
    except Exception as err:
        print(f"An error was encountered when trying to add a schedule. Schedule: {schedule['schedule']['name']} Error: {err}")

    if response.status_code != 200:
        print(f"Something went wrong: {response}")
