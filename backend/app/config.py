from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_api_key: str = ""

    openai_api_key: str = ""
    whisper_model: str = "whisper-1"

    anthropic_api_key: str = ""
    claude_model: str = "claude-opus-5"

    airtable_token: str = ""
    airtable_base_id: str = ""
    airtable_table: str = "Reuniones"

    # Whisper rechaza archivos de mas de 25 MB.
    max_audio_bytes: int = 25 * 1024 * 1024


@lru_cache
def get_settings() -> Settings:
    return Settings()
