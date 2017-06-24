Function Show-XmlError {
    <#
    .SYNOPSIS
    Show fragment of xml code where validation failed.
        
    .PARAMETER InputObject
    Error object from xml validation. Like from custom Test-Xml. 
    
    .PARAMETER InputFile
    Input XML File
    
    .PARAMETER Line
    Error line number
    
    .PARAMETER Column
    Error position number
    
    .PARAMETER OffsetLeft
    How many chars to show from xml file before error. Default 400
    
    .PARAMETER OffsetRight
    How many chars to show from xml file after error. Default 100
    
    .PARAMETER Pause
    Pause after each error fragment
    #>
    [CmdletBinding(DefaultParametersetName = 'custom')] 
    param(
        [parameter(mandatory = $true, valuefrompipeline = $true, ParameterSetName = 'default')]
        $InputObject,
        [parameter(ParameterSetName = 'custom', mandatory)]
        $InputFile,
        [parameter(ParameterSetName = 'custom', mandatory)]
        [int]$Line,
        [parameter(ParameterSetName = 'custom', mandatory)]
        [int]$Column,
        [int]$OffsetLeft = 400,
        [int]$OffsetRight = 100,
        [switch]$Pause
	
    )
    PROCESS {
        if (-not $InputObject) {
            $inputObject = @{
                lineNumber   = $line
                LinePosition = $column
                Message      = "Error"
            }
        }
        else {
            $InputFile = $(($InputObject.SourceUri | Select-Object -first 1) -replace "file:///")
        }
        $file = Get-Content $InputFile -Encoding UTF8
        foreach ($row in $inputObject) {
            $line = $row.lineNumber - 1
            $column = $row.LinePosition - 1
            if (">", "<" -notcontains $FILE[$line].substring($column, 1)) {
                try {
                    if (">", "<" -contains $FILE[$line].substring($column - 2, 1)) {
                        $column = $column - 1
                    }
                    elseif (">", "<" -contains $FILE[$line].substring($column + 2, 1)) {
                        $column = $column + 1
                    }
                }
                catch {}
            }
            if ($column -ge 0 -and $line -ge 0) {
                $column1 = $column - $OffsetLeft
                if ($column1 -lt 0) {
                    $column1 = 0
                }
                $column2 = $OffsetLeft - 1
                "`n=================================`n"
                #write-Host "$($row.Message)" -ForegroundColor DarkRed -BackgroundColor White
                "$($FILE[$line].substring($column1,$column2))" -replace "><", ">`n<"
                Write-Host "  --> $($row.Message)  <--" -BackgroundColor Red -ForegroundColor White
                "$($FILE[$line].substring($column1+$column2,$OffsetRight))..." -replace "><", ">`n<"				
            }
            if ($Pause) {
                pause
            }
        }
    }
}
