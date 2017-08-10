function Test-Xml {
    <#
    .SYNOPSIS
    Validate a XML file against XSD schema.

    .DESCRIPTION
    Validate a XML file against XSD schema and get back error messages if any errors found.

    .PARAMETER XmlFile
    XML file to validate

    .PARAMETER XsdFile
    XSD schema for validation

    .PARAMETER Namespace
    XML Namespace

    .EXAMPLE
    Test-Xml -XmlFile C:\my.xml -XsdFile C:\schema.xsd
    SourceObject       :
    SourceUri          : file:///C:/my.xml
    LineNumber         : 8
    LinePosition       : 414720
    SourceSchemaObject :
    Message            : The element 'Look' in namespace 'http://xml.foo.bar/' has incomplete content. Lis
                        t of possible elements expected: 'A_1' in namespace 'http://xml.foo.bar/'.
    Data               : System.Collections.ListDictionaryInternal
    InnerException     :
    TargetSite         :
    StackTrace         :
    HelpLink           :
    Source             :
    HResult            : -2146231999

    .NOTES
    Author: Adam Mnich

    .LINK
    https://github.com/amnich/Search-XmlError
    #>
    [cmdletbinding()]
    param(
        [parameter(mandatory = $true)]
        [ValidateScript( {Test-Path $_})]
        [Alias('InputFile')]
        [string]$XmlFile,
        [parameter(mandatory = $true)]
        [ValidateScript( {Test-Path $_})]
        [Alias('SchemaFile')]
        [string]$XsdFile,
        [string]$Namespace
    )

    BEGIN {
        $tempFile = "$env:Temp\xml_test.csv"
        #if Namespace not provided read xml file and get schema target namespace
        if (-not $Namespace) {
            [xml]$xml = Get-Content $xsdFile
            $Namespace = $xml.schema.targetNamespace
        }
    }

    PROCESS {
        #delete temporary file
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        write-verbose "xml file: $xmlFile"
        write-verbose "xsd file: $xsdFile"
        #get full filename of XML file
        $fileName = (resolve-path $xmlFile).path
        if (-not (test-path $xsdFile)) {throw "schema file not found $xsdFile"}
        $readerSettings = New-Object -TypeName System.Xml.XmlReaderSettings
        $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
        $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints -bor
        [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation -bor
        [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
        $readerSettings.Schemas.Add($Namespace, $xsdFile) | Out-Null
        $readerSettings.add_ValidationEventHandler(
            {
                Write-Debug $_.exception
                Write-Verbose "Export exception to temporarty file $tempFile"
                $_.exception | Export-Csv $tempFile -Delimiter ";" -Append -NoTypeInformation
            })
        try {
            $reader = [System.Xml.XmlReader]::Create($fileName, $readerSettings)
            Write-Verbose "Start XML reader"
            while ($reader.Read()) { }
            Write-Verbose "Import results from $tempFile"
            $results = Import-Csv $tempFile -Delimiter ";"
            Write-Verbose "Errors found: $($results.count)"
            $results
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        } finally {
            $reader.Close()
        }
    }
}
