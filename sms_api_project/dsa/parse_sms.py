"""
Parsing the XML file and convert SMS records into JSON (list of dictionaries)
"""

import xml.etree.ElementTree as ET  # Built-in Python library for reading XML
import json                          # Built-in Python library for JSON


def parse_sms_xml(filepath):
    """
    Reading the XML file and returns a list of transaction dictionaries.
    Each SMS record becomes one dictionary in the list.
    """

    # Loading and reading the XML file
    tree = ET.parse(filepath)
    root = tree.getroot()  # This is the <smses> tag at the top

    transactions = []  # We are collecting all records here

    # Looping through every <sms> tag inside the file
    for index, sms in enumerate(root.findall("sms")):

        # Each SMS has attributes like: address, date, body, readable_date, etc.
        # We are extracting the ones that are useful for us
        transaction = {
            "id": index + 1,                              # Give each record a unique ID starting at 1
            "address": sms.get("address", ""),            # Who sent it (e.g. "M-Money")
            "date": sms.get("date", ""),                  # Timestamp in milliseconds
            "readable_date": sms.get("readable_date", ""), # Human-readable date
            "body": sms.get("body", ""),                  # The full SMS message text
            "type": sms.get("type", ""),                  # 1 = received, 2 = sent
            "read": sms.get("read", ""),                  # Was it read? 1 = yes
            "service_center": sms.get("service_center", ""), # Telephone service center number
        }

        transactions.append(transaction)

    return transactions


# Running it 
if __name__ == "__main__":

    XML_FILE = r"C:\Users\User\Downloads\modified_sms_v2.xml"  # Path to your XML file

    print(" Parsing XML file...")
    transactions = parse_sms_xml(XML_FILE)

    print(f" Done! Found {len(transactions)} SMS records.\n")

    # Show the first 3 records so you can see what they look like
    print("── First 3 records ──────────────────────────────────────────")
    for record in transactions[:3]:
        print(json.dumps(record, indent=2))
        print()

    # Saving ALL records to a JSON file
    output_file = "transactions.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(transactions, f, indent=2, ensure_ascii=False)

    print(f" All {len(transactions)} records saved to '{output_file}'")
