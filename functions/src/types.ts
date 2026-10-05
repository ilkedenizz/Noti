export type AlertPriority = 'NORMAL' | 'EMERGENCY';

export interface SendAlertRequestPayload {
  recipientToken: string;
  alertId: string;
  senderId: string;
  senderUsername: string;
  recipientId: string;
  recipientUsername: string;
  title: string;
  message: string;
  priority: AlertPriority;
  createdAt: string;
}

export interface SendAlertSuccessResponse {
  success: true;
  messageId: string;
  alertId: string;
  priority: AlertPriority;
  timestamp: string;
}

export interface SendAlertErrorResponse {
  success: false;
  error: string;
  code: string;
}
