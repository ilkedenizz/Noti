import { onRequest } from 'firebase-functions/v2/https';
import { getMessaging, Message } from 'firebase-admin/messaging';
import cors from 'cors';
import { SendAlertRequestPayload, SendAlertSuccessResponse, SendAlertErrorResponse } from './types';
import { checkRateLimit } from './rateLimiter';

const corsHandler = cors({ origin: true });

export const sendNotiAlert = onRequest({ region: 'us-central1' }, (req, res) => {
  return corsHandler(req, res, async () => {
    // Only allow HTTP POST
    if (req.method !== 'POST') {
      res.status(405).json({
        success: false,
        error: 'Method Not Allowed. Use POST.',
        code: 'METHOD_NOT_ALLOWED',
      } as SendAlertErrorResponse);
      return;
    }

    try {
      const body = req.body as Partial<SendAlertRequestPayload>;

      // 1. Mandatory Payload Validation
      if (!body.recipientToken || body.recipientToken.trim() === '') {
        res.status(400).json({
          success: false,
          error: 'MISSING_RECIPIENT_TOKEN: recipientToken is required.',
          code: 'INVALID_PAYLOAD',
        } as SendAlertErrorResponse);
        return;
      }

      if (!body.alertId || body.alertId.trim() === '') {
        res.status(400).json({
          success: false,
          error: 'MISSING_ALERT_ID: alertId must be generated and supplied by sender.',
          code: 'INVALID_PAYLOAD',
        } as SendAlertErrorResponse);
        return;
      }

      if (!body.senderId || !body.senderUsername || !body.recipientId || !body.recipientUsername) {
        res.status(400).json({
          success: false,
          error: 'MISSING_USER_METADATA: senderId, senderUsername, recipientId, and recipientUsername are required.',
          code: 'INVALID_PAYLOAD',
        } as SendAlertErrorResponse);
        return;
      }

      if (!body.title || !body.message) {
        res.status(400).json({
          success: false,
          error: 'MISSING_MESSAGE_CONTENT: title and message are required.',
          code: 'INVALID_PAYLOAD',
        } as SendAlertErrorResponse);
        return;
      }

      const rawPriority = (body.priority ?? 'NORMAL').toString().toUpperCase();
      if (rawPriority !== 'NORMAL' && rawPriority !== 'EMERGENCY') {
        res.status(400).json({
          success: false,
          error: 'INVALID_PRIORITY: priority must be either NORMAL or EMERGENCY.',
          code: 'INVALID_PRIORITY',
        } as SendAlertErrorResponse);
        return;
      }

      const priority = rawPriority as 'NORMAL' | 'EMERGENCY';
      const createdAt = body.createdAt ?? new Date().toISOString();

      // 2. Authentication Check Hook (Prepared for Firebase Auth / request.auth)
      const authHeader = req.headers.authorization;
      if (process.env.REQUIRE_AUTH === 'true' && !authHeader) {
        res.status(401).json({
          success: false,
          error: 'UNAUTHORIZED: Authentication token required.',
          code: 'UNAUTHORIZED',
        } as SendAlertErrorResponse);
        return;
      }

      // 3. Rate Limiting Check
      const rateCheck = checkRateLimit(body.senderId);
      if (!rateCheck.allowed) {
        res.status(429).json({
          success: false,
          error: 'RATE_LIMIT_EXCEEDED: Too many alert requests. Please wait before retrying.',
          code: 'TOO_MANY_REQUESTS',
        } as SendAlertErrorResponse);
        return;
      }

      // 4. Construct FCM Message Payload
      const messagePayload: Message = {
        token: body.recipientToken,
        data: {
          alertId: body.alertId,
          senderId: body.senderId,
          senderUsername: body.senderUsername,
          recipientId: body.recipientId,
          recipientUsername: body.recipientUsername,
          title: body.title,
          message: body.message,
          priority: priority,
          createdAt: createdAt,
        },
        android: {
          priority: 'high',
          notification: {
            title: `[${priority}] ${body.title}`,
            body: `From ${body.senderUsername}: ${body.message}`,
            channelId: priority === 'EMERGENCY' ? 'noti_emergency' : 'default',
            sound: 'default',
          },
        },
      };

      // 5. Dispatch FCM Message via Firebase Admin SDK
      const messageId = await getMessaging().send(messagePayload);

      res.status(200).json({
        success: true,
        messageId: messageId,
        alertId: body.alertId,
        priority: priority,
        timestamp: new Date().toISOString(),
      } as SendAlertSuccessResponse);

    } catch (error: any) {
      console.error('> SEND_NOTI_ALERT_ERROR:', error);
      res.status(500).json({
        success: false,
        error: 'INTERNAL_SERVER_ERROR: Failed to dispatch FCM alert signal.',
        code: 'DISPATCH_FAILED',
      } as SendAlertErrorResponse);
    }
  });
});
