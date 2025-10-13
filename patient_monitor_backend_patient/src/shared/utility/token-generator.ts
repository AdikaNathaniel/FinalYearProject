import jwt from 'jsonwebtoken';
import config from 'config';

const jwtSecret = config.has('JWT_SECRET')
  ? config.get<string>('JWT_SECRET')
  : 'dev_secret_key';

export const generateAuthToken = (id: string) => {
  return jwt.sign({ id }, jwtSecret, { expiresIn: '30d' });
};

export const decodeAuthToken = (token: string) => {
  return jwt.verify(token, jwtSecret);
};
