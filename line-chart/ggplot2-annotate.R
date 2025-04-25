# Load required libraries
library(ggplot2)
library(dplyr)
library(lubridate)
library(grid)
library(scales)

# Create a function to read and process the data
process_data <- function() {
  # Read the data (assuming stocks.csv is in the same directory)
  data <- read.csv("data/stocks.csv")

  # Parse dates
  data$date <- mdy(data$date)
  data$price <- as.numeric(data$price)

  # Group by symbol and year, calculating mean price
  aggregated_data <- data %>%
    mutate(year = year(date)) %>%
    group_by(symbol, year) %>%
    summarize(price = mean(price), .groups = "drop") %>%
    mutate(date = as.Date(paste0(year, "-01-01")))

  return(aggregated_data)
}

# Create the line chart
create_line_chart <- function(data) {
  # Create base plot
  p <- ggplot(data, aes(x = date, y = price, color = symbol, group = symbol)) +
    geom_line(size = 1) +
    geom_point(size = 3, shape = 21, fill = "white", stroke = 1) +
    scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
    scale_color_brewer(palette = "Set1") +
    labs(
      title = "Stock Prices Line Chart",
      x = "Year",
      y = "Price",
      color = "Symbol"
    ) +
    theme_minimal() +
    theme(
      legend.position = "right",
      panel.grid.minor = element_blank(),
      axis.title = element_text(face = "bold"),
      plot.margin = margin(40, 80, 60, 60)
    )

  return(p)
}

# Add annotations to the chart
add_annotations <- function(p, data) {
  # Calculate regression line
  lm_data <- data %>%
    mutate(date_num = as.numeric(date))

  lm_model <- lm(price ~ date_num, data = lm_data)

  # Create prediction data for regression line
  pred_data <- data.frame(
    date_num = c(min(lm_data$date_num), max(lm_data$date_num))
  )
  pred_data$date <- as.Date(pred_data$date_num, origin = "1970-01-01")
  pred_data$price <- predict(lm_model, newdata = pred_data)

  # Add regression line
  p <- p +
    geom_line(
      data = pred_data, aes(x = date, y = price, group = 1),
      color = "black", linetype = "dashed", size = 1, inherit.aes = FALSE
    ) +
    annotate("text",
      x = as.Date(mean(range(pred_data$date))),
      y = mean(pred_data$price) + 50,
      label = "Trend upward!",
      fontface = "bold", size = 4.5
    )

  # GOOG vs AAPL distance in 2007
  aapl_2007 <- data %>%
    filter(symbol == "AAPL", year == 2007) %>%
    select(date, price)

  goog_2007 <- data %>%
    filter(symbol == "GOOG", year == 2007) %>%
    select(date, price)

  if (nrow(aapl_2007) > 0 && nrow(goog_2007) > 0) {
    p <- p +
      geom_segment(
        x = aapl_2007$date, y = aapl_2007$price,
        xend = goog_2007$date, yend = goog_2007$price,
        color = "gray", linetype = "dashed", size = 1,
        arrow = arrow(length = unit(0.3, "cm"), ends = "both", type = "open")
      ) +
      annotate("text",
        x = aapl_2007$date + days(180),
        y = mean(c(aapl_2007$price, goog_2007$price)),
        label = "Price gap in 2007",
        size = 3.5
      )
  }

  # Empty annotation rectangle
  p <- p +
    annotate("rect",
      xmin = min(data$date) + days(180),
      xmax = min(data$date) + days(730),
      ymin = max(data$price) - 200,
      ymax = max(data$price) - 50,
      fill = NA, color = "gray", linetype = "dashed"
    ) +
    annotate("text",
      x = min(data$date) + days(455),
      y = max(data$price) - 230,
      label = "such empty!",
      size = 3.5
    )

  # Text connector to first GOOG point
  first_goog <- data %>%
    filter(symbol == "GOOG") %>%
    arrange(date) %>%
    slice(1)

  p <- p +
    annotate("text",
      x = first_goog$date + days(365),
      y = first_goog$price - 100,
      label = "First Point!",
      size = 3.5
    ) +
    geom_segment(
      x = first_goog$date, y = first_goog$price,
      xend = first_goog$date + days(300), yend = first_goog$price - 90,
      color = "gray", size = 0.8,
      arrow = arrow(length = unit(0.3, "cm"), type = "open")
    )

  return(p)
}

# Main function to create and display the chart
main <- function() {
  # Process data
  data <- process_data()

  # Create base chart
  p <- create_line_chart(data)

  # Add annotations
  final_plot <- add_annotations(p, data)

  # Display the plot
  print(final_plot)

  # Save the plot
  # ggsave("charts/line-chart/r_line_chart.png", final_plot, width = 10, height = 6, dpi = 300)
}

# Run the main function
main()
