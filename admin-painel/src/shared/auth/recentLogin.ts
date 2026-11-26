import { isReauthRequired } from '@/shared/api/panelHttp';

/** Abre o pedido de senha e resolve quando a sessão foi confirmada (rejeita se cancelar). */
type PasswordPrompt = () => Promise<void>;

let prompt: PasswordPrompt | null = null;

/** Registrado pelo ReauthDialogHost montado no App. */
export function registerReauthPrompt(next: PasswordPrompt | null): void {
  prompt = next;
}

export class ReauthCanceledError extends Error {
  constructor() { super('Ação cancelada.'); }
}

/**
 * Executa uma ação sensível. Se o servidor pedir login recente
 * (401 "reauth-required"), pede a senha uma vez e repete a ação.
 */
export async function withRecentLogin<T>(action: () => Promise<T>): Promise<T> {
  try {
    return await action();
  } catch (error) {
    if (!isReauthRequired(error) || !prompt) throw error;
    await prompt();
    return action();
  }
}
