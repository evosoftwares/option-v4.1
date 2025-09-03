-- Criação da tabela para rastrear placas de veículos em uso (opcional, para lógica de app)
-- Esta tabela pode ser usada para uma verificação mais rápida ou para fins de histórico.
-- CREATE TABLE IF NOT EXISTS vehicle_plates_in_use (
--   plate TEXT PRIMARY KEY,
--   driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
--   created_at TIMESTAMPTZ DEFAULT NOW()
-- );

-- Adiciona um comentário à restrição UNIQUE existente para clareza (se ela ainda não tiver um)
-- COMMENT ON CONSTRAINT drivers_vehicle_plate_key ON drivers IS 'Garante que cada placa de veículo seja única entre todos os motoristas.';

-- Política de Segurança para o bucket 'user-photos' para permitir uploads de documentos de motoristas
-- Esta política corrige o erro "new row violates row-level security policy" ao fazer upload
-- para o caminho 'driver_documents/{driver_id}/...'.

-- Primeiro, certifique-se de que a extensão 'pg_tle' ou 'supabase_vault' (se necessário) e 'pgjwt' estejam disponíveis.
-- Para políticas de storage, geralmente a extensão 'storage' é usada implicitamente.

-- A política padrão para 'user-photos' pode ser algo como:
-- CREATE POLICY "Usuários podem fazer upload de suas próprias fotos"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'user-photos' AND (storage.foldername(name))[1] = uid());

-- A nova política permite uploads específicos para documentos de motoristas.
-- Ela verifica se o primeiro segmento do caminho é 'driver_documents' e se o segundo segmento
-- corresponde ao ID de um motorista associado ao usuário autenticado.

CREATE POLICY "Motoristas podem fazer upload de documentos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'driver_documents' AND
  -- Verifica se existe um motorista com o ID igual ao segundo segmento do caminho (driver_id)
  -- e se esse motorista pertence ao usuário autenticado (auth.uid()).
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  )
);

-- Garante que a política de UPDATE também permite ao motorista atualizar seus próprios documentos
-- (se for uma operação suportada e desejada).
CREATE POLICY "Motoristas podem atualizar seus documentos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'driver_documents' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'driver_documents' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  )
);

-- Garante que a política de SELECT também permite ao motorista ler seus próprios documentos.
CREATE POLICY "Motoristas podem ler seus documentos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'driver_documents' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  )
);

-- Garante que a política de DELETE também permite ao motorista deletar seus próprios documentos.
CREATE POLICY "Motoristas podem deletar seus documentos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'driver_documents' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  )
);
