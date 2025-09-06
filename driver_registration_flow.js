// Exemplo de modificação do fluxo de cadastro para salvar documentos diretamente em driver_documents
// Este é um exemplo em JavaScript/TypeScript usando o SDK do Supabase

import { supabase } from './supabaseClient';

// Função para registrar um motorista com documentos
async function registerDriverWithDocuments(driverData, documents) {
  try {
    // 1. Inserir dados básicos do motorista na tabela drivers
    const { data: driver, error: driverError } = await supabase
      .from('drivers')
      .insert({
        user_id: driverData.user_id,
        cnh_expiry_date: driverData.cnh_expiry_date,
        vehicle_brand: driverData.vehicle_brand,
        vehicle_model: driverData.vehicle_model,
        vehicle_year: driverData.vehicle_year,
        vehicle_color: driverData.vehicle_color,
        vehicle_plate: driverData.vehicle_plate,
        vehicle_category: driverData.vehicle_category,
        // Não salvamos mais as URLs aqui, vamos salvar em driver_documents
        // cnh_photo_url: driverData.cnh_photo_url,
        // crlv_photo_url: driverData.crlv_photo_url,
        approval_status: 'pending'
      })
      .select()
      .single();

    if (driverError) throw driverError;

    // 2. Inserir documentos na tabela driver_documents
    const documentsToInsert = documents.map(doc => ({
      driver_id: driver.id,
      document_type: doc.type,
      file_url: doc.url,
      status: 'pending',
      created_at: new Date(),
      updated_at: new Date()
    }));

    const { error: documentsError } = await supabase
      .from('driver_documents')
      .insert(documentsToInsert);

    if (documentsError) throw documentsError;

    return { driver, success: true };
  } catch (error) {
    console.error('Erro ao registrar motorista:', error);
    return { error, success: false };
  }
}

// Função para obter documentos do motorista
async function getDriverDocuments(driverId) {
  try {
    // Consulta otimizada que verifica primeiro em driver_documents
    // e depois usa os campos da tabela drivers como fallback
    const { data, error } = await supabase
      .from('drivers')
      .select(`
        id,
        cnh_photo_url,
        crlv_photo_url,
        driver_documents (
          document_type,
          file_url,
          status
        )
      `)
      .eq('id', driverId)
      .single();

    if (error) throw error;

    // Processar os resultados para unificar os documentos
    const documents = {};
    
    // Primeiro, verificar se há documentos na tabela driver_documents
    if (data.driver_documents && data.driver_documents.length > 0) {
      data.driver_documents.forEach(doc => {
        documents[doc.document_type] = {
          url: doc.file_url,
          status: doc.status
        };
      });
    }
    
    // Se não encontrou em driver_documents, usar os campos da tabela drivers como fallback
    if (!documents['CNH_FRONT'] && data.cnh_photo_url) {
      documents['CNH_FRONT'] = {
        url: data.cnh_photo_url,
        status: 'approved'
      };
    }
    
    if (!documents['CRLV'] && data.crlv_photo_url) {
      documents['CRLV'] = {
        url: data.crlv_photo_url,
        status: 'approved'
      };
    }

    return { documents, success: true };
  } catch (error) {
    console.error('Erro ao obter documentos do motorista:', error);
    return { error, success: false };
  }
}

export { registerDriverWithDocuments, getDriverDocuments };