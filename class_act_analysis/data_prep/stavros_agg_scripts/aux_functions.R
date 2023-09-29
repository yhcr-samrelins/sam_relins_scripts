
overwrite_table <- function(df, con, tbl_name) {

  dbWriteTable(conn = con,
             name = tbl_name,
             value = df,
             as_bq_fields(df),
             overwrite = TRUE,
             append = FALSE)
  
}

# ------------------------------------------------------

check_avail_YearWeek <- function(con){
  
  YearWeek_avail <- con %>%
    dplyr::tbl("df_AIRQ") %>% 
    select(YearWeek) %>% 
    distinct() %>%
    arrange(YearWeek) %>%
    collect()

}

# ======================================================

filter_junk <- function(df, df_key) {
  # Filters out "junk" (useless) data which fall into one of the following categories:
  # 1. School closure dates
  # 2. Days with incomplete / sparse measurements during occupied hours
  # 3. Potentially erroneous data (unphysically high values) during occupied hours
  
  Holidays <- as.Date(c(
    #  ------------ 2022/23 ------------
    seq(ymd("2022-08-01"), ymd("2022-09-02"),"days"),
    seq(ymd("2022-10-24"), ymd("2022-10-26"),"days"),
    seq(ymd("2022-12-16"), ymd("2023-01-02"),"days"),
    seq(ymd("2023-02-13"), ymd("2023-02-15"),"days"),
    seq(ymd("2023-04-03"), ymd("2023-04-14"),"days"),
    seq(ymd("2023-05-29"), ymd("2023-06-02"),"days")), "%d-%m-%Y") #summer holidays
    
  stats_day_school <- stats_daily(df, "Classroom") #%>% collect()
  
  filt_stats_day_school <- stats_day_school %>% 
    filter(!(Date %in% !!Holidays)) %>% # Exclude holidays
    filter(CO2_n >= ((16-9)*60)*0.75) %>% # Days when data completeness is < 75%
    filter(CO2_mean < 3500) %>% # CO2 threshold
    filter(PM10_mean < 500) %>% # PM threshold
    filter(PM10_max < 10000) %>% # PM max threshold
    filter(Temp_mean < 37.5) # Temperature threshold
  
  to_exclude <- stats_day_school %>% 
    anti_join(filt_stats_day_school, by=c("School_ID", "Classroom", "Date")) %>% 
    select(School_ID, Classroom, Date) %>% 
    mutate(Classroom = as.character(Classroom)) %>% 
    left_join(select(df_key, c("School_ID", "Classroom", "Device_ID")), by=c("School_ID", "Classroom")) %>%
    mutate(Classroom = as.integer(Classroom))
  
  # MESSAGE TO THE USER (requires local tables)
  #cat("\r...", nrow(to_exclude), " days excluded (",
  #    round(nrow(to_exclude)/nrow(stats_day_school)*100), "% of total)\n",
  #    "...", length(unique(to_exclude$Device_ID)), " of ", nrow(df_key), " sensors with faulty measurements", 
  #    #"(", round(length(unique(df_filt$Device_ID))/nrow(df_key)*100), "%)", 
  #    sep="")
  
  # ---------------------------
  
  df_clean <- df %>% 
    mutate(Date = sql("PARSE_DATE(\"%d-%m-%Y\", FORMAT_DATETIME(\"%d-%m-%Y\", DateTime))")) %>%
    anti_join(to_exclude, by=c("School_ID", "Classroom", "Date")) %>% 
    arrange(School_ID, Classroom, DateTime)
  
  return(df_clean)
  
}

# ======================================================

# Classification / grouping functions
weather_periods <- function(df) {
  # Split dataframe into designated weather periods 
  
  df %>%
    mutate(WPeriod = case_when( Date>=ymd("2021-03-08") & Date<=ymd("2021-05-28") ~ "Cold 1",
                                Date>=ymd("2021-05-29") & Date<=ymd("2021-07-23") ~ "Warm 1",
                                Date>ymd("2021-09-03") & Date<=ymd("2021-09-26") ~ "Warm 2",
                                Date>=ymd("2021-09-27") & Date<=ymd("2021-10-30") ~ "Transitional",
                                Date>=ymd("2021-10-31") & Date<=ymd("2021-12-17") ~ "Cold 2", 
                                TRUE ~ "OTHER") ) -> df
  
  return(df)
  
}

