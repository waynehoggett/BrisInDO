# Brisbane Infrastructure DevOps User Group
## Overview

All the code from my talks at the Brisbane Infrastructure DevOps User Group.

* [Deploying PowerShell Universal to Azure Container Instances (ACI) - 27th April 2021](#042021)

## Deploying PowerShell Universal to Azure Container Instances (ACI) - 27th April 2021<a name="042021"></a>

In this talk I demonstrated how to deploy PowerShell Universal to Azure Container Instances (ACI) using Azure Container Regsitry as the repository and Azure Files as the persistent data storage.

### Files
📁 PowerShell Universal on ACI  
├──📜Dashboard.ps1  
├──📜Deploy-Container.ps1  
└──🐋dockerfile  

#### Dashboard.ps1
Contains the PowerShell Universal Dashboard code used in the demo.

The demo code requires that you have some virtual machines in the subscription that you deployed the dashboard to.

Deploy the code by logging into PowerShell Universal and completing the steps listed below:
1. Navigate to Dashboard -> Dashboards -> Create new Dashboard
2. Provide a name, e.g. Virtual Machine Self Service
3. Enter the URL /
4. Turn off Authentication
5. Turn on AutoDeploy
6. Click OK
7. Click Info 
8. Click Edit
9. Paste in Dashboard Code from Dashboard.ps1
10. Click Save
11. Navigate to the homepage

#### Deploy-Container.ps1
This Azure PowerShell code will deploy PowerShell Universal to Azure Container Instances (ACI).

Requirements:
* Docker is installed and using Linux Containers
* You run the code from the root of the folder /PowerShell Universal on ACI

#### dockerfile
Provides the instructions to build the docker image from Powershell Universal and installs the Az PowerShell Module in the container.