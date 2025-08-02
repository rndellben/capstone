"""
Test script for the direct FCM implementation
"""
import os
import sys
import logging
import json
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, db
from auth_app.views.fcm_direct import FCMDirectSender

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def test_fcm_direct():
    """Test the direct FCM implementation"""
    # Load environment variables
    load_dotenv()
    
    # Create Firebase config from environment variables
    firebase_config = {
        "type": os.getenv('FIREBASE_TYPE', 'service_account'),
        "project_id": os.getenv('FIREBASE_PROJECT_ID'),
        "private_key_id": os.getenv('FIREBASE_PRIVATE_KEY_ID'),
        "private_key": os.getenv('FIREBASE_PRIVATE_KEY').replace('\\n', '\n') if os.getenv('FIREBASE_PRIVATE_KEY') else None,
        "client_email": os.getenv('FIREBASE_CLIENT_EMAIL'),
        "client_id": os.getenv('FIREBASE_CLIENT_ID'),
        "auth_uri": os.getenv('FIREBASE_AUTH_URI', 'https://accounts.google.com/o/oauth2/auth'),
        "token_uri": os.getenv('FIREBASE_TOKEN_URI', 'https://oauth2.googleapis.com/token'),
        "auth_provider_x509_cert_url": os.getenv('FIREBASE_AUTH_PROVIDER_X509_CERT_URL', 'https://www.googleapis.com/oauth2/v1/certs'),
        "client_x509_cert_url": os.getenv('FIREBASE_CLIENT_X509_CERT_URL'),
        "universe_domain": os.getenv('FIREBASE_UNIVERSE_DOMAIN', 'googleapis.com')
    }
    
    # Check if we have the required config
    if not firebase_config["project_id"] or not firebase_config["private_key"]:
        logger.error("Missing required Firebase configuration")
        return False
    
    logger.info(f"Testing direct FCM implementation with project: {firebase_config['project_id']}")
    
    try:
        # Initialize Firebase
        if not firebase_admin._apps:
            cred = credentials.Certificate(firebase_config)
            firebase_admin.initialize_app(cred, {
                'databaseURL': f"https://{firebase_config['project_id']}-default-rtdb.asia-southeast1.firebasedatabase.app"
            })
            logger.info("Firebase initialized successfully")
        
        # Get a test user with FCM tokens
        users_ref = db.reference('users')
        users = users_ref.get()
        
        if not users:
            logger.error("No users found in database")
            return False
        
        # Find a user with FCM tokens
        test_user_id = None
        test_token = None
        
        for user_id, user_data in users.items():
            if 'fcm_tokens' in user_data and user_data['fcm_tokens']:
                test_user_id = user_id
                # Get the first token
                for token_data in user_data['fcm_tokens'].values():
                    if isinstance(token_data, dict) and 'token' in token_data:
                        test_token = token_data['token']
                        break
                if test_token:
                    break
        
        if not test_user_id or not test_token:
            logger.error("No users with FCM tokens found")
            return False
        
        logger.info(f"Found test user: {test_user_id}")
        logger.info(f"Found test token: {test_token[:10]}...")
        
        # Initialize the direct FCM sender
        fcm_sender = FCMDirectSender(firebase_config)
        
        # Test sending a message
        result = fcm_sender.send_message(
            test_token,
            "Test Direct FCM",
            "This is a test message from the direct FCM implementation",
            {"test_key": "test_value"}
        )
        
        logger.info(f"FCM direct send result: {json.dumps(result, indent=2)}")
        
        if result.get("success", False):
            logger.info("Direct FCM test successful!")
            return True
        else:
            logger.error(f"Direct FCM test failed: {result.get('error')}")
            return False
            
    except Exception as e:
        logger.error(f"Error testing direct FCM: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_fcm_direct()
    if success:
        logger.info("Direct FCM implementation test completed successfully")
        sys.exit(0)
    else:
        logger.error("Direct FCM implementation test failed")
        sys.exit(1)