# ------------------------------------------------------

school_type <- function(df) {
  # Split dataframe into designated weather periods 
  
  df_new <- df %>%
    mutate(School_Type = case_when( sql("STARTS_WITH(\`School_ID\`, \"C\")") ~ "CONTROL",
                                    sql("STARTS_WITH(\`School_ID\`, \"H\")") ~ "HEPA",
                                    TRUE ~ "UV") )
  
  return(df_new)
  
}

# ======================================================

# Calculating Statistics
stats_monthly <- function(df, flag) {
  
  if (flag == "School") {
    a <- df %>% 
      filter(Occupied == TRUE) %>%  
      mutate(YearMonth = sql("FORMAT_DATETIME(\"%Y-%m\", DateTime)")) %>% 
      group_by(School_ID, YearMonth) %>% 
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median
      school_type() %>%
      arrange(School_ID, YearMonth)
    
  } else if (flag == "Classroom") {
    a <- df %>% 
      filter(Occupied == TRUE) %>% 
      #mutate(YearMonth = format(DateTime,"%Y-%m")) %>%
      mutate(YearMonth = sql("FORMAT_DATETIME(\"%Y-%m\", DateTime)")) %>% 
      group_by(School_ID, Classroom, YearMonth) %>% 
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median
      school_type() %>%
      arrange(School_ID, Classroom, YearMonth)
  }
  
  return(a)
}

# ------------------------------------------------------

stats_weekly <- function(df, flag) {
  
  if (flag == "School") {
    a <- df %>% 
      filter(Occupied == TRUE) %>% 
      mutate(YearWeek = sql("FORMAT_DATETIME(\"%Y-W%W\", DateTime)")) %>% 
      group_by(School_ID, YearWeek) %>% 
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median 
      school_type() %>%
      arrange(School_ID, YearWeek)
    
  } else if (flag == "Classroom") {
    a <- df %>% 
      filter(Occupied == TRUE) %>% 
      mutate(YearWeek = sql("FORMAT_DATETIME(\"%Y-W%W\", DateTime)")) %>% 
      group_by(School_ID, Classroom, YearWeek) %>% 
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median 
      school_type() %>%
      arrange(School_ID, Classroom, YearWeek)
  }
  
  return(a)
}

# ------------------------------------------------------

stats_daily <- function(df, flag) {
  
  if (flag == "School") {
    a <- df %>% 
      filter(Occupied == TRUE) %>% 
      #mutate(Date = as.Date(DateTime)) %>%
      mutate(Date = sql("PARSE_DATE(\"%d-%m-%Y\", FORMAT_DATETIME(\"%d-%m-%Y\", DateTime))")) %>%
      group_by(School_ID, Date) %>% 
      select(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))) %>%
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median 
      school_type() %>%
      arrange(School_ID, Date)
      
  } else if (flag == "Classroom") {
    a <- df %>% 
      filter(Occupied == TRUE) %>% 
      #mutate(Date = as.Date(DateTime)) %>%
      mutate(Date = sql("PARSE_DATE(\"%d-%m-%Y\", FORMAT_DATETIME(\"%d-%m-%Y\", DateTime))")) %>%
      #mutate(Date = sql("FORMAT_DATETIME(\"%d-%m-%Y\", DateTime)")) %>% 
      group_by(School_ID, Classroom, Date) %>% 
      select(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))) %>%
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median 
      school_type() %>%
      arrange(School_ID, Classroom, Date)
  }
  
  return(a)
}

# ------------------------------------------------------

stats_wperiod <- function(df, flag) {
  
  if (flag == "School") {
    a <- df %>% 
      filter(Occupied == TRUE) %>% 
      weather_periods() %>% 
      group_by(School, WPeriod) %>% 
      select(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))) %>%
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median 
      school_type() %>%
      arrange(School_ID, WPeriod)
      
  } else if (flag == "Classroom") {
    a <- df %>% 
      filter(Occupied == TRUE) %>% 
      weather_periods() %>% 
      group_by(School, Classroom, WPeriod) %>% 
      select(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))) %>%
      summarise_at(vars(contains(c("TVOC", "CO2", "PM", "Temp", "RH"))), 
                   funs(n=count, mean, sd, min, max)) %>% # median
      school_type() %>%
      arrange(School_ID, Classroom, WPeriod)
  }
  
  return(a)
}

# ------------------------------------------------------