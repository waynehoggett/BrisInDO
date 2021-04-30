$EndpointSchedule = New-UDEndpointSchedule -Every 2 -Minute
New-UDEndpoint -Id VMs -Schedule $EndpointSchedule -Endpoint {
    Import-Module Az
    Connect-AzAccount -Identity
    $Cache:VMs = Get-AzVM -Status | Select-Object Name, Location, PowerState, ResourceGroupName
} | Out-Null

New-UDDashboard -Title "VM Self-Service" -Content {
    $TableColumns = @(
        New-UDTableColumn -Property Name -Title Name
        New-UDTableColumn -Property ResourceGroupName -Title ResourceGroupName
        New-UDTableColumn -Property Location -Title Location
        New-UDTableColumn -Property Action -Title Actions -Render { 
            if ($EventData.PowerState -like "*running*") {
                New-UDButton -Text "Stop" -Icon (New-UDIcon -Icon power_off) -OnClick {
                    try {
                        Show-UDToast -Message 'Connecting to Azure Account...' -BackgroundColor "LightBlue" -Duration 2000
                        Connect-AzAccount -Identity
                        Show-UDToast -Message "Stopping VM $($EventData.Name)..." -BackgroundColor "LightBlue" -Duration 50000 -ReplaceToast
                        Stop-AzVM -Name $EventData.Name -ResourceGroupName $EventData.ResourceGroupName -Force -ErrorAction Stop
                        Show-UDToast -Message 'Successully stopped VM' -BackgroundColor "LightGreen" -Duration 5000 -ReplaceToast
                        Sync-UDElement -Id 'VMs'
                    } catch {
                        Show-UDToast -Message 'Failed to stop VM' -BackgroundColor "OrangeRed" -Duration 5000 -ReplaceToast
                    }
                }
            }
            else {
                New-UDButton -Text "Start" -Icon (New-UDIcon -Icon bolt) -OnClick {
                    try {
                        Show-UDToast -Message 'Connecting to Azure Account...' -BackgroundColor "LightBlue" -Duration 2000
                        Connect-AzAccount -Identity
                        Show-UDToast -Message "Starting VM $($EventData.Name)..." -BackgroundColor "LightBlue" -Duration 90000  -ReplaceToast
                        Start-AzVM -Name $EventData.Name -ResourceGroupName $EventData.ResourceGroupName -ErrorAction Stop
                        Show-UDToast -Message 'Successfully started VM' -BackgroundColor "LightGreen" -Duration 5000 -ReplaceToast
                        Sync-UDElement -Id 'VMs'
                    } catch {
                        Show-UDToast -Message 'Failed to start VM' -BackgroundColor "OrangeRed" -Duration 5000 -ReplaceToast
                    }
                }
            }
        }
    )
    New-UDDynamic -Content {
        while ($null -eq $Cache:VMs) {
            Start-Sleep -Seconds 1
        }
        New-UDButton -Text 'Reload VMs' -Icon (New-UDIcon -Icon sync) -OnClick { Sync-UDElement -Id 'VMs' }
        New-UDTable -Id 'VMs' -Data $Cache:VMs -Columns $TableColumns -Export
    } -LoadingComponent {
        New-UDProgress
    } -AutoRefresh -AutoRefreshInterval 60
}