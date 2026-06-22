import { HttpError } from '../http-error';

describe('HttpError', () => {
  it('should construct error with single string message', () => {
    const error = new HttpError(400, 'Bad Request Msg', 'Bad Request');
    expect(error.statusCode).toBe(400);
    expect(error.message).toBe('Bad Request Msg');
    expect(error.name).toBe('HttpError');
    expect(error.payload).toEqual({
      statusCode: 400,
      message: 'Bad Request Msg',
      error: 'Bad Request',
    });
  });

  it('should construct error with array message and join with comma', () => {
    const messages = ['email is invalid', 'password too short'];
    const error = new HttpError(422, messages, 'Unprocessable Entity');
    expect(error.statusCode).toBe(422);
    expect(error.message).toBe('email is invalid, password too short');
    expect(error.payload).toEqual({
      statusCode: 422,
      message: messages,
      error: 'Unprocessable Entity',
    });
  });
});
