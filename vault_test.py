import hvac
import os

# Initialize the client pointing to your ALB in us-east-1
# Using a 10s timeout to account for trans-Atlantic latency from Albania
client = hvac.Client(
    url='https://vault.sreconcepts.com',
    timeout=10
)

# Your confirmed credentials
ROLE_ID = '408b7951-3de5-a52e-63e0-a3784c3842f2'
SECRET_ID = '297768bd-b56a-130a-6d05-8f4efd8254da'

try:
    # 1. Authenticate via AppRole
    client.auth.approle.login(role_id=ROLE_ID, secret_id=SECRET_ID)
    print("✅ Authenticated successfully.")

    # 2. Read the secret
    # Note: hvac handles the 'data/' path segment automatically for KV V2
    response = client.secrets.kv.v2.read_secret_version(
        mount_point='secret',
        path='qa-squad/config'
    )

    # 3. Print the results
    actual_secrets = response['data']['data']
    print(f"🔓 Secret Found: {actual_secrets}")

except hvac.exceptions.InvalidRequest:
    print("❌ Auth Failed: Check if the SecretID has expired (TTL).")
except hvac.exceptions.Forbidden:
    print("❌ Permission Denied: Token lacks 'read' on this path.")
except Exception as e:
    print(f"⚠️ Error: {e}")