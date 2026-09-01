import os

import pytest

# Las llaves se fijan antes de importar la app para que Settings las tome.
os.environ.update(
    APP_API_KEY="test-key",
    OPENAI_API_KEY="sk-test",
    ANTHROPIC_API_KEY="sk-ant-test",
    AIRTABLE_TOKEN="pat-test",
    AIRTABLE_BASE_ID="appTEST",
    AIRTABLE_TABLE="Reuniones",
)

from fastapi.testclient import TestClient  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def _settings():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def auth():
    return {"X-API-Key": "test-key"}


@pytest.fixture
def meeting_payload():
    return {
        "meta": {
            "title": "Comite semanal",
            "started_at": "2026-09-01T10:00:00",
            "duration_seconds": 1830,
            "participants": ["Ana", "Beto"],
            "questionnaire_id": "default",
            "notes": "",
        },
        "transcript": "Ana propuso revisar el lote 4. Beto queda de enviar el acta.",
        "answers": [
            {
                "question_id": "objetivo",
                "question": "Objetivo de la reunion",
                "answer": "Revisar avance del lote 4",
                "at_second": 42,
            }
        ],
    }
