"""
Direct FCM HTTP v1 implementation to bypass Firebase Admin SDK issues
"""
import requests
import time
import json
import logging
from google.oauth2 import service_account
from google.auth.transport.requests import Request

logger = logging.getLogger(__name__)

class FCMDirectSender:
    """
    Direct FCM sender using HTTP v1 API
    Bypasses the Firebase Admin SDK which is having issues with the batch endpoint
    """
    
    def __init__(self, firebase_config):
        """Initialize with Firebase config dict"""
        self.firebase_config = firebase_config
        self.project_id = firebase_config.get('project_id')
        self._access_token = None
        self._token_expiry = 0
        
    def _get_access_token(self):
        """Get a Google OAuth access token for FCM API"""
        # Check if we have a valid token
        now = int(time.time())
        if self._access_token and now < self._token_expiry:
            return self._access_token
            
        try:
            # Create credentials from service account info
            credentials = service_account.Credentials.from_service_account_info(
                self.firebase_config,
                scopes=['https://www.googleapis.com/auth/firebase.messaging']
            )
            
            # Refresh the token
            request = Request()
            credentials.refresh(request)
            
            # Store token and expiry
            self._access_token = credentials.token
            self._token_expiry = now + 3500  # Expire a bit before the actual 1 hour
            
            return self._access_token
        except Exception as e:
            logger.error(f"Error getting access token: {str(e)}")
            return None
    
    def send_message(self, token, title, body, data=None):
        """Send a single FCM message"""
        access_token = self._get_access_token()
        if not access_token:
            return {"error": "Failed to get access token"}
            
        # Ensure data values are strings
        string_data = {}
        if data:
            for key, value in data.items():
                string_data[key] = str(value)
        
        # Build the message payload
        message = {
            "message": {
                "token": token,
                "notification": {
                    "title": title,
                    "body": body
                },
                "data": string_data,
                "android": {
                    "priority": "high",
                    "notification": {
                        "sound": "default"
                    }
                },
                "apns": {
                    "payload": {
                        "aps": {
                            "sound": "default",
                            "badge": 1,
                            "content-available": 1
                        }
                    }
                }
            }
        }
        
        # Send the request
        url = f"https://fcm.googleapis.com/v1/projects/{self.project_id}/messages:send"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(url, json=message, headers=headers)
            
            if response.status_code == 200:
                return {"success": True, "message_id": response.json().get("name")}
            else:
                logger.error(f"FCM error: {response.status_code} - {response.text}")
                return {"success": False, "error": f"HTTP {response.status_code}: {response.text}"}
                
        except Exception as e:
            logger.error(f"Exception sending FCM message: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def send_multicast(self, tokens, title, body, data=None):
        """Send multiple FCM messages in parallel"""
        if not tokens:
            return {"success_count": 0, "failure_count": 0, "results": []}
            
        results = []
        success_count = 0
        failure_count = 0
        
        for token in tokens:
            result = self.send_message(token, title, body, data)
            results.append(result)
            
            if result.get("success", False):
                success_count += 1
            else:
                failure_count += 1
                
        return {
            "success_count": success_count,
            "failure_count": failure_count,
            "results": results
        }