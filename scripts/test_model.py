"""Rooktest: roept het uitgerolde model aan via het Foundry-project, zonder API-key.

Draaien vanuit de root van de repo:
    uv run --env-file .azure/dev/.env scripts/test_model.py
"""

import os

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

endpoint = os.environ["AZURE_AI_PROJECT_ENDPOINT"]
deployment = os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"]

project = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
openai = project.get_openai_client()

response = openai.responses.create(
    model=deployment,
    input="Leg in één zin uit wat Microsoft Foundry is.",
)

if not response.output_text.strip():
    raise RuntimeError("Het model gaf een leeg antwoord.")

print(f"Model:    {deployment}")
print(f"Antwoord: {response.output_text}")
print(f"Tokens:   {response.usage.input_tokens} in, {response.usage.output_tokens} uit")
