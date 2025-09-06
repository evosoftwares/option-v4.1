import asyncio
from supabase import create_client, Client
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

async def get_tables():
    # Get all tables from the database
    try:
        # This is a simplified approach to get table names
        # In a real scenario, you might need to query the information_schema
        result = supabase.table('app_users').select("*").limit(1).execute()
        print("Successfully connected to Supabase")
        return True
    except Exception as e:
        print(f"Error connecting to Supabase: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(get_tables())