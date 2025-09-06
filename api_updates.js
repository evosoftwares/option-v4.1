// Exemplo de atualização das APIs para utilizar a nova abordagem de acesso aos documentos
// Este é um exemplo em JavaScript/TypeScript usando o SDK do Supabase

import { supabase } from './supabaseClient';

// Função para obter documentos do motorista com a nova abordagem
async function getDriverDocumentsNewApproach(driverId) {
  try {
    // Nova consulta que unifica o acesso aos documentos
    // Primeiro verifica em driver_documents e usa os campos da tabela drivers como fallback
    const { data, error } = await supabase
      .rpc('get_driver_documents_unified', {
        driver_id: driverId
      });

    if (error) throw error;

    return { documents: data, success: true };
  } catch (error) {
    console.error('Erro ao obter documentos do motorista:', error);
    return { error, success: false };
  }
}

// Função RPC no banco de dados para unificar o acesso aos documentos
/*
CREATE OR REPLACE FUNCTION get_driver_documents_unified(driver_id uuid)
RETURNS TABLE(
  document_type text,
  file_url text,
  status text,
  created_at timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(dd.document_type, 
      CASE 
        WHEN d.cnh_photo_url IS NOT NULL THEN 'CNH_FRONT'
        WHEN d.crlv_photo_url IS NOT NULL THEN 'CRLV'
      END
    ) as document_type,
    COALESCE(dd.file_url, 
      CASE 
        WHEN dd.document_type = 'CNH_FRONT' OR (dd.document_type IS NULL AND d.cnh_photo_url IS NOT NULL) THEN d.cnh_photo_url
        WHEN dd.document_type = 'CRLV' OR (dd.document_type IS NULL AND d.crlv_photo_url IS NOT NULL) THEN d.crlv_photo_url
      END
    ) as file_url,
    COALESCE(dd.status, 'approved') as status,
    COALESCE(dd.created_at, d.created_at) as created_at
  FROM drivers d
  LEFT JOIN driver_documents dd ON d.id = dd.driver_id 
    AND dd.document_type IN ('CNH_FRONT', 'CNH_BACK', 'CRLV')
  WHERE d.id = driver_id
  AND (dd.file_url IS NOT NULL OR d.cnh_photo_url IS NOT NULL OR d.crlv_photo_url IS NOT NULL);
END;
$$ LANGUAGE plpgsql;
*/

// Função para verificar se todos os documentos obrigatórios foram enviados
async function checkRequiredDocuments(driverId) {
  try {
    const { data, error } = await supabase
      .rpc('get_driver_documents_unified', {
        driver_id: driverId
      });

    if (error) throw error;

    // Verificar se os documentos obrigatórios estão presentes
    const requiredDocuments = ['CNH_FRONT', 'CNH_BACK', 'CRLV'];
    const submittedDocuments = data.map(doc => doc.document_type);
    
    const missingDocuments = requiredDocuments.filter(
      doc => !submittedDocuments.includes(doc)
    );

    return {
      allRequiredDocumentsSubmitted: missingDocuments.length === 0,
      missingDocuments,
      submittedDocuments,
      success: true
    };
  } catch (error) {
    console.error('Erro ao verificar documentos obrigatórios:', error);
    return { error, success: false };
  }
}

// Função para atualizar status de um documento
async function updateDocumentStatus(documentId, status, rejectionReason = null) {
  try {
    const { data, error } = await supabase
      .from('driver_documents')
      .update({
        status: status,
        rejection_reason: rejectionReason,
        reviewed_at: new Date(),
        updated_at: new Date()
      })
      .eq('id', documentId)
      .select()
      .single();

    if (error) throw error;

    return { document: data, success: true };
  } catch (error) {
    console.error('Erro ao atualizar status do documento:', error);
    return { error, success: false };
  }
}

export { 
  getDriverDocumentsNewApproach, 
  checkRequiredDocuments, 
  updateDocumentStatus 
};