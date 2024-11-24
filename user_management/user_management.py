#!/usr/bin/env python3
#
# User manager adds a set of users and teams to the pagerduty interface 
#
# In the current iteration it auto-generates a set of 50 users, and 11 teams, with
# a set of default values and a spread of business and technology functions, to facilitate
# the setup requirements of the tasking.
#
# While input features could be added, based on a pre-defined 

import getopt, json, requests, sys, yaml

config_file = "../pd_config.yaml"
user_objects = []

#
# add_teams function
# 
# Takes a list of teams as a List[List], each entry formatted as [<team name>, <description>]
# and returns a dictionary of teams mapping team name to the team ID in pagerduty.
#
def add_teams(team_list):
    current_team_objects = requests.get(pd_team_uri, headers=headers, json={"limit": "60"})
    team_objects = json.loads(current_team_objects.content.decode())['teams']
    team_map = {}

    for local_team_set in team_list:
        team_name = local_team_set[0]

        if any(obj["name"] == team_name for obj in team_objects):
            print(f"Team name {team_name} already exists, skipping")
            team_map[team_name] = next((remote_object["id"] for remote_object in team_objects if remote_object["name"] == team_name), "No ID")
        else:
            new_team_object = {"type": "team", "name": team_name, "description": local_team_set[1]}
            print(f"Creating team: {team_name}")
            try:
                response = requests.post(pd_team_uri, headers=headers, json=new_team_object)
            except Exception as err:
                print(f"An error was encountered when trying to add a team. Team: {team_name}, Error: {err}")

            if response:
                if response.status_code == 201:
                    team_map['team_name'] = json.loads(response.text)["team"]["id"]
                else:
                    print(f"Something went wrong: {response.text}")

    return(team_map)

#
# add_users function
#
# Takes a list of user objects (user_info) as the first parameter and a team map (team_map) as the second. 
# Creates the users in pagerduty and adds them to their respective teams.
# No return value
#
# user_info is a list of user objects (List[Dict]), prepared to be fed directly to the pagerduty API.
# Could be improved so add_users formats it itself, but for now the object needs to be constructed like so:
# (YAML Representation)
#
# users:
#  - type: user
#    name: <full name>
#    email: <email_address>
#    time_zone: <TZ>
#    role: <PD User Role>
#    job_title: <user job title>
#    description: <User Description> # Defaulted to location in the generated user set
#    user_teams:
#      - <team to join>
#
# team_map is a List[List] as returned from the add_teams function, mapping human readable names to team IDs in pagerduty
#
def add_users(user_info, team_map):
    pd_user_url = "https://api.pagerduty.com/users"

    current_user_objects = requests.get(pd_user_url, headers=headers, json={"limit": "60"})
    user_objects = json.loads(current_user_objects.content.decode())['users']

    for (local_user_object, user_teams) in user_info:
        user = local_user_object['name']
        if any(obj['name'] == user for obj in user_objects):
            print(f"Cannot create account for {user} as an account already exists under that name.")
        else:
            print(f"Creating account for {user}")
            try:
                response = requests.post(pd_user_url, headers=headers, json=local_user_object)
            except Exception as err:
                print(f"An error was encountered when creating the user {user}, Error: {err}")

            if response:
                if response.status_code == 201:
                    uid = json.loads(response.text)["user"]["id"]

                    for team in user_teams:
                        team_id = team_map[team]
                        try:
                            team_update_response = requests.put(f"{pd_team_uri}/{team_id}/users/{uid}", headers=headers)
                        except Exception as err:
                            print(err)
                            print(f"Could not add user {user} to team {team}")

                        if team_update_response and team_update_response.status_code != 204:
                            print(team_update_response)
                else:
                    print(f"Something went wrong when adding user {user}: {response.text}")

