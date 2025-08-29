#!/bin/bash

# Test remote Supabase connection and disable RLS if possible
SUPABASE_URL="https://qlbwacmavngtonauxnte.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

echo "Testing connection to remote Supabase..."

# Test basic connection
response=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  "$SUPABASE_URL/rest/v1/app_users?select=count&limit=1")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

echo "HTTP Code: $http_code"
echo "Response: $body"

if [ "$http_code" = "200" ]; then
    echo "✅ Connection successful!"
    echo "Attempting to check RLS status..."
    
    # Try to call a function to check RLS status
    rls_response=$(curl -s -w "\n%{http_code}" \
      -X POST \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
      -H "Content-Type: application/json" \
      "$SUPABASE_URL/rest/v1/rpc/simple_auth_check")
    
    rls_http_code=$(echo "$rls_response" | tail -n1)
    rls_body=$(echo "$rls_response" | head -n -1)
    
    echo "RLS Check HTTP Code: $rls_http_code"
    echo "RLS Check Response: $rls_body"
else
    echo "❌ Connection failed with HTTP code: $http_code"
    echo "Response: $body"
fi