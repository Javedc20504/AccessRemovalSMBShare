<#
.Synopsis
   Removes the Deleted Accounts from the SMB Storage
.DESCRIPTION
   Removes the Deleted Accounts from the SMB Storage.
.EXAMPLE
   .\Remove-SMBSID.ps1
   .\Remove-SMBSID.ps1 -domain automatrixai.lab -outFilePath c:\MySMBReport.csv
.NOTES
   www.powershellhacks.com
#>

Param(
$domain      = "AutomatixAI",
$outFilePath = 'C:\Script\SMB_Removal_Status_Report.csv'
)

#Declaration
$inputFile = Import-Csv C:\Script\Input.csv
$collectorArray = @()
$result = @{}
Remove-Item $outFilePath -Force -ErrorAction SilentlyContinue
foreach ($item in $inputFile){
    $session = New-PSSession -ComputerName $item.name  
    $SID = $item.user
    $shareFolder = $item.Share
    #alternate
    #get-adobject -Filter 'isdeleted -eq $true -and name -ne "Deleted Objects" -and objectSID -like "S-1-5-21-3715152346-304165531-80169466-1412"' -IncludeDeletedObjects -Properties samaccountname,displayname,objectsid
    $deletedUser = (get-adobject -Filter 'objectSID -like $sid' -IncludeDeletedObjects -Properties samaccountname,displayname,objectsid).samaccountname 
    [string]$fullUser = $domain+$deletedUser


     try{
        Invoke-Command -Session $session -ScriptBlock {
            Revoke-SmbShareAccess -Name  $args[0] -AccountName  $args[1] -Confirm:$false
        }-ArgumentList  $shareFolder, $deletedUser -ea Stop | Out-Null

        $Proc = [ordered] @{
                ComputerName = $item.name
                DeletedUser  = $fullUser
                SID          = $sid
                SharePath    = $shareFolder
                Status       = "Access Removed"
            }
            $result= [pscustomobject]$Proc
    }
    Catch{

        $Proc = [ordered] @{
                ComputerName = $item.name
                DeletedUser  = $fullUser
                SID          = $sid
                SharePath    = $shareFolder
                Status       = "Failed Removal"
            }
            $result= [pscustomobject]$Proc
    }
    finally{
        Remove-PSSession -Session $session
    }
   $collectorArray +=$result
}

$collectorArray | Export-csv $outFilePath -Force -NoTypeInformation
Write-Output "Script Executed Successfully"
Invoke-Expression $outFilePath

#---Script End Here----
