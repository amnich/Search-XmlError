function Test-Xml {
[cmdletbinding()]
param(
    [parameter(mandatory=$true)]$InputFile,
    [parameter(mandatory=$true)]$SchemaFile,	
    $Namespace
)

BEGIN {
    if (-not $Namespace){
		[xml]$xml = Get-Content $SchemaFile
		$Namespace = $xml.schema.targetNamespace
	}	
}

PROCESS {
	Remove-Item $env:Temp\xml_test.csv -Force -ErrorAction SilentlyContinue
	write-verbose "input file: $inputfile"
    write-verbose "schemafile: $SchemaFile"
    $fileName = (resolve-path $inputfile).path
    if (-not (test-path $SchemaFile)) {throw "schemafile not found $schemafile"}
    $readerSettings = New-Object -TypeName System.Xml.XmlReaderSettings
    $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
    $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints -bor
        [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation -bor 
        [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
    $readerSettings.Schemas.Add($Namespace, $SchemaFile) | Out-Null
    $readerSettings.add_ValidationEventHandler(
    {        
		Write-Verbose $_.exception
		$_.exception | Export-Csv $env:Temp\xml_test.csv -Delimiter ";" -Append -NoTypeInformation
    })
    try {
        $reader = [System.Xml.XmlReader]::Create($fileName, $readerSettings)
        while ($reader.Read()) { }
		Import-Csv $env:temp\xml_test.csv -Delimiter ";"
		Remove-Item $nev:temp\xml_test.csv -Force -ErrorAction SilentlyContinue
    }
    finally {
        $reader.Close()
    }
}
}
