-- Política de Segurança para o bucket 'user-photos' para permitir uploads de documentos de motoristas
-- Esta política corrige o erro "new row violates row-level security policy" ao fazer upload
-- para o caminho 'drivers/{driver_id}/documents/{document_type}/...'.

-- Remove a política INSERT antiga, se existir
DROP POLICY IF EXISTS "Motoristas podem fazer upload de documentos (novo caminho)" ON storage.objects;

-- Remove a política UPDATE antiga, se existir
DROP POLICY IF EXISTS "Motoristas podem atualizar seus documentos (novo caminho)" ON storage.objects;

-- Remove a política SELECT antiga, se existir
DROP POLICY IF EXISTS "Motoristas podem ler seus documentos (novo caminho)" ON storage.objects;

-- Remove a política DELETE antiga, se existir
DROP POLICY IF EXISTS "Motoristas podem deletar seus documentos (novo caminho)" ON storage.objects;


-- Nova política para INSERT
-- Permite que usuários autenticados façam upload para o caminho 'drivers/{driver_id}/documents/{document_type}/...'
-- desde que o {driver_id} corresponda a um motorista associado ao usuário autenticado (auth.uid()).
CREATE POLICY "Motoristas podem fazer upload de documentos (caminho drivers)"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'drivers' AND
  -- Verifica se existe um motorista com o ID igual ao segundo segmento do caminho (driver_id)
  -- e se esse motorista pertence ao usuário autenticado (auth.uid()).
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  ) AND
  (storage.foldername(name))[3] = 'documents'
);

-- Nova política para UPDATE
CREATE POLICY "Motoristas podem atualizar seus documentos (caminho drivers)"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'drivers' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  ) AND
  (storage.foldername(name))[3] = 'documents'
)
WITH CHECK (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'drivers' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  ) AND
  (storage.foldername(name))[3] = 'documents'
);

-- Nova política para SELECT
CREATE POLICY "Motoristas podem ler seus documentos (caminho drivers)"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'drivers' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  ) AND
  (storage.foldername(name))[3] = 'documents'
);

-- Nova política para DELETE
CREATE POLICY "Motoristas podem deletar seus documentos (caminho drivers)"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'drivers' AND
  EXISTS (
    SELECT 1
    FROM drivers d
    WHERE d.id::text = (storage.foldername(name))[2]
      AND d.user_id = auth.uid()
  ) AND
  (storage.foldername(name))[3] = 'documents'
);
