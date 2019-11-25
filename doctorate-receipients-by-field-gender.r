library(readxl)
library(httr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(ggthemes)
library(directlabels)
library(scales)


left_align_title_sub <- function(plot){
  g <- ggplotGrob(plot)
  g$layout$l[g$layout$name == "title"] <- 1
  g$layout$l[g$layout$name == "subtitle"] <- 1
  grid::grid.draw(g)
}

myplot_theme <- theme_wsj() + 
  theme(panel.grid = element_blank(), 
        panel.grid.major = element_blank(),
        axis.text = element_text(face = "bold", size = rel(0.7)),
        rect = element_rect(fill = "gray98"),
        #title = element_text(family = "Helvetica", size = rel(1.2)),
        #plot.caption = element_text(size = rel(0.6)),
        plot.title = element_text(size = rel(0.8), 
                                  face = "bold", 
                                  colour = "#990000", 
                                  hjust = 0, 
                                  family = "Helvetica"),
        plot.subtitle = element_text(size = rel(0.5), family = "Helvetica"),
        plot.caption = element_text(size = rel(0.4), family = "Helvetica"))

tmp <- tempfile(fileext = ".xlsx")

httr::GET(url = "https://ncses.nsf.gov/pubs/nsf19301/assets/data/tables/sed17-sr-tab014.xlsx",
          write_disk(tmp))

data <- read_xlsx(tmp,
                  skip = 5,
                  col_names = c("field_gender", paste(
                    c("Number", "Percent"),
                    rep(seq(
                      from = 1987, to = 2017, by = 5
                    ), each = 2),
                    sep = "_"
                  )))

data <- mutate(
  data,
  field = case_when(
    field_gender == 'Male' ~ lag(field_gender),
    field_gender == 'Female' ~ lag(field_gender, 2),
    TRUE ~ field_gender
  ),
  gender = ifelse(!(field_gender %in% c('Male', 'Female')), 'Total', field_gender)
) %>%
  select(field_gender, field, gender, everything())

data <- select(data, -field_gender) %>% 
  filter(gender != 'Total') %>% 
  pivot_longer(cols = c(-field, -gender), 
               names_to = c("measure", "year"), 
               values_to = "value", 
               names_sep = "_") %>% 
  mutate(year = as.numeric(year))

data_plt <- filter(data, measure == 'Percent', year %in% c(1987, 2017)) %>% 
  mutate(value = value/100)


## slopegraph by gender
g <- ggplot(data = data_plt, 
            aes(x = year, 
                y = value,
                color = field,
                group = field)) +
  geom_line(size = 1.2, alpha = 0.7) + 
  geom_point() + 
  facet_wrap(~ gender)
g

label_colors <- rep("gray80", length(unique(data_plt$field)))
names(label_colors) <- unique(data_plt$field)
label_colors["All fieldsa"] <- "orange"

g <- g + scale_color_manual(values = label_colors)
g

g <- g + scale_x_continuous(breaks = c(1987, 2017), 
                            limits = c(1986.9, 2017.5)) + 
  theme_wsj() 
g
g <- g + scale_y_continuous(labels = percent)
#g <- g + theme(axis.text.y = element_blank(), 
#               panel.grid.major.y = element_blank())
g <- g + theme(legend.position = "none", 
               plot.background = element_rect(fill = "white"), 
               panel.background = element_rect(fill = "white"))
g <- g + geom_dl(aes(label = field, x = year + 0.1), 
                 method = "first.points", 
                 cex = 1)

g <- g + theme(axis.ticks.x = element_line(size = 1), 
               axis.ticks.length = unit(0.2,"cm"))
g <- g + ggtitle("Doctorate Recipients", subtitle= "By broad field of study and sex") + 
  labs(caption = "Source: ncses.nsf.gov") +
  theme(plot.title = element_text(size = 14, 
                                  face = "bold", 
                                  colour = "#990000", 
                                  hjust = 0, 
                                  family = "Helvetica"),
        plot.subtitle = element_text(size = 10, family = "Helvetica"),
        plot.caption = element_text(size = 8, family = "Helvetica"))
g

## dot chart by gender
g <- ggplot(data_plt, aes(x = field, y = value, shape = gender, fill = gender)) + 
  geom_line(aes(group = field), alpha = 0.3) + 
  geom_point(size = 3) +
  scale_y_continuous(label = percent) +
  #scale_y_continuous(limits = c(0, 160), expand = expand_scale(mult = c(0, 0.1))) + 
  coord_flip() + facet_wrap(~ year)



g <- g + ggtitle("Doctorate Recipients", 
                 subtitle= "By broad field of study and sex (filled circles: males; empty circles: females)") + 
  labs(caption = "Source: ncses.nsf.gov") 

g <- g + scale_shape_manual(values = rep(21, 2)) + 
  scale_fill_manual(values = c("Male" = "#FF993F", "Female" = "white")) + 
  scale_color_manual(values = c("Male" = "#B85905", "Female" = "#098894"), guide = FALSE)
g <- g + myplot_theme +
  theme(strip.text.x = element_text(face = "bold", size = rel(1.2)),
        legend.justification = c(1.5, 0),
        legend.position = c(0.07, 1),
        legend.direction = "horizontal",
        legend.title = element_blank(),
        panel.grid.major.y = element_line(color = "white")) 
#g
ggsave(filename = "doctorate-receipients-by-field-year-wrapped.png",
       plot = left_align_title_sub(g),
       width = 8,
       height = 7,
       units = "in",
       dpi = 100)



# wrap by field
g <- ggplot(data = data_plt, 
            aes(x = year, 
                y = value,
                color = gender,
                group = gender)) +
  geom_line(size = 1.2, alpha = 0.7) + 
  geom_point() + 
  facet_wrap(~ field)
g


g <- g + scale_color_manual(values = c("Female" = "gray70", 
                                       "Male" = "gray10"))
#g




g <- g + scale_x_continuous(breaks = c(1987, 2017), 
                            limits = c(1986.9, 2017.5)) +
  myplot_theme

#g
g <- g + scale_y_continuous(labels = percent)

g <- g + theme(legend.position = "none", 
               plot.background = element_rect(fill = "white"), 
               panel.background = element_rect(fill = "white"))

g <- g + theme(axis.ticks.x = element_line(size = 1), 
               axis.ticks.length = unit(0.2,"cm"))
g <- g + ggtitle("Doctorate Recipients", 
                 subtitle= "By broad field of study and sex (darker lines: males; lighter lines: females)") + 
  labs(caption = "Source: ncses.nsf.gov") 

g <- g + theme()
g
ggsave(filename = "doctorate-receipients-by-field-gender-wrapped.png",
       plot = left_align_title_sub(g),
       width = 8,
       height = 7,
       units = "in",
       dpi = 100)
