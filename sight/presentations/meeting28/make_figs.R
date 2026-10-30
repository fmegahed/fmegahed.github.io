# Session timing chart for Meeting 28.
# Sources: refs/VR Module & Assesment Time.xlsx - Sheet1.csv, refs/SIGHT Time Table - AR timing.csv,
# and the 15-minute baseline and 5-minute breaks stated in the consent form and protocol draft.
# Briefing: Fadel's Oct 30 figures (VR 10 to 15 minutes, drawn at 15; AR 5 minutes).
# Estimates, since nothing has been timed yet: 15 minutes for the TAM and interview, and AR
# assessments at the VR length, because the AR assessment questions do not exist yet.
library(ggplot2)

mins = function(x) {
  p = strsplit(x, ":")[[1]]
  as.numeric(p[1]) + as.numeric(p[2]) / 60
}

# Longest single assessment per machine, since the protocol keeps one assessment for each machine.
one_assess = mins("3:14") + mins("2:51") + mins("4:12")
tam_interview = 15

parts = c("Briefing", "Baseline questionnaires", "Training modules", "Breaks", "Assessments", "TAM + interview (est.)")

rows = rbind(
  data.frame(session = "VR: every module\nand every assessment", part = parts,
             m = c(15, 15, mins("33:03"), 10, mins("30:36"), tam_interview)),
  data.frame(session = "VR: every module and\none assessment per machine", part = parts,
             m = c(15, 15, mins("33:03"), 10, one_assess, tam_interview)),
  data.frame(session = "AR: every module,\nassessments estimated", part = parts[c(1, 3, 4, 5, 6)],
             m = c(5, mins("63:04"), 10, one_assess, tam_interview))
)
rows$part = factor(rows$part, levels = rev(parts))
rows$session = factor(rows$session, levels = rev(unique(rows$session)))

totals = aggregate(m ~ session, rows, sum)
totals$label = sprintf("%d min", round(totals$m))

p = ggplot(rows, aes(x = m, y = session, fill = part)) +
  geom_col(width = 0.6, colour = "white", linewidth = 0.8) +
  geom_vline(xintercept = 90, colour = "#1f2326", linewidth = 0.7, linetype = "22") +
  annotate("text", x = 89.2, y = 3.46, label = "90 minutes per session (consent form)",
           hjust = 1, size = 4.4, colour = "#1f2326") +
  geom_text(data = totals, aes(x = 120.5, y = session, label = label), inherit.aes = FALSE,
            hjust = 0, size = 5.4, fontface = "bold", colour = "#1f2326") +
  scale_fill_manual(
    values = c("Briefing" = "#3E5468", "Baseline questionnaires" = "#8a8f93", "Training modules" = "#c3142d",
               "Breaks" = "#d9d9d6", "Assessments" = "#2563A8", "TAM + interview (est.)" = "#C99700"),
    breaks = parts
  ) +
  scale_x_continuous(limits = c(0, 133), breaks = seq(0, 120, 15), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(x = "Minutes, before consent", y = NULL, fill = NULL) +
  theme_bw(base_size = 16) +
  theme(
    legend.position = "top", legend.justification = "left", legend.text = element_text(size = 12),
    legend.key.width = grid::unit(0.45, "cm"), legend.spacing.x = grid::unit(0.1, "cm"),
    panel.border = element_blank(), panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(), panel.grid.major.x = element_line(colour = "#ececec"),
    axis.ticks = element_blank(), axis.text.y = element_text(colour = "#1f2326"),
    plot.margin = margin(4, 8, 4, 4)
  )

dir.create("imgs", showWarnings = FALSE)
ggsave("imgs/session_time.png", p, width = 11.5, height = 5.6, dpi = 170)
print(totals)
