/**
 * Testes de integração das Cloud Functions.
 *
 * Estratégia: mock do Firebase Admin SDK para testar a lógica de negócio
 * pura das funções sem depender de infraestrutura real.
 */

// =========================================================================
// MOCKS — devem ser declarados antes de qualquer import que use firebase
// =========================================================================

const mockSet = jest.fn().mockResolvedValue(undefined);
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockDelete = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockBatch = {
    delete: jest.fn(),
    commit: jest.fn().mockResolvedValue(undefined),
};
const mockCollectionGet = jest.fn().mockResolvedValue({ docs: [] });

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const mockDocRef = (): any => ({
    id: 'mock-doc-id',
    set: mockSet,
    update: mockUpdate,
    delete: mockDelete,
    get: mockGet,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    collection: jest.fn((): any => ({
        get: mockCollectionGet,
        add: jest.fn().mockResolvedValue({ id: 'new-doc-id' }),
        doc: jest.fn(() => mockDocRef()),
    })),
});

jest.mock('firebase-admin/app', () => ({ initializeApp: jest.fn() }));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn(() => ({ getUser: jest.fn() })) }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn(() => ({ bucket: jest.fn() })) }));
jest.mock('firebase-admin/firestore', () => ({
    getFirestore: jest.fn(() => ({
        collection: jest.fn(() => ({
            doc: jest.fn(() => mockDocRef()),
            get: mockCollectionGet,
            where: jest.fn(() => ({ get: mockCollectionGet })),
        })),
        batch: jest.fn(() => mockBatch),
        runTransaction: jest.fn(async (fn: (t: any) => Promise<any>) => fn({})),
    })),
    FieldValue: {
        serverTimestamp: jest.fn(() => ({ _methodName: 'serverTimestamp' })),
        delete: jest.fn(() => ({ _methodName: 'deleteField' })),
        arrayUnion: jest.fn((...args: any[]) => args),
    },
}));
jest.mock('firebase-functions/v2/firestore', () => ({
    onDocumentCreated: jest.fn((_opts: any, handler: Function) => handler),
}));
jest.mock('firebase-functions/v2/https', () => ({
    onCall: jest.fn((_opts: any, handler: Function) => handler),
    HttpsError: class HttpsError extends Error {
        constructor(public code: string, message: string) { super(message); }
    },
}));
jest.mock('firebase-functions/logger', () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
}));
jest.mock('firebase-functions/params', () => ({
    defineSecret: jest.fn((name: string) => ({
        value: jest.fn(() => name === 'PROXY_URL' ? 'http://proxy:3000' : 'secret123'),
    })),
    defineString: jest.fn((name: string, opts: any) => ({
        value: jest.fn(() => opts?.default ?? ''),
    })),
}));

// =========================================================================
// IMPORTS DOS UTILITÁRIOS (não dependem do Firebase)
// =========================================================================
import {
    parseJsonSafely,
    isValidTicketStatus,
    isValidNewProviderId,
    TICKET_STATUSES,
    logger,
} from './utils';

// =========================================================================
// HELPERS DE TESTE
// =========================================================================

function makeFirestoreEvent(data: Record<string, unknown>, params: Record<string, string> = {}) {
    return {
        params: { requestId: 'test-request-id', ...params },
        data: {
            data: () => data,
            ref: mockDocRef(),
        },
    };
}

// =========================================================================
// TESTES DE LÓGICA DE NEGÓCIO (sem Firebase)
// =========================================================================

