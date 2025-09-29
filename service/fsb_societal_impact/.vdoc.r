#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| include: false

miamired = "#c3142d"

ggplot2::theme_set(
  ggplot2::theme_bw() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"),
      plot.subtitle = ggtext::element_markdown(size = 12, color = "black"),
      legend.position='none',
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(fill ="#C3142D"),
      strip.text = ggplot2::element_text(color = "white", size = 8, face = "bold"),
      panel.spacing = ggplot2::unit(1, "lines"),
      axis.text = ggplot2::element_text(face = "bold", color = "black"),
      axis.title = ggplot2::element_text(face = "bold", color = "black"),
      plot.caption = ggtext::element_markdown(size = 8, color = "black")
    ) 
)
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
clean_fun <- function(html_string) {
  stringr::str_remove_all(html_string, "<.*?>")
}

df = readr::read_csv("data/Contrib_and_Axis_SDG.csv") |> 
    janitor::clean_names() |> 
    dplyr::rename(
        last_name = name
    )

df_cleaned = 
    df |> 
    dplyr::select(-c(first_name, last_name)) |> 
    unique() |> 
    dplyr::mutate(
        pub_year = stringr::str_extract(citation, "\\(\\d{4}\\)") |>
            stringr::str_remove_all("[()]") |> 
            as.integer(),
        citation = clean_fun(citation) |> stringr::str_to_title(),
        sdg = stringr::str_to_title(sdg)
    ) |> 
    tidyr::separate_rows(sdg, sep = ",") |>
    dplyr::mutate(sdg = stringr::str_squish(sdg)) |>
    dplyr::filter(!is.na(sdg), sdg != "") |>
    dplyr::mutate(has_sdg = 1L) |>
    tidyr::pivot_wider(
        names_from  = sdg,
        values_from = has_sdg,
        values_fill = list(has_sdg = 0L),      # make missing SDGs = 0
        values_fn   = list(has_sdg = max)      # resolve duplicates to 1
    ) |> 
    dplyr::rename(
        no_sdg_listed = None
    ) |> 
    dplyr::mutate(
        industry_innovation_and_infrastructure = pmin(1, Industry + `Innovation And Infrastructure`),
        peace_justice_and_strong_institutions = pmin(1, Peace + `Justice And Strong Institutions`),
    ) |> 
    janitor::clean_names() |> 
    dplyr::select(
        pub_year,
        citation,
        no_sdg_listed,
        no_poverty, zero_hunger,  good_health_and_well_being, quality_education,
        gender_equality, clean_water_and_sanitation, affordable_and_clean_energy, decent_work_and_economic_growth,
        industry_innovation_and_infrastructure, reduce_inequalities, sustainable_cities_and_communities, responsible_consumption_and_production,
        climate_action, life_below_water, life_on_land, peace_justice_and_strong_institutions, partnerships_for_the_goals
    ) |> 
    dplyr::rename_with(
    .fn = ~ paste0("sdg", seq_along(.), "_", .x),
    .cols = no_poverty:partnerships_for_the_goals
  ) |> 
    dplyr::arrange(pub_year)

DT::datatable(
    df_cleaned,
    options = list(
    pageLength = 20, autoWidth = TRUE, scrollX = TRUE,
    dom = 'Bfrtip',
    buttons = c('copy', 'csv', 'excel', 'pdf', 'print')
    )
)
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

#| fig-width: 10in
#| fig-align: center
#| fig-height: 4in

# 1) Summarize by year: total publications and percent by SDG, including "none"
heatmap_wide <- df_cleaned |>
  dplyr::filter(pub_year >= 2016) |>                             # keep recent years only
  dplyr::group_by(pub_year) |>
  dplyr::summarise(
    n_publications = dplyr::n(),                                 # yearly total count
    dplyr::across(
      c(no_sdg_listed, tidyselect::matches("^sdg\\d+_")),        # all SDG indicator columns
      ~ mean(.x) * 100                                           # convert share to percent
    ),
    .groups = "drop"
  )

# 2) Reshape to long format for heatmap cells and build display labels
heatmap_long <- heatmap_wide |>
  tidyr::pivot_longer(
    cols = c(no_sdg_listed, tidyselect::matches("^sdg\\d+_")),   # one row per year x SDG
    names_to = "sdg",
    values_to = "percent"
  ) |>
  dplyr::mutate(
    sdg_display = dplyr::case_when(                              # readable label used on x axis
      sdg == "no_sdg_listed" ~ "none",
      TRUE ~ stringr::str_extract(sdg, "^sdg\\d+")
    ),
    label = sprintf("%.0f%%", percent)                           # text annotation shown in tiles
  )

