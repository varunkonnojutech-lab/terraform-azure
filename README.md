# Terraform on Azure — App Service + SQL + Key Vault + Service Bus

[![Build](https://github.com/varunkonnojutech-lab/terraform-azure/actions/workflows/ci.yml/badge.svg)](https://github.com/varunkonnojutech-lab/terraform-azure/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA)](https://www.terraform.io/)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/varunkonnojutech-lab/terraform-azure)

Production-shaped Terraform for a typical .NET workload on Azure: a Linux web
app (.NET 8) with a managed identity, Azure SQL, Key Vault, Service Bus, and
Application Insights — all in one resource group, all tagged per environment.

## Who is this for

Developers who can build apps but have only ever clicked through the Azure
portal — and DevOps-curious engineers who want infrastructure they can review,
version, and reproduce. If "infrastructure as code" is on your resume, this is
the repo that proves it.

## What you'll learn

- **Terraform workflow**: `init` → `plan` → `apply` → `destroy`, the honest way
- **Real Azure resources**: App Service, Azure SQL, Key Vault, Service Bus, Application Insights — wired together
- **Managed identities**: the web app authenticates to Key Vault with no passwords in config
- **Variables and outputs**: reusable, environment-aware modules of your own stack
- **Cost awareness**: low-cost SKUs and the habit of destroying what you don't need

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and an Azure subscription

```bash
az login
```

## Quick start

```bash
git clone https://github.com/varunkonnojutech-lab/terraform-azure.git
cd terraform-azure
terraform init
terraform plan
terraform apply
```

(Codespaces users: click the badge above — Terraform comes preinstalled in the
dev container. You'll still need `az login`, which requires an interactive
browser step.)

Terraform will prompt for `sql_admin_password` (it is marked sensitive).
To avoid typing it, export it instead:

```bash
export TF_VAR_sql_admin_password='YourStrongPassword123!'
terraform apply
```

After apply, Terraform prints the web app URL, SQL server FQDN, Key Vault URI,
and Service Bus namespace name (see `outputs.tf`).

## How it works

Everything lives in one resource group, tagged per environment:

```
azurerm_resource_group
 |
 +-- azurerm_service_plan (Linux, B1)
 |    +-- azurerm_linux_web_app (.NET 8, SystemAssigned identity)
 |
 +-- azurerm_mssql_server (v12.0)
 |    +-- azurerm_mssql_database (S0)
 |
 +-- azurerm_key_vault (Standard)
 |    access policies: deployer (manage) + web app identity (Get/List)
 |
 +-- azurerm_servicebus_namespace (Standard)
 |    +-- azurerm_servicebus_queue ("orders")
 |
 +-- azurerm_application_insights (web)
```

The web app gets a **system-assigned managed identity**, and Key Vault grants
that identity `Get`/`List` on secrets — so the app reads secrets with no
passwords or connection strings in its configuration. Variables (`prefix`,
`environment`, `location`) keep every resource name consistent and let you spin
up `dev`, `qa`, and `prod` copies without editing code.

Useful variables:

| Variable | Default | Purpose |
|---|---|---|
| `prefix` | `orders` | Prefix for every resource name |
| `environment` | `dev` | Used in names and tags (`dev`, `qa`, `prod`) |
| `location` | `eastus` | Azure region |
| `sql_admin_user` | `sqladmin` | SQL Server admin login |
| `sql_admin_password` | `ChangeMe123!` | SQL Server admin password (sensitive) |

## Connecting to SQL Server

No firewall rule is created by default. Add your IP before connecting:

```hcl
resource "azurerm_mssql_firewall_rule" "office" {
  name             = "office"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "<your-public-ip>"
  end_ip_address   = "<your-public-ip>"
}
```

## Cost

The SKUs are deliberately low-cost: **B1** App Service plan, **S0** SQL
database, **Standard** Service Bus and Key Vault. It is still real money while
it exists — run `terraform destroy` when you are done experimenting.

## State

State is local (`terraform.tfstate`, gitignored) which is fine for learning.
For a team, configure a remote backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<state-rg>"
    storage_account_name = "<state-storage>"
    container_name       = "tfstate"
    key                  = "orders.terraform.tfstate"
  }
}
```

## Project structure

```
terraform-azure/
├── versions.tf   # Terraform and azurerm provider version pins
├── variables.tf  # Inputs: prefix, environment, location, SQL credentials
├── main.tf       # Resource group, plan + web app, SQL, Key Vault, Service Bus, App Insights
├── outputs.tf    # URLs and names printed after apply
└── .devcontainer/ # One-click Codespaces setup (Terraform preinstalled)
```

## Next steps

Finish the learning path with [dotnet-advanced](https://github.com/varunkonnojutech-lab/dotnet-advanced) — go deeper than infrastructure into the runtime itself: event sourcing, zero-allocation performance, source generators, and native AOT.

## License

MIT — see [LICENSE](LICENSE).
