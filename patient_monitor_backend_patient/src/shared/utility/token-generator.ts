import jwt from 'jsonwebtoken';
import config from 'config';

export const generateAuthToken = (id: string) => {
  return jwt.sign({ id }, config.get('JWT_SECRET'), {
    expiresIn: '30d',
  });
};

export const decodeAuthToken = (token: string) => {
  return jwt.verify(token, config.get('JWT_SECRET'));
};