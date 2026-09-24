# foundry-landing-zone

Infrastructure-as-code voor een Microsoft Foundry-project dat je zonder aanpassingen aan een klant kunt laten zien: managed identity, keyless authenticatie, RBAC, private networking, en een CI/CD-workflow die het uitrolt.

> Status: in opbouw. Hoort bij blok 1 van AI-103 (*Plan and manage an Azure AI solution*, 25-30% van het examen).

## Het probleem

<!-- Waarom deze repo bestaat. Wat gaat er mis als je een Foundry-project met de standaardinstellingen uitrolt: key-based auth, publiek endpoint, geen scheiding tussen omgevingen, geen kostenzicht. -->

## De keuzes

<!-- Per keuze: wat je gekozen hebt, welk alternatief er was, en waarom. Bijvoorbeeld:
- Nieuwe generatie Foundry (CognitiveServices/account, kind AIServices) en niet hub-based
- Basic of standard agent-setup
- Bicep of Terraform, en waarom niet allebei half
- Standalone of hub-and-spoke deployment mode
-->

## Hoe je het draait

```bash
# vult zich als de eerste template werkt
```

## Valkuilen

<!-- De sectie die deze repo als portfolio laat werken. Wat je onderweg tegenkwam en een middag kostte. -->

## Bronnen

- [microsoft-foundry/foundry-samples](https://github.com/microsoft-foundry/foundry-samples) - genummerde infrastructure-setups (00-05 basis, 10-19 private networking, 20-25 identity, 30-32 customer-managed keys, 40-45 agents)
- [Azure/AI-Landing-Zones](https://github.com/Azure/AI-Landing-Zones) - productie-referentiearchitectuur op Azure Verified Modules
- [Foundry-documentatie](https://learn.microsoft.com/azure/foundry/) - let op de docs-boom: `azure/foundry` is actueel, `azure/foundry-classic` en `azure/ai-foundry` zijn ouder
