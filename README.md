# Umami on Azure 🚀

[![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=flat&logo=microsoft-azure&logoColor=white)](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
[![Umami](https://img.shields.io/badge/Umami-FF6B35?style=flat&logo=umami&logoColor=white)](https://umami.is/)

## 📋 Overview

This repository provides a complete, automated infrastructure-as-code solution for hosting **Umami**, a privacy-focused, open-source web analytics platform, in Microsoft Azure.
Designed as a modern alternative to Google Analytics, this setup prioritizes data privacy, security, and full organizational control over analytics data.

The entire deployment is orchestrated using **Azure Bicep templates**, ensuring reproducible, maintainable, and scalable infrastructure provisioning.

### 🏗️ Architecture Highlights

- **🔧 Infrastructure as Code**: All resources defined using Azure Bicep for maintainable, version-controlled infrastructure
- **🐳 Containerized Deployment**: Umami runs on Azure App Service with Linux containers for optimal performance and scalability  
- **🔒 Network Security**: Isolated deployment using Azure Virtual Networks with private DNS and secure connectivity
- **🌐 Hybrid Connectivity**: Point-to-Site VPN Gateway with Azure AD authentication for secure on-premises access
- **🔍 DNS Resolution**: Azure DNS Private Resolver for seamless name resolution between on-premises and Azure resources
- **📊 Privacy-First Analytics**: Complete data ownership with GDPR-compliant analytics platform

This solution is perfect for organizations seeking enterprise-grade analytics without compromising on data privacy or control.

## 🚀 Quick Start

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- Active Azure subscription with appropriate permissions

### Deployment Steps

1. **Authenticate with Azure**

   ```pwsh
   az login
   ```

2. **Deploy the Infrastructure**

   ```pwsh
   az deployment sub create --location <your-azure-region> -f ./deployUmami.bicep -p ./parameters/local.bicepparam
   ```

   > Replace `<your-azure-region>` with your preferred Azure region (e.g., `swedencentral`)

3. **Resource Provisioning**

   The deployment automatically provisions:
   - Azure App Service with Linux container
   - PostgreSQL Flexible Server database
   - Virtual Network with private endpoints
   - Point-to-Site VPN Gateway with Azure AD authentication
   - DNS Private Resolver for hybrid name resolution
   - Supporting networking infrastructure

> ⚠️ **Environment Notice**: This configuration currently deploys a local/development environment. Production and staging environments will be supported in future releases.

## 🐳 Local Development with Docker Compose

For local development and testing, you can run Umami using Docker Compose. The Docker Compose configuration is based on the official Umami repository with minor modifications for increased reusability and flexibility.

### Prerequisites

- [Docker](https://www.docker.com/get-started) and Docker Compose installed
- Git for cloning the repository

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/Physer/umami-setup
   cd umami-setup
   ```

2. **Configure environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit the `.env` file with your configuration:
   - Set database credentials
   - Configure application settings
   - Adjust any other environment-specific variables

3. **Start the services**

   ```bash
   docker compose up -d
   ```

4. **Access Umami**

   Once started, Umami will be available at `http://localhost:3000`

5. **Stop the services**

   ```bash
   docker compose down
   ```

## 🔐 Secrets Management with Azure Key Vault

This project integrates **Azure Key Vault** for secure, centralized management of application secrets and sensitive configuration values. Secrets are not stored in source control or parameter files, but are managed directly in Azure Key Vault and injected into the application at runtime.

### How It Works

- Secrets required by Umami (such as database credentials, API keys, etc.) are stored in Azure Key Vault.
- The infrastructure and App Service are configured to reference these secrets securely using managed identity.
- A helper script, [`sync-keyvault-secrets.sh`](./sync-keyvault-secrets.sh), is provided to automate uploading secrets from a local file to your Azure Key Vault.

### Using the Key Vault Sync Script

You can quickly sync secrets from a local `.env.keyvault` file to your Azure Key Vault using the provided script. This is especially useful for initial setup or when rotating secrets.

#### 1. Prepare Your Secrets File

Copy the provided `.env.keyvault.example` file to `.env.keyvault` in the project root. Each line should be in `KEY=VALUE` format. The example file lists all required secret keys—fill in the values for your environment.

#### 2. Run the Sync Script

Make sure you are logged in to Azure CLI and have access to the target Key Vault:

```bash
az login
```

Then run the script, specifying your Key Vault name (and optionally the env file):

```bash
./sync-keyvault-secrets.sh <your-keyvault-name> [.env.keyvault]
```

Example:

```bash
./sync-keyvault-secrets.sh my-keyvault-dev
```

The script will upload each secret to the specified Key Vault. It will report any failures and a summary at the end.

> **Note:** The script requires Bash (Linux/macOS or WSL on Windows) and Azure CLI installed.

#### 3. Reference Secrets in Bicep/Parameters

The Bicep templates are designed to reference secrets from Key Vault using the `@Microsoft.KeyVault` syntax in parameter files, or by configuring App Service to use Key Vault references for environment variables.

No secrets are stored in source control or plain text parameter files.

---

## 🔐 VPN Connectivity

The infrastructure includes a Point-to-Site VPN Gateway that enables secure connectivity from on-premises machines to the Azure Virtual Network. This allows direct access to private resources and seamless integration with existing corporate networks.

### VPN Features

- **🔑 Azure AD Authentication**: Secure authentication using your organization's Azure Active Directory
- **🌐 OpenVPN Protocol**: Modern, secure VPN protocol with cross-platform client support
- **🔍 DNS Resolution**: Integrated DNS Private Resolver for seamless name resolution between on-premises and Azure
- **📱 Multi-Platform Support**: Compatible with Windows, macOS, iOS, and Android devices

### Connecting to the VPN

1. **Download VPN Client Configuration**

   After deployment, download the VPN client configuration from the Azure portal:

   ```pwsh
   # Get the VPN client configuration URL
   az network vnet-gateway vpn-client generate --name <gateway-name> --resource-group <resource-group> --authentication-method EAPTLS
   ```

2. **Install VPN Client**

   - **Windows/macOS/Linux**: Use the Azure VPN Client or OpenVPN client
   - **Mobile**: Use the Azure VPN Client app from your device's app store

3. **Import Configuration**

   Import the downloaded configuration file into your VPN client and connect using your Azure AD credentials.

### DNS Configuration

The DNS Private Resolver automatically handles name resolution for:

- Azure private endpoints (PostgreSQL, App Service)
- On-premises resources (forwarded to your corporate DNS)
- Cross-network connectivity scenarios

> 💡 **Note**: VPN connectivity is particularly useful for development teams, database administration, and secure access to private Azure resources without exposing them to the public internet.

## ✨ Current Features

- ✅ **Automated Infrastructure Provisioning** - Complete resource deployment using Bicep templates
- ✅ **Azure CLI Integration** - Streamlined deployment via command-line interface with parameter files  
- ✅ **Virtual Network Security** - Isolated network architecture with private endpoint connectivity
- ✅ **Hybrid Connectivity** - Point-to-Site VPN Gateway with Azure AD authentication for secure on-premises access
- ✅ **DNS Resolution** - Azure DNS Private Resolver for seamless name resolution between networks
- ✅ **Container-Based Hosting** - Modern Linux container deployment on Azure App Service
- ✅ **Local Development Setup** - Docker Compose configuration for streamlined local development and testing
- ✅ **Application Monitoring** - Azure Application Insights integration for comprehensive observability

## 🛣️ Roadmap

The following enhancements are planned to expand and improve the platform:

### 🔧 Development & Operations

- **🔄 CI/CD Automation** – Automated deployment pipelines for staging and production environments

### 🔐 Security & Configuration

- **✅ Secrets Management** – Azure Key Vault integration for secure credential handling (**Completed**)
- **🌐 Custom Domains** – Support for custom domain configuration via Bicep automation
- **🛡️ Access Control** – IP whitelisting and Entra ID managed identity integration
- **🔒 Site-to-Site VPN** – Extension to support site-to-site VPN connections for branch offices
- **📡 ExpressRoute Integration** – Support for dedicated network connections via Azure ExpressRoute
- **🔄 Secret Rotation Automation** – Automated workflows for rotating and syncing secrets between environments

### 🚀 Advanced Deployment

- **⚡ Zero-Downtime Updates** – Sidecar deployment pattern implementation
- **🔒 Enhanced Security** – Advanced network isolation and access restrictions

---

## 📞 Support

For questions, issues, or contributions, please open an issue in this repository.

## 📄 License

This project is open-source. Please review the license file for details.
