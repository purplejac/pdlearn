#!/usr/bin/env python
#
# Creates support schedules based on team assignments, populated with existing users from PagerDuty
# BEWARE: Regenerates the whole config.yaml to a local output for safety. Will need to overwrite pd_config.yaml for use.
#
import requests
import json
import yaml

from collections import deque

#
# Disable alias creation for yaml dumping
#
class NoAliasDumper(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True

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
config_file = "../pd_config.yaml"
config_dict = read_config(config_file)

api_token = config_dict["api_token"]
pd_team_uri = config_dict["pd_team_uri"]
schedules = config_dict["schedules"]
new_schedule = []

headers = {
        "Accept": "application/json",
        "Authorization": f"Token token={api_token}",
        "Content-Type": "application/json"
}

#
# Work through the schedule entries in the configuration file, identify the matching teams, and retrieve a list of user objects
# for schedule population.
#
for schedule_entry in schedules:
    pd_team_id = "" 
    target_team = schedule_entry["team"]
    schedule = schedule_entry["schedule"]

    # Retrieve the teams from the PagerDuty instance to work through and identify the target team ID
    try:
        current_team_json = requests.get(pd_team_uri, headers=headers, json={"limit": "60"}, stream=True)
        team_objects = json.loads(current_team_json.content.decode())["teams"]
    except Exception as err:
        print(err)
        exit(1)

    for team in team_objects:
        if team["name"] == target_team:
            pd_team_id = team["id"]
            break

    # If no matching team could be found, skip the schedule creation and write the existing one back for safe-keeping
    if pd_team_id == "":
        print(f"Cannot configure schedule for {target_team} as the etam does not exist.")
        new_schedule.append({"team": target_team, "schedule": schedule})
        continue

    # Setup the team endpoing to query for team members that can then be populated into the schedule
    pd_team_target_endpoint = f"{pd_team_uri}/{pd_team_id}/members"

    try:
        team_member_json = requests.get(pd_team_target_endpoint, headers=headers, json={"limit": "60"}, stream=True)
        team_member_objects = deque(json.loads(team_member_json.content.decode())["members"])
    except Exception as err:
        print(err)
        exit(2)

    layer_counter = 0

    #
    # Create the new roster, cycling through the team by making a new member the primary responsible person each day.
    # this could definitely be made more complex as-needed, perhaps by adding an extra key to the schedule hiera, specifying
    # the rotationa approach.
    #

    for layer in schedule["schedule_layers"]:
        schedule["schedule_layers"][layer_counter]["users"] = [user_element["user"] for user_element in list(team_member_objects)]
        team_member_objects.rotate(-1)
        layer_counter += 1

    new_schedule.append({"team": target_team, "schedule": schedule})

#
# Overwrite the existing schedule with the new ones and write them to a local yaml file
#
config_dict["schedules"] = new_schedule

with open("new_pd_config.yaml", "w+") as fh:
    fh.write(yaml.dump(config_dict, Dumper=NoAliasDumper))
    print("")

team_list = []
