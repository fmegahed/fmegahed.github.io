

# * Duke Data -------------------------------------------------------------

# https://www.duke-energyohiocbp.com/Documents/LoadandOtherData.aspx

duke_links = c(
  "https://www.duke-energyohiocbp.com/Portals/0/Documents/Actual_Hourly_Loads_by_Class_2021.xlsx",
  "https://www.duke-energyohiocbp.com/Portals/0/Documents/Actual_Hourly_Loads_by_Class_2022_20230307.xlsx",
  "https://www.duke-energyohiocbp.com/Portals/0/Documents/Actual_Hourly_Loads_by_Class_2023_20240507.xlsx",
  "https://www.duke-energyohiocbp.com/Portals/0/Documents/Actual_Hourly_Loads_by_Class_2024.xlsx",
  "https://www.duke-energyohiocbp.com/Portals/0/Documents/Actual_Hourly_Loads_by_Class_2025_20250814.xlsx"
)

names(duke_links) = paste0("duke_loads_", 2021:2025, ".xlsx")

# download each file to data folder
for (i in seq_along(duke_links)) {
  download.file(duke_links[i], destfile = paste0("data/", names(duke_links)[i]), mode = "wb")
}

local_files = list.files("data/", pattern = "*.xlsx", full.names = TRUE)

duke_data = purrr::map_df(
  .x = local_files, .f = readxl::read_excel, sheet = 1, skip = 1
)

duke_data_clean = 
  duke_data |> 
  # a column based operator to select columns by their names
  dplyr::select("REPORT DAY", "HOUR ENDING", "#TOTAL", "TOTAL") |> 
  # a column based operation to rename columns
  dplyr::rename(
    date = "REPORT DAY", hour = "HOUR ENDING", total = "TOTAL", clients = "#TOTAL")


daily_peak_loads = 
  duke_data_clean |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    peak_load_mw = max(total),
    clients = max(clients)
    ) |> 
  dplyr::ungroup() |> 
  dplyr::mutate(
    weekday = lubridate::wday(date, label = TRUE),
    month = lubridate::month(date, label = TRUE)
  )



# * U.S. Holidays ---------------------------------------------------------

# scape tables from web

scrape_holidays = function(year){
  url = paste0("https://www.timeanddate.com/holidays/us/", year)
  
  data = rvest::read_html(url) |> 
    rvest::html_element("table") |> 
    rvest::html_table(header = TRUE) |>
    janitor::clean_names() |>
    dplyr::select(1:4) |> 
    dplyr::slice(-1) |>
    dplyr::filter(type == "Federal Holiday") |> 
    dplyr::mutate(
      date = paste0(date, " ", year) |> lubridate::mdy(),
      
    ) |> 
    dplyr::select(date, name)
  
  return(data)
}

holidays_df = purrr::map_df(2021:2025, scrape_holidays)


# * Cincy Weather ---------------------------------------------------------

meteo_api_key = Sys.getenv("meteo_api_key")

hist_weather_pull = function(lat, long, alt, city){
  resp <- httr2::request("https://meteostat.p.rapidapi.com/point/daily") |>
    httr2::req_url_query(
      lat = lat,
      lon = long,
      alt = alt,
      start = "2021-01-01",
      end = "2025-05-31"
    ) |>
    httr2::req_headers(
      "x-rapidapi-host" = "meteostat.p.rapidapi.com",
      "x-rapidapi-key" = meteo_api_key
    ) |>
    httr2::req_perform()
  
  weather_data <- httr2::resp_body_json(resp)[[2]] |> 
    dplyr::bind_rows() |> 
    dplyr::rename_with(~ paste0(.x, "_", city), -date)
  
  return(weather_data)
}


lats = c(39.1031, 39.5744, 41.5)
longs = c(-84.5120, -83.00, -81.6954)
alts = c(226, 241, 200)
cities = c("cincy", 'columbus', 'cleveland')

weather_data = purrr::pmap(
  .l = list(lat = lats, long = longs, alt = alts, city = cities),
  .f = hist_weather_pull
)

weather_df = purrr::reduce(weather_data, dplyr::full_join, by = "date") |> 
  dplyr::mutate(
    date = lubridate::as_date(date)
  )



# * Combine the data ------------------------------------------------------

df = daily_peak_loads |>
  dplyr::left_join(holidays_df, by = "date") |>
  dplyr::mutate(
    holiday = ifelse(is.na(name), "No", "Yes"),
    name = ifelse(is.na(name), "No Holiday", name)
  ) |> 
  dplyr::left_join(weather_df, by = "date") |> 
  dplyr::mutate(
    lag28 = dplyr::lag(peak_load_mw, 28),
    lag35 = dplyr::lag(peak_load_mw, 35),
    lag42 = dplyr::lag(peak_load_mw, 42),
    lag49 = dplyr::lag(peak_load_mw, 49)
  ) |> 
  # move total column to the end
  dplyr::relocate(peak_load_mw, .after = dplyr::last_col()) |> 
  na.omit()

# save the final data frame
write.csv(df, "data/duke_peak_loads.csv", row.names = FALSE)



# * Simple EDA ------------------------------------------------------------

DataExplorer::plot_correlation(df, maxcat = 7)



# * Modeling in Python ----------------------------------------------------



