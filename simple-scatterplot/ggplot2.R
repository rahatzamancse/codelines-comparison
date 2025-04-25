# Load required libraries
library(ggplot2)
library(jsonlite)
library(scales)
library(ggrepel)
library(grid)

# Read the JSON data file
cars_data <- fromJSON("data/input.json")

# Convert to data frame
cars_df <- as.data.frame(cars_data)

# Extract specific car models for annotations
electric_car <- cars_df[cars_df$model == "Electric", ]
sports_car <- cars_df[cars_df$model == "Sports", ]
hybrid_car <- cars_df[cars_df$model == "Hybrid", ]

# Create a data frame for the custom trend line
trend_line_df <- data.frame(
  x = c(20000, 60000),
  y = c(38, 21)
)

# Custom annotation functions
add_text_annotation <- function(plot, x, y, label, color = "black", fontface = "bold", angle = 0, size = 3.5) {
  plot +
    geom_text(
      data = data.frame(x = x, y = y, label = label),
      aes(x = x, y = y, label = label),
      inherit.aes = FALSE,
      color = color,
      fontface = fontface,
      angle = angle,
      size = size
    )
}

add_rectangle_annotation <- function(plot, xmin, xmax, ymin, ymax, color = "black", linetype = "dashed", size = 1, fill = NA) {
  plot +
    geom_rect(
      data = data.frame(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      inherit.aes = FALSE,
      color = color,
      linetype = linetype,
      size = size,
      fill = fill
    )
}

# Create base scatterplot
annotated_scatter <- ggplot(cars_df, aes(x = price, y = mpg, color = model)) +
  # Add points
  geom_point(size = 3, alpha = 0.7) +

  # Add custom trend line
  geom_line(
    data = trend_line_df,
    aes(x = x, y = y),
    inherit.aes = FALSE,
    color = "red",
    linetype = "dashed",
    size = 1
  )

# Apply annotations using custom functions
# Annotation 1: Electric car
annotated_scatter <- add_text_annotation(
  annotated_scatter,
  x = electric_car$price,
  y = electric_car$mpg - 5,
  label = "Electric cars have highest efficiency"
)

# Annotation 2: Sports car
annotated_scatter <- add_text_annotation(
  annotated_scatter,
  x = sports_car$price,
  y = sports_car$mpg + 5,
  label = "Sports cars are least efficient"
)

# Annotation 3: Trend description
annotated_scatter <- add_text_annotation(
  annotated_scatter,
  x = 40000,
  y = 30,
  label = "Trend: Higher price = Lower efficiency",
  color = "red",
  angle = -15
)

# Annotation 4: Highlighting hybrid model
annotated_scatter <- add_rectangle_annotation(
  annotated_scatter,
  xmin = hybrid_car$price - 15,
  xmax = hybrid_car$price + 15,
  ymin = hybrid_car$mpg - 15,
  ymax = hybrid_car$mpg + 15,
  color = "green"
)

# Annotation 5: Hybrid text
annotated_scatter <- add_text_annotation(
  annotated_scatter,
  x = hybrid_car$price + 20,
  y = hybrid_car$mpg - 5,
  label = "Hybrid: Best balance of price and efficiency",
  color = "green"
)

# Apply scales and theme
annotated_scatter <- annotated_scatter +
  # Scale settings
  scale_x_continuous(
    name = "Price ($)",
    labels = dollar_format(prefix = "$", suffix = "k", scale = 1 / 1000),
    limits = c(15000, 65000)
  ) +
  scale_y_continuous(
    name = "Fuel Efficiency (MPG)",
    limits = c(0, 140)
  ) +
  scale_color_manual(values = scales::hue_pal()(10)) +

  # Titles and theme
  labs(
    title = "Car Price vs Fuel Efficiency (Annotated)",
    color = "Car Model"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    axis.title = element_text(face = "bold"),
    legend.position = "right"
  )

# Print the plot
print(annotated_scatter)
