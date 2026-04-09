# Retrieve dataset metadata

Returns package-facing metadata for one of the bundled corpora,
including column names, versions, identifier fields, and available
storage formats.

## Usage

``` r
metadata(dataset = c("campaign_booklet", "party_statements"))
```

## Arguments

- dataset:

  Character; which dataset to describe. One of `"campaign_booklet"` or
  `"party_statements"`.

## Value

A named list with dataset metadata.

## Examples

``` r
metadata("campaign_booklet")
#> $name
#> [1] "South Korean Election Campaign Booklets"
#> 
#> $description
#> [1] "Official campaign booklets (manifesto booklets) filed by 49,678 individual candidates in South Korean presidential, National Assembly, and local elections from 2000 to 2022. Text extracted via OCR and parsed using the khaiii Korean morphological analyzer."
#> 
#> $time_coverage
#> [1] "2000-2022"
#> 
#> $columns
#>  [1] "date"         "name"         "region"       "district"     "office_id"   
#>  [6] "office"       "giho"         "party"        "party_eng"    "result"      
#> [11] "sex"          "birthday"     "age"          "job_id"       "job"         
#> [16] "job_name"     "job_name_eng" "job_code"     "edu_id"       "edu"         
#> [21] "edu_name"     "edu_name_eng" "edu_code"     "career1"      "career2"     
#> [26] "pages"        "code"         "sex_code"     "result_code"  "text"        
#> [31] "filtered"    
#> 
#> $n_candidates_or_entries
#> [1] 49678
#> 
#> $data_version
#> [1] "v2022"
#> 
#> $package_version
#> [1] "0.2.0"
#> 
#> $identifier_columns
#> [1] "code"
#> 
#> $text_columns
#> [1] "text"     "filtered"
#> 
#> $supported_formats
#> [1] "csv"     "parquet"
#> 
#> $managed_formats
#> [1] "csv"     "parquet"
#> 
#> $source_url
#> [1] "https://osf.io/rct9y/"
#> 
#> $paper_doi
#> [1] "10.1038/s41597-025-05220-4"
#> 
#> $license
#> [1] "CC BY-NC-ND 4.0"
#> 
#> $citation
#> [1] "Lim, T.H. (2025). South Korean Election Campaign Booklet and Party Statements Corpora. Scientific Data, 12, 1030. https://doi.org/10.1038/s41597-025-05220-4"
#> 
#> $osf_citation
#> [1] "Lim, T.H. (2024). South Korean Election Campaign Booklet Corpus and Party Statements Corpus. OSF. https://doi.org/10.17605/OSF.IO/RCT9Y"
#> 
#> $notes
#> $notes$missing_values
#> [1] "2,283 candidates lack a booklet; 151 are missing biographical information. 23 booklets were unprocessable."
#> 
#> $notes$identifiers
#> [1] "'code' uniquely identifies each document. 'job_id' and 'edu_id' vary across election years; use 'job_code' and 'edu_code' for cross-year analysis."
#> 
#> $notes$text_processing
#> [1] "All text is UTF-8 encoded Korean. 'text' contains the full original text; 'filtered' contains the morphologically parsed version."
#> 
#> 
metadata("party_statements")
#> $name
#> [1] "South Korean Party Statements"
#> 
#> $description
#> [1] "Official statements from party spokespersons and minutes from daily leadership meetings of South Korea's two major parties (Conservative and Progressive), covering 2003 to 2022. 83,201 total entries (35,115 conservative + 48,086 progressive). Parsed using the khaiii Korean morphological analyzer."
#> 
#> $time_coverage
#> [1] "2003-2022"
#> 
#> $columns
#> [1] "no"           "year"         "ymd"          "title"        "text"        
#> [6] "filtered"     "partisan"     "conservative" "id"          
#> 
#> $n_candidates_or_entries
#> [1] 83201
#> 
#> $data_version
#> [1] "v2022"
#> 
#> $package_version
#> [1] "0.2.0"
#> 
#> $identifier_columns
#> [1] "id"
#> 
#> $text_columns
#> [1] "text"     "filtered"
#> 
#> $supported_formats
#> [1] "csv"     "parquet"
#> 
#> $managed_formats
#> [1] "csv"     "parquet"
#> 
#> $source_url
#> [1] "https://osf.io/rct9y/"
#> 
#> $paper_doi
#> [1] "10.1038/s41597-025-05220-4"
#> 
#> $license
#> [1] "CC BY-NC-ND 4.0"
#> 
#> $citation
#> [1] "Lim, T.H. (2025). South Korean Election Campaign Booklet and Party Statements Corpora. Scientific Data, 12, 1030. https://doi.org/10.1038/s41597-025-05220-4"
#> 
#> $osf_citation
#> [1] "Lim, T.H. (2024). South Korean Election Campaign Booklet Corpus and Party Statements Corpus. OSF. https://doi.org/10.17605/OSF.IO/RCT9Y"
#> 
#> $notes
#> $notes$missing_values
#> [1] "Some fields may contain NA or empty strings."
#> 
#> $notes$party_names
#> [1] "Both parties have undergone frequent name changes. The 'partisan' column uses stable ideological labels rather than party names."
#> 
#> $notes$text_processing
#> [1] "All text is UTF-8 encoded Korean. 'text' contains the full original text; 'filtered' contains the morphologically parsed version."
#> 
#> 
```
