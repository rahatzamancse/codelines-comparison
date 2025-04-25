# Load required libraries
library(ggplot2)
library(dplyr)
library(ggforce) # For ellipses
library(ggrepel) # For text labels that avoid overlapping
library(grid) # For grid graphics
library(gtable) # For modifying the plot layout

# Create a function to read and process the data
process_data <- function() {
  # Read the data (assuming penguins.json is in the same directory)
  # If the file is in JSON format, we'll need jsonlite
  library(jsonlite)
  data <- fromJSON("data/penguins.json")

  # Convert to data frame if it's not already
  if (!is.data.frame(data)) {
    data <- as.data.frame(data)
  }

  # Ensure numeric columns are numeric
  data$`Flipper Length (mm)` <- as.numeric(data$`Flipper Length (mm)`)
  data$`Body Mass (g)` <- as.numeric(data$`Body Mass (g)`)

  return(data)
}

# Create the scatter plot
create_scatter_plot <- function(data) {
  # Calculate data ranges with some padding for annotations
  x_range <- range(data$`Flipper Length (mm)`, na.rm = TRUE)
  y_range <- range(data$`Body Mass (g)`, na.rm = TRUE)
  x_padding <- diff(x_range) * 0.15
  y_padding <- diff(y_range) * 0.15

  # Create base plot
  p <- ggplot(data, aes(
    x = `Flipper Length (mm)`, y = `Body Mass (g)`,
    color = Species, shape = Species
  )) +
    geom_point(size = 3, alpha = 0.8) +
    scale_color_brewer(palette = "Set1") +
    scale_shape_manual(values = c(16, 17, 18)) + # Different shapes for species
    # Expand the plot limits to accommodate annotations
    coord_cartesian(
      xlim = c(x_range[1] - x_padding, x_range[2] + x_padding),
      ylim = c(y_range[1] - y_padding, y_range[2] + y_padding),
      expand = TRUE
    ) +
    labs(
      title = "Penguin Scatterplot",
      x = "Flipper Length (mm)",
      y = "Body Mass (g)"
    ) +
    theme_minimal() +
    theme(
      legend.position = "right",
      panel.grid.minor = element_blank(),
      axis.title = element_text(face = "bold"),
      plot.title = element_text(size = 16, face = "bold"),
      plot.margin = margin(40, 100, 60, 70)
    )

  return(p)
}

# Add annotations to the chart
add_annotations <- function(p, data) {
  # Get Gentoo data for rectangle
  gentoo_data <- data %>% filter(Species == "Gentoo")

  # Calculate mean and standard deviation for Gentoo
  gentoo_x_mean <- mean(gentoo_data$`Flipper Length (mm)`, na.rm = TRUE)
  gentoo_y_mean <- mean(gentoo_data$`Body Mass (g)`, na.rm = TRUE)
  gentoo_x_sd <- sd(gentoo_data$`Flipper Length (mm)`, na.rm = TRUE) * 2
  gentoo_y_sd <- sd(gentoo_data$`Body Mass (g)`, na.rm = TRUE) * 2

  # Calculate rectangle boundaries
  rect_xmin <- gentoo_x_mean - gentoo_x_sd
  rect_xmax <- gentoo_x_mean + gentoo_x_sd
  rect_ymin <- gentoo_y_mean - gentoo_y_sd
  rect_ymax <- gentoo_y_mean + gentoo_y_sd

  # Create a data frame for the rectangle
  rect_df <- data.frame(
    xmin = rect_xmin, xmax = rect_xmax,
    ymin = rect_ymin, ymax = rect_ymax
  )

  # Create a data frame for the Gentoo cluster label
  gentoo_label_df <- data.frame(
    x = gentoo_x_mean,
    y = rect_ymin - (gentoo_y_sd * 0.1),
    label = "Gentoo Cluster"
  )

  # Add Gentoo rectangle instead of ellipse
  p <- p +
    geom_rect(
      data = rect_df,
      aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      fill = scales::hue_pal()(3)[1], alpha = 0.2,
      color = scales::hue_pal()(3)[1], linetype = "dashed",
      inherit.aes = FALSE
    ) +
    geom_text(
      data = gentoo_label_df,
      aes(x = x, y = y, label = label),
      color = scales::hue_pal()(3)[1],
      fontface = "bold",
      size = 4,
      inherit.aes = FALSE
    )

  # Add outlier annotation
  # Find approximate coordinates of outlier
  outlier_x <- 180
  outlier_y <- 5900

  # Find the closest point to these coordinates
  distances <- sqrt((data$`Flipper Length (mm)` - outlier_x)^2 +
    (data$`Body Mass (g)` - outlier_y)^2)
  outlier_index <- which.min(distances)
  outlier_point <- data[outlier_index, ]

  # Ensure outlier point exists before adding annotation
  if (!is.na(outlier_point$`Flipper Length (mm)`) && !is.na(outlier_point$`Body Mass (g)`)) {
    # Create data frames for the segment and label
    segment_df <- data.frame(
      x = outlier_point$`Flipper Length (mm)`,
      y = outlier_point$`Body Mass (g)`,
      xend = outlier_point$`Flipper Length (mm)` + 5,
      yend = outlier_point$`Body Mass (g)` + 100
    )

    outlier_label_df <- data.frame(
      x = outlier_point$`Flipper Length (mm)` + 7,
      y = outlier_point$`Body Mass (g)` + 100,
      label = "Outlier!"
    )

    p <- p +
      geom_segment(
        data = segment_df,
        aes(x = x, y = y, xend = xend, yend = yend),
        arrow = arrow(length = unit(0.3, "cm"), type = "closed"),
        color = "blue",
        size = 0.8,
        inherit.aes = FALSE
      ) +
      geom_text(
        data = outlier_label_df,
        aes(x = x, y = y, label = label),
        color = "blue",
        fontface = "bold",
        size = 4,
        inherit.aes = FALSE
      )
  }

  # Add simple text to top left of the chart
  # Get the plot limits
  x_range <- layer_scales(p)$x$range$range
  y_range <- layer_scales(p)$y$range$range

  if (!is.null(x_range) && !is.null(y_range)) {
    simple_text_df <- data.frame(
      x = x_range[1] + (x_range[2] - x_range[1]) * 0.05, # 5% from left edge
      y = y_range[2] - (y_range[2] - y_range[1]) * 0.05, # 5% from top edge
      label = "This is a simple text"
    )

    p <- p +
      geom_text(
        data = simple_text_df,
        aes(x = x, y = y, label = label),
        hjust = 0,
        size = 4,
        inherit.aes = FALSE
      )
  } else {
    # Fallback if plot limits cannot be determined
    fallback_text_df <- data.frame(
      x = min(data$`Flipper Length (mm)`, na.rm = TRUE),
      y = max(data$`Body Mass (g)`, na.rm = TRUE) * 1.05,
      label = "This is a simple text"
    )

    p <- p +
      geom_text(
        data = fallback_text_df,
        aes(x = x, y = y, label = label),
        hjust = 0,
        size = 4,
        inherit.aes = FALSE
      )
  }

  # Add annotation for Gentoo in the legend
  # This is tricky in ggplot2, so we'll use a different approach
  # We'll add a subtitle with the annotation
  p <- p +
    labs(subtitle = "Note: Gentoo (G for Green) penguins form a distinct cluster")

  return(p)
}

