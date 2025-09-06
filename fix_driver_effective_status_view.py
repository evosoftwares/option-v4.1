#!/usr/bin/env python3
"""
Script para corrigir a view driver_effective_status no Supabase
"""

import requests
import json

# Configurações do Supabase (substituir com valores reais)
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

headers = {
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def execute_sql_query(query):
    """Executa uma query SQL no Supabase"""
    try:
        url = f"{SUPABASE_URL}/rest/v1/rpc/execute_sql"
        data = {"query": query}
        
        response = requests.post(url, headers=headers, json=data)
        
        if response.status_code in [200, 201]:
            print("✅ Query executada com sucesso!")
            if response.text:
                print(f"📊 Resultado: {response.text}")
            return True
        else:
            print(f"❌ Erro ao executar query: {response.status_code}")
            print(f"📋 Detalhes: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na execução: {e}")
        return False

def fix_driver_effective_status_view():
    """Corrige a view driver_effective_status"""
    print("🔧 Iniciando correção da view driver_effective_status...")
    
    # Script SQL para corrigir a view
    sql_script = """
    -- Remover view existente se houver
    DROP VIEW IF EXISTS driver_effective_status;
    
    -- Criar a view corrigida
    CREATE OR REPLACE VIEW driver_effective_status AS
    SELECT 
        ds.driver_id,
        ds.online_intent,
        ds.updated_at as intent_updated_at,
        -- Verificar se o motorista está nos horários de trabalho
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM working_hours wh 
                WHERE wh.driver_id = ds.driver_id 
                AND wh.is_active = true
                AND wh.day_of_week = EXTRACT(DOW FROM NOW())  -- 0 = Domingo, 6 = Sábado
                AND (
                    -- Caso normal: mesmo dia (ex: 08:00 às 18:00)
                    (wh.start_time <= wh.end_time AND 
                     CURRENT_TIME >= wh.start_time AND 
                     CURRENT_TIME < wh.end_time)
                    OR
                    -- Caso que cruza meia-noite (ex: 22:00 às 06:00)
                    (wh.start_time > wh.end_time AND 
                     (CURRENT_TIME >= wh.start_time OR 
                      CURRENT_TIME < wh.end_time))
                )
            ) THEN true
            -- Se não há horários definidos, assume que está disponível
            WHEN NOT EXISTS (
                SELECT 1 
                FROM working_hours wh 
                WHERE wh.driver_id = ds.driver_id 
                AND wh.is_active = true
            ) THEN true
            ELSE false
        END as is_within_working_hours,
        -- Status efetivo: intenção online E dentro dos horários
        (ds.online_intent AND (
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM working_hours wh 
                    WHERE wh.driver_id = ds.driver_id 
                    AND wh.is_active = true
                    AND wh.day_of_week = EXTRACT(DOW FROM NOW())
                    AND (
                        (wh.start_time <= wh.end_time AND 
                         CURRENT_TIME >= wh.start_time AND 
                         CURRENT_TIME < wh.end_time)
                        OR
                        (wh.start_time > wh.end_time AND 
                         (CURRENT_TIME >= wh.start_time OR 
                          CURRENT_TIME < wh.end_time))
                    )
                ) THEN true
                WHEN NOT EXISTS (
                    SELECT 1 
                    FROM working_hours wh 
                    WHERE wh.driver_id = ds.driver_id 
                    AND wh.is_active = true
                ) THEN true
                ELSE false
            END
        )) as effective_online
    FROM driver_status ds;
    """
    
    # Executar o script
    success = execute_sql_query(sql_script)
    
    if success:
        print("✅ View driver_effective_status corrigida com sucesso!")
        
        # Testar a view
        print("\n🧪 Testando a view corrigida...")
        test_query = "SELECT * FROM driver_effective_status LIMIT 3;"
        execute_sql_query(test_query)
    else:
        print("❌ Falha ao corrigir a view")

def check_working_hours_data():
    """Verifica dados de working_hours para diagnóstico"""
    print("\n🔍 Verificando dados de working_hours...")
    
    # Verificar se há dados na tabela
    query = "SELECT COUNT(*) as total FROM working_hours;"
    execute_sql_query(query)
    
    # Verificar alguns registros
    query = "SELECT driver_id, day_of_week, start_time, end_time, is_active FROM working_hours LIMIT 5;"
    execute_sql_query(query)

def check_driver_status_data():
    """Verifica dados de driver_status para diagnóstico"""
    print("\n🔍 Verificando dados de driver_status...")
    
    # Verificar se há dados na tabela
    query = "SELECT COUNT(*) as total FROM driver_status;"
    execute_sql_query(query)
    
    # Verificar alguns registros
    query = "SELECT driver_id, online_intent, updated_at FROM driver_status LIMIT 5;"
    execute_sql_query(query)

if __name__ == "__main__":
    print("🚀 Script de correção da view driver_effective_status")
    print("=" * 50)
    
    # Verificar dados atuais
    check_working_hours_data()
    check_driver_status_data()
    
    # Corrigir a view
    fix_driver_effective_status_view()
    
    print("\n✨ Processo concluído!")