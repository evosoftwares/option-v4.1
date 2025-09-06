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

def get_table_info():
    """Get table information using the REST API"""
    try:
        # Get the OpenAPI specification which contains table information
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/",
            headers=headers
        )
        
        if response.status_code == 200:
            spec = response.json()
            
            # Extract tables from the paths
            tables = {}
            for path, methods in spec["paths"].items():
                # Skip RPC functions and root path
                if path in ["/", "/rpc"] or path.startswith("/rpc/"):
                    continue
                
                # Extract table name from path
                table_name = path.lstrip("/")
                
                # Get table properties from definitions
                if table_name in spec["definitions"]:
                    table_def = spec["definitions"][table_name]
                    tables[table_name] = table_def
            
            return tables
        else:
            print(f"Error getting API spec: {response.status_code} - {response.text}")
            return {}
    except Exception as e:
        print(f"Exception getting API spec: {str(e)}")
        return {}

def main():
    """Main function to extract schema information"""
    print("Extracting Supabase schema information...")
    
    # Get table information
    tables = get_table_info()
    print(f"Found {len(tables)} tables/views")
    
    # Save to file
    with open("current_supabase_schema.json", "w") as f:
        json.dump(tables, f, indent=2)
    
    print("Schema information saved to current_supabase_schema.json")
    
    # Also save as markdown
    with open("current_supabase_schema.md", "w") as f:
        f.write("# Current Supabase Schema\n\n")
        
        # Separate tables and views
        table_names = []
        view_names = []
        
        for table_name, table_def in tables.items():
            # Check if it's a view based on the description
            if "description" in table_def and "View" in table_def["description"]:
                view_names.append(table_name)
            else:
                table_names.append(table_name)
        
        f.write("## Tables\n\n")
        for table_name in table_names:
            f.write(f"### {table_name}\n")
            table_def = tables[table_name]
            if "properties" in table_def:
                for col_name, col_def in table_def["properties"].items():
                    col_type = col_def.get("type", "unknown")
                    if "format" in col_def:
                        col_type = col_def["format"]
                    f.write(f"- {col_name} ({col_type})\n")
            f.write("\n")
        
        f.write("## Views\n\n")
        for view_name in view_names:
            f.write(f"### {view_name}\n")
            view_def = tables[view_name]
            if "properties" in view_def:
                for col_name, col_def in view_def["properties"].items():
                    col_type = col_def.get("type", "unknown")
                    if "format" in col_def:
                        col_type = col_def["format"]
                    f.write(f"- {col_name} ({col_type})\n")
            f.write("\n")
        
        # Extract RPC functions from paths
        f.write("## Functions (RPCs)\n\n")
        rpc_functions = []
        try:
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/",
                headers=headers
            )
            if response.status_code == 200:
                spec = response.json()
                for path in spec["paths"]:
                    if path.startswith("/rpc/"):
                        rpc_functions.append(path.replace("/rpc/", ""))
        except Exception as e:
            print(f"Error extracting RPC functions: {str(e)}")
        
        for func in sorted(set(rpc_functions)):
            f.write(f"- {func}\n")
    
    print("Schema information saved to current_supabase_schema.md")

if __name__ == "__main__":
    main()