# Main function to create and display the chart
main <- function() {
  # Process data
  data <- tryCatch(
    {
      process_data()
    },
    error = function(e) {
      # If there's an error reading the data, create sample data
      message("Error reading data: ", e$message)
      message("Creating sample penguin data instead...")

      # Create sample data similar to Palmer Penguins
      set.seed(123)
      species <- rep(c("Adelie", "Chinstrap", "Gentoo"), each = 50)

      # Different distributions for each species
      flipper_length <- c(
        rnorm(50, mean = 190, sd = 5), # Adelie
        rnorm(50, mean = 195, sd = 5), # Chinstrap
        rnorm(50, mean = 215, sd = 7) # Gentoo
      )

      body_mass <- c(
        rnorm(50, mean = 3700, sd = 300), # Adelie
        rnorm(50, mean = 3800, sd = 300), # Chinstrap
        rnorm(50, mean = 5000, sd = 400) # Gentoo
      )

      # Add one outlier
      flipper_length[25] <- 180
      body_mass[25] <- 5900

      data.frame(
        Species = species,
        `Flipper Length (mm)` = flipper_length,
        `Body Mass (g)` = body_mass
      )
    }
  )

  # Create base chart
  p <- create_scatter_plot(data)

  # Add annotations
  final_plot <- add_annotations(p, data)

  # Add "G for Gentoo" text below the legend
  # First, convert the plot to a gtable object
  gt <- ggplotGrob(final_plot)

  # Find the legend in the gtable
  legend_index <- which(gt$layout$name == "guide-box")

  if (length(legend_index) > 0) {
    # Get legend position
    legend_pos <- gt$layout[legend_index, c("t", "l", "b", "r")]

    # Create text grob for "G for Gentoo"
    text_grob <- textGrob(
      "G for Gentoo",
      x = unit(0.5, "npc"),
      y = unit(0, "npc"),
      just = c("center", "top"),
      gp = gpar(fontsize = 10, fontface = "italic", col = scales::hue_pal()(3)[1])
    )

    # Add text below the legend
    gt <- gtable_add_grob(
      gt,
      text_grob,
      t = legend_pos$b + 1,
      l = legend_pos$l,
      b = legend_pos$b + 1,
      r = legend_pos$r
    )
  }

  # Display the plot
  grid.newpage()
  grid.draw(gt)
}

# Run the main function
main()
