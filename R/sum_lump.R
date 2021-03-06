#' Sum and lump together small flows into "other"
#'
#' @description Lump together regions/countries if their flows are below a given threshold.
#'
#' @param m A \code{matrix} or data frame of origin-destination flows. For \code{matrix} the first and second dimensions correspond to origin and destination respectively. For a data frame ensure the correct column names are passed to \code{orig_col}, \code{dest_col} and \code{flow_col}.
#' @param threshold Numeric value used to determine small flows, origins or destinations that will be grouped (lumped) together. 
#' @param lump Character string to indicate where to apply the threshold. Choose from the `flow` values, `in` migration totals and/or `out` migration totals.
#' @param other_level Character string for the origin and/or destination label for the lumped values below the `threshold`. Default `"other"`.
#' @param complete Logical value to return a `tibble` with complete the origin-destination combinations
#' @param fill Numeric value for to fill small cells below the `threshold` when `complete` is `TRUE`. Default of zero.
#' @param return_matrix Logical to return a matrix. Default `FALSE`.
#' @param orig_col Character string of the origin column name (when \code{m} is a data frame rather than a \code{matrix})
#' @param dest_col Character string of the destination column name (when \code{m} is a data frame rather than a \code{matrix})
#' @param flow_col Character string of the flow column name (when \code{m} is a data frame rather than a \code{matrix})
#'
#' @return A \code{tibble} with an additional `other` origins and/or destinations region based on the grouping together of small values below the `threshold` argument and the `lump` argument to indicate on where to apply the threshold. 
#' 
#' @details The `lump` argument can take values `flow` or `bilat` to apply the threshold to the data values for between region migration, `in` or `imm` to apply the threshold to the incoming region totals and `out` or `emi` to apply the threshold to outgoing region totals.
#' @export
#'
#' @examples
#' dn <- LETTERS[1:4]
#' m <- matrix(data = c(0, 100, 30, 10, 50, 0, 50, 5, 10, 40, 0, 40, 20, 25, 20, 0),
#'             nrow = 4, ncol = 4, dimnames = list(orig = dn, dest = dn), byrow = TRUE)
#' 
#' # threshold on in and out totals
#' sum_lump(m, threshold = 100, lump = c("in", "out"))
#' 
#' # threshold on flows (default)
#' sum_lump(m, threshold = 40)
#' 
#' # return a matrix (only possible when input is a matrix and 
#' # complete = TRUE) with small values replaced by zeros
#' sum_lump(m, threshold = 50, complete = TRUE)
#' 
#' # return a data frame with small values replaced with zero
#' sum_lump(m, threshold = 80, complete = TRUE, return_matrix = FALSE)
#' 
#' \dontrun{
#' # data frame (tidy) format
#' library(tidyverse)
#' 
#' # download Abel and Cohen (2019) estimates
#' f <- read_csv("https://ndownloader.figshare.com/files/26239945")
#' 
#' # large 1990-1995 flow estimates
#' f %>%
#'   filter(year0 == 1990) %>%
#'   sum_lump(flow_col = "da_pb_closed", threshold = 1e5)
#' 
#' # large flow estimates for each year
#' f %>%
#'   group_by(year0) %>%
#'   sum_lump(flow_col = "da_pb_closed", threshold = 1e5)
#' }
sum_lump <- function(m, threshold = 1, lump = "flow",
                     other_level = "other",
                     complete = FALSE, fill = 0, return_matrix = TRUE,
                     orig_col = "orig", dest_col = "dest", flow_col = "flow"){
  # m = filter(f, year0 == 1990) 
  # threshold = 1e5; lump = c("in", "out");
  # lump = "flow"
  # other_level = "other"; complete = TRUE; fill = 0
  # orig_col = "orig"; dest_col = "dest"; flow_col = "da_pb_closed"
  orig <- dest <- flow <- region <- in_mig <- out_mig <- NULL
  if(!all(lump %in% c("flow", "bilat", "in", "imm", "emi", "out")))
    stop("lump is not recognised")
  if(!is.matrix(m)){
    d <- m %>%
      dplyr::rename(orig := !!orig_col,
                    dest := !!dest_col,
                    flow := !!flow_col)
    g <- dplyr::group_vars(d)
    if(length(g) == 0) 
      g <- NULL
  }
  if(is.matrix(m)){
    d <- as.data.frame.table(x = m, responseName = "flow", stringsAsFactors = FALSE) %>%
      dplyr::rename(orig := 1,
                    dest := 2) %>%
      dplyr::as_tibble()
    g <- NULL
  }
  
  imm_lump <- emi_lump <- flow_lump <- NULL
  if(any(lump %in% c("in", "imm"))){
    imm_lump <- d %>%
      sum_turnover() %>%
      dplyr::filter(in_mig < threshold) %>%
      dplyr::pull(region)
  }
  if(any(lump %in% c("out", "emi"))){
    emi_lump <- d %>%
      sum_turnover() %>%
      dplyr::filter(out_mig < threshold) %>%
      dplyr::pull(region)
  }
  if(any(lump %in% c("flow", "bilat")))
    flow_lump <- TRUE
  
  # set other
  x0 <- d %>%
    if(length(imm_lump)==0) . else dplyr::mutate(., orig = ifelse(orig %in% imm_lump, other_level, orig)) %>%
    if(length(emi_lump)==0) . else dplyr::mutate(., dest = ifelse(dest %in% emi_lump, other_level, dest))

  x1 <- x0 %>%
    if(is.null(flow_lump)) . else dplyr::mutate(., orig = ifelse(flow < threshold, other_level, orig)) %>%
    if(is.null(flow_lump)) . else dplyr::mutate(., dest = ifelse(flow < threshold, other_level, dest))

  x2 <- x1 %>%
    dplyr::group_by_at(c({{g}}, "orig", "dest")) %>%
    dplyr::summarise(flow = sum(flow), .groups = "drop") %>%
    dplyr::ungroup() %>%
    dplyr::group_by_at({{g}}) %>%
    if(complete) tidyr::complete(., orig = c(unique(d$orig), "other"),
                                    dest = c(unique(d$dest), "other"),
                                    fill = list(flow = fill)) else .
  
  if(complete & is.matrix(m) & return_matrix){
    x2 <- stats::xtabs(formula = flow ~ orig + dest, data = x2)
  }
  return(x2)
}
