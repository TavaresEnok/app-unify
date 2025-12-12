// pages/api/providers/[id]/force-update.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { getFirestore } from 'firebase-admin/firestore';
import { initializeApp, getApps, cert } from 'firebase-admin/app';

if (getApps().length === 0) {
  initializeApp({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

const db = getFirestore();

interface ForceUpdateConfig {
  minVersion: string;
  latestVersion: string;
  forceUpdate: boolean;
  updateMessage: {
    pt_BR: {
      title: string;
      message: string;
      buttonText: string;
    };
  };
  storeUrls: {
    android: string;
    ios: string;
  };
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { id: providerId } = req.query;

  if (!providerId || typeof providerId !== 'string') {
    return res.status(400).json({ error: 'Provider ID inválido' });
  }

  try {
    if (req.method === 'GET') {
      const docRef = db.collection('provedores').doc(providerId);
      const doc = await docRef.get();

      if (!doc.exists) {
        return res.status(404).json({ error: 'Provedor não encontrado' });
      }

      const data = doc.data();
      return res.status(200).json({
        appVersion: data?.appVersion || null,
      });
    }

    if (req.method === 'POST') {
      const { appVersion } = req.body as { appVersion: ForceUpdateConfig };

      if (!appVersion) {
        return res.status(400).json({ error: 'Configuração inválida' });
      }

      if (!isValidVersion(appVersion.minVersion)) {
        return res.status(400).json({ 
          error: 'Versão mínima inválida. Use formato X.Y.Z' 
        });
      }

      if (!isValidVersion(appVersion.latestVersion)) {
        return res.status(400).json({ 
          error: 'Última versão inválida. Use formato X.Y.Z' 
        });
      }

      if (
        appVersion.forceUpdate &&
        !appVersion.storeUrls.android &&
        !appVersion.storeUrls.ios
      ) {
        return res.status(400).json({ 
          error: 'Adicione pelo menos um link de loja quando forceUpdate estiver ativo' 
        });
      }

      const docRef = db.collection('provedores').doc(providerId);
      await docRef.update({
        appVersion,
        updatedAt: new Date().toISOString(),
      });

      return res.status(200).json({ 
        success: true,
        message: 'Configuração salva com sucesso' 
      });
    }

    if (req.method === 'DELETE') {
      const docRef = db.collection('provedores').doc(providerId);
      await docRef.update({
        appVersion: null,
        updatedAt: new Date().toISOString(),
      });

      return res.status(200).json({ 
        success: true,
        message: 'Configuração removida com sucesso' 
      });
    }

    return res.status(405).json({ error: 'Método não permitido' });
  } catch (error) {
    console.error('Erro na API force-update:', error);
    return res.status(500).json({ 
      error: 'Erro interno do servidor',
      details: error instanceof Error ? error.message : 'Erro desconhecido'
    });
  }
}

function isValidVersion(version: string): boolean {
  return /^\d+\.\d+\.\d+$/.test(version);
}
