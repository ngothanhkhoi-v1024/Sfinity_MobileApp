/** JSON shape aligned with NestJS default HttpException responses */
export class HttpError extends Error {
  readonly statusCode: number;
  readonly payload: {
    statusCode: number;
    message: string | string[];
    error: string;
  };

  constructor(statusCode: number, message: string | string[], error: string) {
    const msg = Array.isArray(message) ? message.join(', ') : message;
    super(msg);
    this.statusCode = statusCode;
    this.payload = { statusCode, message, error };
    this.name = 'HttpError';
  }
}
