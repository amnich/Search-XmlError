Function Show-XmlError {
    <#
    .SYNOPSIS
    Show fragment of XML code where validation failed.

    .PARAMETER InputObject
    Error object from XML validation. Like from custom Test-Xml.

    .PARAMETER XmlFile
    Input XML File if no InputObject provided

    .PARAMETER Line
    Error line number if no InputObject provided

    .PARAMETER Column
    Error position number if no InputObject provided

    .PARAMETER OffsetLeft
    How many chars to show from xml file before error. Default 400

    .PARAMETER OffsetRight
    How many chars to show from xml file after error. Default 100

    .PARAMETER Pause
    Pause after each error fragment

    .EXAMPLE
    Test-Xml -XmlFile C:\my.xml -XsdFile C:\schema.xsd | Show-XmlError

    <Look typ="G">
    <LookOne>1453</LookOne>
    <Number>.</Number>
    <Name>Carl Johann GmbH Bonn</Name>
    <Address>Vor den Siebenburgen 123 , Bonn</Address>
    <LookFoo>DDD/11/03/2</LookFoo>
    <DataWystawienia>2015-03-17</DateOne>
    <DateTwo>2015-03-17</DateTwo>
    <A_0>3627.18</A_0>
    --> The element 'Look' in namespace 'http://xml.foo.bar/' has incomplete content. List
        of possible elements expected: 'A_1' in namespace 'http://xml.foo.bar/'..  <--
    </Look>
    <Look typ="G">
    <LookOne>1454</LookOne>
    <Number>.</Number...

    #>
    [CmdletBinding(DefaultParametersetName = 'custom')]
    param(
        [parameter(mandatory = $true, valuefrompipeline = $true, ParameterSetName = 'default')]
        $InputObject,
        [parameter(ParameterSetName = 'custom', mandatory)]
        [ValidateScript( {Test-Path $_})]
        [Alias('InputFile')]
        $XmlFile,
        [parameter(ParameterSetName = 'custom', mandatory)]
        [int]$Line,
        [parameter(ParameterSetName = 'custom', mandatory)]
        [int]$Column,
        [int]$OffsetLeft = 400,
        [int]$OffsetRight = 100,
        [switch]$Pause

    )
    BEGIN {
        #offset check for html tag < or >
        $offset = 0, -1, 1, -2, 2, -3, 3
    }
    PROCESS {
        #if not an exception object then create one from arguments
        if (-not $InputObject) {
            $inputObject = @{
                lineNumber   = $line
                LinePosition = $column
                Message      = "Error"
            }
        } else {
            #remove file:///from sourceUri
            $xmlFile = $(($InputObject.SourceUri | Select-Object -first 1) -replace "file:///")
        }
        try {
            $file = Get-Content $xmlFile -Encoding UTF8
        } catch {
            throw "Error getting content from file $xmlFile`n$($error[0] | out-string)"
        }
        #loop all errors
        foreach ($row in $inputObject) {
            #line number counted from 0 not 1
            $line = $row.lineNumber - 1
            #column number counted from 0 not 1
            $column = $row.LinePosition - 1
            #try to find nearest xml tag > or < for line break
            foreach ($i in $offset) {
                try {
                    if (">", "<" -contains $file[$line].substring($column + $i, 1)) {
                        $column = $column + $i + 1
                        break
                    }
                } catch {}
            }
            #check if not out of bounds
            if ($column -ge 0 -and $line -ge 0) {
                $column1 = $column - $OffsetLeft
                if ($column1 -lt 0) {
                    $column1 = 0
                }
                $column2 = $OffsetLeft - 1
                "`n=================================`n"
                #write-Host "$($row.Message)" -ForegroundColor DarkRed -BackgroundColor White
                "$($file[$line].substring($column1,$column2))" -replace "><", ">`n<"
                Write-Host "  --> $($row.Message)  <--" -BackgroundColor Red -ForegroundColor White
                "$($file[$line].substring($column1+$column2,$OffsetRight))..." -replace "><", ">`n<"
            }
            if ($Pause) {
                pause
            }
        }
    }
}
