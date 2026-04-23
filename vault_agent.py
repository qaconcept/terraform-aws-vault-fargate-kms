import hvac
import os
import sys

# 1. Configuration from Environment
# This is the SRE standard for avoiding credential leakage.
VAULT_URL = os.getenv('VAULT_ADDR', 'https://vault.sreconcepts.com')
ROLE_ID = os.getenv('VAULT_ROLE_ID')
SECRET_ID = os.getenv('VAULT_SECRET_ID')

def run_vault_agent():
    # Safety Check: Exit early if the shell isn't configured
    if not ROLE_ID or not SECRET_ID:
        print("❌ Error: VAULT_ROLE_ID or VAULT_SECRET_ID not found in environment.")
        sys.exit(1)

    # Initialize client with a 10s timeout for the cross-Atlantic connection
    client = hvac.Client(url=VAULT_URL, timeout=10)

    try:
        print(f"Connecting to {VAULT_URL}...")
        
        # 2. Authenticate
        client.auth.approle.login(role_id=ROLE_ID, secret_id=SECRET_ID)
        print("✅ Authentication Successful.")

        # 3. Read the Secret
        # Explicitly setting raise_on_deleted_version silences the hvac v3.0.0 warning
        read_response = client.secrets.kv.v2.read_secret_version(
            mount_point='secret',
            path='qa-squad/config',
            raise_on_deleted_version=True
        )

        # 4. Extract data
        secret_data = read_response['data']['data']
        print("\n--- Secret Retrieved ---")
        for key, value in secret_data.items():
            print(f"{key}: {value}")

    except hvac.exceptions.InvalidRequest:
        print("❌ Error: Invalid credentials or expired SecretID.")
    except hvac.exceptions.Forbidden:
        print("❌ Error: Permission denied. Check your 'read-access-to-specific-paths' policy.")
    except Exception as e:
        print(f"⚠️ Unexpected Error: {e}")

if __name__ == "__main__":
    run_vault_agent()