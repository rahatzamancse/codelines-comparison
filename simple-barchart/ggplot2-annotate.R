# Load required libraries
library(ggplot2)
library(jsonlite)
library(scales)
library(ggrepel)

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
  y = c(1500, 500)
)

# Create annotated barchart
annotated_bar <- ggplot(cars_df, aes(x = price, y = sales, fill = model)) +
  # Add bars
  geom_col(position = position_dodge(width = 2000), width = 2000, alpha = 0.7) +

  # Add custom trend line
  geom_line(
    data = trend_line_df,
    aes(x = x, y = y),
    inherit.aes = FALSE,
    color = "red",
    linetype = "dashed",
    size = 1
  ) +

  # Add annotations to match d3.html exactly

  # Annotation 1: Electric car
  annotate("text",
    x = electric_car$price, y = electric_car$sales + 100,
    label = "Electric cars have highest efficiency",
    fontface = "bold", size = 3.5
  ) +

  # Annotation 2: Sports car
  annotate("text",
    x = sports_car$price, y = sports_car$sales + 100,
    label = "Sports cars are least efficient",
    fontface = "bold", size = 3.5
  ) +

  # Annotation 4: Trend description
  annotate("text",
    x = 40000, y = 1000,
    label = "Trend: Higher price = Lower efficiency",
    color = "red", fontface = "bold", angle = -15, size = 3.5
  ) +

  # Annotation 5: Highlighting hybrid model
  annotate("rect",
    xmin = hybrid_car$price - 1000,
    xmax = hybrid_car$price + 1000,
    ymin = 0,
    ymax = hybrid_car$sales + 100,
    color = "green",
    linetype = "dashed",
    size = 1,
    fill = NA
  ) +

  # Add text for the highlighted car
  annotate("text",
    x = hybrid_car$price + 5000, y = hybrid_car$sales + 100,
    label = "Hybrid: Best balance of price and efficiency",
    color = "green", fontface = "bold", size = 3.5
  ) +

  # Scale settings
  scale_x_continuous(
    name = "Price ($)",
    labels = dollar_format(prefix = "$", suffix = "k", scale = 1 / 1000),
    limits = c(15000, 65000)
  ) +
  scale_y_continuous(
    name = "Sales (units)",
    limits = c(0, 2000)
  ) +
  scale_fill_manual(values = scales::hue_pal()(10)) +

  # Titles and theme
  labs(
    title = "Car Price vs Sales (Annotated)",
    fill = "Car Model"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    axis.title = element_text(face = "bold"),
    legend.position = "right"
  )

# Print the plot
print(annotated_bar)
