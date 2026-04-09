# Retrieve dataset schema

Returns the column-level schema definition used by `krpoltext` for a
given dataset, including column types, descriptions, artifact metadata,
and dataset-specific extras such as office mappings.

## Usage

``` r
schema(dataset = c("campaign_booklet", "party_statements"))
```

## Arguments

- dataset:

  Character; which dataset to describe. One of `"campaign_booklet"` or
  `"party_statements"`.

## Value

A named list describing the dataset schema.

## Examples

``` r
schema("campaign_booklet")
#> $dataset
#> [1] "campaign_booklet"
#> 
#> $name
#> [1] "South Korean Election Campaign Booklets"
#> 
#> $description
#> [1] "Official campaign booklets (manifesto booklets) filed by 49,678 individual candidates in South Korean presidential, National Assembly, and local elections from 2000 to 2022. Text extracted via OCR and parsed using the khaiii Korean morphological analyzer."
#> 
#> $time_coverage
#> [1] "2000-2022"
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
#> $artifacts
#> $artifacts$csv
#> $artifacts$csv$format
#> [1] "csv"
#> 
#> $artifacts$csv$file
#> [1] "sk_election_campaign_booklet_v2022.csv"
#> 
#> $artifacts$csv$download_url
#> [1] "https://osf.io/download/6ybj8/"
#> 
#> $artifacts$csv$sha256
#> [1] "6ce6f40f5358829b167109d9ca9195e5089d2c6d05a61ad1c1925e424f55021d"
#> 
#> $artifacts$csv$size_bytes
#> [1] 756245336
#> 
#> $artifacts$csv$managed
#> [1] TRUE
#> 
#> 
#> $artifacts$parquet
#> $artifacts$parquet$format
#> [1] "parquet"
#> 
#> $artifacts$parquet$file
#> [1] "sk_election_campaign_booklet_v2022.parquet"
#> 
#> $artifacts$parquet$download_url
#> [1] "https://osf.io/download/pxg2k/"
#> 
#> $artifacts$parquet$sha256
#> [1] "a291a887d157963cffcffbe2c1ad60333222dd479bf4b01e90cec3a28d5c19a6"
#> 
#> $artifacts$parquet$size_bytes
#> [1] 406524268
#> 
#> $artifacts$parquet$managed
#> [1] TRUE
#> 
#> 
#> 
#> $columns
#> $columns[[1]]
#> $columns[[1]]$name
#> [1] "date"
#> 
#> $columns[[1]]$type
#> [1] "character"
#> 
#> $columns[[1]]$description
#> [1] "Election date (YYYY-MM-DD)"
#> 
#> 
#> $columns[[2]]
#> $columns[[2]]$name
#> [1] "name"
#> 
#> $columns[[2]]$type
#> [1] "character"
#> 
#> $columns[[2]]$description
#> [1] "Candidate name (Korean)"
#> 
#> 
#> $columns[[3]]
#> $columns[[3]]$name
#> [1] "region"
#> 
#> $columns[[3]]$type
#> [1] "character"
#> 
#> $columns[[3]]$description
#> [1] "Metropolitan region (province or metropolitan city)"
#> 
#> 
#> $columns[[4]]
#> $columns[[4]]$name
#> [1] "district"
#> 
#> $columns[[4]]$type
#> [1] "character"
#> 
#> $columns[[4]]$description
#> [1] "Electoral district"
#> 
#> 
#> $columns[[5]]
#> $columns[[5]]$name
#> [1] "office_id"
#> 
#> $columns[[5]]$type
#> [1] "integer"
#> 
#> $columns[[5]]$description
#> [1] "Office type identifier (1=president, 2=national_assembly, 3=edu_superintendent, 4=metro_head, 5=metro_assembly, 6=basic_head, 7=basic_assembly)"
#> 
#> 
#> $columns[[6]]
#> $columns[[6]]$name
#> [1] "office"
#> 
#> $columns[[6]]$type
#> [1] "character"
#> 
#> $columns[[6]]$description
#> [1] "Office type label (president, national_assembly, edu_superintendent, metro_head, metro_assembly, basic_head, basic_assembly)"
#> 
#> 
#> $columns[[7]]
#> $columns[[7]]$name
#> [1] "giho"
#> 
#> $columns[[7]]$type
#> [1] "integer"
#> 
#> $columns[[7]]$description
#> [1] "Candidate ballot number"
#> 
#> 
#> $columns[[8]]
#> $columns[[8]]$name
#> [1] "party"
#> 
#> $columns[[8]]$type
#> [1] "character"
#> 
#> $columns[[8]]$description
#> [1] "Political party name (Korean)"
#> 
#> 
#> $columns[[9]]
#> $columns[[9]]$name
#> [1] "party_eng"
#> 
#> $columns[[9]]$type
#> [1] "character"
#> 
#> $columns[[9]]$description
#> [1] "Political party name (English); transliteration if no official English name"
#> 
#> 
#> $columns[[10]]
#> $columns[[10]]$name
#> [1] "result"
#> 
#> $columns[[10]]$type
#> [1] "character"
#> 
#> $columns[[10]]$description
#> [1] "Election result in Korean"
#> 
#> 
#> $columns[[11]]
#> $columns[[11]]$name
#> [1] "sex"
#> 
#> $columns[[11]]$type
#> [1] "character"
#> 
#> $columns[[11]]$description
#> [1] "Sex in Korean"
#> 
#> 
#> $columns[[12]]
#> $columns[[12]]$name
#> [1] "birthday"
#> 
#> $columns[[12]]$type
#> [1] "character"
#> 
#> $columns[[12]]$description
#> [1] "Date of birth (YYYY-MM-DD)"
#> 
#> 
#> $columns[[13]]
#> $columns[[13]]$name
#> [1] "age"
#> 
#> $columns[[13]]$type
#> [1] "integer"
#> 
#> $columns[[13]]$description
#> [1] "Age at the time of the election"
#> 
#> 
#> $columns[[14]]
#> $columns[[14]]$name
#> [1] "job_id"
#> 
#> $columns[[14]]$type
#> [1] "integer"
#> 
#> $columns[[14]]$description
#> [1] "Original NEC job category identifier (varies across years)"
#> 
#> 
#> $columns[[15]]
#> $columns[[15]]$name
#> [1] "job"
#> 
#> $columns[[15]]$type
#> [1] "character"
#> 
#> $columns[[15]]$description
#> [1] "Standardized job category (Korean)"
#> 
#> 
#> $columns[[16]]
#> $columns[[16]]$name
#> [1] "job_name"
#> 
#> $columns[[16]]$type
#> [1] "character"
#> 
#> $columns[[16]]$description
#> [1] "Job title (Korean)"
#> 
#> 
#> $columns[[17]]
#> $columns[[17]]$name
#> [1] "job_name_eng"
#> 
#> $columns[[17]]$type
#> [1] "character"
#> 
#> $columns[[17]]$description
#> [1] "Job title (English)"
#> 
#> 
#> $columns[[18]]
#> $columns[[18]]$name
#> [1] "job_code"
#> 
#> $columns[[18]]$type
#> [1] "integer"
#> 
#> $columns[[18]]$description
#> [1] "Standardized job code consistent across years"
#> 
#> 
#> $columns[[19]]
#> $columns[[19]]$name
#> [1] "edu_id"
#> 
#> $columns[[19]]$type
#> [1] "integer"
#> 
#> $columns[[19]]$description
#> [1] "Original NEC education level identifier (varies across years)"
#> 
#> 
#> $columns[[20]]
#> $columns[[20]]$name
#> [1] "edu"
#> 
#> $columns[[20]]$type
#> [1] "character"
#> 
#> $columns[[20]]$description
#> [1] "Education description (Korean, free-text from NEC)"
#> 
#> 
#> $columns[[21]]
#> $columns[[21]]$name
#> [1] "edu_name"
#> 
#> $columns[[21]]$type
#> [1] "character"
#> 
#> $columns[[21]]$description
#> [1] "Standardized education level label (Korean)"
#> 
#> 
#> $columns[[22]]
#> $columns[[22]]$name
#> [1] "edu_name_eng"
#> 
#> $columns[[22]]$type
#> [1] "character"
#> 
#> $columns[[22]]$description
#> [1] "Standardized education level label (English)"
#> 
#> 
#> $columns[[23]]
#> $columns[[23]]$name
#> [1] "edu_code"
#> 
#> $columns[[23]]$type
#> [1] "integer"
#> 
#> $columns[[23]]$description
#> [1] "Standardized education code consistent across years"
#> 
#> 
#> $columns[[24]]
#> $columns[[24]]$name
#> [1] "career1"
#> 
#> $columns[[24]]$type
#> [1] "character"
#> 
#> $columns[[24]]$description
#> [1] "Career description 1"
#> 
#> 
#> $columns[[25]]
#> $columns[[25]]$name
#> [1] "career2"
#> 
#> $columns[[25]]$type
#> [1] "character"
#> 
#> $columns[[25]]$description
#> [1] "Career description 2"
#> 
#> 
#> $columns[[26]]
#> $columns[[26]]$name
#> [1] "pages"
#> 
#> $columns[[26]]$type
#> [1] "integer"
#> 
#> $columns[[26]]$description
#> [1] "Number of pages in the booklet"
#> 
#> 
#> $columns[[27]]
#> $columns[[27]]$name
#> [1] "code"
#> 
#> $columns[[27]]$type
#> [1] "character"
#> 
#> $columns[[27]]$description
#> [1] "Unique document identifier"
#> 
#> $columns[[27]]$identifier
#> [1] TRUE
#> 
#> 
#> $columns[[28]]
#> $columns[[28]]$name
#> [1] "sex_code"
#> 
#> $columns[[28]]$type
#> [1] "integer"
#> 
#> $columns[[28]]$description
#> [1] "Sex code: 1 = male, 0 = female"
#> 
#> 
#> $columns[[29]]
#> $columns[[29]]$name
#> [1] "result_code"
#> 
#> $columns[[29]]$type
#> [1] "integer"
#> 
#> $columns[[29]]$description
#> [1] "Result code: 1 = elected, 0 = not elected"
#> 
#> 
#> $columns[[30]]
#> $columns[[30]]$name
#> [1] "text"
#> 
#> $columns[[30]]$type
#> [1] "character"
#> 
#> $columns[[30]]$description
#> [1] "Full OCR-extracted text of the campaign booklet"
#> 
#> 
#> $columns[[31]]
#> $columns[[31]]$name
#> [1] "filtered"
#> 
#> $columns[[31]]$type
#> [1] "character"
#> 
#> $columns[[31]]$description
#> [1] "Parsed text after morphological analysis; Korean-only, numbers, foreign characters, and symbols removed"
#> 
#> 
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
#> $extras
#> $extras$office_mapping
#> $extras$office_mapping[[1]]
#> $extras$office_mapping[[1]]$office_id
#> [1] 1
#> 
#> $extras$office_mapping[[1]]$office
#> [1] "president"
#> 
#> $extras$office_mapping[[1]]$description
#> [1] "Presidential election"
#> 
#> 
#> $extras$office_mapping[[2]]
#> $extras$office_mapping[[2]]$office_id
#> [1] 2
#> 
#> $extras$office_mapping[[2]]$office
#> [1] "national_assembly"
#> 
#> $extras$office_mapping[[2]]$description
#> [1] "National Assembly election"
#> 
#> 
#> $extras$office_mapping[[3]]
#> $extras$office_mapping[[3]]$office_id
#> [1] 3
#> 
#> $extras$office_mapping[[3]]$office
#> [1] "edu_superintendent"
#> 
#> $extras$office_mapping[[3]]$description
#> [1] "Education superintendent"
#> 
#> 
#> $extras$office_mapping[[4]]
#> $extras$office_mapping[[4]]$office_id
#> [1] 4
#> 
#> $extras$office_mapping[[4]]$office
#> [1] "metro_head"
#> 
#> $extras$office_mapping[[4]]$description
#> [1] "Metropolitan city mayor / provincial governor"
#> 
#> 
#> $extras$office_mapping[[5]]
#> $extras$office_mapping[[5]]$office_id
#> [1] 5
#> 
#> $extras$office_mapping[[5]]$office
#> [1] "metro_assembly"
#> 
#> $extras$office_mapping[[5]]$description
#> [1] "Metropolitan assembly member"
#> 
#> 
#> $extras$office_mapping[[6]]
#> $extras$office_mapping[[6]]$office_id
#> [1] 6
#> 
#> $extras$office_mapping[[6]]$office
#> [1] "basic_head"
#> 
#> $extras$office_mapping[[6]]$description
#> [1] "Basic local government head"
#> 
#> 
#> $extras$office_mapping[[7]]
#> $extras$office_mapping[[7]]$office_id
#> [1] 7
#> 
#> $extras$office_mapping[[7]]$office
#> [1] "basic_assembly"
#> 
#> $extras$office_mapping[[7]]$description
#> [1] "Basic assembly member"
#> 
#> 
#> 
#> 
schema("party_statements")
#> $dataset
#> [1] "party_statements"
#> 
#> $name
#> [1] "South Korean Party Statements"
#> 
#> $description
#> [1] "Official statements from party spokespersons and minutes from daily leadership meetings of South Korea's two major parties (Conservative and Progressive), covering 2003 to 2022. 83,201 total entries (35,115 conservative + 48,086 progressive). Parsed using the khaiii Korean morphological analyzer."
#> 
#> $time_coverage
#> [1] "2003-2022"
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
#> $artifacts
#> $artifacts$csv
#> $artifacts$csv$format
#> [1] "csv"
#> 
#> $artifacts$csv$file
#> [1] "sk_party_statements_v2022.csv"
#> 
#> $artifacts$csv$download_url
#> [1] "https://osf.io/download/8u2ah/"
#> 
#> $artifacts$csv$sha256
#> [1] "60874e7c44d851c9cfc0892d70f6ef9ff9fb3993a5324963297ca4eabd4868e4"
#> 
#> $artifacts$csv$size_bytes
#> [1] 740785920
#> 
#> $artifacts$csv$managed
#> [1] TRUE
#> 
#> 
#> $artifacts$parquet
#> $artifacts$parquet$format
#> [1] "parquet"
#> 
#> $artifacts$parquet$file
#> [1] "sk_party_statements_v2022.parquet"
#> 
#> $artifacts$parquet$download_url
#> [1] "https://osf.io/download/8cjxu/"
#> 
#> $artifacts$parquet$sha256
#> [1] "cee8a49adbe90f96ee4e2b45b6d84c433e5eb9ebb4849cfc979f6a19c57378ea"
#> 
#> $artifacts$parquet$size_bytes
#> [1] 393216464
#> 
#> $artifacts$parquet$managed
#> [1] TRUE
#> 
#> 
#> 
#> $columns
#> $columns[[1]]
#> $columns[[1]]$name
#> [1] "no"
#> 
#> $columns[[1]]$type
#> [1] "integer"
#> 
#> $columns[[1]]$description
#> [1] "Sequential entry number within each party"
#> 
#> 
#> $columns[[2]]
#> $columns[[2]]$name
#> [1] "year"
#> 
#> $columns[[2]]$type
#> [1] "integer"
#> 
#> $columns[[2]]$description
#> [1] "Year the statement was posted"
#> 
#> 
#> $columns[[3]]
#> $columns[[3]]$name
#> [1] "ymd"
#> 
#> $columns[[3]]$type
#> [1] "character"
#> 
#> $columns[[3]]$description
#> [1] "Full date (YYYY-MM-DD)"
#> 
#> 
#> $columns[[4]]
#> $columns[[4]]$name
#> [1] "title"
#> 
#> $columns[[4]]$type
#> [1] "character"
#> 
#> $columns[[4]]$description
#> [1] "Title of the statement"
#> 
#> 
#> $columns[[5]]
#> $columns[[5]]$name
#> [1] "text"
#> 
#> $columns[[5]]$type
#> [1] "character"
#> 
#> $columns[[5]]$description
#> [1] "Full text of the statement"
#> 
#> 
#> $columns[[6]]
#> $columns[[6]]$name
#> [1] "filtered"
#> 
#> $columns[[6]]$type
#> [1] "character"
#> 
#> $columns[[6]]$description
#> [1] "Parsed text after morphological analysis; Korean-only"
#> 
#> 
#> $columns[[7]]
#> $columns[[7]]$name
#> [1] "partisan"
#> 
#> $columns[[7]]$type
#> [1] "character"
#> 
#> $columns[[7]]$description
#> [1] "Party affiliation: Progressive / Conservative"
#> 
#> 
#> $columns[[8]]
#> $columns[[8]]$name
#> [1] "conservative"
#> 
#> $columns[[8]]$type
#> [1] "integer"
#> 
#> $columns[[8]]$description
#> [1] "Binary indicator: 1 = Conservative Party, 0 = Progressive Party"
#> 
#> 
#> $columns[[9]]
#> $columns[[9]]$name
#> [1] "id"
#> 
#> $columns[[9]]$type
#> [1] "character"
#> 
#> $columns[[9]]$description
#> [1] "Unique document identifier (party prefix + entry number)"
#> 
#> $columns[[9]]$identifier
#> [1] TRUE
#> 
#> 
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
#> $extras
#> list()
#> 
```
