# Prompt for the JSON file path
$fichierJson = Read-Host "Enter the full path to the JSON file"

# Check if the file exists
if (-Not (Test-Path $fichierJson)) {
    Write-Host "File not found. Please check the path." -ForegroundColor Red
    exit
}

# Load the JSON file content
$jsonContent = Get-Content -Raw -Path $fichierJson | ConvertFrom-Json

# Extract values for specific types
$typesRecherches = @("title", "url", "username", "password", "note", "email")

$resultats = @()

# Iterate through each JSON item (at the 'items' level)
if ($jsonContent.items) {
    foreach ($item in $jsonContent.items) {
        # Initialize the object for each item
        $resultat = [PSCustomObject]@{
            name            = $item.title
            url             = ""
            username        = ""
            password        = ""
            note            = $item.note
            email           = ""
        }
        
        # Extract fields from the main item level
        if ($item.fields) {
            foreach ($field in $item.fields) {
                if ($field.type -in $typesRecherches) {
                    switch ($field.type) {
                        "url"       { $resultat.url = $field.value }
                        "username"  { $resultat.username = $field.value }
                        "password"  { $resultat.password = $field.value }
                        "email"     { $resultat.email = $field.value }
                    }
                }
            }
        }
        
        # Extract data from 'entries' if they exist
        if ($item.entries) {
            foreach ($entry in $item.entries) {
                if ($entry.fields) {
                    foreach ($field in $entry.fields) {
                        if ($field.type -in $typesRecherches) {
                            switch ($field.type) {
                                "url"       { $resultat.url = $field.value }
                                "username"  { $resultat.username = $field.value }
                                "password"  { $resultat.password = $field.value }
                                "email"     { $resultat.email = $field.value }
                            }
                        }
                    }
                }
            }
        }
        
        # Add the result object to the collection if at least one field is filled
        if ($resultat.name -or $resultat.url -or $resultat.username -or $resultat.password -or $resultat.email) {
            $resultats += $resultat
        }
    }
} else {
    Write-Host "No data found under 'items'." -ForegroundColor Yellow
}

# Add an empty object to enforce headers if no results were found
if ($resultats.Count -eq 0) {
    $resultats += [PSCustomObject]@{
        name            = ""
        url             = ""
        username        = ""
        password        = ""
        note            = ""
        email           = ""
    }
    Write-Host "No data found, creating a CSV with headers only." -ForegroundColor Yellow
}

# Generate the output file name
$date = (Get-Date).ToString("yyyyMMdd_HHmmss")
$nomFichier = [System.IO.Path]::GetFileNameWithoutExtension($fichierJson)
$dossierSortie = [System.IO.Path]::GetDirectoryName($fichierJson)
$nomSortie = "${dossierSortie}\${date}_${nomFichier}.csv"

# Export to CSV
$resultats | Export-Csv -Path $nomSortie -NoTypeInformation -Encoding UTF8

Write-Host "Export completed: $nomSortie" -ForegroundColor Green
