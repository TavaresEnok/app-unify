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
