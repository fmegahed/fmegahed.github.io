# hl_r(): render R source as HTML styled like Fadel's RStudio ("Tomorrow Night Bright" on #222222,
# rainbow parentheses, function-call highlighting). Colors were sampled from a screenshot of his editor:
#   identifiers #dedede | pkg before :: #e7c547 | function calls #7aa6da | strings #b9ca4a
#   numbers and TRUE/FALSE/NULL/NA #e78c45 | operators, = and , #70c0b1 | comments #969896
#   brackets by depth: #ed90a4 (pink), #d3a263 (tan), #99b657 (green), repeating
#
# Line highlighting: end a line with `#<<` (the knitr marker). If that line opens a bracket that closes on a
# later line, the highlight extends through the closing line, so a call broken over several lines is
# highlighted as a unit. Highlighted lines get a pulsing ">" in the left gutter (CSS). Moving the cursor over
# any line highlights it.
#
# Usage in a xaringan deck:
#   1. add "../../style_files/code-tomorrow-night-bright.css" to the YAML css list
#   2. source("../../style_files/hl_r.R") in the setup chunk
# Every echoed chunk then renders through hl_r() (knitr source hook), and chunk OUTPUT, warnings, messages
# and errors are rendered as raw HTML console blocks (<pre class='rout'>), so nothing a chunk produces is
# exposed to remark's markdown parser (which otherwise mangles output inside .pull-left[ ] / .panel[ ]).
# Chunk option hl.size = "70%" sets the source font size. Chunks that emit HTML (kable, htmltools)
# must use results = "asis", which bypasses the output hook.
# Call hl_r() directly inside raw HTML with `r hl_r(knitr::knit_code$get("label"), "64%")`.

