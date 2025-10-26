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
- **🌍 Custom Domain Support**: Automated custom domain configuration with SSL certificates and DNS management
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

2. **Deploy the Networking Infrastructure**

   ```pwsh
   az deployment sub create --location <your-azure-region> -f ./deployNetwork.bicep -p ./parameters/network/local.bicepparam
   ```

   > Replace `<your-azure-region>` with your preferred Azure region (e.g., `swedencentral`)

3. **Deploy the Azure Key Vault**

   ```pwsh
   az deployment sub create --location <your-azure-region> -f ./deployKeyVault.bicep -p ./parameters/keyvault/local.bicepparam
   ```

4. **Upload Secrets to Azure Key Vault**

   After Key Vault is deployed, upload your secrets before deploying the application infrastructure:

   ```bash
   ./sync-keyvault-secrets.sh <your-keyvault-name> [.env.keyvault]
   ```

   > Fill in `.env.keyvault` with your secret values before running the script.

5. **Deploy the Application Infrastructure**

   ```pwsh
   az deployment sub create --location <your-azure-region> -f ./deployApplication.bicep -p ./parameters/application/local.bicepparam
   ```

6. **Configure Custom Domain (Optional)**

   If you want to use a custom domain instead of the default Azure App Service URL:

   ```pwsh
   # Deploy custom domain configuration
   az deployment group create --resource-group <your-resource-group> -f ./deployCustomDomains.bicep --parameters umamiAppServiceName=<your-app-service-name> customDomainName=<your-domain.com>
   ```

   For Cloudflare DNS management, see the [Custom Domain Setup](#-custom-domain-setup) section below.

7. **Resource Provisioning**

   The deployments will provision:
   - Azure Virtual Network with private endpoints and DNS Private Resolver
   - Point-to-Site VPN Gateway with Azure AD authentication
   - Azure Key Vault for secure secret management
   - Azure App Service with Linux container (secrets injected from Key Vault)
   - PostgreSQL Flexible Server database
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

This project integrates **Azure Key Vault** for secure, centralized management of application secrets and sensitive configuration values. The Key Vault is protected by a private endpoint, restricting access to only resources and users on the private network.

Secrets are not stored in source control or parameter files, but are managed directly in Azure Key Vault and injected into the application at runtime.

### How It Works

- Secrets required by Umami (such as database credentials, API keys, etc.) are stored in Azure Key Vault.
- The infrastructure and App Service are configured to reference these secrets securely using managed identity.
- A helper script, [`sync-keyvault-secrets.sh`](./sync-keyvault-secrets.sh), is provided to automate uploading secrets from a local file to your Azure Key Vault.

### Using the Key Vault Sync Script

You can quickly sync secrets from a local `.env.keyvault` file to your Azure Key Vault using the provided script.

**Note:** Because the Key Vault is protected by a private endpoint, you must run the script from a machine with network access to the private subnet (e.g., via VPN or a VM in the same network). This is especially useful for initial setup or when rotating secrets.

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

Example parameter reference:

```bicep
param umamiAppSecret string = '@Microsoft.KeyVault(SecretUri=https://<your-keyvault-name>.vault.azure.net/secrets/umamiAppSecret/)'
```

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

---

## 🌍 Custom Domain Setup

The infrastructure supports custom domain configuration with automated SSL certificate provisioning through Azure App Service Managed Certificates. This allows you to access your Umami instance using your own domain name with HTTPS encryption.

### Custom Domain Features

- **🔒 Automatic SSL Certificates**: Azure-managed SSL certificates with automatic renewal
- **🌐 DNS Integration**: Automated Cloudflare DNS record management scripts
- **🔧 Bicep Automation**: Infrastructure-as-code approach for domain configuration
- **⚡ Easy Deployment**: Simple command-line deployment of custom domain resources

### Setting Up a Custom Domain

1. **Verify Domain Ownership**

   Before deploying, ensure you have administrative access to your domain's DNS settings.

2. **Deploy Custom Domain Infrastructure**

   ```pwsh
   az deployment group create --resource-group <your-resource-group> -f ./deployCustomDomains.bicep --parameters umamiAppServiceName=<your-app-service-name> customDomainName=<your-domain.com>
   ```

3. **Configure DNS Records**

   For Cloudflare users, automated scripts are provided to manage DNS records:

   ```bash
   # Create .env.cloudflare from the example template
   cp .env.cloudflare.example .env.cloudflare
   
   # Edit .env.cloudflare with your Cloudflare API token and Zone ID
   
   # Create/update DNS record pointing to your App Service
   ./create-cloudflare-dns-records.sh <your-domain.com> CNAME <your-app-service>.azurewebsites.net
   
   # Enable Cloudflare proxy (optional)
   ./proxy-cloudflare-dns-records.sh <your-domain.com> on
   ```

### Cloudflare Integration

The project includes specialized scripts for Cloudflare DNS management:

#### Prerequisites for Cloudflare Scripts

- **Cloudflare API Token**: Create an API token with `Zone:Edit` permissions for your domain
- **Zone ID**: Your Cloudflare Zone ID for the target domain
- **jq**: JSON processor tool for parsing API responses

#### DNS Management Scripts

- **`create-cloudflare-dns-records.sh`**: Creates or updates DNS records (CNAME, A, etc.)
- **`proxy-cloudflare-dns-records.sh`**: Toggles Cloudflare proxy status for enhanced security and performance

#### Configuration

1. **Create Cloudflare Configuration**

   ```bash
   cp .env.cloudflare.example .env.cloudflare
   ```

2. **Edit Configuration File**

   Add your Cloudflare credentials:
   ```bash
   CLOUDFLARE_API_TOKEN=your_api_token_here
   ZONE_ID=your_zone_id_here
   ```

3. **Use the Scripts**

   ```bash
   # Create a CNAME record
   ./create-cloudflare-dns-records.sh subdomain.yourdomain.com CNAME your-app-service.azurewebsites.net
   
   # Enable Cloudflare proxy for additional security
   ./proxy-cloudflare-dns-records.sh subdomain.yourdomain.com on
   ```

> 💡 **Best Practice**: Enable Cloudflare proxy after DNS propagation for additional DDoS protection, CDN benefits, and enhanced security features.

## ✨ Current Features

- ✅ **Automated Infrastructure Provisioning** – Complete resource deployment using Bicep templates
- ✅ **Azure Key Vault Integration** – Centralized, secure management of all application secrets and sensitive configuration values
- ✅ **Secret Automation Script** – Easily sync secrets from local files to Azure Key Vault using the provided script
- ✅ **Azure CLI Integration** – Streamlined deployment via command-line interface with parameter files
- ✅ **Virtual Network Security** – Isolated network architecture with private endpoint connectivity
- ✅ **Hybrid Connectivity** – Point-to-Site VPN Gateway with Azure AD authentication for secure on-premises access
- ✅ **DNS Resolution** – Azure DNS Private Resolver for seamless name resolution between networks
- ✅ **Custom Domain Support** – Automated custom domain configuration with Azure-managed SSL certificates
- ✅ **Cloudflare Integration** – Specialized scripts for automated Cloudflare DNS record management
- ✅ **Container-Based Hosting** – Modern Linux container deployment on Azure App Service, with secrets injected securely from Key Vault
- ✅ **Local Development Setup** – Docker Compose configuration for streamlined local development and testing
- ✅ **Application Monitoring** – Azure Application Insights integration for comprehensive observability

## 🛣️ Roadmap

The following enhancements are planned to expand and improve the platform:

### 🔧 Development & Operations

- **🔄 CI/CD Automation** – Automated deployment pipelines for staging and production environments

### 🔐 Security & Configuration

- **✅ Secrets Management** – Azure Key Vault integration for secure credential handling (**Completed**)
- **✅ Custom Domains** – Support for custom domain configuration via Bicep automation (**Completed**)
- **✅ Cloudflare DNS Management** – Automated DNS record creation and proxy configuration (**Completed**)
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
