import requests
from dotenv import load_dotenv
import os
import json
import sys

def auth(TENANT_ID,CLIENT_ID,CLIENT_SECRET):
    # Token endpoint
    token_url = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"

    # Request body
    token_data = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope": "https://graph.microsoft.com/.default"
    }

    # Request token
    response = requests.post(token_url, data=token_data)
    if response.status_code != 200:
        print("Error: #10001 | Failed to get access token. Server response code: {}".format(response.status_code))
        sys.exit(10001)

    access_token = response.json().get("access_token")
    if access_token:
        print("Success: Access Token acquired successfully.")
        return access_token

def get_exclusion_list(access_token,SHAREPOINT_DOMAIN,SHAREPOINT_SITE,SHAREPOINT_LIST):
    # Replace with your actual site and list info
    site_url = "https://graph.microsoft.com/v1.0/sites/{}.sharepoint.com:/sites/{}".format(SHAREPOINT_DOMAIN,SHAREPOINT_SITE)
    list_name = SHAREPOINT_LIST

    # Get site ID
    site_response = requests.get(
        site_url,
        headers={"Authorization": f"Bearer {access_token}"}
    )
    site_response.raise_for_status()
    site_id = site_response.json()["id"]

    # Get list items
    list_url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/lists/{list_name}/items?expand=fields"
    list_response = requests.get(
        list_url,
        headers={"Authorization": f"Bearer {access_token}"}
    )
    list_response.raise_for_status()

    users = list_response.json()["value"]

    exclusion_list = []

    for user in users:
        fields = user.get("fields", {})
        country = fields.get("Provide_x0020_country_x0020_to_x")
        email = fields.get("Email_x0020_address_x0020_for_x0")
        exclusion_expires = fields.get("Expires_x0020_date")

        exclusion_list.append({
            "email": email,
            "country": country,
            "expires": exclusion_expires
        })

    return exclusion_list

def should_alert(email_address,user_object_id, country, exclusion_list):
    # Some logs do not include the user email address
    print(email_address)

def read_wazuh_input():
    try:
        input_data = sys.stdin.read()
        event = json.loads(input_data)
        return event
    except Exception as e:
        print(f"Error reading input: {e}")
        sys.exit(10002)
  

if __name__ == "__main__":
    event = read_wazuh_input()
    with open("/home/paul/event.json","w") as file:
        file.write(event)
        file.close()
    exit()
    load_dotenv()

    TENANT_ID = os.getenv("TENANT_ID")
    CLIENT_ID = os.getenv("CLIENT_ID")
    CLIENT_SECRET = os.getenv("CLIENT_SECRET")

    SHAREPOINT_DOMAIN = os.getenv("SHAREPOINT_DOMAIN")
    SHAREPOINT_SITE = os.getenv("SHAREPOINT_SITE")
    SHAREPOINT_LIST = os.getenv("SHAREPOINT_LIST")

    access_token = auth(TENANT_ID,CLIENT_ID,CLIENT_SECRET)
    exclusion_list = get_exclusion_list(access_token,SHAREPOINT_DOMAIN,SHAREPOINT_SITE,SHAREPOINT_LIST)
    