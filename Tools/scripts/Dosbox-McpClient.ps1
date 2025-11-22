<#!
.SYNOPSIS
    Thin PowerShell helper for talking to the DOSBox-X Machine Control Protocol (MCP).

.DESCRIPTION
    REMastered v1 treats DOSBox-X control as an optional adapter. This script is a
    lightweight foundation: it knows how to open a TCP connection to an MCP
    listener, send commands, and expose simple Pause/Resume helpers. Real MCP
    commands vary between DOSBox-X builds, so you should adjust the command text
    in the wrappers once you settle on the exact protocol.

    Typical workflow from other scripts:
        $conn = Connect-DosboxMcp -Host "127.0.0.1" -Port 5555
        Pause-DosboxMcp -Connection $conn
        Invoke-DosboxMcpCommand -Connection $conn -Command "SOME_OTHER_COMMAND"
        Resume-DosboxMcp -Connection $conn
        Disconnect-DosboxMcp -Connection $conn

.NOTES
    - Connection objects are simple PSCustomObjects that hold the TcpClient and
      reader/writer streams.
    - Logging is left to the caller (e.g., Write-MasterLog.ps1), so this module
      remains side-effect free.
    - Error handling favors clear exceptions so callers can decide whether to
      retry or fall back to host-only workflows.
#>

Set-StrictMode -Version Latest

function Connect-DosboxMcp {
    [CmdletBinding()]
    param(
        [string]$Host = '127.0.0.1',
        [int]$Port = 5555,
        [int]$TimeoutMilliseconds = 3000
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    $async = $client.BeginConnect($Host, $Port, $null, $null)
    if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) {
        $client.Close()
        throw "Unable to connect to DOSBox-X MCP at $Host:$Port (timeout)."
    }

    try {
        $client.EndConnect($async)
    }
    catch {
        $client.Close()
        throw "Unable to connect to DOSBox-X MCP at $Host:$Port ($_ )"
    }

    $stream = $client.GetStream()
    $encoding = [System.Text.Encoding]::UTF8
    $writer = [System.IO.StreamWriter]::new($stream, $encoding, 1024, $true)
    $writer.NewLine = "\n"
    $writer.AutoFlush = $true
    $reader = [System.IO.StreamReader]::new($stream, $encoding, $false, 1024, $true)

    return [pscustomobject]@{
        Client = $client
        Stream = $stream
        Writer = $writer
        Reader = $reader
        Host   = $Host
        Port   = $Port
    }
}

function Disconnect-DosboxMcp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection
    )

    if ($Connection.Writer) { $Connection.Writer.Dispose() }
    if ($Connection.Reader) { $Connection.Reader.Dispose() }
    if ($Connection.Stream) { $Connection.Stream.Dispose() }
    if ($Connection.Client) { $Connection.Client.Close() }
}

function Invoke-DosboxMcpCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$Command,
        [switch]$ReadResponse
    )

    if (-not $Connection.Writer -or -not $Connection.Reader) {
        throw "Connection object is missing stream writers/readers."
    }

    $Connection.Writer.WriteLine($Command)

    if ($ReadResponse) {
        # MCP responses differ per build; we read a single line by default.
        try {
            return $Connection.Reader.ReadLine()
        }
        catch {
            throw "Failed to read response for MCP command '$Command': $_"
        }
    }
}

function Pause-DosboxMcp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [string]$Command = 'MCP_PAUSE'
    )

    Invoke-DosboxMcpCommand -Connection $Connection -Command $Command
}

function Resume-DosboxMcp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [string]$Command = 'MCP_RESUME'
    )

    Invoke-DosboxMcpCommand -Connection $Connection -Command $Command
}

function Send-DosboxKeys {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$Text
    )

    Invoke-DosboxMcpCommand -Connection $Connection -Command ("SEND_KEYS " + $Text)
}

Export-ModuleMember -Function Connect-DosboxMcp, Disconnect-DosboxMcp, Invoke-DosboxMcpCommand, Pause-DosboxMcp, Resume-DosboxMcp, Send-DosboxKeys
