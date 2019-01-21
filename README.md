# Diag-V

[![Minimum Supported PowerShell Version](https://img.shields.io/badge/PowerShell-5.1-blue.svg)](https://github.com/PowerShell/PowerShell)
[![downloads](https://img.shields.io/powershellgallery/dt/Diag-V.svg?label=downloads)](https://www.powershellgallery.com/packages/Diag-V)

master | Enhancements
--- | ---
![Build Status](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiU1FRSnE3aFlRbnVsd3R4aDBYS2JjUlh3OGlnZmRadW9CeWVucTcwRFJnQktnSjdraFNmL05ZMGlRSzRsZFhCbE54Z204anJheTd5QThzQjNwOUhOaytnPSIsIml2UGFyYW1ldGVyU3BlYyI6ImZTT1g2akZaTXJqSWJscEIiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master) | ![Build Status](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiaW1BTGJMNnBkckVnNnlYUTZZbXF2MFh1UVRiS2tEZHRVdk9XTFRMdVdqT1AxNjlVaGVEMm1WTjBHK3lXVkpNTEI3S2F4UloyQURPY1Y5SUU1MjlRdkFzPSIsIml2UGFyYW1ldGVyU3BlYyI6IjN4TWx0T1F0bzJyYlNCRmkiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=Enhancements)

## Synopsis
Diag-V is a read-only PowerShell module containing several Hyper-V related diagnostics to assist with managing standalone Hyper-V Servers and Hyper-V clusters

## Description
Diag-V is a PowerShell Module collection of primarily Hyper-V diagnostic functions, as well as several windows diagnostic functions useful when interacting with Hyper-V servers.

With the module imported diagnostics can be run via the desired function name, alternatively, Diag-V can also present a simple choice menu that enables you to browse via console all diagnostics and execute the desired choice.

## Why

## Installation

### Prerequisites
* Designed and tested on Server 2012R2 and Server 2016 Hyper-V servers running PowerShell 5.1
  * Most functions should work with PowerShell 4
* Diag-V must be run as a user that has local administrator rights on the Hyper-V server
* If running diagnostics that interact with all cluster nodes Diag-V must be run as a user that has local administrator right to all members of the cluster

### Installing Diag-V via PowerShell Gallery

***This is the recommended method***

```powershell
#from an administrative 5.1.0+ PowerShell session
Install-Module -Name "Diag-V"
```

### Installing PoshGram direct from GitHub

*Note: You will need to **build** PoshGram yourself using [Invoke-Build](https://github.com/nightroman/Invoke-Build) if you want to install directly from GitHub*

1. Download Zip from GitHub
2. Extract files
3. Navigate to download location
4. Change dir to **\src**
5. Invoke build
     ``` powershell
     Invoke-Build -Task Clean,CreateHelp,Build
     ```
6. Build will now be available in **\src\Artifacts**
7. Import PoshGram
    * Create the following directory: ```C:\Program Files\WindowsPowerShell\Modules\PoshGram```
      * Copy Artifact files into the created directory
    * Alternatively you can import module from Artifacts location manually

## Quick start

```powershell
#------------------------------------------------------------------------------------------------
#import the PoshGram module
Import-Module -Name "Diag-V"
#------------------------------------------------------------------------------------------------
#easy way to validate your Bot token is functional
Test-BotToken -BotToken $botToken
#------------------------------------------------------------------------------------------------
#send a basic Text Message
Send-TelegramTextMessage -BotToken $botToken -ChatID $chat -Message "Hello"
#------------------------------------------------------------------------------------------------
#send a photo message from a local source
Send-TelegramLocalPhoto -BotToken $botToken -ChatID $chat -PhotoPath $photo
#------------------------------------------------------------------------------------------------
#send a photo message from a URL source
Send-TelegramURLPhoto -BotToken $botToken -ChatID $chat -PhotoURL $photoURL
#------------------------------------------------------------------------------------------------
#send a file message from a local source
Send-TelegramLocalDocument -BotToken $botToken -ChatID $chat -File $file
#------------------------------------------------------------------------------------------------
#send a file message from a URL source
Send-TelegramURLDocument -BotToken $botToken -ChatID $chat -FileURL $fileURL
#------------------------------------------------------------------------------------------------
#send a video message from a local source
Send-TelegramLocalVideo -BotToken $botToken -ChatID $chat -Video $video
#------------------------------------------------------------------------------------------------
#send a video message from a URL source
Send-TelegramURLVideo -BotToken $botToken -ChatID $chat -VideoURL $videoURL
#------------------------------------------------------------------------------------------------
#send an audio message from a URL source
Send-TelegramLocalAudio -BotToken $botToken -ChatID $chat -Audio $audio
#------------------------------------------------------------------------------------------------
#send an audio message from a local source
Send-TelegramURLAudio -BotToken $botToken -ChatID $chat -AudioURL $audioURL
#------------------------------------------------------------------------------------------------
Send-TelegramLocation -BotToken $botToken -ChatID $chat -Latitude $latitude -Longitude $longitude
#------------------------------------------------------------------------------------------------
Send-TelegramLocalAnimation -BotToken $botToken -ChatID $chat -AnimationPath $animation
#------------------------------------------------------------------------------------------------
Send-TelegramURLAnimation -BotToken $botToken -ChatID $chat -AnimationURL $AnimationURL
#------------------------------------------------------------------------------------------------
Send-TelegramMediaGroup -BotToken $botToken -ChatID $chat -FilePaths (Get-ChildItem C:\PhotoGroup | Select-Object -ExpandProperty FullName)
#------------------------------------------------------------------------------------------------
###########################################################################
#sending a telegram message from older versions of powershell
###########################################################################
#here is an example of calling PowerShell 6.1 from PowerShell 5.1 to send a Telegram message with PoshGram
& 'C:\Program Files\PowerShell\6-preview\pwsh.exe' -command { Import-Module PoshGram;$token = "#########:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx";$chat = "-#########";Send-TelegramTextMessage -BotToken $token -ChatID $chat -Message "Test from 5.1 calling 6.1 to send Telegram Message via PoshGram" }
#--------------------------------------------------------------------------
#here is an example of calling PowerShell 6.1 from PowerShell 5.1 to send a Telegram message with PoshGram using dynamic variables in the message
$token = “#########:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx”
$chat = “-#########”
$test = "I am a test"
& '.\Program Files\PowerShell\6-preview\pwsh.exe' -command "& {Import-Module PoshGram;Send-TelegramTextMessage -BotToken $token -ChatID $chat -Message '$test';}"
#--------------------------------------------------------------------------
```

## Author
[Jake Morrison](https://twitter.com/JakeMorrison) - [http://techthoughts.info/](http://techthoughts.info/)

## Contributors
* Marco-Antonio Cervantez

## Updates
* **12 December 2017**
  * *Complete re-write*
    * Converted Diag-V from a ps1 PowerShell script to a fully supported PowerShell module
    * Redesigned all diagnostic functions
      * Improved error control
      * General bug fixes
      * Better readability
    * Added new Hyper-V log parser function
* **04 Dec 2015**
  * Improved Cluster detection error control
  * Re-ordered the code of the diagnostics
  * Improved comments and documentation
* **02 Dec 2015**
  * Fixed error where RAM was not being tallied properly
  * Added code to allow diagnostics to run correctly on VMM platforms

## Notes

A complete write-up on Diag-V as well as a video demonstration can be found on the Tech Thoughts blog: http://techthoughts.info/diag-v/

```powershell
Get-VM : CredSSP authentication is currently disabled in the client configuration. Change the client
configuration and try the request again.
```