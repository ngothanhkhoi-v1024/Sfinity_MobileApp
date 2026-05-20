import { plainToInstance } from 'class-transformer';
import { validate, type ValidationError } from 'class-validator';

import { HttpError } from './http-error';

function flattenErrors(errors: ValidationError[]): string[] {
  const messages: string[] = [];
  for (const err of errors) {
    if (err.constraints) {
      messages.push(...Object.values(err.constraints));
    }
    if (err.children?.length) {
      messages.push(...flattenErrors(err.children));
    }
  }
  return messages;
}

export async function validateBody<T extends object>(
  Cls: new () => T,
  body: unknown,
): Promise<T> {
  const instance = plainToInstance(Cls, body ?? {}, {
    enableImplicitConversion: true,
  });
  const errors = await validate(instance as object, {
    whitelist: true,
    forbidNonWhitelisted: true,
  });
  if (errors.length) {
    const messages = flattenErrors(errors);
    throw new HttpError(400, messages, 'Bad Request');
  }
  return instance;
}
