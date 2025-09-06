import requests
import json

# Supabase configuration
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

# Headers for API requests
headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json"
}

def get_tables():
    """Get all tables from the database"""
    try:
        # Get tables from information_schema
        query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/sql",
            headers=headers,
            json={"query": query}
        )
        
        if response.status_code == 200:
            tables = [item['table_name'] for item in response.json()]
            return tables
        else:
            print(f"Error getting tables: {response.status_code} - {response.text}")
            return []
    except Exception as e:
        print(f"Exception getting tables: {str(e)}")
        return []

def get_table_columns(table_name):
    """Get columns for a specific table"""
    try:
        query = f"""
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = '{table_name}'
        ORDER BY ordinal_position
        """
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/sql",
            headers=headers,
            json={"query": query}
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error getting columns for {table_name}: {response.status_code} - {response.text}")
            return []
    except Exception as e:
        print(f"Exception getting columns for {table_name}: {str(e)}")
        return []

def get_views():
    """Get all views from the database"""
    try:
        query = "SELECT table_name FROM information_schema.views WHERE table_schema = 'public'"
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/sql",
            headers=headers,
            json={"query": query}
        )
        
        if response.status_code == 200:
            views = [item['table_name'] for item in response.json()]
            return views
        else:
            print(f"Error getting views: {response.status_code} - {response.text}")
            return []
    except Exception as e:
        print(f"Exception getting views: {str(e)}")
        return []

def get_functions():
    """Get all functions from the database"""
    try:
        query = """
        SELECT proname 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND proname NOT LIKE 'pg_%'
        AND proname NOT LIKE 'information_schema%'
        ORDER BY proname
        """
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/sql",
            headers=headers,
            json={"query": query}
        )
        
        if response.status_code == 200:
            functions = [item['proname'] for item in response.json()]
            return functions
        else:
            print(f"Error getting functions: {response.status_code} - {response.text}")
            return []
    except Exception as e:
        print(f"Exception getting functions: {str(e)}")
        return []

def main():
    """Main function to extract schema information"""
    print("Extracting Supabase schema information...")
    
    # Get tables
    print("Getting tables...")
    tables = get_tables()
    print(f"Found {len(tables)} tables")
    
    # Get table details
    schema_data = {
        "tables": {},
        "views": {},
        "functions": []
    }
    
    for table in tables:
        print(f"Getting columns for table: {table}")
        columns = get_table_columns(table)
        schema_data["tables"][table] = columns
    
    # Get views
    print("Getting views...")
    views = get_views()
    print(f"Found {len(views)} views")
    
    for view in views:
        print(f"Getting columns for view: {view}")
        columns = get_table_columns(view)
        schema_data["views"][view] = columns
    
    # Get functions
    print("Getting functions...")
    functions = get_functions()
    schema_data["functions"] = functions
    print(f"Found {len(functions)} functions")
    
    # Save to file
    with open("current_supabase_schema.json", "w") as f:
        json.dump(schema_data, f, indent=2)
    
    print("Schema information saved to current_supabase_schema.json")
    
    # Also save as markdown
    with open("current_supabase_schema.md", "w") as f:
        f.write("# Current Supabase Schema\n\n")
        f.write("## Tables\n\n")
        
        for table_name, columns in schema_data["tables"].items():
            f.write(f"### {table_name}\n")
            for col in columns:
                nullable = "nullable" if col["is_nullable"] == "YES" else "not null"
                default = f", default: {col['column_default']}" if col['column_default'] else ""
                f.write(f"- {col['column_name']} ({col['data_type']}, {nullable}{default})\n")
            f.write("\n")
        
        f.write("## Views\n\n")
        for view_name, columns in schema_data["views"].items():
            f.write(f"### {view_name}\n")
            for col in columns:
                nullable = "nullable" if col["is_nullable"] == "YES" else "not null"
                default = f", default: {col['column_default']}" if col['column_default'] else ""
                f.write(f"- {col['column_name']} ({col['data_type']}, {nullable}{default})\n")
            f.write("\n")
        
        f.write("## Functions (RPCs)\n\n")
        for func in schema_data["functions"]:
            f.write(f"- {func}\n")
    
    print("Schema information saved to current_supabase_schema.md")

if __name__ == "__main__":
    main()