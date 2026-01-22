const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const providerData = {
    actionColor: "#255d8e",
    active: true,
    apiUrl: "http://45.176.56.70:3000",
    appConfig: null,
    backgroundColor: "#F3F4F6",
    cardColor: "#FFFFFF",
    config: {
        actionColor: "#255d8e",
        backgroundColor: "#F3F4F6",
        cardColor: "#FFFFFF",
        diagnosticStyle: "default",
        iconColor: "#6366F1",
        invoiceColor: "#00b3ff",
        layoutType: "layout_02",
        logoUrl: "",
        secondaryColor: "#202dd9",
        strings: {
            layoutThemes: '{"layout_06":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_02":{"themeColor":"#60a5fa","secondaryColor":"#202dd9","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1F2937","backgroundColor":"#F3F4F6","iconColor":"#6366F1"},"layout_03":{"themeColor":"#60a5fa","secondaryColor":"#202dd9","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1F2937","backgroundColor":"#F3F4F6","iconColor":"#6366F1"},"layout_08":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_09":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_10":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_11":{"themeColor":"#1A1A1A","secondaryColor":"#E63946","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1A1A1A","backgroundColor":"#F7F1E3","iconColor":"#1A1A1A"},"layout_12":{"themeColor":"#00F3FF","secondaryColor":"#FF00FF","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#1C1C1E","textColor":"#00F3FF","backgroundColor":"#0A0A0B","iconColor":"#00F3FF"},"layout_13":{"themeColor":"#0071E3","secondaryColor":"#34C759","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1D1D1F","backgroundColor":"#F5F5F7","iconColor":"#0071E3"},"layout_14":{"themeColor":"#BF953F","secondaryColor":"#000000","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#1C1C1C","textColor":"#FFFFFF","backgroundColor":"#101010","iconColor":"#BF953F"},"layout_15":{"themeColor":"#6366F1","secondaryColor":"#10B981","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1F2937","backgroundColor":"#F3F4F6","iconColor":"#6366F1"},"layout_05":{"themeColor":"#00D4FF","secondaryColor":"#FF00FF","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#1A1A2E","textColor":"#FFFFFF","backgroundColor":"#0A0A0F","iconColor":"#00D4FF"},"layout_07":{"themeColor":"#4F46E5","secondaryColor":"#7C3AED","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#171717","backgroundColor":"#FAFAFA","iconColor":"#4F46E5"},"layout_01":{"themeColor":"#6B46C1","secondaryColor":"#9F7AEA","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#2D3748","textColor":"#FFFFFF","backgroundColor":"#1A202C","iconColor":"#9F7AEA"},"layout_04":{"themeColor":"#0891B2","secondaryColor":"#059669","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#212121","textColor":"#ededed","backgroundColor":"#000000","iconColor":"#07b7e4"}}'
        },
        supportContacts: [
            {
                id: "contact-1765997004088",
                name: "vibe",
                type: "whatsapp",
                value: "5508007312500"
            }
        ]
    },
    textColor: "#1F2937",
    themeColor: "#60a5fa",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    details: {
        apiToken: "4b6aae35-219a-4580-8c5c-dfb4efdbfae3",
        appName: "APP-PROVEDOR",
        city: "",
        cnpj: "32354591000191",
        email: "vibe@gmail.com",
        hasAndroidApp: true,
        hasIosApp: false,
        menuConfig: {
            items: {
                contract: { color: "#6366F1", enabled: true, name: "Contrato", type: "internal" },
                internet_usage: { color: "#EC4899", enabled: true, name: "Consumo de Internet", type: "internal" },
                invoices: { color: "#1E6FF8", enabled: true, name: "Faturas", type: "internal" },
                my_ip: { color: "#F97316", enabled: true, name: "Meu IP", type: "internal" },
                notifications: { color: "#F59E0B", enabled: false, name: "Notificações", type: "internal" },
                payment_promise: { color: "#10B981", enabled: true, name: "Promessa de Pagamento", type: "internal" },
                speed_test: { color: "#8B5CF6", enabled: true, name: "Teste de Velocidade", type: "internal" },
                support: { color: "#06B6D4", enabled: true, name: "Suporte", type: "internal" }
            },
            order: ["notifications", "invoices", "payment_promise", "speed_test", "internet_usage", "support", "contract", "my_ip"]
        },
        nomeFantasia: "Vibe teste",
        razaoSocial: "Vibe teste",
        secondaryColor: "#9575CD",
        state: "",
        systemType: "SGP",
        systemUrl: "https://vibetelecom.sgp.net.br",
        telefone: "000000000000"
    },
    diagnosticStyle: "default",
    features: {
        consumption: true,
        contract: true,
        imageCarousel: true,
        invoices: true,
        speedTest: true,
        support: true,
        unlock: true
    },
    iconColor: "#6366F1",
    invoiceColor: "#00b3ff",
    layoutType: "layout_02",
    logoUrl: "",
    name: "vibe2",
    notifications: null,
    secondaryColor: "#202dd9",
    strings: {
        layoutThemes: '{"layout_06":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_02":{"themeColor":"#60a5fa","secondaryColor":"#202dd9","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1F2937","backgroundColor":"#F3F4F6","iconColor":"#6366F1"},"layout_03":{"themeColor":"#60a5fa","secondaryColor":"#202dd9","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1F2937","backgroundColor":"#F3F4F6","iconColor":"#6366F1"},"layout_08":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_09":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_10":{"themeColor":"#19b1cc","secondaryColor":"#0026e6","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#0f0f0f","textColor":"#ffffff","backgroundColor":"#000000","iconColor":"#00fbff"},"layout_11":{"themeColor":"#1A1A1A","secondaryColor":"#E63946","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1A1A1A","backgroundColor":"#F7F1E3","iconColor":"#1A1A1A"},"layout_12":{"themeColor":"#00F3FF","secondaryColor":"#FF00FF","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#1C1C1E","textColor":"#00F3FF","backgroundColor":"#0A0A0B","iconColor":"#00F3FF"},"layout_13":{"themeColor":"#0071E3","secondaryColor":"#34C759","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1D1D1F","backgroundColor":"#F5F5F7","iconColor":"#0071E3"},"layout_14":{"themeColor":"#BF953F","secondaryColor":"#000000","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#1C1C1C","textColor":"#FFFFFF","backgroundColor":"#101010","iconColor":"#BF953F"},"layout_15":{"themeColor":"#6366F1","secondaryColor":"#10B981","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#1F2937","backgroundColor":"#F3F4F6","iconColor":"#6366F1"},"layout_05":{"themeColor":"#00D4FF","secondaryColor":"#FF00FF","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#1A1A2E","textColor":"#FFFFFF","backgroundColor":"#0A0A0F","iconColor":"#00D4FF"},"layout_07":{"themeColor":"#4F46E5","secondaryColor":"#7C3AED","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#FFFFFF","textColor":"#171717","backgroundColor":"#FAFAFA","iconColor":"#4F46E5"},"layout_01":{"themeColor":"#6B46C1","secondaryColor":"#9F7AEA","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#2D3748","textColor":"#FFFFFF","backgroundColor":"#1A202C","iconColor":"#9F7AEA"},"layout_04":{"themeColor":"#0891B2","secondaryColor":"#059669","actionColor":"#255d8e","invoiceColor":"#00b3ff","cardColor":"#212121","textColor":"#ededed","backgroundColor":"#000000","iconColor":"#07b7e4"}}'
    },
    supportContacts: [
        {
            id: "contact-1765997004088",
            name: "vibe",
            type: "whatsapp",
            value: "5508007312500"
        }
    ]
};

async function createVibeDocument() {
    try {
        console.log('🔧 Criando documento provedores/vibe...');

        await db.collection('provedores').doc('vibe').set(providerData);
        console.log('✅ Documento criado com sucesso!');

        console.log('\n🗑️  Deletando documento vazio 32354591000191...');
        await db.collection('provedores').doc('32354591000191').delete();
        console.log('✅ Documento vazio deletado!');

        console.log('\n🎉 CONCLUÍDO!');
        console.log('⚠️  Faça LOGOUT e LOGIN novamente no painel admin.');
        console.log('   O token já tem providerId: "vibe", então deve funcionar agora.');

        process.exit(0);
    } catch (error) {
        console.error('❌ Erro:', error.message);
        console.error(error);
        process.exit(1);
    }
}

createVibeDocument();
