#' Generate Conda Environment YAML from DESCRIPTION Dependencies
#'
#' This function reads the DESCRIPTION file in the current directory,
#' extracts the Depends and Imports dependencies, converts them to
#' conda-forge package names, and writes an environment.yml file.
#'
#' @param path Path to DESCRIPTION file. Defaults to "DESCRIPTION" in current dir.
#' @param r_version Version of R to use in conda env. Default "4.2".
#' @param env_suffix Suffix for environment name. Default is "-env".
#' @param include_suggests Logical; whether to include Suggests dependencies. Default FALSE.
#'
#' @return Invisibly returns the path to the generated environment.yml file.
#' @export
#'
#' @examples
#' \dontrun{
#' make_yaml()
#' }
make_yaml <- function(
    path = "DESCRIPTION",
    r_version = "4.2",
    env_suffix = "-env",
    include_suggests = FALSE
) {
  if (!requireNamespace("desc", quietly = TRUE)) {
    stop("Package 'desc' is required. Please install it first.")
  }

  d <- desc::desc(file = path)

  pkg_name <- tolower(d$get("Package")[[1]])
  env_name <- paste0(pkg_name, env_suffix)

  dep_types <- c("Depends", "Imports")
  if (include_suggests) {
    dep_types <- c(dep_types, "Suggests")
  }

  deps <- d$get_deps()
  deps <- deps[deps$type %in% dep_types, ]
  deps <- deps[deps$package != "R", ]

  r_pkgs <- unique(paste0("r-", tolower(deps$package)))
  base_deps <- c(paste0("r-base=", r_version), "r-devtools", "r-remotes")

  yaml_lines <- c(
    paste0("name: ", env_name),
    "channels:",
    "  - conda-forge",
    "  - defaults",
    "dependencies:",
    paste0("  - ", base_deps),
    paste0("  - ", sort(r_pkgs))
  )

  file_out <- "environment.yml"
  writeLines(yaml_lines, file_out)
  message("✅ Created ", file_out, " with environment name: ", env_name)

  invisible(file_out)
}


#' Check which R packages in environment.yml are not available on conda-forge
#'
#' @param file Path to environment.yml (default: "environment.yml")
#' @return A character vector of missing packages
#' @export
check_conda_availability_from_yaml <- function(file = "environment.yml") {
  if (!file.exists(file)) {
    stop("❌ File not found: ", file)
  }

  lines <- readLines(file)

  # Extract only lines starting with one dash and r- prefix (ignores extra -)
  pkg_lines <- grep("^\\s*-\\s*r-[a-z0-9\\.\\-]+", lines, value = TRUE)
  pkgs <- trimws(sub("^\\s*-\\s*", "", pkg_lines))

  # Remove duplicates and base R built-ins
  pkgs <- unique(pkgs)
  pkgs <- setdiff(pkgs, c("r-base", "r-stats", "r-utils"))

  # Check each package on conda-forge
  check_url <- function(pkg) {
    url <- paste0("https://anaconda.org/conda-forge/", pkg)
    tryCatch({
      con <- url(url, "r")
      close(con)
      TRUE
    }, error = function(e) FALSE)
  }

  missing <- pkgs[!vapply(pkgs, check_url, logical(1))]

  if (length(missing)) {
    message("⚠️ The following packages were NOT found on conda-forge:\n  - ",
            paste(missing, collapse = "\n  - "))
  } else {
    message("✅ All R packages found on conda-forge.")
  }

  invisible(missing)
}

