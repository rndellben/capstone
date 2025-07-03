from firebase_admin import messaging
from firebase_admin import db
import logging
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from datetime import datetime

logger = logging.getLogger(__name__)

def send_fcm_notification(user_id, title, body, data=None):
    """Send FCM notification to a user's devices"""
    try:
        logger.info(f"Attempting to send FCM notification for user_id: {user_id}")
        # Get user's FCM tokens
        user_ref = db.reference(f'users/{user_id}/fcm_tokens')
        tokens = user_ref.get()
        
        if not tokens:
            logger.warning(f"No FCM tokens found for user {user_id}")
            return False
            
        # Extract the 'token' field from each token dict
        token_list = [
            str(token_info['token'])
            for token_info in tokens.values()
            if isinstance(token_info, dict) and token_info.get('token')
        ]
        
        if not token_list:
            logger.warning(f"No valid FCM tokens found for user {user_id}")
            return False
        
        if len(token_list) == 1:
            # Send to a single token
            message = messaging.Message(
                data=data or {},
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                token=token_list[0]
            )
            response = messaging.send(message)
            logger.info(f"Sent FCM notification with message ID: {response} for user_id: {user_id}")
            return True
        else:
            # Send to multiple tokens
            message = messaging.MulticastMessage(
                data=data or {},
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                tokens=token_list
            )
            response = messaging.send_multicast(message)
            if hasattr(response, 'failure_count') and response.failure_count > 0:
                logger.warning(f"Some notifications failed to send: {response.failure_count} failures for user_id: {user_id}")
            return getattr(response, 'success_count', 0) > 0
    
    except Exception as e:
        logger.error(f"Error sending FCM notification for user_id {user_id}: {str(e)}")
        return False

def should_send_notification(alert_type, current_value, threshold_value):
    """Determine if a notification should be sent based on alert type and values"""
    try:
        if alert_type == 'high':
            return float(current_value) > float(threshold_value)
        elif alert_type == 'low':
            return float(current_value) < float(threshold_value)
        return False
    except (ValueError, TypeError):
        return False

def notify_alert_update(user_id, alert_id, message, alert_type):
    """Notify WebSocket clients about alert updates"""
    try:
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"user_{user_id}",
            {
                "type": "alert.update",
                "message": {
                    "alert_id": alert_id,
                    "message": message,
                    "alert_type": alert_type,
                    "timestamp": datetime.now().isoformat()
                }
            }
        )
    except Exception as e:
        logger.error(f"Error sending WebSocket notification: {str(e)}")

def user_prefers_notification(user_id, alert_type):
    """Check if the user has enabled notifications for the given alert type."""
    try:
        user_prefs_ref = db.reference(f'users/{user_id}/notification_preferences')
        user_prefs = user_prefs_ref.get() or {}
        # Map alert_type to the correct preference key
        pref_key = {
            'ph': 'ph_level_alerts_enabled',
            'ec': 'ec_alerts_enabled',
            'temperature': 'temperature_alerts_enabled',
            'humidity': 'humidity_alerts_enabled',
            'water_level': 'water_level_alerts_enabled',
            # Add more mappings as needed
        }.get(alert_type, None)
        if pref_key is None:
            return True  # Default to True if unknown type
        return user_prefs.get(pref_key, True)
    except Exception:
        return True  # Default to True on error 