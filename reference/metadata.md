# Retrieve dataset metadata

Returns a list of metadata about the specified corpus, including its
name, description, time coverage, column names, observation count, and
citation information.

## Usage

``` r
metadata(dataset = c("campaign_booklet", "party_statements"))
```

## Arguments

- dataset:

  Character; which dataset to describe. One of `"campaign_booklet"` or
  `"party_statements"`.

## Value

A named list with elements:

- name:

  Human-readable dataset name.

- description:

  Brief description.

- time_coverage:

  Temporal coverage (YYYY-YYYY).

- columns:

  Character vector of column names.

- n_candidates_or_entries:

  Number of unique candidates or entries as reported in the Data
  Descriptor.

- source_url:

  OSF repository URL.

- paper_doi:

  DOI of the Data Descriptor in *Scientific Data*.

- citation:

  Suggested citation string.

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
#> $source_url
#> [1] "https://osf.io/rct9y/"
#> 
#> $paper_doi
#> [1] "10.1038/s41597-025-05220-4"
#> 
#> $citation
#> [1] "Lim, T.H. (2025). South Korean Election Campaign Booklet and Party Statements Corpora. Scientific Data, 12, 1030. https://doi.org/10.1038/s41597-025-05220-4"
#> 
metadata("party_statements")
#> $name
#> [1] "South Korean Party Statements"
#> 
#> $description
#> [1] "Official statements from party spokespersons and minutes from daily leadership meetings of South Korea's two major parties (Conservative and Progressive), covering 2003 to 2022. 82,723 total entries (35,115 conservative + 42,335 progressive). Parsed using the khaiii Korean morphological analyzer."
#> 
#> $time_coverage
#> [1] "2003-2022"
#> 
#> $columns
#> [1] "no"           "year"         "ymd"          "title"        "text"        
#> [6] "filtered"     "partisan"     "conservative" "id"          
#> 
#> $n_candidates_or_entries
#> [1] 82723
#> 
#> $source_url
#> [1] "https://osf.io/rct9y/"
#> 
#> $paper_doi
#> [1] "10.1038/s41597-025-05220-4"
#> 
#> $citation
#> [1] "Lim, T.H. (2025). South Korean Election Campaign Booklet and Party Statements Corpora. Scientific Data, 12, 1030. https://doi.org/10.1038/s41597-025-05220-4"
#> 
```
