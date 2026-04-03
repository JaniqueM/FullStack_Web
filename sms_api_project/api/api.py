"""
Start the server:   python api.py
Stop the server:    Press Ctrl + C
"""

import json
import base64
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

# Configuration
PORT = 8000                  # Setting the server to run on http://localhost:8000
TRANSACTIONS_FILE = "transactions.json"  # The file created by parse_sms.py

# Valid username and password (Basic Auth)
VALID_USERNAME = "admin"
VALID_PASSWORD = "password123"

# Loading transactions from the JSON file
def load_transactions():
    try:
        with open(TRANSACTIONS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"ERROR: '{TRANSACTIONS_FILE}' not found. Run parse_sms.py first!")
        return []

"""Saving the current list of transactions back to transactions.json."""
def save_transactions(transactions):
    with open(TRANSACTIONS_FILE, "w", encoding="utf-8") as f:
        json.dump(transactions, f, indent=2, ensure_ascii=False)

# Load data once when the server starts
transactions = load_transactions()
print(f"✅ Loaded {len(transactions)} transactions from '{TRANSACTIONS_FILE}'")

# Checking if the request has valid credentials
def is_authorized(handler):
    """
    This code reads the Authorization header from the request.
    Returns True if the username and password are correct.
    Returns False if they are missing or wrong.
    """
    auth_header = handler.headers.get("Authorization", "")

    # The header looks like: "Basic YWRtaW46cGFzc3dvcmQxMjM="
    if not auth_header.startswith("Basic "):
        return False

    # Decode the base64 part to get "username:password"
    try:
        encoded = auth_header.split(" ")[1]
        decoded = base64.b64decode(encoded).decode("utf-8")
        username, password = decoded.split(":", 1)
        return username == VALID_USERNAME and password == VALID_PASSWORD
    except Exception:
        return False

# Sending JSON responses
def send_json(handler, status_code, data):
    """Sending a JSON response with the given status code and data."""
    body = json.dumps(data, indent=2, ensure_ascii=False).encode("utf-8")
    handler.send_response(status_code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)

# The Main Request Handler
class APIHandler(BaseHTTPRequestHandler):
    # This silence the default request logs to print our own
    def log_message(self, format, *args):
        pass

    # Checking auth on every request
    def check_auth(self):
        """Returns True if authorized, sends 401 and returns False if not."""
        if not is_authorized(self):
            print(f" 401 Unauthorized request to {self.path}")
            send_json(self, 401, {
                "error": "Unauthorized",
                "message": "Valid username and password required."
            })
            return False
        return True

    # GET requests
    def do_GET(self):
        if not self.check_auth():
            return
        parsed = urlparse(self.path)
        path_parts = parsed.path.strip("/").split("/")

        # GET /transactions  -  returning all transactions
        if path_parts == ["transactions"]:
            print(f" GET /transactions → returning {len(transactions)} records")
            send_json(self, 200, transactions)

        # GET /transactions/{id}  - returning one transaction
        elif len(path_parts) == 2 and path_parts[0] == "transactions":
            try:
                record_id = int(path_parts[1])
                # Search for the record with that ID
                record = next((t for t in transactions if t["id"] == record_id), None)

                if record:
                    print(f" GET /transactions/{record_id} → found")
                    send_json(self, 200, record)
                else:
                    print(f" GET /transactions/{record_id} → not found")
                    send_json(self, 404, {"error": f"Transaction with id {record_id} not found."})
            except ValueError:
                send_json(self, 400, {"error": "ID must be a number."})
        else:
            send_json(self, 404, {"error": "Route not found."})

    # POST requests
    def do_POST(self):
        if not self.check_auth():
            return
        parsed = urlparse(self.path)
        path_parts = parsed.path.strip("/").split("/")

        # POST /transactions  -  adding a new transaction
        if path_parts == ["transactions"]:
            try:
                # Read the request body
                length = int(self.headers.get("Content-Length", 0))
                body = self.rfile.read(length)
                new_data = json.loads(body)

                # Give it a new unique ID (max existing ID + 1)
                new_id = max((t["id"] for t in transactions), default=0) + 1
                new_data["id"] = new_id
                transactions.append(new_data)
                save_transactions(transactions)
                print(f" POST /transactions → created record id={new_id}")
                send_json(self, 201, {"message": "Transaction created.", "transaction": new_data})

            except json.JSONDecodeError:
                send_json(self, 400, {"error": "Invalid JSON in request body."})

        else:
            send_json(self, 404, {"error": "Route not found."})

    # PUT requests
    def do_PUT(self):
        if not self.check_auth():
            return
        parsed = urlparse(self.path)
        path_parts = parsed.path.strip("/").split("/")

        # PUT /transactions/{id}  -  updating an existing transaction
        if len(path_parts) == 2 and path_parts[0] == "transactions":
            try:
                record_id = int(path_parts[1])

                # Find the record index
                index = next((i for i, t in enumerate(transactions) if t["id"] == record_id), None)

                if index is None:
                    send_json(self, 404, {"error": f"Transaction with id {record_id} not found."})
                    return

                # Read the new data from the request body
                length = int(self.headers.get("Content-Length", 0))
                body = self.rfile.read(length)
                updated_data = json.loads(body)

                # Keep the original ID, update everything else
                updated_data["id"] = record_id
                transactions[index] = updated_data
                save_transactions(transactions)

                print(f" PUT /transactions/{record_id} → updated")
                send_json(self, 200, {"message": "Transaction updated.", "transaction": updated_data})

            except ValueError:
                send_json(self, 400, {"error": "ID must be a number."})
            except json.JSONDecodeError:
                send_json(self, 400, {"error": "Invalid JSON in request body."})

        else:
            send_json(self, 404, {"error": "Route not found."})

    # DELETE requests
    def do_DELETE(self):
        if not self.check_auth():
            return

        parsed = urlparse(self.path)
        path_parts = parsed.path.strip("/").split("/")

        # DELETE /transactions/{id}  -  deleting a transaction
        if len(path_parts) == 2 and path_parts[0] == "transactions":
            try:
                record_id = int(path_parts[1])

                # Find the record
                record = next((t for t in transactions if t["id"] == record_id), None)

                if record is None:
                    send_json(self, 404, {"error": f"Transaction with id {record_id} not found."})
                    return

                transactions.remove(record)
                save_transactions(transactions)

                print(f" DELETE /transactions/{record_id} → deleted")
                send_json(self, 200, {"message": f"Transaction {record_id} deleted successfully."})

            except ValueError:
                send_json(self, 400, {"error": "ID must be a number."})

        else:
            send_json(self, 404, {"error": "Route not found."})


# Start the server
if __name__ == "__main__":
    server = HTTPServer(("localhost", PORT), APIHandler)
    print(f"\n API server running at http://localhost:{PORT}")
    print(f"   Username : {VALID_USERNAME}")
    print(f"   Password : {VALID_PASSWORD}")
    print(f"\n   Endpoints available:")
    print(f"   GET    http://localhost:{PORT}/transactions")
    print(f"   GET    http://localhost:{PORT}/transactions/1")
    print(f"   POST   http://localhost:{PORT}/transactions")
    print(f"   PUT    http://localhost:{PORT}/transactions/1")
    print(f"   DELETE http://localhost:{PORT}/transactions/1")
    print(f"\n   Press Ctrl+C to stop.\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n Server stopped.")
