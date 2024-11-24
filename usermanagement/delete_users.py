#!/usr/bin/env python
#
# Added as an add-on feature. Beware, though. The deletion is non-discriminatory.
# No feature checks are performed, users are deleted with prejudice, so the function
# is quite destructive.
#
import requests
import json

api_token = '<PD_API_TOKEN>"
headers = {
        "Accept": "application/json",
        "Authorization": f"Token token={api_token}",
        "Content-Type": "application/json"
}

user_list = [f"User {user_number}" for user_number in range(1,51)]

pd_user_url = "https://api.pagerduty.com/users"

current_user_objects = requests.get(pd_user_url, headers=headers, json={"limit": "60"}, stream=True)
user_objects = json.loads(current_user_objects.content.decode())['users']

for user_name in user_list:
    for user_object in user_objects:
        if  user_name == user_object["name"]:
            uid = user_object["id"]
            requests.delete(f"{pd_user_url}/{uid}", headers=headers)