hl_r = function(lines, size = "80%") {
  lines = unlist(strsplit(paste(lines, collapse = "\n"), "\n", fixed = TRUE))
  esc = function(x) {
    x = gsub("&", "&amp;", x, fixed = TRUE)
    x = gsub("<", "&lt;", x, fixed = TRUE)
    gsub(">", "&gt;", x, fixed = TRUE)
  }
  bracket_cols = c("#ed90a4", "#d3a263", "#99b657")
  # operators (already HTML-escaped), longest first so "|>" wins over "|" and ">"
  ops = c("|&gt;", "&lt;&lt;-", "&lt;-", "-&gt;", "==", "!=", "&lt;=", "&gt;=", "%in%", "%%", "%/%",
          "&amp;&amp;", "||", "&lt;", "&gt;", "&amp;", "|", "+", "-", "*", "/", "^", "=", ",", "!", "~")
  env = new.env(); env$depth = 0L; env$hl_until = NA_integer_

  one = function(l) {
    marked = grepl("#<<\\s*$", l); l = sub("\\s*#<<\\s*$", "", l)
    depth_before = env$depth
    hi = marked || (!is.na(env$hl_until))
    if (!nzchar(trimws(l))) {
      cls = if (hi) "rl rhl" else "rl"
      return(sprintf("<span class='%s'>&nbsp;</span>", cls))
    }
    sm = gregexpr("\"[^\"]*\"|'[^']*'", l); strs = regmatches(l, sm)[[1]]
    if (length(strs)) regmatches(l, sm) = list(paste0("\001", strrep("Q", seq_along(strs)), "\001"))
    code = l; com = ""
    m = regexpr("#.*$", l)
    if (m > 0) { code = substr(l, 1, m - 1); com = substr(l, m, nchar(l)) }
    code = esc(code)
    for (i in seq_along(ops)) code = gsub(ops[i], paste0("\002", strrep("O", i), "\002"), code, fixed = TRUE)
    code = gsub("([A-Za-z.][A-Za-z0-9._]*)::", "<span class='rpkg'>\\1</span>::", code, perl = TRUE)
    code = gsub("([A-Za-z.][A-Za-z0-9._]*)\\(", "<span class='rfun'>\\1</span>(", code, perl = TRUE)
    code = gsub("\\b(TRUE|FALSE|NULL|NA|NaN|Inf)\\b", "<span class='rkw'>\\1</span>", code, perl = TRUE)
    code = gsub("\\b(function|if|else|for|while|in|return|next|break)\\b", "<span class='rkey'>\\1</span>", code, perl = TRUE)
    code = gsub("(?<![A-Za-z0-9_.])(\\d+\\.?\\d*(e[+-]?\\d+)?L?)(?![A-Za-z0-9_])", "<span class='rnum'>\\1</span>", code, perl = TRUE)
    chars = strsplit(code, "")[[1]]
    out = character(length(chars))
    for (k in seq_along(chars)) {
      ch = chars[k]
      if (ch %in% c("(", "[", "{")) {
        col = bracket_cols[env$depth %% length(bracket_cols) + 1]; env$depth = env$depth + 1L
        out[k] = sprintf("<span style='color:%s'>%s</span>", col, ch)
      } else if (ch %in% c(")", "]", "}")) {
        env$depth = max(env$depth - 1L, 0L); col = bracket_cols[env$depth %% length(bracket_cols) + 1]
        out[k] = sprintf("<span style='color:%s'>%s</span>", col, ch)
      } else out[k] = ch
    }
    code = paste(out, collapse = "")
    for (i in seq_along(ops)) code = gsub(paste0("\002", strrep("O", i), "\002"), sprintf("<span class='rop'>%s</span>", ops[i]), code, fixed = TRUE)
    for (i in seq_along(strs)) code = sub(paste0("\001", strrep("Q", i), "\001"), sprintf("<span class='rstr'>%s</span>", esc(strs[i])), code, fixed = TRUE)
    if (nzchar(com)) {
      for (i in seq_along(strs)) com = sub(paste0("\001", strrep("Q", i), "\001"), strs[i], com, fixed = TRUE)
      code = paste0(code, sprintf("<span class='rcom'>%s</span>", esc(com)))
    }
    if (marked && env$depth > depth_before) env$hl_until = depth_before
    if (!is.na(env$hl_until) && env$depth <= env$hl_until) env$hl_until = NA_integer_
    cls = if (hi) "rl rhl" else "rl"
    sprintf("<span class='%s'>%s</span>", cls, code)
  }
  paste0("<pre class='rcode' style='font-size:", size, ";'>", paste(vapply(lines, one, ""), collapse = ""), "</pre>")
}

# Console-style block for chunk results (output, messages, warnings, errors): raw HTML, no markdown exposure.
hl_out = function(x, size = "80%", kind = "rout") {
  x = paste(x, collapse = "")
  x = sub("\n+$", "", x)
  x = gsub("&", "&amp;", x, fixed = TRUE); x = gsub("<", "&lt;", x, fixed = TRUE); x = gsub(">", "&gt;", x, fixed = TRUE)
  x = gsub("\n\n", "\n&nbsp;\n", x, fixed = TRUE)       # a blank line would end the HTML block in remark
  paste0("\n<pre class='rout ", kind, "' style='font-size:", size, ";'>", x, "</pre>\n")
}

knitr::opts_chunk$set(comment = "")   # console look: no "##" in front of results

knitr::knit_hooks$set(
  source  = function(x, options) { s = if (!is.null(options$hl.size)) options$hl.size else "80%"; paste0("\n", hl_r(x, s), "\n") },
  output  = function(x, options) { if (identical(options$results, "asis")) return(x); hl_out(x, if (!is.null(options$hl.size)) options$hl.size else "80%") },
  message = function(x, options) hl_out(x, if (!is.null(options$hl.size)) options$hl.size else "80%", "rmsg"),
  warning = function(x, options) hl_out(x, if (!is.null(options$hl.size)) options$hl.size else "80%", "rwarn"),
  error   = function(x, options) hl_out(x, if (!is.null(options$hl.size)) options$hl.size else "80%", "rerr")
)
