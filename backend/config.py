import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # MongoDB
    MONGO_URL: str = os.getenv("MONGO_URL", "mongodb://localhost:27017")
    MONGO_DB_NAME: str = os.getenv("MONGO_DB_NAME", "clinicai")

    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "clinicai-super-secret-jwt-key-change-in-production")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_DAYS: int = 7

    # Vapi
    VAPI_API_KEY: str = os.getenv("VAPI_API_KEY", "")
    VAPI_ASSISTANT_ID: str = os.getenv("VAPI_ASSISTANT_ID", "")
    VAPI_SERVER_SECRET: str = os.getenv("VAPI_SERVER_SECRET", "vapi-mock-secret-12345")
    BACKEND_URL: str = os.getenv("BACKEND_URL", "https://clinicai-4zu2.onrender.com")

    # Cal.com
    CALCOM_API_KEY: str = os.getenv("CALCOM_API_KEY", "")
    CALCOM_BASE_URL: str = "https://api.cal.com/v1"

    # Twilio
    TWILIO_ACCOUNT_SID: str = os.getenv("TWILIO_ACCOUNT_SID", "")
    TWILIO_AUTH_TOKEN: str = os.getenv("TWILIO_AUTH_TOKEN", "")
    TWILIO_FROM_NUMBER: str = os.getenv("TWILIO_FROM_NUMBER", "+15005550006")

    # Anthropic / Claude
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")

    # Feature flags
    USE_MOCK_EXTERNAL: bool = os.getenv("USE_MOCK_EXTERNAL", "false").lower() == "true"

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
