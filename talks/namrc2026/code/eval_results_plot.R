require(ggtext)

df = readr::read_csv("C:\\Users\\megahefm\\Dropbox\\PC\\Downloads\\merged_output_finished.csv") |> 
  dplyr::mutate(
    model = dplyr::case_when(
      model == "gpt-5-mini-2025-08-07" ~ "GPT-5-Mini",
      model == "gpt-5-nano-2025-08-07" ~ "GPT-5-Nano"
  ),
    approach = dplyr::case_when(
      approach == "graph_eager" ~ "Graph Eager",
      approach == "graph_mmr" ~ "Graph MMR",
      approach == "openai_keyword" ~ "OpenAI Keyword",
      approach == "openai_semantic" ~ "OpenAI Semantic",
      approach == "lc_bm25" ~ "LC BM25",
      approach == "vanilla" ~ "Vanilla"
    ),
  total_elapsed_time = stringr::str_replace(total_elapsed_time, " Seconds", "") |> as.numeric(),
  cost = dplyr::case_when(
    model == "GPT-5-Mini" ~ ((meta_input_tokens*0.25 *10^-6) + (meta_output_tokens*2*10^-6)),
    model == "GPT-5-Nano" ~ ((meta_input_tokens*0.05 *10^-6) + (meta_output_tokens*0.4*10^-6))
    ),
  judge_answer_correctness_vs_ref = as.numeric(judge_answer_correctness_vs_ref),
  judge_answer_helpfulness = as.numeric(judge_answer_helpfulness),
  # if you ended up adding reasoning effort, add below before top_k
  comb_id = paste(model, approach, top_k, sep = "_") |> 
    stringr::str_replace_all(" ", "") |> stringr::str_replace_all("-", "")
  ) |> 
  dplyr::select(
    comb_id,
    question,
    model, approach, top_k, # changable parameters
    max_tokens, reasoning_effort, answer_instructions_id, few_shot_id, replicate, # fixed
    total_elapsed_time,
    cost,
    judge_answer_correctness_vs_ref, judge_answer_helpfulness,
    cosine, rougeL, bleu
  )

# colors
colors = pals::alphabet2(24)
names(colors) = df$comb_id |> as.factor() |> unique()

# Using same colors for text
color_labels = tibble::tibble(
  comb_id = names(colors),
  colored_label = glue::glue(
    "<b><span style='color:{colors}'>{comb_id}</span></b>"
  )
)

label_map = stats::setNames(color_labels$colored_label, color_labels$comb_id)

# Time plot
ggplot2::ggplot(
  df,
  ggplot2::aes(
    y =  forcats::fct_reorder(comb_id, -total_elapsed_time, .fun = median),
    x = total_elapsed_time, 
    color = comb_id
    )
) +
  ggplot2::geom_boxplot(
    fill = "white",
    ) +
  ggplot2::geom_point(
    position = ggplot2::position_jitter(height = -.15),
    alpha = .1,
    size = 1,
  ) +
  # ggdist::stat_halfeye() +
  ggplot2::scale_x_continuous(breaks= scales::pretty_breaks(n=5)) + 
  ggplot2::scale_y_discrete(labels = label_map) +
  ggplot2::scale_color_manual(values = colors) +
  ggplot2::theme_bw() +
  ggplot2::labs(
    title = "",
    y = "",
    x = "Time to last generated character (Sec)"
  ) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    axis.text.y = ggtext::element_markdown(),
    axis.text.x = ggplot2::element_text(face = "bold"),
    axis.title.x = ggplot2::element_text(face = "bold")
  ) -> plot_time


# Cost plot
ggplot2::ggplot(
  df,
  ggplot2::aes(
    y =  forcats::fct_reorder(comb_id, -cost, .fun = median),
    x = cost, 
    color = comb_id
  )
) +
  ggplot2::geom_boxplot(
    fill = "white",
  ) +
  ggplot2::geom_point(
    position = ggplot2::position_jitter(height = -.15),
    alpha = .1,
    size = 1,
  ) +
  # ggdist::stat_halfeye() +
  ggplot2::scale_x_continuous(breaks= scales::pretty_breaks(n=5)) + 
  ggplot2::scale_y_discrete(labels = label_map) +
  ggplot2::scale_color_manual(values = colors) +
  ggplot2::theme_bw() +
  ggplot2::labs(
    title = "",
    y = "",
    x = "Cost of the request (USD)"
  ) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    axis.text.y = ggtext::element_markdown(),
    axis.text.x = ggplot2::element_text(face = "bold"),
    axis.title.x = ggplot2::element_text(face = "bold")
  ) -> plot_cost


# Correctness plot 
df |>
  dplyr::group_by(comb_id) |>
  dplyr::summarise(
    p_correct = mean(judge_answer_correctness_vs_ref, na.rm = TRUE),
    n = dplyr::n()
  ) |>
  dplyr::ungroup() |>
  ggplot2::ggplot(
    ggplot2::aes(
      x = p_correct,
      y = forcats::fct_reorder(comb_id, p_correct),
      color = comb_id
    )
  ) +
  # Add the lollipop stems
  ggplot2::geom_segment(
    ggplot2::aes(
      x = 0, 
      xend = p_correct, 
      yend = comb_id
    ),
    linewidth = 0.7,
    color = "gray60"
  ) +
  # Add the lollipop heads
  ggplot2::geom_point(
    size = 3
  ) +
  ggplot2::geom_text(
    ggplot2::aes(label = scales::percent(p_correct, accuracy = 1)),
    hjust = -0.4,
    size = 2.8
  ) +
  ggplot2::scale_x_continuous(
    limits = c(0, 1.05),
    breaks = seq(0, 1, by = 0.2),
    labels = scales::percent_format(accuracy = 1)
  ) +
  ggplot2::scale_y_discrete(labels = label_map) +
  ggplot2::scale_color_manual(values = colors) +
  ggplot2::theme_bw() +
  ggplot2::labs(
    title = "",
    x = "Share of answers judged correct vs reference",
    y = ""
  ) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    axis.text.y = ggtext::element_markdown(),
    axis.text.x = ggplot2::element_text(face = "bold"),
    axis.title.x = ggplot2::element_text(face = "bold")
  ) -> plot_correctness


bottom_row = ggpubr::ggarrange(
  plot_time, plot_cost, 
  ncol = 2, nrow = 1,
  labels = c("B", "C")
)

ggpubr::ggarrange(
  plot_correctness,
  bottom_row,
  ncol = 1,
  nrow = 2,
  labels = c("A", "")
) -> combined_plot

ggplot2::ggsave(
  filename = "C:\\Users\\megahefm\\Dropbox\\PC\\Downloads\\time_cost_correctness.pdf",
  plot = combined_plot,
  width = 11,
  height = 8,
  dpi = 300
)
