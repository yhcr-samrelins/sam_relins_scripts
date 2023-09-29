# Summary: Script to merge corrected data for Bradford Academy provided after 
# it became apparent that original dataset included attendance records for the 
# attached secondary school (not part of the study).

library(tidyverse)

# load and reformat data with wrong B Acad info
raw_attendance_w_wrong_bacad <- read_csv("data/raw_attendance_sep_2021_jun_2022_wrong_bacad.csv")
raw_attendance_w_wrong_bacad <- raw_attendance_w_wrong_bacad %>%
    rename(`Clincally Extremely Vulnerable` = `Clincally Extremely Vunderable`) %>%
    filter(School != "Bradford Academy") %>%
    select(-X1)

# load and reformat correct B Acad data
# normalise column names and formats between two datasets
correct_bacad <- read_csv("data/BradfordAcademy2021Primary.csv")
wrong_names <- raw_attendance_w_wrong_bacad %>% names()
correct_names <- correct_bacad %>% names()
m_from_correct_names <- correct_names[!(correct_names %in% wrong_names)]
correct_bacad <- correct_bacad %>% 
    select(-all_of(m_from_correct_names)) %>%
    mutate(WeekStart = as.Date(WeekStart, format="%m/%d/%y")) 

# drop extra weeks in B Acad Data
correct_weeks <- correct_bacad %>% 
    group_by(WeekStart) %>% 
    count() %>% 
    pull(WeekStart)
wrong_weeks <- raw_attendance_w_wrong_bacad %>% 
    group_by(WeekStart) %>% 
    count() %>% 
    pull(WeekStart)
drop_weeks <- correct_weeks[!(correct_weeks %in% wrong_weeks)]
correct_bacad <- correct_bacad %>% 
    filter(!(WeekStart %in% drop_weeks))

# merge two dataframes and save
raw_attendance_w_wrong_bacad %>%
    rbind(correct_bacad) %>%
    write_csv("data/raw_attendance_sep_2021_jun_2022.csv")