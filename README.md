# Azure-Bastion-Link-Cleanup

Howdy Folks

This time it's about Azure Bastion. There was a requirement in one of the recent projects around Azure Bastion Sharable Links. Before we get into more details let's talk about what are the sharable links

## Overview

As per Microsoft,

"The Bastion Shareable Link feature lets users connect to a target resource (virtual machine or virtual machine scale set) using Azure Bastion without accessing the Azure portal. This article helps you use the Shareable Link feature to create a shareable link for an existing Azure Bastion deployment.

When a user without Azure credentials clicks a shareable link, a webpage opens that prompts the user to sign into the target resource via RDP or SSH. Users authenticate using username and password or private key, depending on what you have configured for the target resource. The shareable link does not contain any credentials - the admin must provide sign-in credentials to the user."

This is a pretty good addition to Azure Bastion, but it does come with a security flow too. Since we will be sharing these links with external users/vendors, Links that we generate does not expire or cannot set an expiry at the moment. I'm sure MS will give this option really soon.

But until then requirement was

Automatically delete these links every day at 12am, So vendors would need to talk to the internal IT department to get access again.

## Solution.

At the moment we have 2 options to achieve this. either thru GUI or using API. So, there is no PowerShell option. So, I came up with a script to perform the cleanup using Azure Automation Runbook. 

### Explanation - 

Azure automation service principal was granted following permissions.

- Microsoft.Network/bastionHosts/deleteShareableLinks/action

- Microsoft.Network/bastionHosts/deleteShareableLinksByToken/action

- Microsoft.Network/bastionHosts/getShareableLinks/action

Script will

Query the tenant to get the bastion details

- Go thru all the subscriptions to query all the virtual machines with sharable links

- Make sure links are not more than 1 day older, if so, it will delete the link.

- You need to update the script with subscription id where you have the bastion. deployed.

Microsoft Reference --> https://learn.microsoft.com/en-us/azure/bastion/shareable-link
