# 🔴 Problema: Erro de Upload de Logo no Firebase Storage

## ❌ Erro Atual

```
Firebase Storage: An unknown error occurred, please check the error payload for server response. (storage/unknown)
```

## 📋 Contexto do Sistema

- **Projeto**: Sistema white-label para provedores de internet
- **Frontend**: React + Vite + TypeScript (admin-painel)
- **Backend**: Firebase Cloud Functions (Node.js 20)
- **Storage**: Firebase Storage
- **Usuário**: `tavares.enok@gmail.com` (superAdmin confirmado via custom claims)

## 🎯 O Que Estamos Tentando Fazer

Fazer upload de uma imagem de logo (PNG/JPG) através do painel admin, que deve:
1. Redimensionar a imagem para 512x512px no frontend
2. Converter para Base64
3. Enviar para Cloud Function `uploadProviderLogo`
4. Cloud Function salva no Firebase Storage em `providers/{providerId}/logo.png`
5. Retornar URL pública da imagem

## 📁 Arquivos Relevantes

### 1. Frontend - Upload Component
**Arquivo**: `/home/app/projects/painel_provedores/admin-painel/src/pages/provider-settings/AndroidBuilder_Final.tsx`

**Código do Upload** (linhas 162-243):

```typescript
<Input
    type="file"
    id="logo-upload"
    accept="image/png, image/jpeg, image/jpg"
    className="hidden"
    onChange={async (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        const toastId = toast.loading("Processando imagem...");

        try {
            // 1. Resize Image to 512x512
            const resizeImage = (file: File): Promise<Blob> => {
                return new Promise((resolve, reject) => {
                    const img = new Image();
                    img.src = URL.createObjectURL(file);
                    img.onload = () => {
                        const canvas = document.createElement('canvas');
                        canvas.width = 512;
                        canvas.height = 512;
                        const ctx = canvas.getContext('2d');
                        if (!ctx) {
                            reject(new Error("Canvas context failed"));
                            return;
                        }
                        const scale = Math.min(512 / img.width, 512 / img.height);
                        const x = (512 / 2) - (img.width / 2) * scale;
                        const y = (512 / 2) - (img.height / 2) * scale;

                        ctx.drawImage(img, x, y, img.width * scale, img.height * scale);

                        canvas.toBlob((blob) => {
                            if (blob) resolve(blob);
                            else reject(new Error("Blob creation failed"));
                        }, 'image/png');
                    };
                    img.onerror = reject;
                });
            };

            const resizedBlob = await resizeImage(file);

            // 2. Convert to Base64 and call Cloud Function
            const reader = new FileReader();
            reader.readAsDataURL(resizedBlob);
            reader.onloadend = async () => {
                const base64data = reader.result as string;
                
                try {
                    const uploadFn = httpsCallable(functions, 'uploadProviderLogo');
                    const result = await uploadFn({
                        imageBase64: base64data,
                        providerId: settings.provider?.id
                    });
                    
                    const data = result.data as any;
                    if (data.success) {
                        settings.setConfig((prev: any) => ({
                            ...prev,
                            logoUrl: data.url,
                            details: { ...(prev.details || {}), logoUrl: data.url }
                        }));
                        
                        toast.success("Logo processada e enviada com sucesso!", { id: toastId });
                    } else {
                        throw new Error(data.error || 'Upload falhou');
                    }
                } catch (error: any) {
                    console.error("Upload error:", error);
                    toast.error(`Erro: ${error.message || error.code || 'Falha desconhecida'}`, { 
                        id: toastId, 
                        duration: 5000 
                    });
                }
            };
        } catch (error: any) {
            console.error("Resize error:", error);
            toast.error(`Erro ao processar imagem: ${error.message}`, { id: toastId });
        }
    }}
/>
```

### 2. Backend - Cloud Function
**Arquivo**: `/home/app/projects/painel_provedores/functions/src/index.ts` (linhas 57-110)

```typescript
export const uploadProviderLogo = onCall({
    region: "southamerica-east1",
    maxInstances: 10
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be logged in.');
    }

    const { imageBase64, providerId } = request.data;
    if (!imageBase64 || !providerId) {
        throw new HttpsError('invalid-argument', 'Missing imageBase64 or providerId.');
    }

    logger.info(`Upload logo request for provider: ${providerId} by user: ${request.auth.uid}`);

    const user = await auth.getUser(request.auth.uid);
    const isSuperAdmin = user.customClaims?.superAdmin === true;
    const isOwner = user.customClaims?.providerId === providerId;

    logger.info(`User permissions - superAdmin: ${isSuperAdmin}, isOwner: ${isOwner}`);

    if (!isSuperAdmin && !isOwner) {
        throw new HttpsError('permission-denied', 'Not allowed to edit this provider.');
    }

    const bucket = storage.bucket();
    const filePath = `providers/${providerId}/logo.png`;
    const buffer = Buffer.from(imageBase64.replace(/^data:image\/\w+;base64,/, ""), 'base64');

    logger.info(`Uploading to path: ${filePath}, buffer size: ${buffer.length} bytes`);

    try {
        const file = bucket.file(filePath);
        
        await file.save(buffer, {
            metadata: {
                contentType: 'image/png',
            },
        });

        logger.info(`File uploaded successfully to ${filePath}`);

        await file.makePublic();
        logger.info(`File made public successfully`);

        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;

        await db.collection('provedores').doc(providerId).set({
            logoUrl: publicUrl,
            details: { logoUrl: publicUrl }
        }, { merge: true });

        logger.info(`Firestore updated with logoUrl: ${publicUrl}`);

        return { success: true, url: publicUrl };

    } catch (error: any) {
        logger.error("Upload Failed", error);
        throw new HttpsError('internal', `Upload failed: ${error.message}`);
    }
});
```

### 3. Firebase Storage Rules
**Arquivo**: `/home/app/projects/painel_provedores/storage.rules`

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /providers/{providerId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null &&
                    (request.auth.token.superAdmin == true || 
                     request.auth.token.providerId == providerId) &&
                    request.resource.size < 5 * 1024 * 1024 &&
                    request.resource.contentType.matches('image/(jpeg|png|webp)');
    }
  }
}
```

## ✅ Verificações Já Feitas

1. ✅ Custom Claims: `superAdmin: true` confirmado
2. ✅ Autenticação funcionando
3. ✅ Cloud Function deployada
4. ✅ Frontend usando `httpsCallable`
5. ✅ Não é cache do navegador

## 🤔 Possíveis Causas

1. Permissões do Service Account para `makePublic()`
2. Problema com bucket name
3. CORS entre frontend e Cloud Function
4. Tamanho do Base64
5. Conflito de região

## 🎯 Pergunta

Por que o erro "storage/unknown" acontece mesmo com permissões corretas?
