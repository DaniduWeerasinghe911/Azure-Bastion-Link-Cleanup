# Define the subscription ID for the platform/Bastion Service
$PlatformSubscriptionId = ""

# Define header for HTTP requests
$header = @{
    "Content-Type" = "application/json"
    # Acquire token for authentication
    Authorization  = ("Bearer " + (Get-AzAccessToken).Token)
}

# Select the given subscription
select-azsubscription -SubscriptionId $PlatformSubscriptionId

# Attempt to retrieve Bastion information; suppress any errors
$azBastion = Get-AzBastion -ErrorAction SilentlyContinue   

# Check if the Bastion provisioning was successful
if ($azBastion.ProvisioningState -eq "Succeeded") {
    # Extract necessary details from the Bastion information
    $ResourceGroupName = $azBastion.ResourceGroupName
    $SubscriptionId = $azBastion.Id.Split('/')[2]
    $Name = $azBastion.Name      

    # Display relevant information
    Write-Output "🔵 Bastion Host Name: $name"
    Write-Output "🔵 Resource Group: $ResourceGroupName"
    Write-Output "🔵 Subscription: $SubscriptionId"

    # Define the URI for the shareable link request
    $uri = "https://management.azure.com/subscriptions/$($PlatformSubscriptionId)/resourceGroups/$($azBastion.ResourceGroupName)/providers/Microsoft.Network/bastionHosts/$($azBastion.Name)/GetShareableLinks?api-version=2023-02-01"
    
    # Retrieve a list of all subscriptions
    $SubscriptionList = Get-AzSubscription | Select-Object Id, Name

    # Iterate over each subscription
    foreach ($sub in $SubscriptionList) {
        select-azsubscription -SubscriptionId $sub.Id
        Write-Output "Processing Subscription $($sub.Name)"

        # Fetch all VMs under the current subscription
        $vmList = Get-AzVm

        # Iterate over each VM in the subscription
        foreach ($vm in $vmList) {         
            Write-Host "Processing VM $($vm.Name)"
            
            # Define the request body to get shareable link for the VM
            $requestBody = @{
                "vms" = @(
                    @{
                        "vm" = @{
                            "id" = $vm.Id
                        }
                    }
                )
            }

            # Check if request body exists and is not null
            if ($null -ne $requestBody) {    
                # Make HTTP request to fetch shareable link
                $getBastionLink = Invoke-RestMethod -Method Post -Uri $uri -Headers $header -Body (ConvertTo-Json $requestBody -Depth 10) -SkipHttpErrorCheck   
                
                # Check if the link exists
                if ($null -ne $getBastionLink.value) {
                    # Convert string date to DateTime object
                    $convertedDate = [DateTime]::parseexact($getBastionLink.value.createdAt,"MM/dd/yyyy HH:mm:ss",[System.Globalization.CultureInfo]::InvariantCulture)
                    # Calculate difference in days from link creation date to now
                    $daysDifference = (Get-Date) - $convertedDate
                    
                    # Check if link was created more than 1 days ago
                    if ($daysDifference.Days -gt 1) {
                        # Print details and potentially delete old links
                        Write-Output "Deleting the Shareable Link for the Virtual Machine: $($vm.Name)"
                    }
                    else {
                        # The link is not older than 1 days
                        Write-Output "The date is not older than 1 days."
                        continue  
                    } 
                }
                else {
                    # No ABS Link for the VM
                    # Write-Output "ABS Link does not exist for the Virtual Machine: $($vm.Name)" 
                    continue     
                }                  
            }
            else {
                # Something went wrong, potentially with the VM
                Write-Output "VM $($vm.Name) Something went wrong."
                continue  
            }
        }
    }
}
else {
    # No Azure Bastion was found in the provided subscription
    Write-Output "NO Azure Bastion Exists within the permitted subscription."
    continue
}
