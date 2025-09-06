#!/usr/bin/env python3
"""
Script to check if a driver exists in the database
"""

import psycopg2
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection parameters
DB_HOST = "aws-0-us-east-1.pooler.supabase.com"
DB_PORT = 5432
DB_NAME = "postgres"
DB_USER = "postgres"
DB_PASSWORD = "R5E2WhmsfZDfLY3P"  # This should be loaded from environment variables

# Driver ID from the error
DRIVER_ID = "6e77285d-6b80-4670-8379-9c00e65ea739"

def check_driver_exists():
    """Check if the driver exists in the database"""
    try:
        # Connect to database
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        cursor = conn.cursor()
        
        # Check if driver exists
        cursor.execute("SELECT id, user_id FROM drivers WHERE id = %s", (DRIVER_ID,))
        driver = cursor.fetchone()
        
        if driver:
            print(f"✅ Driver found: id={driver[0]}, user_id={driver[1]}")
            return True
        else:
            print("❌ Driver not found in drivers table")
            
            # Check if user exists
            cursor.execute("SELECT id FROM auth.users WHERE id = %s", (DRIVER_ID,))
            user = cursor.fetchone()
            
            if user:
                print(f"✅ User exists in auth.users: id={user[0]}")
            else:
                print("❌ User not found in auth.users table")
                
        return False
        
    except Exception as e:
        print(f"❌ Error connecting to database: {e}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    print("🔍 Checking if driver exists in database...")
    print(f"Driver ID: {DRIVER_ID}")
    check_driver_exists()