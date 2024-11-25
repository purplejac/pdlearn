#!/usr/bin/env python
#
# Booking system monitoring script
#
# Queries the booking system for the number of room types available in a Hotel,
# compares against an expected count and alerts in the case of mismatch.
# The QloApps API does not have an endpoint to query the actual number of rooms,
# so for demonstration purposes I have instead opted for the number of room types 
# in a hotel.
#
# The feature itself targets primarily the business use of the system, to 
# alert on unplanned and unexpected changes impacting a hotel.
#
import base64, json, requests
from datetime import datetime
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

def lambda_handler(event, context):
    #
    # Open text API keys are not ideal, but functional for the purpose of this demo
    #
    qlo_api_key = <QLO_API_KEY>
    encoded_qlo_key = base64.b64encode(f"{qlo_api_key}:".encode("utf-8")).decode("utf-8")
    pd_routing_key = <PAGERDUTY_ROUTING_KEY>
    pd_api_token = <PAGERDUTY API TOKEN>

    #
    # Setting up Qlo endpoint and Pagerduty alerting endpoint
    # then building headers to match for each endpoing.
    #
    api_server = "http://pd-web-01.hald.id.au"
    api_endpoint = f"{api_server}/api"
    pd_event_server = "https://events.pagerduty.com"
    pd_event_endpoint = f"{pd_event_server}/v2/enqueue"

    #
    # Set up PD Incident query endpoint
    #
    pd_api_server = "https://api.pagerduty.com"
    pd_incident_endpoint = f"{pd_api_server}/incidents"
    pd_incident_q_endpoint = f"{pd_incident_endpoint}?statuses[]=triggered&statuses[]=acknowledged"

    qlo_notices = []
    connect_ok = True


    timestamp = datetime.now().astimezone().isoformat()

    #
    # Setup max retries for for GET/HEAD/OPTIONS through request, in case of time-out or non-availability
    #
    retry_strategy = Retry(
            total = 3, 
            backoff_factor = 1,
            status_forcelist = [500, 502, 503, 504],
    )

    adapter = HTTPAdapter(max_retries=retry_strategy)

    #
    # Only currently doing http requests, but may as well set for SSL for good measure
    #
    session = requests.Session()
    session.mount("http://", adapter)
    session.mount("https://", adapter)


    qlo_headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": f"Basic {encoded_qlo_key}",
    }

    pd_headers = {
        "Content-Type": "application/json",
    }

    headers = {
        "Accept": "application/json",
        "Authorization": f"Token token={pd_api_token}",
        "Content-Type": "application/json"
    }

    try:
        incident_json = requests.get(pd_incident_q_endpoint, headers=headers, json={"limit": "60"})
    except Exception as err:
        return {
            "statusCode": 500,
            "body": json.dumps("Failure in incident retrieval")
        }
    
    alert_list = {}

    #
    # Query the PagerDuty incidents endpoint to get a list of 'live' incidents
    #
    if len(incident_json.content) > 0:
        # Get OBS-related incidents
        for incident in json.loads(incident_json.content)["incidents"]:
            # If the incident is matched to the OBS Backend service, store if for checking
            if incident["service"]["id"] == 'PYVCMOF':
                pd_alert_query = f"{incident['html_url']}/alerts"
                alerts_response = requests.get(pd_alert_query, headers=headers, json={"limit": "60"})
                alerts = json.loads(alerts_response.content)

                for alert in alerts["alerts"]:
                    if "Location" in alert["body"]["details"] and "dedup_key" in alert["body"]["cef_details"]:
                        alert_item = {
                            "summary": alert["summary"],
                            "dedup_key": alert["body"]["cef_details"]["dedup_key"],
                            "severity": alert["severity"],
                            "priority": alert["body"]["details"]["Priority"],
                            "group": alert["body"]["cef_details"]["service_group"],
                            "location": alert["body"]["details"]["Location"],
                        }

                        if alert["body"]["details"]["Location"] not in alert_list:
                            alert_list[alert["body"]["details"]["Location"]] = [alert_item]
                        else:
                            alert_list[alert["body"]["details"]["Location"]].push(alert_item)

    #
    # In an ideal/full-blown solution, much like the API keys, this information would be retrieved externally,
    # for the keys, perhaps through something like Vault or AWS Secrets Manager.
    #
    # For information such as the hotel room count, some key:value-pair storage such as ETCd or Redis could be useful
    # as a query point before running the API interactions
    #

    hotels = {"ACME Atlanta": {"id": "1", "room_count": 4}, "ACME Melbourne": {"id": "2", "room_count": 4}}

    #
    # Once the hotel and API information has been built, cycle through the hotel datasets and query the APIs to match
    # against the expected data.
    #
    for hotel_name, hotel_data in hotels.items():
        id = hotel_data["id"]
        room_count = hotel_data["room_count"]

        try:
            response = requests.get(f"{api_endpoint}/hotels/{id}?output_format=JSON", headers=qlo_headers, timeout=5)
            allocated_room_types = json.loads(response.content)["hotel"]["associations"]["room_types"]

            # If the number of rooms does not match what was expected, raise an alert.
            # Opting 'only' for Warning level, as the hotel will still be able to do business, it is simply that the OBS 
            # won't appropriately reflect the number of room types available, which should be resolved.

            if len(allocated_room_types) != room_count:
                qlo_notices.append(
                    {
                        "event_action": "trigger",
                        "message": f"Room count for {hotel_name} has changed from the expected target of {room_count}. Current count: {len(allocated_room_types)}",
                        "dedup_key": f"{hotel_name}-room_count",
                        "severity": "warning",
                        "priority": "P2",
                        "group": "OBS Content",
                        "component": "QloApps-Web",
                        "location": hotel_name,
                    }
                )
            #
            # If there is a live incident against the current check, which just succeeded, setup to send a resolution alert
            #
            elif hotel_name in alert_list:
                for alert_info in alert_list[hotel_name]:
                    qlo_notices.append(
                        {
                            "event_action": "resolve",
                            "message": alert_info["summary"],
                            "dedup_key": alert_info["dedup_key"],
                            "severity": alert_info["severity"],
                            "priority": alert_info["priority"],
                            "group": alert_info["group"],
                            "component": "QloApps-Web",
                            "location": hotel_name,
                        }
                    )
                
        except requests.exceptions.Timeout:
            qlo_notices.append(
                {
                    "event_action": "trigger",
                    "message": "OBS API Query timed out",
                    "dedup_key": "OBSAPI-QueryError",
                    "severity": "error",
                    "priority": "P3",
                    "group": "OBS API",
                    "component": "QloApps-Web",
                    "location": "Online",
                }
                #
                # If we're here, the API hit failed, so connectivity issues should be raised
                #
            )
            connect_ok = False
        except requests.exceptions.RequestException as err:
            qlo_notices.append(
                {
                    "event_action": "trigger",
                    "message": f"An error occurred when querying OBS: {err}",
                    "dedup_key": "OBSAPI-QueryError",
                    "severity": "error",
                    "priority": "P3",
                    "group": "OBS API",
                    "component": "QloApps-Web",
                    "location": "Online",
                }
                #
                # If we're here, the API hit failed, so connectivity issues should be raised
                #
            )
            connect_ok = False

        #
        # If no exceptions were hit during the checking, the API is responding and not timing out,
        # so checking if there are any outstanding incidents against the actual service availability.
        #
        if "Online" in alert_list and connect_ok:
            for alert_info in alert_list["Online"]:
                qlo_notices.append(
                    {
                        "event_action": "resolve",
                        "message": alert_info["summary"],
                        "dedup_key": alert_info["dedup_key"],
                        "severity": alert_info["severity"],
                        "priority": alert_info["priority"],
                        "group": alert_info["group"],
                        "component": "QloApps-Web",
                        "location": hotel_name,
                    }
                )    

        #
        # If qlo_notices has been populated, an alert trigger or resolution should be logged.
        #
        if len(qlo_notices) > 0:
            for alert in qlo_notices:
                alert_payload = { 
                    "routing_key": pd_routing_key,
                    "event_action": alert["event_action"],
                    "dedup_key": alert["dedup_key"],
                    "payload": {
                        "summary": alert["message"],
                        "source": api_server,
                        "severity": alert["severity"],
                        "component": alert["component"],
                        "group": alert["group"],
                        "custom_details": {"Priority": alert["priority"], "Location": alert["location"]},
                    }
                }

                try:
                    response = requests.post(pd_event_endpoint, headers=pd_headers, data=json.dumps(alert_payload))
                except Exception as err:
                    return {
                        "statusCode": 500,
                        "body": json.dumps("Failure in PagerDuty ticket submission")
                    }
            
    return {
        "statusCode": 200,
        "body": "Run Complete"
    }
        
