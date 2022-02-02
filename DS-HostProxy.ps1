# PS Script to set the proxy server to connect to the Trend Micro Smart Protection Network.  Sets proxy for Anti-Malware, Web Reputation and Global Services

#Pass 4 parameters to the script
# 1 - URL of the Deep Security Manager.  (including port which is default 4119)
# 2 - Hostname of the system you want to change
# 3 - ID of the Proxy Server to set
# 4 - API Key 

Param(
    [String]$URL,
    [String]$Host_name,
    [String]$ProxyID,
    [String]$API_Key
    )

$URL = $URL + "/api"

#Need this to ignore certificate checks to support self signed certs
$code= @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
Add-Type -TypeDefinition $code -Language CSharp
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$Headers = @{
    "api-secret-key" = $API_Key
    "api-version" = "v1"
    }

#Get the list of computers from the C1WS Manager
$ListComputersAPI = $url + "/computers"
$resp = Invoke-RestMethod -Uri $ListComputersAPI -Headers $Headers | Select-Object -ExpandProperty Computers

$HostFound = "False"

#write-host $resp

#For each computer, match the hostname to get the ID
ForEach ($Computer in $resp)
{
    if ($Computer.hostName -eq $Host_name) {
        $HostFound = "True"
        $ComputerID = $Computer.ID
        #$Current_ACAction = $Computer.applicationControl.maintenancemodeStatus
    }
}

if ($HostFound -eq "False") {
    write-host "Host Not Found - Terminating"
    break
}

#write-host "Searching for Host: "  $Host_name
#write-host "Found Host: "  $HostFound
#write-host "Host Computer ID: "  $ComputerID
#write-host "API URL: "  $URL 

#Enable Anti-Malware Global Smart Protection Server for the ComputerID
$ComputerAPI= $url + "/computers/" + $ComputerID                                

#write-host "URL Called: "  $ComputerAPI

#Build JSON Body for the Configuration Items
$JSON_Body = @{}
$JSON_Array = @{}

#Enable Anti-Malware Global Smart Protection Server
$JSON_Data = @{"value" = "true"}
$JSON_Array.Add("antiMalwareSettingSmartProtectionGlobalServerEnabled", $JSON_Data)

#Enable Anti-Malware Global Smart Protection Server Proxy
$JSON_Data = @{"value" = "true"}
$JSON_Array.Add("antiMalwareSettingSmartProtectionGlobalServerUseProxyEnabled", $JSON_Data)

#Set Anti-Malware Global Smart Protection Server Proxy ID
$JSON_Data = @{"value" = $ProxyID}
$JSON_Array.Add("platformSettingSmartProtectionAntiMalwareGlobalServerProxyId", $JSON_Data)

#Enable Web-Rep Global Smart Protection Server
$JSON_Data = @{"value" = "false"}
$JSON_Array.Add("webReputationSettingSmartProtectionLocalServerEnabled", $JSON_Data)

#Enable Anti-Malware Global Smart Protection Server Proxy
$JSON_Data = @{"value" = "true"}
$JSON_Array.Add("webReputationSettingSmartProtectionGlobalServerUseProxyEnabled", $JSON_Data)

#Set Anti-Malware Global Smart Protection Server Proxy ID
$JSON_Data = @{"value" = $ProxyID}
$JSON_Array.Add("webReputationSettingSmartProtectionWebReputationGlobalServerProxyId", $JSON_Data)

#Enable Global Settings Global Smart Protection Server Proxy
$JSON_Data = @{"value" = "true"}
$JSON_Array.Add("platformSettingSmartProtectionGlobalServerUseProxyEnabled", $JSON_Data)

#Set Global Settings Global Smart Protection Server Proxy ID
$JSON_Data = @{"value" = $ProxyID}
$JSON_Array.Add("platformSettingSmartProtectionGlobalServerProxyId", $JSON_Data)

$JSON_Body.Add("computerSettings", $JSON_Array)


$APIBody = $JSON_Body | ConvertTo-Json

#write-host $APIBody

    
$resp = Invoke-RestMethod -Uri $ComputerAPI -Headers $Headers -Method Post -Body $APIBody -ContentType 'application/json'

#write-host $resp









