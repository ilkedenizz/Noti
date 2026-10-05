import { initializeApp } from 'firebase-admin/app';

// Initialize Firebase Admin SDK using Application Default Credentials (ADC)
initializeApp();

export { sendNotiAlert } from './sendNotiAlert';
