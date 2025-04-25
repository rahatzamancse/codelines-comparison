# Load required libraries
library(ggplot2)
library(dplyr)
library(grid)
library(gridExtra)
library(gtable)

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
  # Expand y-axis limits to make room for annotations
  scale_y_continuous(expand = expansion(mult = c(0.1, 0.3))) +
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
    # Increase plot margins to prevent annotations from being cut off
    plot.margin = margin(40, 120, 80, 60)
  )

# Function to manually add annotations directly to the ggplot
create_manual_annotations <- function(p) {
  # Get position data for annotations
  a_z_data <- data %>% filter(category == "A", group == "z")
  b_z_data <- data %>% filter(category == "B", group == "z")
  c_x_data <- data %>% filter(category == "C", group == "x")

  # Define colors for clarity
  arrow_color <- "darkblue"
  text_color <- "black"
  rect_color <- "darkred"

  # Add arrow annotations with grobs using annotation_custom
  p <- p +
    # Arrow from A-z to B-z (vertical segment up)
    annotation_custom(
      grob = segmentsGrob(
        x0 = unit(0, "npc"), y0 = unit(0, "npc"),
        x1 = unit(0, "npc"), y1 = unit(1, "npc"),
        gp = gpar(lwd = 2, col = arrow_color),
        arrow = arrow(length = unit(0.3, "cm"))
      ),
      xmin = 0.9, xmax = 1.1,
      ymin = a_z_data$value, ymax = a_z_data$value + 0.3
    ) +
    # Horizontal segment
    annotation_custom(
      grob = segmentsGrob(
        x0 = unit(0, "npc"), y0 = unit(0.5, "npc"),
        x1 = unit(1, "npc"), y1 = unit(0.5, "npc"),
        gp = gpar(lwd = 2, col = arrow_color)
      ),
      xmin = 1, xmax = 2,
      ymin = a_z_data$value + 0.25, ymax = a_z_data$value + 0.35
    ) +
    # Vertical segment down with arrow
    annotation_custom(
      grob = segmentsGrob(
        x0 = unit(0, "npc"), y0 = unit(1, "npc"),
        x1 = unit(0, "npc"), y1 = unit(0, "npc"),
        gp = gpar(lwd = 2, col = arrow_color),
        arrow = arrow(length = unit(0.3, "cm"))
      ),
      xmin = 1.9, xmax = 2.1,
      ymin = b_z_data$value, ymax = a_z_data$value + 0.3
    ) +
    # Text for increase annotation
    annotation_custom(
      grob = textGrob(
        "Value increase",
        gp = gpar(fontsize = 10, col = text_color)
      ),
      xmin = 1.3, xmax = 1.7,
      ymin = a_z_data$value + 0.35, ymax = a_z_data$value + 0.45
    ) +
    # Rectangle highlight for C-x
    annotation_custom(
      grob = rectGrob(
        gp = gpar(lwd = 2, fill = NA, col = rect_color)
      ),
      xmin = 2.73, xmax = 2.93,
      ymin = 0, ymax = c_x_data$value + 0.1
    ) +
    # Text for C-x annotation
    annotation_custom(
      grob = textGrob(
        "Group C x value",
        gp = gpar(fontsize = 10, col = text_color)
      ),
      xmin = 2.8, xmax = 3.3,
      ymin = c_x_data$value + 0.15, ymax = c_x_data$value + 0.25
    ) +
    # Text for A and B categories
    annotation_custom(
      grob = textGrob(
        "Categories A and B",
        gp = gpar(fontsize = 10, col = text_color)
      ),
      xmin = 1.3, xmax = 1.7,
      ymin = -0.2, ymax = -0.1
    ) +
    # Horizontal line for "curly brace"
    annotation_custom(
      grob = segmentsGrob(
        x0 = unit(0, "npc"), y0 = unit(0.5, "npc"),
        x1 = unit(1, "npc"), y1 = unit(0.5, "npc"),
        gp = gpar(lwd = 2)
      ),
      xmin = 0.7, xmax = 2.3,
      ymin = -0.15, ymax = -0.05
    ) +
    # Left vertical segment for "curly brace"
    annotation_custom(
      grob = segmentsGrob(
        x0 = unit(0.5, "npc"), y0 = unit(0, "npc"),
        x1 = unit(0.5, "npc"), y1 = unit(1, "npc"),
        gp = gpar(lwd = 2)
      ),
      xmin = 0.65, xmax = 0.75,
      ymin = -0.15, ymax = -0.05
    ) +
    # Right vertical segment for "curly brace"
    annotation_custom(
      grob = segmentsGrob(
        x0 = unit(0.5, "npc"), y0 = unit(0, "npc"),
        x1 = unit(0.5, "npc"), y1 = unit(1, "npc"),
        gp = gpar(lwd = 2)
      ),
      xmin = 2.25, xmax = 2.35,
      ymin = -0.15, ymax = -0.05
    )

  return(p)
}

# Create and display the annotated plot
final_plot <- create_manual_annotations(p)

# Display the plot
print(final_plot)

# Save the plot with increased size to ensure all annotations are visible
# ggsave("charts/bar-chart/r_grouped_bar_chart.png", final_plot, width = 10, height = 8, dpi = 300)
