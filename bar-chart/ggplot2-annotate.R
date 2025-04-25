# Load required libraries
library(ggplot2)
library(dplyr)
library(grid)
library(gridExtra)

# Create the same data as in the D3 example
data <- data.frame(
  category = c("A", "A", "A", "B", "B", "B", "C", "C", "C"),
  group = c("x", "y", "z", "x", "y", "z", "x", "y", "z"),
  value = c(0.1, 0.6, 0.9, 0.7, 0.2, 1.1, 0.6, 0.1, 0.2)
)

# Create the base grouped bar chart
p <- ggplot(data, aes(x = category, y = value, fill = group)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7, alpha = 0.8) +
  scale_fill_brewer(palette = "Set1", name = "Group") +
  labs(
    x = "Categories",
    y = "Values",
    title = "Grouped Bar Chart"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold"),
    plot.margin = margin(20, 120, 50, 60)
  )

# Function to create annotation layers
create_annotations <- function(p) {
  # Get position data for annotations
  a_z_data <- data %>% filter(category == "A", group == "z")
  b_z_data <- data %>% filter(category == "B", group == "z")
  c_x_data <- data %>% filter(category == "C", group == "x")

  # Add arrow from A-z to B-z
  p <- p +
    annotate("segment",
      x = 1 - 0.8 / 3, y = a_z_data$value + 0.15,
      xend = 1 - 0.8 / 3, yend = a_z_data$value + 0.3,
      arrow = arrow(length = unit(0.3, "cm")), linewidth = 0.8
    ) +
    annotate("segment",
      x = 1 - 0.8 / 3, y = a_z_data$value + 0.3,
      xend = 2 - 0.8 / 3, yend = a_z_data$value + 0.3,
      linewidth = 0.8
    ) +
    annotate("segment",
      x = 2 - 0.8 / 3, y = a_z_data$value + 0.3,
      xend = 2 - 0.8 / 3, yend = b_z_data$value,
      arrow = arrow(length = unit(0.3, "cm")), linewidth = 0.8
    ) +
    annotate("text",
      x = 1.5, y = a_z_data$value + 0.35,
      label = "Value increase", size = 3.5
    )

  # Add rectangle highlight for C-x
  dodge_width <- 0.8
  bar_width <- 0.7
  group_width <- bar_width / 3

  p <- p +
    annotate("rect",
      xmin = 3 - dodge_width / 2 + 0.05,
      xmax = 3 - dodge_width / 2 + group_width - 0.05,
      ymin = 0,
      ymax = c_x_data$value + 0.1,
      alpha = 0, color = "black", linewidth = 1
    ) +
    annotate("text",
      x = 3 - dodge_width / 3,
      y = c_x_data$value + 0.15,
      label = "Group C x value", size = 3.5
    )

  # Add curly brace for A and B categories
  p <- p +
    annotate("text",
      x = 1.5,
      y = -0.15,
      label = "Categories A and B", size = 3.5
    )

  # We can't easily draw a curly brace in ggplot2, so we'll use a straight line with small vertical segments
  p <- p +
    annotate("segment", x = 0.7, xend = 2.3, y = -0.1, yend = -0.1, linewidth = 0.8) +
    annotate("segment", x = 0.7, xend = 0.7, y = -0.1, yend = -0.05, linewidth = 0.8) +
    annotate("segment", x = 2.3, xend = 2.3, y = -0.1, yend = -0.05, linewidth = 0.8)

  return(p)
}

# Apply annotations
final_plot <- create_annotations(p)

# Display the plot
print(final_plot)

# Save the plot
# ggsave("charts/bar-chart/r_grouped_bar_chart.png", final_plot, width = 8, height = 6, dpi = 300)
