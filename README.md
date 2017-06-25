# Search-XmlError

Validate XML with XSD and if errors found show XML fragment with error message using this two functions.

Test-Xml - validate a XML file against XSD schema and returns exceptions with message, line and position/column in XML file.

Show-XmlError - shows the XML fragment before and after the error. It accepts input from Test-Xml but also manual XML file input with specified line and column number of error.

Example usage:

    Test-Xml -inputfile file.xml -schemafile schema.xsd | Show-XmlError
