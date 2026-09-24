# foundry-landing-zone

Een Microsoft Foundry-omgeving die volledig uit code ontstaat: Bicep voor de resources, `azd` om ze uit te rollen, en GitHub Actions met OIDC om het zonder secrets vanuit CI te doen. Geen API-keys, rechten volgens least privilege, tracing en een budget vanaf dag één.

> Hoort bij domein 1 van AI-103 (*Plan and manage an Azure AI solution*). De [cv-agent](https://github.com/Dennisvw85/cv-agent) draait als workload bovenop deze landing zone.

## Wat er staat

| Onderdeel | Bestand | Waarom |
|---|---|---|
| Resource group + Foundry-account (`kind: AIServices`) | `infra/main.bicep`, `infra/foundry.bicep` | Nieuwe generatie Foundry, niet de classic hub |
| Foundry-project `proj-dev` | `infra/foundry.bicep` | De werkruimte voor agents, evaluaties en bestanden |
| Model `gpt-4.1-mini` (GlobalStandard, 30K TPM, geen auto-upgrade) | `infra/foundry.bicep` | Goedkoopste deploymenttype met quotum; versie verandert niet stilletjes |
| Keyless: `disableLocalAuth: true` | `infra/foundry.bicep` | Alleen Entra ID, er bestaan geen keys die kunnen lekken |
| Rol **Foundry User** voor wie uitrolt | `infra/foundry.bicep` | Owner beheert resources (control plane) maar mag het model niet aanroepen (data plane) |
| Log Analytics + Application Insights, gekoppeld aan het project | `infra/monitoring.bicep` | Tracing in de Foundry-portal; 30 dagen retentie en max. 1 GB/dag als kostenrem |
| Budget van €50/maand met alerts op 50%, 80% en 100% forecast | `infra/main.bicep` | Waarschuwt ruim voor de spending limit van de subscription |
| CI/CD-identiteit (managed identity + federated credential) | `infra/bootstrap/` | GitHub Actions logt in via OIDC, zonder opgeslagen secret |
| Workflow: valideren bij elke push, uitrollen op knopdruk | `.github/workflows/infra.yml` | Bicep wordt altijd gecontroleerd; Azure alleen geraakt als ik het wil |
| Rooktest in Python | `scripts/test_model.py` | "Deployment geslaagd" betekent niet "werkt" |

Bewust **niet** gebouwd: private networking. Het endpoint is publiek bereikbaar, maar alleen met een geldig Entra-token. Voor productie zijn de templates `10`-`19` in foundry-samples het startpunt.

## De keuzes

- **Nieuwe generatie Foundry, niet hub-based.** `Microsoft.CognitiveServices/accounts` met `kind: AIServices` en projecten als child. De classic hub (`MachineLearningServices/workspaces`) gebruikt de Assistants API; verwisselen geeft 404's.
- **Deterministische namen.** `uniqueString(subscription, omgeving, regio, revisie)` in plaats van `utcNow()`, zoals het officiële template doet. Opnieuw uitrollen past dezelfde resources aan in plaats van nieuwe aan te maken.
- **De resource group in `main.bicep`, de rest in modules.** Eén Bicep-bestand heeft één scope; de module wisselt van subscription naar resource group. Daardoor ruimt `azd down` alles in één keer op.
- **Geen ID's in de repo.** `main.parameters.json` bevat alleen `${AZURE_...}`-verwijzingen die `azd` lokaal of in CI invult.
- **Managed identity voor CI in plaats van een app-registratie.** In de tenant waar dit draait mogen gebruikers geen app-registraties maken. Een user-assigned managed identity is een gewone Azure-resource en ondersteunt ook federated credentials.
- **Least privilege voor CI.** Contributor om resources te maken, plus RBAC Administrator met een *conditie*: de identiteit mag alleen de rol Foundry User toewijzen, niets anders.

## Hoe je het draait

```bash
azd auth login
azd env new dev --subscription <subscription-id> --location swedencentral
azd env set AZURE_BUDGET_EMAIL <jouw-e-mail>   # optioneel: zonder e-mail geen budget
azd provision --preview                         # what-if, verandert niets
azd up
uv run --env-file .azure/dev/.env scripts/test_model.py
```

CI eenmalig inrichten: rol `infra/bootstrap/cicd.bicep` uit met je GitHub-owner, repo en hun numerieke ID's (zie het commentaar in het bestand), maak een GitHub-environment `dev` met de secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` en `AZURE_SUBSCRIPTION_ID`, en start de workflow met **Run workflow**.

## Valkuilen

Wat onderweg een middag kostte, of had kunnen kosten:

1. **Project en model tegelijk uitrollen geeft `RequestConflict`.** Een Foundry-account accepteert één wijziging tegelijk. Oplossing: de modeldeployment `dependsOn` het project, zoals Microsoft in template `10-private-network-basic` doet.
2. **`.gitignore` negeerde `*.parameters.json`.** Standaard voor ARM-projecten, maar `azd` heeft `main.parameters.json` nodig en er staat hier niets geheims in. Uitzondering met `!infra/main.parameters.json`.
3. **Na `azd down --purge` en opnieuw uitrollen gaf de Responses API urenlang `404 Project not found`.** ARM zei `Succeeded` en andere project-API's werkten gewoon. Bewezen oorzaak: het hergebruiken van de accountnaam na een purge. Een account met een nieuwe naam werkte binnen twee minuten. Oplossing: de parameter `revision` (`AZURE_RESOURCE_REVISION`) gaat mee in de naam; verhoog hem na een purge.
4. **App-registraties waren niet toegestaan in de tenant.** `azd pipeline config` loopt daarop vast. Managed identity met federated credential is het alternatief.
5. **GitHub zet in nieuwe repo's ID's in het OIDC-subject.** Niet `repo:owner/repo:environment:dev` maar `repo:owner@<id>/repo@<id>:environment:dev`. De meeste documentatie toont nog het oude formaat; de fout is `AADSTS700213`.
6. **Owner is niet genoeg om een model aan te roepen.** Met `disableLocalAuth` en zonder data-plane-rol krijg je 401/403 in de playground.

## Bronnen

- [microsoft-foundry/foundry-samples](https://github.com/microsoft-foundry/foundry-samples): genummerde infrastructure-setups (00-05 basis, 10-19 private networking, 20-25 identity, 30-32 customer-managed keys, 40-45 agents)
- [Azure/AI-Landing-Zones](https://github.com/Azure/AI-Landing-Zones): productie-referentiearchitectuur op Azure Verified Modules
- [Foundry-documentatie](https://learn.microsoft.com/azure/foundry/): let op de docs-boom, `azure/foundry` is actueel, `azure/foundry-classic` en `azure/ai-foundry` zijn ouder
