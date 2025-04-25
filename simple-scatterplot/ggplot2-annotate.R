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
  y = c(38, 21)
)

# Create annotated scatterplot
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
  ) +

  # Add annotations to match d3.html exactly

  # Annotation 1: Electric car
  annotate("text",
    x = electric_car$price, y = electric_car$mpg - 5,
    label = "Electric cars have highest efficiency",
    fontface = "bold", size = 3.5
  ) +

  # Annotation 2: Sports car
  annotate("text",
    x = sports_car$price, y = sports_car$mpg + 5,
    label = "Sports cars are least efficient",
    fontface = "bold", size = 3.5
  ) +

  # Annotation 4: Trend description
  annotate("text",
    x = 40000, y = 30,
    label = "Trend: Higher price = Lower efficiency",
    color = "red", fontface = "bold", angle = -15, size = 3.5
  ) +

  # Annotation 5: Highlighting hybrid model
  annotate("rect",
    xmin = hybrid_car$price - 15,
    xmax = hybrid_car$price + 15,
    ymin = hybrid_car$mpg - 15,
    ymax = hybrid_car$mpg + 15,
    color = "green",
    linetype = "dashed",
    size = 1,
    fill = NA
  ) +

  # Add text for the highlighted car
  annotate("text",
    x = hybrid_car$price + 20, y = hybrid_car$mpg - 5,
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