#
# generate_user function
#
# Generates 50 users, across a spread of technical and business functions to use in the Pagerduty demo.
# Takes no parameters but returns a list of user objects, as consumed by the add_users function.
#
def generate_users():
    for user_number in range(1,51):
        user_name = f"User {user_number}"
        user_email = f"{user_name.lower().replace(" ",".")}@test.test"
        user_role = "limited_user"
        user_time_zone = "Australia/Sydney"
        user_location = "Head Office, Sydney"
        user_teams = ["business_admin"]

        if user_number == 1:
            user_job_title = "CEO"
        elif user_number == 2:
            user_job_title = "CIO"
            user_role = "admin"
            user_teams = ["central_tech", "business_admin"]
        elif user_number < 5:
            user_job_title = "IT Management"
            user_role = "admin"
            user_teams = ["central_tech", "business_admin"]
        elif user_number < 7:
            user_job_title = "Business Management"
        elif user_number < 12:
            user_job_title = "OPS Engineer"
            user_role = "limited_user"
            user_teams = ["central_tech"]
        elif user_number < 14:
            user_job_title = "Developer"
            user_role = "limited_user"
            user_teams = ["central_tech"]
        elif user_number < 15:
            user_job_title = "Support Center Manager"
            user_role = "admin"
            user_teams = ["business_admin", "support_center"]
        elif user_number < 25:
            user_job_title = "Service Desk Staff"
            user_location = "Hotel Support Center"
            user_role = "limited_user"
            user_teams = ["support_center"]
        elif user_number < 29:
            user_job_title = "Hotel Tech-Ops Supporter"
            user_teams = ["hotel_tech_ops"]
        elif user_number < 32:
            user_job_title = "Corporate Facilities Engineer"
            user_teams = ["tech_hotel_facility_eng"]
        elif user_number < 35:
            user_job_title = "Incident Manager"
            user_teams = ["incident_management", "central_tech"]
        else:
            user_time_zone = "Australia/Melbourne"
            user_location = "Hotel: Melbourne, Australia"
            user_teams = ["melbourne", "all_hotels"]

            if user_number == 35:
                user_job_title = "Hotel General Manager"
            elif user_number < 46:
                user_job_title = "Guest Relations"
            elif user_number < 49:
                user_job_title = "Housekeeping"
            else:
                user_job_title = "Facilities Engineering"
                user_teams = ["melbourne", "all_hotels"]

        user_objects.append([{"type": "user", "name": user_name, "email": user_email, "time_zone": user_time_zone, "role": user_role, "job_title": user_job_title, "description": user_location}, user_teams])  #, "teams": user_teams})
    return(user_objects)

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
# Core functionality driving the script.
#

gen_teams = gen_users = True

# If no parameters are provided, use defaults
if len(sys.argv) > 1:

    # Parameters have been provided. Read them and action them.
    short_options = "hutc:"
    long_options = ["help","load-users", "load-teams", "config="]

    arguments = sys.argv[1:]

    try:
        arguments, values = getopt.getopt(arguments, short_options, long_options)

        for argument, value in arguments:
            if argument in ["-h", "--help"]:
                print("""Help:
The following options are available for this script:
-h, --help
  Display this help text
-u, --load-users
  Load user list from config file
-t, --load-teams
  Load team list from config file
-c, --config <file_name>
  Point to script yaml-format config file (defaults to pd_config.yaml)

example:
  {sys.argv[0]} -u -t -c config_file.yaml
  """)
                exit(0)
            elif argument in ["-u", "--load-users"]:
                gen_users = False
            elif argument in ["t", "--load-teams"]:
                gen_teams = False
            elif argument in ["c", "--config"]:
                config_file = value
    except getopt.error as err:
        print(str(err))
        exit(1)

config_dict = read_config(config_file)

api_token = config_dict['api_token']
pd_id_uri = config_dict['pd_id_uri'] if 'pd_id_uri' in config_dict else 'https://identity.pagerduty.com/oauth'
pd_team_uri = config_dict['pd_team_uri'] if 'pd_team_uri' in config_dict else 'https://api.pagerduty.com/teams'

pd_auth_endpoint = f"{pd_id_uri}/authorize"
pd_token_endpoint = f"{pd_id_uri}/token"

headers = {
        "Accept": "application/json",
        "Authorization": f"Token token={api_token}",
        "Content-Type": "application/json"
}

#
# If team 'generation' is required, add the default set of teams
#
if gen_teams:
    teams = [
        ["central_tech", "Central Technology Engineering & Ops team"],
        ["support_center", "Hotel Support Center - Service Desk"],
        ["hotel_tech_ops", "Hotel Technology Operations Team"],
        ["tech_hotel_facility_eng", "Hotel Facility Engineering"],
        ["business_admin", "General Business and Admin Teams"],
        ["incident_management", "Incident Management Team"],
        ["guest_experience", "Corporate Guest Experience Team"],
        ["all_hotels", "All Hotel Staff"],
        ["melbourne", "Melbourne Staff"],
        ["tokyo", "Tokyo Staff"],
        ["atlanta", "Atlanta Staff"],
        ["london", "London Staff"],
        ["auckland", "Auckland Staff"]
    ]
else:
    teams = config_dict['teams']

team_map = add_teams(teams)

#
# If generic user account generation is required, call generate_users to do so
#
if gen_users:
    user_objects = generate_users()
else:
    user_objects = config_dict['users']

add_users(user_objects, team_map)

