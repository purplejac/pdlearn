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
    qlo_api_key = "<API KEY>"
    encoded_qlo_key = base64.b64encode(f"{qlo_api_key}:".encode("utf-8")).decode("utf-8")
    pd_routing_key = "R028C3ZH6G61XLX5GRHBE9KYX1FV1JVE"

    #
    # Setting up Qlo endpoint and Pagerduty alerting endpoint
    # then building headers to match for each endpoing.
    #
    api_server = "http://pd-web-01.hald.id.au"
    api_endpoint = f"{api_server}/api"
    pd_endpoint = "https://events.pagerduty.com/v2/enqueue"

    qlo_error = {}

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
            response = requests.get(f"http://{api_endpoint}/hotels/{id}?output_format=JSON", headers=qlo_headers, timeout=5)
            allocated_room_types = json.loads(response.content)["hotel"]["associations"]["room_types"]


            # If the number of rooms does not match what was expected, raise an alert.
            # Opting 'only' for Warning level, as the hotel will still be able to do business, it is simply that the OBS 
            # won't appropriately reflect the number of room types available, which should be resolved.
            
            if len(allocated_room_types) != room_count:
                qlo_error = {
                    "message": f"Room count for {hotel_name} has changed from the expected target of {room_count}. Current count: {len(allocated_room_types)}",
                    "dedup_key": f"{hotel_name}-room_count",
                    "severity": "warning",
                    "priority": "P2",
                    "group": "OBS Content",
                    "component": "QloApps-Web",
                    "location": hotel_name,
                }
                
        except requests.exceptions.Timeout:
            qlo_error = {
                "message": "OBS API Query timed out",
                "dedup_key": "OBSAPI-QueryError",
                "severity": "error",
                "priority": "P3",
                "group": "OBS API",
                "component": "PGAM100",
                "location": "Online",
            }
        except requests.exceptions.RequestException as err:
            qlo_error = {
                "message": f"An error occurred when querying OBS: {err}",
                "dedup_key": "OBSAPI-QueryError",
                "severity": "error",
                "priority": "P3",
                "group": "OBS API",
                "component": "PGAM100",
                "location": "Online",
            }

        #
        # If qlo_error has been populated, an error has occurred somewhere and an alert should be logged.
        #
        if len(qlo_error) > 0:
            alert_payload = { 
                "routing_key": pd_routing_key,
                "event_action": "trigger",
                "dedup_key": qlo_error["dedup_key"],
                "payload": {
                    "summary": qlo_error["message"],
                    "source": api_server,
                    "severity": qlo_error["severity"],
                    "component": qlo_error["component"],
                    "group": qlo_error["group"],
                    "custom_details": {"Priority": qlo_error["priority"], "Location": qlo_error["location"]},
                }
            }

            try:
                response = requests.post(pd_endpoint, headers=pd_headers, data=json.dumps(alert_payload))
            except Exception as err:
                return {
                    "statusCode": 500,
                    "body": json.dumps(err)
                }
            
    return {
        "statusCode": 200,
        "body": "Run Complete"
    }
        
