export interface PasswordValidation {
  valid: boolean;
  errors: string[];
  strength: 'weak' | 'medium' | 'strong';
}

/**
 * Valida força de senha conforme política do sistema.
 * Mínimo: 8 caracteres, 1 maiúscula, 1 minúscula, 1 número.
 */
export function validatePassword(password: string): PasswordValidation {
  const errors: string[] = [];

  if (password.length < 8) errors.push('Mínimo de 8 caracteres');
  if (password.length > 64) errors.push('Máximo de 64 caracteres');
  if (!/[A-Z]/.test(password)) errors.push('Pelo menos 1 letra maiúscula');
  if (!/[a-z]/.test(password)) errors.push('Pelo menos 1 letra minúscula');
  if (!/[0-9]/.test(password)) errors.push('Pelo menos 1 número');

  const passedChecks = 5 - errors.length;
  const strength: PasswordValidation['strength'] =
    passedChecks <= 2 ? 'weak' : passedChecks <= 4 ? 'medium' : 'strong';

  return { valid: errors.length === 0, errors, strength };
}

export const PASSWORD_STRENGTH_COLORS = {
  weak: 'text-red-500',
  medium: 'text-yellow-500',
  strong: 'text-green-500',
} as const;

export const PASSWORD_STRENGTH_LABELS = {
  weak: 'Fraca',
  medium: 'Média',
  strong: 'Forte',
} as const;

/** Senhas de administrador do painel: mínimo de 10 caracteres + regras gerais. */
export const ADMIN_PASSWORD_MIN_LENGTH = 10;

export function validateAdminPassword(password: string): PasswordValidation {
  const base = validatePassword(password);
  const errors = base.errors.filter((error) => error !== 'Mínimo de 8 caracteres');
  if (password.length < ADMIN_PASSWORD_MIN_LENGTH) errors.unshift(`Mínimo de ${ADMIN_PASSWORD_MIN_LENGTH} caracteres`);
  return { valid: errors.length === 0, errors, strength: errors.length ? (base.strength === 'strong' ? 'medium' : base.strength) : 'strong' };
}

export function changePasswordFormError(current: string, next: string, confirm: string): string | null {
  if (!current) return 'Informe a senha atual.';
  const check = validateAdminPassword(next);
  if (!check.valid) return `Nova senha: ${check.errors.join(', ').toLowerCase()}.`;
  if (next !== confirm) return 'A confirmação não confere com a nova senha.';
  if (next === current) return 'A nova senha precisa ser diferente da atual.';
  return null;
}
