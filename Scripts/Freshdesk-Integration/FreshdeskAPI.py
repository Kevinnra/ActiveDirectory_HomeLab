import requests


# Configuration
api_key = "1ch6IxCLxXG5st7Mtps" # 🔴 Replace with environment variable in production!
domain = "uberkevinnra.freshdesk.com"
url = f"https://{domain}/api/v2/tickets"

# Required fields for ticket
ticket_data = {
    "subject": "New password request - Automated Ticket ",
    "description": "User forgot password need to get a new one",
    "priority": 1, # 1= Critical, 2= High, etc. (required)
    "status": 2,  # 2= Open, 3= pending, etc.  (required)
    "tags": ["automation"],
    "requester_id": 156012020510,  # Replace with valid requester ID from your Freshdesk
    "custom_fields": {
        "cf_department": "HR",
        "cf_employee_id":"55" # Your custom fields name may vary
    }
}

#  Create a mock ticket / API call
response = requests.post(url,
    auth=(api_key, "X"), # 'X' is a placeholder for blank password
    json=ticket_data,
    headers={"Content-Type": "application/json"}
)

# Handle response and Verify success
if response.status_code == 201:
    print(f"✅ Ticket created! ID: {response.json()['id']}")
else:
    print(f"❌ Error {response.status_code}: {response.text}")
