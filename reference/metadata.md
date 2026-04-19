# Retrieve dataset metadata

Returns package-facing metadata for one of the bundled corpora,
including column names, versions, identifier fields, and available
storage formats.

## Usage

``` r
metadata(dataset = c("campaign_booklet", "party_statements"), variant = NULL)
```

## Arguments

- dataset:

  Character; which dataset to describe. One of `"campaign_booklet"` or
  `"party_statements"`.

- variant:

  Character or `NULL`; optional dataset variant. For `campaign_booklet`,
  defaults to `"original"` and may also be set to `"enriched"`. Other
  datasets do not define variants.

## Value

A named list with dataset metadata.

## Examples

``` r
metadata("campaign_booklet")
#> $name
#> [1] "South Korean Election Campaign Booklets"
#> 
#> $description
#> [1] "Original krpoltext campaign booklet corpus artifact covering 49,678 document rows from South Korean presidential, National Assembly, and local elections, 2000-2022."
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
#> $variant
#> [1] "original"
#> 
#> $default_variant
#> [1] "original"
#> 
#> $available_variants
#> [1] "original" "enriched"
#> 
#> $variant_description
#> [1] "The original krpoltext campaign booklet corpus artifact."
#> 
#> $recommended_use
#> [1] "General corpus analysis and backward-compatible workflows."
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
#> [1] "2,283 rows have no booklet code or text because a booklet was not available. 151 are missing biographical information. 23 booklets were unprocessable."
#> 
#> $notes$text_processing
#> [1] "All text is UTF-8 encoded Korean. 'text' contains the full original text; 'filtered' contains the morphologically parsed version."
#> 
#> $notes$identifiers
#> [1] "'code' is the krpoltext document row identifier, but some original rows have missing code values, so row identity should not be inferred from code alone. 'job_id' and 'edu_id' vary across election years; use 'job_code' and 'edu_code' for cross-year analysis."
#> 
#> $notes$provenance
#> [1] "The original variant is the source corpus artifact distributed without NEC linkage fields."
#> 
#> 
metadata("campaign_booklet", variant = "enriched")
#> $name
#> [1] "South Korean Election Campaign Booklets"
#> 
#> $description
#> [1] "Enriched campaign booklet artifact using the same document-row universe as the original CSV source, with conservative NEC linkage fields such as 'huboid', 'sg_id', and 'sg_typecode' added to improve interoperability with kr-elections-mcp and related NEC-aligned workflows."
#> 
#> $time_coverage
#> [1] "2000-2022"
#> 
#> $columns
#>  [1] "date"            "name"            "region"          "district"       
#>  [5] "office_id"       "office"          "giho"            "party"          
#>  [9] "party_eng"       "result"          "sex"             "birthday"       
#> [13] "age"             "job_id"          "job"             "job_name"       
#> [17] "job_name_eng"    "job_code"        "edu_id"          "edu"            
#> [21] "edu_name"        "edu_name_eng"    "edu_code"        "career1"        
#> [25] "career2"         "pages"           "code"            "huboid"         
#> [29] "sg_id"           "sg_typecode"     "link_status"     "matcher_version"
#> [33] "nec_snapshot_id" "sex_code"        "result_code"     "text"           
#> [37] "filtered"       
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
#> $variant
#> [1] "enriched"
#> 
#> $default_variant
#> [1] "original"
#> 
#> $available_variants
#> [1] "original" "enriched"
#> 
#> $variant_description
#> [1] "The same document-row universe as the original CSV source, plus conservative NEC linkage fields for integration workflows."
#> 
#> $recommended_use
#> [1] "NEC-aligned workflows, kr-elections-mcp, and linkage-aware joins."
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
#> [1] "2,283 rows have no booklet code or text because a booklet was not available. 151 are missing biographical information. 23 booklets were unprocessable."
#> 
#> $notes$text_processing
#> [1] "All text is UTF-8 encoded Korean. 'text' contains the full original text; 'filtered' contains the morphologically parsed version."
#> 
#> $notes$identifiers
#> [1] "'code' is the krpoltext document row identifier, but some rows have missing code values, so row identity should not be inferred from code alone. 'huboid' is a linked NEC identifier, not a native krpoltext identifier. Rows with 'link_status == \"resolved\"' are expected to have a non-null 'huboid'. 'sg_id' and 'sg_typecode' describe the NEC-aligned election scope attached to the row. 'job_id' and 'edu_id' vary across election years; use 'job_code' and 'edu_code' for cross-year analysis."
#> 
#> $notes$provenance
#> [1] "The enriched variant is a row-preserving transformation of the original campaign_booklet CSV source. It adds conservative NEC linkage metadata to improve interoperability with kr-elections-mcp and related NEC-aligned workflows."
#> 
#> $notes$artifact_transition
#> [1] "When the enriched campaign_booklet artifact is rebuilt or republished, update registry checksums, sizes, and URLs in lockstep with this schema."
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
#> $variant
#> NULL
#> 
#> $default_variant
#> NULL
#> 
#> $available_variants
#> character(0)
#> 
#> $variant_description
#> NULL
#> 
#> $recommended_use
#> NULL
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
