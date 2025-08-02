"""
Script to verify Firebase configuration and FCM functionality
"""
import os
import sys
import logging
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, messaging

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def verify_firebase_config():
    """Verify Firebase configuration from environment variables"""
    load_dotenv()
    
    # Check required environment variables
    required_vars = [
        'FIREBASE_PROJECT_ID', 
        'FIREBASE_PRIVATE_KEY_ID',
        'FIREBASE_PRIVATE_KEY',
        'FIREBASE_CLIENT_EMAIL',
        'FIREBASE_CLIENT_ID',
        'FIREBASE_CLIENT_X509_CERT_URL'
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        logger.error(f"Missing required environment variables: {', '.join(missing_vars)}")
        return False
    
    # Create Firebase config from environment variables
    firebase_config = {
        "type": os.getenv('FIREBASE_TYPE', 'service_account'),
        "project_id": os.getenv('FIREBASE_PROJECT_ID'),
        "private_key_id": os.getenv('FIREBASE_PRIVATE_KEY_ID'),
        "private_key": os.getenv('FIREBASE_PRIVATE_KEY').replace('\\n', '\n'),
        "client_email": os.getenv('FIREBASE_CLIENT_EMAIL'),
        "client_id": os.getenv('FIREBASE_CLIENT_ID'),
        "auth_uri": os.getenv('FIREBASE_AUTH_URI', 'https://accounts.google.com/o/oauth2/auth'),
        "token_uri": os.getenv('FIREBASE_TOKEN_URI', 'https://oauth2.googleapis.com/token'),
        "auth_provider_x509_cert_url": os.getenv('FIREBASE_AUTH_PROVIDER_X509_CERT_URL', 'https://www.googleapis.com/oauth2/v1/certs'),
        "client_x509_cert_url": os.getenv('FIREBASE_CLIENT_X509_CERT_URL'),
        "universe_domain": os.getenv('FIREBASE_UNIVERSE_DOMAIN', 'googleapis.com')
    }
    
    logger.info(f"Firebase project ID: {firebase_config['project_id']}")
    logger.info(f"Firebase client email: {firebase_config['client_email']}")
    
    try:
        # Try to initialize Firebase
        if not firebase_admin._apps:
            cred = credentials.Certificate(firebase_config)
            firebase_admin.initialize_app(cred, {
                'databaseURL': f"https://{firebase_config['project_id']}-default-rtdb.asia-southeast1.firebasedatabase.app"
            })
            logger.info("Firebase initialized successfully")
        
        # Test FCM functionality
        test_message = messaging.Message(
            notification=messaging.Notification(
                title='Test Notification',
                body='This is a test notification from HydroZap'
            ),
            token='test_token_not_valid'
        )
        
        try:
            # This will fail with an invalid token error, which is expected
            messaging.send(test_message)
        except messaging.UnregisteredError:
            # This is the expected error for an invalid token
            logger.info("FCM test successful - received expected UnregisteredError for invalid token")
            return True
        except Exception as e:
            if "Requested entity was not found" in str(e):
                # This is also an expected error for an invalid token
                logger.info("FCM test successful - received expected error for invalid token")
                return True
            else:
                logger.error(f"FCM test failed with unexpected error: {str(e)}")
                return False
            
    except Exception as e:
        logger.error(f"Firebase initialization failed: {str(e)}")
        return False

if __name__ == "__main__":
    success = verify_firebase_config()
    if success:
        logger.info("Firebase configuration verification completed successfully")
        sys.exit(0)
    else:
        logger.error("Firebase configuration verification failed")
        sys.exit(1)