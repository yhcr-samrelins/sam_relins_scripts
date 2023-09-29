# Summary: script to clean and transform latest version of attendance data 
# provided by Bradford Council IMT. Resulting cleaned/transformed table uploaded 
# to Connected Bradford Google Cloud at `CB_CLASS_ACT.attendance`

library(tidyverse)
library(stringr)
library(foreach)
library(gridExtra)

setwd("~/Documents/BIHR/class_act/")

raw_attendance <- read_csv("data/raw_attendance_sep_2021_jun_2022.csv") %>%
    select(School, WeekStart, WeekMarks)

# Infer chars for attendance string with less than 14 sessions
add_missing_att_chars <- function(att_string) {
    if (is.na(att_string)) {
        output <- "______________"
    } else if (nchar(att_string) == 14) {
        output <- att_string
    } else if (nchar(att_string) == 10 & str_count(att_string, "#") == 0) {
        output <- paste(att_string, "####", sep="")
    } else if (nchar(att_string) > 10 & str_sub(att_string, start=-1) == "#") {
        tail_chars <- str_dup("#", 14 - nchar(att_string))
        output <- paste(att_string, tail_chars, sep="")
    } else {
        tail_chars <- str_dup("_", 14 - nchar(att_string))
        output <- paste(att_string, tail_chars, sep="")
    }
    return(output)
}

# vectorise missing chars function
correct_att_vector <- function(att_vector) {
    output <- foreach(i=1:length(att_vector)) %do% 
        add_missing_att_chars(att_vector[i])
    return(unlist(output))
}

# infer missing chars for raw attendance data
raw_attendance <- raw_attendance %>% 
    mutate(att_string = correct_att_vector(WeekMarks))

# group by week and school and collapse attendance strings into one long string
attendance <- raw_attendance %>%  
    group_by(School, WeekStart) %>% 
    summarise(pupils = n(),
              att_string = paste(att_string, collapse=""))

# define characters and descriptions for atteandance strings
att_chars <- c(
    "_", "-", ";", "\\(", "\\)", "\\[", "\\]", "\\{", "\\}", "\\*", "/", "\\\\",
    "#", "^", "\\+", "=", "B", "C", "D", "E", "G", "H", "I", "J", "L", "M", "N", 
    "O", "P", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
)
char_descriptions <- c(
    "Unk", "Unk", "I02", "X02", "Unk", "Unk", "X09", "X06", "X07", "Unk", "am", 
    "pm","#", "X08", "X01", "I01", "B", "C", "D", "E", "G", "H", "I", "J", "L", 
    "M", "N", "O", "P", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
)
unique_descriptions <- unique(unlist(char_descriptions))

# create a column for each unique attendance type
for (description in unique_descriptions) {
    attendance[description] <- 0
}

# add counts of each attendance type to data
for (i in 1:length(att_chars)) {
    char <- att_chars[i]
    char_count <- str_count(attendance$att_string, char)
    desc <- char_descriptions[i]
    attendance[desc] <- attendance[desc] + char_count 
}

# Shorten school names to more manageable length
attendance <- attendance %>% 
  mutate(School = replace(School, 
                          School == "St Joseph's Catholic Primary School (Bingley)",  
                          "St Joseph's Bingley")) %>%
  mutate(School = replace(School, 
                          School == "St Joseph's Catholic Primary School (Bradford)",  
                          "St Joseph's Bradford")) %>% 
  mutate(School = replace(School, 
                          School == "The Academy At St. James",  
                          "Academy At St.James"))

shorten_name <- function(name) {
    words = unlist(strsplit(name, " "))
    if(length(words) >= 3) {
      paste(words[1:3], collapse=" ")
    } else {
      paste(words, collapse=" ")
    }
}
attendance <- attendance %>%
  mutate(School = sapply(School, shorten_name))

# drop massive attendance string
attendance <- attendance %>% select(-att_string)

# Add figures for present in school and illness absence
in_school_codes = c("am", "pm", "L", "U")
illness_codes = c("I", "I01", "I02", "X02")
attendance <- attendance %>% 
    mutate(in_school = rowSums(across(in_school_codes)),
           ill = rowSums(across(illness_codes))) %>% 
    mutate(pct_in_school = in_school / (pupils * 14 - `#`),  
           prop_absent_ill = ill /in_school ) %>%
    replace(is.na(.), 0)

# read in anonymisation key and merge with attendance data
school_codes <- read_csv("~/Documents/BIHR/class_act/data/school_keys.csv") %>%
    select(School_AnonID_old, School, msoa)  %>% 
    drop_na() 
anon_attendance <- left_join(attendance, school_codes, by="School") %>%
    rename(closed = `#`, School_AnonID = School_AnonID_old) %>% 
    ungroup() %>% 
    relocate(School_AnonID)  %>% 
    filter(!is.na(School_AnonID)) %>% 
    select(-School) 

save_name <- paste(
    "data/checkpoints/anon_attendance_ckpt_",  Sys.Date(), ".csv", 
    sep = ""
)

# Save anonymised attendance data
anon_attendance %>%  write_csv(save_name)