# 3) Define x axis order: count, none, then sdg1..sdg17
sdg_order <- c("count", "none", stringr::str_c("sdg", 1:17))
heatmap_long <- heatmap_long |>
  dplyr::mutate(sdg_display = factor(sdg_display, levels = sdg_order))

# 4) Build small data frames that feed specific plot layers
count_tiles <- heatmap_wide |>
  dplyr::transmute(
    pub_year,
    sdg_display = factor("count", levels = sdg_order),           # synthetic column for counts
    n_publications = n_publications
  )

none_tiles <- heatmap_long |>
  dplyr::filter(sdg_display == "none")                           # percent with no SDG listed

sdg_tiles <- heatmap_long |>
  dplyr::filter(sdg_display != "none")                           # percents for sdg1..sdg17

# 5) Plot parameters and SDG definitions used in the subtitle
miamired <- "#c3142d"

# SDG definitions in order 1..17
sdg_defs <- c(
  "No Poverty","Zero Hunger","Good Health & Well-Being","Quality Education",
  "Gender Equality","Clean Water & Sanitation","Affordable & Clean Energy",
  "Decent Work & Economic Growth","Industry, Innovation & Infrastructure",
  "Reduced Inequalities","Sustainable Cities & Communities",
  "Responsible Consumption & Production","Climate Action","Life Below Water",
  "Life on Land","Peace, Justice & Strong Institutions","Partnerships for the Goals"
)

# Build colored, bold HTML labels like "<span><b>sdg1:</b></span> No Poverty"
sdg_items <- purrr::imap_chr(sdg_defs, function(def, i) {
  lbl <- paste0("<span style='color:", miamired, ";'><b>sdg", i, ":</b></span> ")
  paste0(lbl, def)
})

# Word-wrap helper that respects HTML spans and only inserts breaks between items
wrap_items_html <- function(items, width = 100) {
  strip_tags <- function(x) stringr::str_replace_all(x, "<[^>]+>", "")
  lines <- character()
  current <- ""
  for (itm in items) {
    sep <- if (current == "") "" else "; "
    proposal <- paste0(current, sep, itm)
    if (nchar(strip_tags(proposal)) > width && current != "") {
      lines <- c(lines, paste0(current, ";"))                    # end previous line with semicolon
      current <- itm
    } else {
      current <- proposal
    }
  }
  lines <- c(lines, current)
  paste(lines, collapse = "<br>")
}

sdg_subtitle_wrapped <- wrap_items_html(sdg_items, width = 120)

# 6) Draw heatmap with three aligned columns of tiles:
#    - a gray "count" column with raw counts
#    - a light gray "none" column with percent having no SDG
#    - a white-to-red gradient for sdg1..sdg17 percents
ggplot2::ggplot() +
  # Count column tiles and labels
  ggplot2::geom_tile(
    data = count_tiles,
    ggplot2::aes(x = sdg_display, y = factor(pub_year)),
    fill = "grey75",
    color = "white"
  ) +
  ggplot2::geom_text(
    data = count_tiles,
    ggplot2::aes(x = sdg_display, y = factor(pub_year), label = n_publications)
  ) +
  # "None" column tiles and labels
  ggplot2::geom_tile(
    data = none_tiles,
    ggplot2::aes(x = sdg_display, y = factor(pub_year)),
    fill = "grey85",
    color = "white"
  ) +
  ggplot2::geom_text(
    data = none_tiles,
    ggplot2::aes(x = sdg_display, y = factor(pub_year), label = label),
    color = "white",
    fontface = "bold"
  ) +
  # SDG 1..17 tiles and labels
  ggplot2::geom_tile(
    data = sdg_tiles,
    ggplot2::aes(x = sdg_display, y = factor(pub_year), fill = percent),
    color = "white"
  ) +
  ggplot2::geom_text(
    data = sdg_tiles,
    ggplot2::aes(x = sdg_display, y = factor(pub_year), label = label)
  ) +
  # Color scale, titles, and caption
  ggplot2::scale_fill_gradient(
    name = "% of publications",
    low = "white",
    high = miamired
  ) +
  ggplot2::labs(
    x = "SDGs",
    y = "Publication Year",
    title = "Publications per Year and SDG Coverage",
    subtitle = sdg_subtitle_wrapped,
    caption = "**Credits:** Created by the *FSB Societal Impact Committee* based on data pulled from Academ on Sept 29, 2025."
  ) +
  # Keep simple x labels and theme
  ggplot2::scale_x_discrete(
    labels = function(x) dplyr::case_when(
      x == "count" ~ "count",
      x == "none"  ~ "none",
      TRUE         ~ x
    )
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    plot.subtitle = ggtext::element_markdown(size = 8, lineheight = 1.1),
    plot.caption  = ggtext::element_markdown(size = 8)
  ) +
  ggplot2::guides(fill = "none")

#
#
#
