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
knitr::include_url("https://miamioh.edu/it-services/offices-centers-programs/information-security/security-awareness-tips/phishing.html", height = '550px')
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
countdown::countdown(minutes = 5, bottom = 1.5, right = -0.15)
#
#
#
#| echo: false
#| results: asis

# Read CSV with the 6 columns:
# id, sender_name, sender_email, subject, body_preview, artifacts
msgs <- readr::read_csv("data/phishing_activity_student.csv")

sample_ids <- 1:8

tbl <- msgs |>
  dplyr::filter(id %in% sample_ids) |>
  dplyr::mutate(
    # escape HTML to avoid rendering issues
    sender_name = htmltools::htmlEscape(sender_name),
    sender_email = htmltools::htmlEscape(sender_email),
    subject = htmltools::htmlEscape(subject),
    body_preview = htmltools::htmlEscape(body_preview),
    # trim previews so rows stay readable on a slide
    body_preview = stringr::str_trunc(body_preview, 140, side = "right", ellipsis = "…"),
    zebra = dplyr::if_else(dplyr::row_number() %% 2 == 0, "#fafafa", "#ffffff"),
    row_html = glue::glue(
      "<tr style='background-color:{zebra};'>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top;'><span style=\"color:#666; font-size:14px;\">{id}</span></td>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top;'>{sender_name}<br><span style=\"color:#666; font-size:14px;\">&lt;{sender_email}&gt;</span></td>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top; word-break:break-word;'>{subject}</td>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top; word-break:break-word;'>{body_preview}</td>
       </tr>"
    )
  ) |>
  dplyr::pull(row_html)

cat("
<table style='border-collapse:collapse; width:100%; font-size:18px;'>
  <colgroup>
    <col style='width:4%'>
    <col style='width:23%'>
    <col style='width:23%'>
    <col style='width:50%'>
  </colgroup>
  <thead>
    <tr style='background-color:#c3142d; color:#ffffff;'>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>ID</th>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>Sender</th>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>Subject</th>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>Preview</th>
    </tr>
  </thead>
  <tbody>
")
cat(paste(tbl, collapse = "\n"))
cat("
  </tbody>
</table>
")

#
#
#
