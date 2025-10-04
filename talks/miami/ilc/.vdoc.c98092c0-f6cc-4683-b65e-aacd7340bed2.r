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
countdown::countdown(minutes = 5, top = "-0.35in", right="-0.5in", margin = "0.02em")
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
    sender_name  = htmltools::htmlEscape(sender_name),
    sender_email = htmltools::htmlEscape(sender_email),
    subject      = htmltools::htmlEscape(subject),
    body_preview = htmltools::htmlEscape(body_preview),
    # trim previews so rows stay readable on a slide
    body_preview = stringr::str_trunc(body_preview, 140, side = "right", ellipsis = "…"),
    zebra        = dplyr::if_else(dplyr::row_number() %% 2 == 0, "#fafafa", "#ffffff"),
    row_html     = glue::glue(
      "<tr data-id='{id}' style='background-color:{zebra};'>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top;'>
           <span style=\"color:#666; font-size:14px;\">{id}</span>
         </td>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top;'>
           {sender_name}<br>
           <span style=\"color:#666; font-size:14px;\">&lt;{sender_email}&gt;</span>
         </td>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top; word-break:break-word;'>{subject}</td>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top; word-break:break-word;'>{body_preview}</td>
         <td style='border:1px solid #ccc; padding:8px; vertical-align:top;'>
           <select data-classify style='width:100%; font-size:16px; padding:4px;'>
             <option value=''>— choose —</option>
             <option value='Legit'>Legit</option>
             <option value='Spam'>Spam</option>
           </select>
         </td>
       </tr>"
    )
  ) |>
  dplyr::pull(row_html)

cat("
<table data-phish-table='1' style='border-collapse:collapse; width:100%; font-size:18px;'>
  <colgroup>
    <col style='width:3%'>
    <col style='width:22%'>
    <col style='width:22%'>
    <col style='width:39%'>
    <col style='width:13%'>
  </colgroup>
  <thead>
    <tr style='background-color:#c3142d; color:#ffffff;'>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>ID</th>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>Sender</th>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>Subject</th>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>Preview</th>
      <th style='border:1px solid #c3142d; padding:8px; text-align:left;'>Your Solution</th>
    </tr>
  </thead>
  <tbody>
")
cat(paste(tbl, collapse = "\n"))
cat("
  </tbody>
</table>

<div style='margin-top:8px; text-align:right;'>
  <button id='export-phish' style='font-size:14px; padding:6px 10px; border:1px solid #ccc; background:#f7f7f7; border-radius:6px;'>
    Download CSV of your classifications
  </button>
</div>

<script>
(function(){
  const btn = document.getElementById('export-phish');
  if(!btn) return;
  btn.addEventListener('click', function(){
    const rows = Array.from(document.querySelectorAll(\"table[data-phish-table] tbody tr\")) || [];
    const header = 'id,classification';
    const lines = [header];
    rows.forEach(function(tr){
      const id  = tr.getAttribute('data-id') || '';
      const sel = tr.querySelector('select[data-classify]');
      const val = sel ? sel.value : '';
      // avoid commas issues by quoting values
      lines.push('\"' + id + '\",\"' + val + '\"');
    });
    const blob = new Blob([lines.join('\\n')], {type:'text/csv'});
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href = url;
    a.download = 'phishing_classifications.csv';
    document.body.appendChild(a);
    a.click();
    URL.revokeObjectURL(url);
    a.remove();
  });
})();
</script>
")
#
#
#
#
#
# Load data
msgs <- readr::read_csv("data/phishing_activity_student.csv") |>
  dplyr::select(id, sender_email, subject, body_preview) |>
  dplyr::slice(1:8)

system_prompt <- ""  # <-- students fill this in

# Schema for one row
one_row_schema <- ellmer::type_object(
  id = ellmer::type_integer("Row id"),
  classification = ellmer::type_enum(c("Legit", "Spam"), "Label"),
  rationale = ellmer::type_string("Short reason", required = FALSE)
)

# Chat handle
chat <- ellmer::chat_openai(
  system_prompt = system_prompt,
  model = "gpt-5-mini-2025-08-07"
)

# Iterate rows with purrr and request structured output per row
classify_one <- function(id, sender_email, subject, body_preview) {
  user_msg <- paste0(
    "Classify this message as Legit or Spam and explain briefly.\n",
    "id: ", id, "\n",
    "sender_email: ", sender_email, "\n",
    "subject: ", subject, "\n",
    "body_preview: ", body_preview, "\n"
  )
  res <- chat$chat_structured(
    user_msg,
    type = one_row_schema
  )
  tibble::as_tibble(res)
}

out <- purrr::pmap_dfr(
  msgs,
  classify_one
)

out

#
#
#
#
#
