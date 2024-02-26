Import-Module MSAL.ps

#region Setup
$Settings = Get-Content ./pftestsecrets.json | ConvertFrom-Json 
$clientSecret = ConvertTo-SecureString -String $Settings.clientSecret -AsPlainText -Force 

$authparams = @{ 
    ClientId     = $Settings.clientId 
    TenantId     = $Settings.tenantId 
    ClientSecret = $clientSecret 
} 


$Global:auth -$null 
function  Get-AuthHeader { 
    $invalid = $null -eq $Global:auth 
    if ($invalid -eq $false) 

    { 
        $invalid = [datetime]::utcnow -gt $Global:auth.ExpiresOn.UtcDateTime 
        if ($invalid -eq $true) 
        { 
            write-host 'token expired' 
        } 
    } 
    else { 
        Write-Host 'no token found' 
    } 
    if ($invalid) 
    { 
        Write-Host 'refreshing token' 
        $Global:auth = Get-MsalToken @authParams -Scopes $Settings.scope
    } 
    else{ 
        Write-Host 'token is valid' 
    } 
    return $Global:auth.CreateAuthorizationHeader() 
} 


$serviceURI = "SECRET"


$pathToJson = "./testinvoice.json"

$json = Get-Content -Path $pathToJson -Raw | ConvertFrom-Json


$MyContent = @{
    'name' = 'James'
    'sourceId' = 'some rubbish - ignore this well never use it' 
}

$json =  $MyContent |convertto-json
Write-Host $json

for($i=0;$i -lt 11;$i++){
    $MyContent['sourceId'] = 'number is {0} now' -f $i
    $json =  $MyContent |convertto-json
    Write-Host $json
}




$body = Get-Content ./testinvoice.json | ConvertFrom-Json -Depth 5


$Params = @{
    Method = "POST"
    Uri = $serviceURI
    Body = ConvertTo-Json -InputObject $body -Depth 10
    ContentType = 'application/json'
    Headers = @{Authorization = Get-AuthHeader}
}
write-host $Params.Body

function testingtheApi {
    $stopwatch = New-Object System.Diagnostics.Stopwatch
    $stopwatch.Start()


    try {
        $Result = Invoke-RestMethod @Params
        $resultMessage = 'Invoice posted with number {0}' -f $Result.number
    }
    catch {
        #Write-Output "Ran into an issue: $($PSItem.ToString())"
        $resultMessage = "Call failed with StatusCode: {0}" -f $_.Exception.Response.StatusCode.value__ 
    }


    $stopwatch.Stop()
    $daterightnow = date
    Add-Content -Path ./test.txt -Value $daterightnow
    $text = "operation took: "
    Add-Content -Path ~/test.txt -Value $text, $stopwatch.Elapsed
    Add-Content -Path ~/test.txt -Value "result message:"
    Add-Content -Path ./test.txt -Value $resultMessage
    
}
testingtheApi