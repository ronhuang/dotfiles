# Script for notifying me when IP address is changed.

$dataDirectory = Join-Path $env:LocalAppData "IPAddressMailer"
$addressFile = Join-Path $dataDirectory "LastIPAddress.txt"
$runFile = Join-Path $dataDirectory "LastIPAddressRunDate.txt"

function Get-LastIpAddress()
{
  # Get the IP Address from the last time the script ran

  if ((Test-Path $addressFile) -eq $false)
  {
    # If the file doesn't exist, just set to empty string
    $lastIPAddress = ''
  }
  else
  {
    # Get the IP Address from the last run, and strip out any special characters
    $lastIPAddress = Get-Content $addressFile -Raw
    $lastIPAddress = $lastIPAddress -replace "`t|`r|`n", ""
  }

  return $lastIPAddress
}

function Get-ExternalIPAddress ()
{
  # Get external IP Address
  $externalIP = Get-NetIPAddress -PrefixOrigin Dhcp -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
  if ($externalIP.Length -gt 1)
  {
    $externalIP = $externalIP[0]
  }

  # The string that is returned includes a carriage return/line feed character
  # at the end. We have to strip it off otherwise if we use it in the email
  # subject the Send-MailMessage cmdlet will reject it, as CRLF isn't allowed
  # in email subject lines.
  $externalIP = $externalIP -replace "`t|`r|`n", ""

  return $externalIP
}

function Get-LastIPAddressRunDate()
{
  if ((Test-Path $runFile) -eq $false)
  {
    # If the file doesn't exist, just set to empty string
    $lastTime = ''

    # Then go ahead and create the file
    New-Item -ItemType Directory -Force -Path $dataDirectory
    Set-Content -Path $runFile -Value $today
  }
  else
  {
    # Get the IP Address from the last run, and strip out any special characters
    $lastTime = Get-Content $runFile -Raw
    $lastTime = $lastTime -replace "`t|`r|`n", ""
  }

  return $lastTime
}

# Get today's date and the date the script last ran
$today = Get-Date -Format d
$lastTime = Get-LastIPAddressRunDate

# Get the current IP address, and the IPAddress from the last time
# the script ran
$lastIPAddress = Get-LastIpAddress
$externalIP = Get-ExternalIPAddress

# Go through checks to determine if we need to send an email
$sendEmail = $false

# If the IP address has changed, send an email
if ($externalIP -ne $lastIPAddress)
{
  $sendEmail = $true
}

# Send the email if the checks said we need to
if ($sendEmail -eq $true)
{
  # Including the IP Address in the subject line will make it nice for
  # the receiver, as they won't even have to open the message to see it.
  $subject = "$env:COMPUTERNAME's IP as of $(Get-Date -Format d) is $externalIP"

  # One minor change you may wish to make is add someone's name after the
  # word Hi, so it's a bit friendlier, such as Hi Robert,
  $body = @"
It's $(Get-Date -Format d), and $env:COMPUTERNAME's IP address is $externalIP.
"@

  # OK, we are finally done, let's send an e-mail!
  Send-MailMessage -From "ron.huang@hp.com" `
    -To "ron.huang@hp.com" `
    -Subject $subject `
    -Body $body `
    -SmtpServer "smtp3.hp.com"

  New-Item -ItemType Directory -Force -Path $dataDirectory
  # Update the last IP address file
  Set-Content -Path $addressFile -Value $externalIP -Force
  # And the date we ran
  Set-Content -Path $runFile -Value $today -Force
}