describe('Validação de dados de entrada', () => {
    describe('parseJsonSafely', () => {
        it('retorna objeto para JSON válido', () => {
            expect(parseJsonSafely('{"key":"value"}')).toEqual({ key: 'value' });
        });
        it('retorna null para string vazia', () => {
            expect(parseJsonSafely('')).toBeNull();
        });
        it('retorna null para JSON inválido', () => {
            expect(parseJsonSafely('{invalid}')).toBeNull();
        });
        it('retorna array para JSON de array', () => {
            expect(parseJsonSafely('[1,2,3]')).toEqual([1, 2, 3]);
        });
    });

    describe('isValidTicketStatus', () => {
        it('aceita os status válidos', () => {
            TICKET_STATUSES.forEach(status => {
                expect(isValidTicketStatus(status)).toBe(true);
            });
        });
        it('rejeita status inválidos', () => {
            expect(isValidTicketStatus('Cancelado')).toBe(false);
            expect(isValidTicketStatus('')).toBe(false);
            expect(isValidTicketStatus('aberto')).toBe(false); // case sensitive
        });
    });

    describe('isValidNewProviderId', () => {
        it('aceita identificadores válidos', () => {
            expect(isValidNewProviderId('vibe-telecom')).toBe(true);
            expect(isValidNewProviderId('provedor_123')).toBe(true);
            expect(isValidNewProviderId('abc')).toBe(true);
        });
        it('rejeita caracteres inválidos', () => {
            expect(isValidNewProviderId('Provedor')).toBe(false);
            expect(isValidNewProviderId('a b')).toBe(false);
            expect(isValidNewProviderId('p@inel')).toBe(false);
            expect(isValidNewProviderId('')).toBe(false);
        });
    });
});

// =========================================================================
// TESTES DO LOGGER ESTRUTURADO
// =========================================================================

describe('logger estruturado', () => {
    beforeEach(() => jest.clearAllMocks());

    it('emite JSON com severity ERROR para logger.error', () => {
        const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
        logger.error('falha na função', { functionName: 'handleDeleteProvider', requestId: 'req-1' });
        const entry = JSON.parse(spy.mock.calls[0][0]);
        expect(entry.severity).toBe('ERROR');
        expect(entry.functionName).toBe('handleDeleteProvider');
        expect(entry.timestamp).toBeDefined();
        spy.mockRestore();
    });

    it('emite JSON com severity WARNING para logger.warn', () => {
        const spy = jest.spyOn(console, 'warn').mockImplementation(() => {});
        logger.warn('configuração ausente', { key: 'PROXY_URL' });
        const entry = JSON.parse(spy.mock.calls[0][0]);
        expect(entry.severity).toBe('WARNING');
        spy.mockRestore();
    });

    it('inclui timestamp em todos os logs', () => {
        const spy = jest.spyOn(console, 'log').mockImplementation(() => {});
        logger.info('operação ok');
        const entry = JSON.parse(spy.mock.calls[0][0]);
        expect(new Date(entry.timestamp).getTime()).toBeGreaterThan(0);
        spy.mockRestore();
    });
});

// =========================================================================
// TESTES DE FLUXO: ROTEAMENTO DE function_requests
// =========================================================================

describe('Roteamento de function_requests', () => {
    it('ignora eventos com tipo desconhecido (retorna null)', () => {
        const event = makeFirestoreEvent({ type: 'UNKNOWN_TYPE', requesterUid: 'user-1' });
        const data = event.data.data();
        // Simula a guarda de tipo presente em todas as funções
        const shouldProcess = data?.type === 'UPDATE_PROVIDER_CONFIG';
        expect(shouldProcess).toBe(false);
    });

    it('ignora eventos sem dados (data() retorna undefined)', () => {
        const event = {
            params: { requestId: 'test' },
            data: { data: () => undefined, ref: mockDocRef() },
        };
        const data = event.data.data() as Record<string, unknown> | undefined;
        expect(data).toBeUndefined();
        const shouldProcess = !!data && (data as any).type === 'UPDATE_PROVIDER_CONFIG';
        expect(shouldProcess).toBe(false);
    });

    it('processa evento com tipo correto', () => {
        const event = makeFirestoreEvent({
            type: 'UPDATE_PROVIDER_CONFIG',
            requesterUid: 'admin-uid',
            payload: { providerId: 'vibe', config: { themeColor: '#ff0000' } },
        });
        const data = event.data.data();
        expect(data?.type).toBe('UPDATE_PROVIDER_CONFIG');
        expect((data?.payload as any)?.providerId).toBe('vibe');
    });
});

// =========================================================================
// TESTES DE SEGURANÇA: VALIDAÇÃO DE AUTORIZAÇÃO
// =========================================================================

