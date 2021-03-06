#' get_urls_from_ct_histdata
#'
#' Given a CSV created by the CrowdTangle Historical Data feature (preferbly filtered for link type posts), this function extract a unique list of URLs with a first shared date
#'
#' @param ct_histdata_csv a local or remote link to a CSV created by the CrowdTangle Historical Data
#' @param newformat set to TRUE in order to use new CrowdTangle CSV format
#'
#' @return A data.frame with a unique list of URLs with respective first seen date
#'
#' @examples
#' urls <- get_urls_from_ct_histdata(ct_histdata_csv="mylocaldata.csv")
#'
#' urls <- get_urls_from_ct_histdata(ct_histdata_csv="https://ct-download.s3.us-west-2.amazonaws.com/...")
#'
#' # Use the new urls dataset to call get_ct_shares function
#' ct_shares.dt <- get_ctshares(urls, url_column="url", date_column="date", save_ctapi_output=TRUE)
#'
#' @importFrom readr read_csv cols col_character col_skip
#' @importFrom dplyr group_by summarise %>% select
#'
#' @export

get_urls_from_ct_histdata <- function(ct_histdata_csv=NULL, newformat=FALSE) {

  if(is.null(ct_histdata_csv)) {
    stop("The function requires a valid CSV local or remote link to run")
    }

cat("\nLoading CSV...")

if (newformat == TRUE) {
  df <- read_csv(col_types = cols(
    .default = col_skip(),
    date = col_character(),
    expandedLinks.original = col_character(),
    expandedLinks.expanded = col_character()),
    file =  ct_histdata_csv)

  df$url <- ifelse(is.na(df$expandedLinks.expanded), df$expandedLinks.original, df$expandedLinks.expanded) # keep expanded links only

  df <- clean_urls(df, "url") # clean up the url to avoid duplicates

  urls <- df %>%
    group_by(url) %>%
    summarise(date = min(date)) %>%
    select(url, date)


} else {
  df <- read_csv(col_types = cols(
  .default = col_skip(),
  Created = col_character(),
  Link = col_character(),
  `Final Link` = col_character()),
  file =  ct_histdata_csv)

  df$url <- ifelse(is.na(df$`Final Link`), df$Link, df$`Final Link`) # keep expanded links only

  df <- clean_urls(df, "url") # clean up the url to avoid duplicates

  urls <- df %>%
    group_by(url) %>%
    summarise(Created = min(Created)) %>%
    select(url, date=Created)
}

attr(urls, 'spec') <- NULL

rm(df)
return(urls)
}