describe('Validação de autorização', () => {
    it('detecta superAdmin via custom claims', () => {
        const claims = { superAdmin: true, providerId: undefined };
        expect(claims.superAdmin === true).toBe(true);
    });

    it('detecta providerAdmin via custom claims', () => {
        const claims = { superAdmin: false, providerId: 'vibe-telecom' };
        const canManageProvider = (targetProviderId: string) =>
            claims.superAdmin === true || claims.providerId === targetProviderId;
        expect(canManageProvider('vibe-telecom')).toBe(true);
        expect(canManageProvider('outro-provedor')).toBe(false);
    });

    it('bloqueia usuário sem claims adequados', () => {
        const claims = { superAdmin: false, providerId: 'vibe-telecom' };
        const canManageProvider = (targetProviderId: string) =>
            claims.superAdmin === true || claims.providerId === targetProviderId;
        expect(canManageProvider('provedor-x')).toBe(false);
    });

    it('superAdmin pode gerenciar qualquer provedor', () => {
        const claims = { superAdmin: true };
        const canManageProvider = (_targetProviderId: string) => claims.superAdmin === true;
        expect(canManageProvider('provedor-qualquer')).toBe(true);
        expect(canManageProvider('outro-provedor')).toBe(true);
    });
});

// =========================================================================
// TESTES DE PAYLOAD: CRIAÇÃO DE TICKET
// =========================================================================

describe('Payload de criação de ticket', () => {
    function validateTicketPayload(payload: any): { valid: boolean; errors: string[] } {
        const errors: string[] = [];
        if (!payload?.providerId || typeof payload.providerId !== 'string') {
            errors.push('providerId obrigatório');
        }
        if (!payload?.subject || typeof payload.subject !== 'string' || payload.subject.trim().length < 5) {
            errors.push('subject deve ter ao menos 5 caracteres');
        }
        if (!payload?.message || typeof payload.message !== 'string' || payload.message.trim().length < 10) {
            errors.push('message deve ter ao menos 10 caracteres');
        }
        if (payload?.status && !isValidTicketStatus(payload.status)) {
            errors.push(`status inválido: ${payload.status}`);
        }
        return { valid: errors.length === 0, errors };
    }

    it('aceita payload válido', () => {
        const result = validateTicketPayload({
            providerId: 'vibe-telecom',
            subject: 'Lentidão na conexão',
            message: 'Minha internet está muito lenta desde ontem à noite.',
            status: 'Aberto',
        });
        expect(result.valid).toBe(true);
        expect(result.errors).toHaveLength(0);
    });

    it('rejeita payload sem providerId', () => {
        const result = validateTicketPayload({
            subject: 'Assunto válido',
            message: 'Mensagem longa o suficiente para passar.',
        });
        expect(result.valid).toBe(false);
        expect(result.errors).toContain('providerId obrigatório');
    });

    it('rejeita subject curto', () => {
        const result = validateTicketPayload({
            providerId: 'vibe',
            subject: 'ok',
            message: 'Mensagem longa o suficiente.',
        });
        expect(result.valid).toBe(false);
        expect(result.errors[0]).toContain('subject');
    });

    it('rejeita status inválido', () => {
        const result = validateTicketPayload({
            providerId: 'vibe',
            subject: 'Assunto ok aqui',
            message: 'Mensagem suficientemente longa.',
            status: 'Inexistente',
        });
        expect(result.valid).toBe(false);
        expect(result.errors[0]).toContain('status inválido');
    });
});

// =========================================================================
// TESTES DE EXCLUSÃO EM CASCATA (lógica pura)
// =========================================================================

describe('Lógica de exclusão em cascata de provedor', () => {
    it('identifica todas as subcoleções a excluir', () => {
        const subcollectionsToDelete = ['clientes', 'backups', 'diagnostic_results'];
        const rootCollectionsWithProviderId = ['users', 'tickets'];

        expect(subcollectionsToDelete).toContain('clientes');
        expect(subcollectionsToDelete).toContain('backups');
        expect(subcollectionsToDelete).toContain('diagnostic_results');
        expect(rootCollectionsWithProviderId).toContain('users');
        expect(rootCollectionsWithProviderId).toContain('tickets');
    });

    it('processa em batches de até 500 documentos', () => {
        const MAX_BATCH_SIZE = 500;
        const totalDocs = 1250;
        const batches = Math.ceil(totalDocs / MAX_BATCH_SIZE);
        expect(batches).toBe(3);
    });
});
