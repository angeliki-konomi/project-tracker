
library(shiny)
library(plotly)
library(lubridate)
library(dplyr)
library(readxl)
library(shinythemes)
library(shinyjs)
library(DT)
library(RSQLite)
library(DBI)
library(glue)

db_path <- "Project_Tracker_Database.db"

if (!file.exists(db_path)) {
  db <- dbConnect(SQLite(), db_path)
  
  dbExecute(db, "
    CREATE TABLE IF NOT EXISTS project_summary (
      Task TEXT,
      Start TEXT,
      Deadline TEXT,
      Responsible TEXT,
      Subtask TEXT,
      Progress INTEGER,
      DaysRemaining INTEGER,
      Information TEXT,
      UNIQUE(Task, Subtask)
    );
  ")
  
  dbExecute(db, "
    CREATE TABLE IF NOT EXISTS log_table (
      Subtask TEXT,
      Progress INTEGER,
      timestamp TEXT
    );
  ")
  
  sample_data <- data.frame(
    Task = c(
      "Data Pipeline Migration", "Data Pipeline Migration", "Data Pipeline Migration", "Data Pipeline Migration",
      "Interactive Web Publications", "Interactive Web Publications", "Interactive Web Publications", "Interactive Web Publications",
      "PX-WEB API Integration", "PX-WEB API Integration", "PX-WEB API Integration", "PX-WEB API Integration",
      "Statistical Quality Control", "Statistical Quality Control", "Statistical Quality Control", "Statistical Quality Control",
      "Containerized System Deployment", "Containerized System Deployment", "Containerized System Deployment", "Containerized System Deployment"
    ),
    Start = c(
      "2026-01-15", "2026-02-10", "2026-03-01", "2026-04-05",
      "2026-02-01", "2026-03-15", "2026-05-01", "2026-06-10",
      "2026-03-01", "2026-04-15", "2026-05-10", "2026-07-01",
      "2026-04-01", "2026-05-01", "2026-06-01", "2026-07-15",
      "2026-05-01", "2026-06-15", "2026-08-01", "2026-09-10"
    ),
    Deadline = c(
      "2026-02-28", "2026-03-31", "2026-04-30", "2026-05-25",
      "2026-03-30", "2026-04-30", "2026-06-15", "2026-07-20",
      "2026-04-20", "2026-05-30", "2026-06-30", "2026-08-15",
      "2026-04-30", "2026-05-25", "2026-07-01", "2026-08-30",
      "2026-06-10", "2026-07-31", "2026-09-05", "2026-10-30"
    ),
    Responsible = c(
      "Alice Smith", "Bob Jones", "Charlie Brown", "Diana Prince",
      "Ethan Hunt", "Fiona Gallagher", "George Clark", "Alice Smith",
      "Bob Jones", "Diana Prince", "Ethan Hunt", "George Clark",
      "Fiona Gallagher", "Charlie Brown", "Alice Smith", "Ethan Hunt",
      "Bob Jones", "George Clark", "Fiona Gallagher", "Diana Prince"
    ),
    Subtask = c(
      "Audit Legacy SAS Scripts", "Translate Processing Pipelines to R data.table", "Automate HTML Comparison Reports", "Benchmark Memory & Processing Efficiency",
      "Design Quarto Web Template", "Configure SCSS & Custom Styling", "Integrate Interactive Plotly Charts", "Mobile Responsiveness & Usability Testing",
      "Map JSON-STAT2 Response Schemas", "Develop Power Query M Connectors", "Validate PX-WEB API Output Consistency", "Build Dynamic Refresh Mechanism",
      "Replicate SPSS Cross-Tabulations", "Execute Outlier Detection Scenarios", "Conduct Dual-Run Validation Checks", "Draft Methodology & QC Documentation",
      "Set Up Docker & Container Environments", "Configure Filebeat & Winlogbeat Logs", "Deploy Elasticsearch & Kibana Stack", "Draft System Administration Guide"
    ),
    Progress = c(
      100, 85, 40, 10,
      100, 90, 60, 20,
      100, 75, 30, 0,
      100, 80, 50, 15,
      100, 65, 25, 0
    ),
    DaysRemaining = c(
      0, 15, 35, 50,
      0, 10, 45, 65,
      0, 20, 40, 75,
      0, 12, 38, 70,
      0, 28, 55, 90
    ),
    Information = c(
      "Completed and archived", "In progress - translating CTABLES routines", "HTML rendering script generated", "Awaiting larger test dataset",
      "Base layout approved", "Custom branding applied", "Plotly tooltips configured", "Pending tablet layout checks",
      "API response endpoints mapped", "Power BI queries built", "Testing edge cases in multi-variable tables", "Scheduled for next sprint",
      "SPSS syntax verified against raw survey data", "Identified 12 extreme values for review", "Comparing SAS vs R output results", "Initial outline written",
      "Container instances running locally", "Log collection pipelines active", "Kibana dashboard draft created", "Not started"
    ),
    stringsAsFactors = FALSE
  )
  
  dbWriteTable(db, "project_summary", sample_data, append = TRUE, row.names = FALSE)
  dbDisconnect(db)
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
    .dataTables_wrapper td input {
      width: 100% !important;
      background-color: white !important;
      color: black !important;
      border: 1px solid #ddd !important;
      padding: 5px !important;
      font-size: 14px !important;
    }
    .dataTables_wrapper td input:focus {
      outline: none !important;
      border-color: #0056b3 !important;
    }
  "))
  ),
  theme = shinytheme("flatly"),
  titlePanel("Project Tracker"),
  useShinyjs(),
  
  sidebarLayout(
    sidebarPanel(
      uiOutput("taskFilter"),
      uiOutput("subsectionFilter"),
      dateRangeInput("dateRange", "Filter by Deadline:",
                     start = as.Date("2026-01-01"),
                     end = as.Date("2026-12-31")),
      actionButton("applyFilters", "Apply Filters", 
                   class = "btn btn-primary", 
                   style = "margin-top: 10px; width: 100%;"), 
      actionButton("clearFilters", "Clear All", 
                   class = "btn btn-secondary", style = "margin-top: 10px; width: 100%;"),
      div(style = "margin-top: 10px;", verbatimTextOutput("clickInfo")),
      actionButton("mark_complete", "Mark as Complete", 
                   class = "btn-success", 
                   style = "display: none; margin-top: 10px; width: 100%;"),
      actionButton("add_task", "Add New Task/Subtask", 
                   class = "btn btn-success", 
                   style = "margin-top: 10px; width: 100%;")
    ), 
    mainPanel(
      tabsetPanel(
        tabPanel("Gantt Chart", 
                 plotlyOutput("ganttChart", height = "600px"),
                 br(),
                 h4("Overall Progress"),
                 div(
                   style = "width: 100%; background-color: #e0e0e0; border-radius: 10px;",
                   div(
                     id = "progressBar",
                     style = "width: 0%; height: 30px; background-color: #007bff; text-align: center; 
                          line-height: 30px; color: white; font-weight: bold; border-radius: 10px;",
                     "0%"
                   )
                 )
        ),
        tabPanel("Table", 
                 DTOutput("taskTable")
        )
      )
    )  
  )
)

server <- function(input, output, session) {
  
  db <- dbConnect(RSQLite::SQLite(), db_path)
  
  taskData <- reactive({
    df <- dbGetQuery(db, "
      SELECT 
        CAST(Task AS TEXT) AS Task,
        CAST(Start AS TEXT) AS Start,
        CAST(Deadline AS TEXT) AS Deadline,
        CAST(Responsible AS TEXT) AS Responsible,
        CAST(Subtask AS TEXT) AS Subtask,
        CAST(Progress AS INTEGER) AS Progress,
        CAST(DaysRemaining AS INTEGER) AS DaysRemaining,
        CAST(Information AS TEXT) AS Information
      FROM project_summary
    ")
    
    df <- df %>%
      rename(
        Task = Task,
        Start_Date = Start,
        Deadline = Deadline,
        Responsible = Responsible,
        Subtask = Subtask
      )
    
    df$Start_Date <- as.Date(df$Start_Date)  
    df$Deadline   <- as.Date(df$Deadline, format = "%Y-%m-%d")
    
    df <- df[!is.na(df$Start_Date) & !is.na(df$Deadline), ]
    
    return(df)
  })
  
  observe({
    df <- filteredData()
    
    if (nrow(df) == 0) {
      overall_progress <- 0 
    } else {
      df$duration <- as.numeric(df$Deadline - df$Start_Date) + 1  
      overall_progress <- sum(df$Progress * df$duration) / sum(df$duration)  
    }
    
    overall_progress <- round(overall_progress, 1) 
    
    runjs(sprintf('document.getElementById("progressBar").style.width = "%s%%"; 
                    document.getElementById("progressBar").innerText = "%s%%";',
                  overall_progress, overall_progress))
  })
  
  averageProgress <- reactive({
    df <- taskData()
    
    df$Task <- trimws(df$Task)
    df$Task <- gsub("[\u00A0]+", " ", df$Task)
    df$Task <- iconv(df$Task, from = "", to = "UTF-8")
    
    if (nrow(df) == 0) {
      return(data.frame())  
    }
    
    df %>%
      mutate(duration2 = as.numeric(Deadline - Start_Date) + 1) %>%
      group_by(Task) %>%
      summarise(Average_Progress = round(sum(Progress * duration2) / sum(duration2)), 
                .groups = "drop")  
  })
  
  selectedFilters <- reactiveValues(
    category = "All",
    subsection = "All",
    startDate = as.Date("2026-01-01"),
    endDate = as.Date("2026-12-31")
  )
  
  filteredData <- reactive({
    df <- taskData()
    
    req(selectedFilters$category, selectedFilters$subsection)  
    
    if (selectedFilters$category != "All") {
      if (selectedFilters$category == "Task" && selectedFilters$subsection != "All") {
        df <- df[df$Task == selectedFilters$subsection, , drop = FALSE]
      } else if (selectedFilters$category == "Responsible" && selectedFilters$subsection != "All") {
        df <- df[df$Responsible == selectedFilters$subsection, , drop = FALSE]
      }
    }
    
    if (!is.null(selectedFilters$startDate) && !is.na(selectedFilters$startDate)) {
      df <- df[as.Date(df$Deadline) >= as.Date(selectedFilters$startDate), , drop = FALSE]
    }
    if (!is.null(selectedFilters$endDate) && !is.na(selectedFilters$endDate)) {
      df <- df[as.Date(df$Deadline) <= as.Date(selectedFilters$endDate), , drop = FALSE]
    }
    
    if (nrow(df) == 0) {
      return(data.frame())  
    }
    
    df$Start_Date <- as.Date(df$Start_Date)
    df$Deadline   <- as.Date(df$Deadline)
    
    df$duration <- as.numeric(df$Deadline - df$Start_Date) + 1
    df$Progress[df$Progress > 100] <- 100
    
    if (is.null(df$Subtask) || all(is.na(df$Subtask))) {
      df$Subtask <- df$Task
    } else {
      df$ColorCategory <- ifelse(selectedFilters$category == "Responsible", df$Responsible, df$Task)
    }
    
    return(df)
  })
  
  observeEvent(input$taskTable_rows_selected, {
    if (!is.null(input$taskTable_rows_selected)) {
      shinyjs::show("mark_complete")  
    }
  })
  
  observeEvent(input$mark_complete, {
    selected_rows <- input$taskTable_rows_selected
    if (length(selected_rows) > 0) {
      showModal(modalDialog(
        title = "Confirmation",
        paste("Are you sure you want to mark this subtask as complete?"),
        easyClose = FALSE,
        footer = tagList(
          modalButton("Cancel"),
          actionButton("confirm_mark_complete", "Yes, Mark as Complete")
        )
      ))
    }
  })
  
  observeEvent(input$confirm_mark_complete, {
    selected_rows <- input$taskTable_rows_selected
    if (length(selected_rows) > 0) {
      selected_task <- filteredData()[selected_rows, "Task"]
      selected_subtask <- filteredData()[selected_rows, "Subtask"]
      
      tryCatch({
        dbBegin(db)  
        
        dbExecute(db, "
          UPDATE project_summary 
          SET Progress = 100
          WHERE Task = ? AND Subtask = ?", 
                  params = list(selected_task, selected_subtask))
        
        current_time_athens <- format(Sys.time(), tz = "Europe/Athens", usetz = TRUE)
        
        dbExecute(db, "
          INSERT INTO log_table (Subtask, Progress, timestamp)
          VALUES (?, ?, ?)",
                  params = list(selected_subtask, 100, current_time_athens))
        
        dbCommit(db)  
        removeModal()
        
      }, error = function(e) {
        dbRollback(db)  
        showModal(modalDialog(
          title = "Error",
          paste("Update failed:", e$message),
          easyClose = TRUE
        ))
      })
    }
  })
  
  observeEvent(input$add_task, {
    showModal(modalDialog(
      title = "Add New Task",
      textInput("new_task_name", "Task Name:"),
      selectInput("new_responsible", "Responsible Person:", 
                  choices = c("", "Alice Smith", "Bob Jones", "Charlie Brown")),
      dateInput("new_start_date", "Start Date:"),
      dateInput("new_deadline", "Deadline:"),
      numericInput("new_progress", "Progress:", value = 0, min = 0, max = 100),
      textInput("new_information", "Information:"),
      textInput("new_subtask", "Subtask:"),  
      actionButton("submit_task", "Submit", class = "btn btn-primary"),
      modalButton("Cancel")
    ))
  })
  
  observeEvent(input$submit_task, {
    task_name <- input$new_task_name
    responsible <- input$new_responsible
    start_date <- format(input$new_start_date, "%Y-%m-%d")
    deadline <- format(input$new_deadline, "%Y-%m-%d")
    progress <- input$new_progress
    information <- input$new_information
    subtask <- input$new_subtask
    days_remaining <- as.integer(as.Date(deadline) - Sys.Date())
    
    if (task_name != "" && responsible != "" && !is.null(start_date) && !is.null(deadline)) {
      tryCatch({
        dbBegin(db)  
        
        dbExecute(db, "
          INSERT OR REPLACE INTO project_summary (Task, Responsible, Start, Deadline, Progress, Information, Subtask, DaysRemaining)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ", params = list(task_name, responsible, start_date, deadline, progress, information, subtask, days_remaining))
        
        dbCommit(db)  
        removeModal()  
        
      }, error = function(e) {
        dbRollback(db)  
        showModal(modalDialog("Error", paste("Failed to insert/update task:", e$message)))
      })
    } else {
      showModal(modalDialog("Error", "Please fill in all required fields."))
    }
  })
  
  responsible_options <- c("Alice Smith", "Bob Jones", "Charlie Brown")
  
  output$taskTable <- renderDT({
    df <- filteredData()
    
    df_table <- df %>%
      select(Task, Subtask, Responsible, Start_Date, Deadline, Progress, DaysRemaining, Information)
    
    disable_index <- which(colnames(df_table) == "DaysRemaining") - 1
    responsible_col_index <- which(colnames(df_table) == "Responsible") - 1
    js_options <- paste0("[", paste0('"', responsible_options, '"', collapse = ", "), "]")
    
    editable_config <- if (length(disable_index) > 0) {
      list(target = "cell", disable = list(columns = disable_index))
    } else {
      list(target = "cell")
    }
    
    datatable(
      df_table,
      options = list(
        pageLength = 15,
        searching = FALSE,
        columnDefs = list(
          list(targets = "_all", className = 'dt-center')
        ),
        initComplete = JS(glue::glue("
          function(settings, json) {{
            var column = this.api().column({responsible_col_index});
            var selectOptions = {js_options};

            this.api().cells(null, {responsible_col_index}).every(function () {{
              var cell = this.node();
              var currentValue = $(cell).text();
              var select = $('<select class=\"form-control form-control-sm\"></select>');

              selectOptions.forEach(function(option) {{
                var selected = (option === currentValue) ? 'selected' : '';
                select.append('<option ' + selected + '>' + option + '</option>');
              }});

              $(cell).html(select);
              $(select).on('change', function(e) {{
                var rowIdx = column.index();
                var cellIdx = $(cell).closest('tr').index();
                var newVal = $(this).val();
                Shiny.setInputValue('taskTable_cell_edit', {{
                  row: cellIdx + 1,
                  col: column.index(),
                  value: newVal,
                  nonce: Math.random()
                }});
              }});
            }});
          }}
        "))
      ),
      editable = editable_config,
      rownames = FALSE,
      selection = "single"
    )
  })
  
  pendingEdit <- reactiveValues(info = NULL)
  
  observeEvent(input$taskTable_cell_edit, {
    pendingEdit$info <- input$taskTable_cell_edit
    
    showModal(modalDialog(
      title = "Confirm Edit",
      paste("You changed cell at row", input$taskTable_cell_edit$row,
            "and column", input$taskTable_cell_edit$col + 1,
            "to:", input$taskTable_cell_edit$value),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirmEdit", "Confirm")
      )
    ))
  })
  
  observeEvent(input$confirmEdit, {
    req(pendingEdit$info)
    
    row <- pendingEdit$info$row
    col <- pendingEdit$info$col + 1
    new_value <- pendingEdit$info$value
    
    display_cols <- c("Task", "Subtask", "Responsible", "Start_Date", "Deadline", "Progress", "DaysRemaining", "Information")
    df <- filteredData()
    
    display_to_db_cols <- c(
      "Task" = "Task",
      "Subtask" = "Subtask",
      "Responsible" = "Responsible",
      "Start_Date" = "Start",
      "Deadline" = "Deadline",
      "Progress" = "Progress",
      "DaysRemaining" = "DaysRemaining",
      "Information" = "Information"
    )
    
    if (col < 1 || col > length(display_cols)) {
      showModal(modalDialog("Error", "Invalid column index."))
      return()
    }
    
    edited_display_col <- display_cols[col]
    edited_db_col <- display_to_db_cols[[edited_display_col]]
    
    task_key <- df[row, "Task"]
    subtask_key <- df[row, "Subtask"]
    
    if (edited_db_col %in% c("Start", "Deadline")) {
      parsed_date <- tryCatch(as.Date(new_value, format = "%Y-%m-%d"), error = function(e) NA)
      if (is.na(parsed_date)) {
        showModal(modalDialog("Error", "Invalid date format. Please use YYYY-MM-DD."))
        return()
      }
      new_value <- format(parsed_date, "%Y-%m-%d")
    }
    
    if (edited_db_col == "Deadline") {
      today <- Sys.Date()
      new_deadline_date <- as.Date(new_value)
      new_days_remaining <- as.integer(new_deadline_date - today)
      
      dbExecute(db, "
        UPDATE project_summary 
        SET DaysRemaining = ? 
        WHERE Task = ? AND Subtask = ?",
                params = list(new_days_remaining, task_key, subtask_key))
    }
    
    if (edited_db_col %in% c("Progress", "DaysRemaining")) {
      num_val <- suppressWarnings(as.numeric(new_value))
      if (is.na(num_val)) {
        showModal(modalDialog("Error", "Invalid number entered."))
        return()
      }
      if (edited_db_col == "Progress") {
        num_val <- min(max(num_val, 0), 100)
      }
      new_value <- num_val
    }
    
    tryCatch({
      query <- sprintf("UPDATE project_summary SET %s = ? WHERE Task = ? AND Subtask = ?", edited_db_col)
      
      dbBegin(db)
      dbExecute(db, query, params = list(new_value, task_key, subtask_key))
      dbCommit(db)
      
      removeModal()
      
    }, error = function(e) {
      message("Error during DB update: ", e$message)
      dbRollback(db)
      showModal(modalDialog("Error", paste("Failed to update database:", e$message)))
    })
  })
  
  output$taskFilter <- renderUI({
    selectInput("selectedCategory", "Select Category:", choices = c("All", "Task", "Responsible"), selected = "All")
  })
  
  output$subsectionFilter <- renderUI({
    df <- taskData()
    selected_category <- input$selectedCategory
    if (is.null(selected_category)) selected_category <- "All"  
    
    if (selected_category == "All") {
      subsections <- unique(c(na.omit(df$Task), na.omit(df$Responsible)))  
    } else if (selected_category == "Task") {
      subsections <- na.omit(unique(df$Task))  
    } else {
      subsections <- na.omit(unique(df$Responsible))  
    }
    
    selectInput("selectedSubsection", "Select Subsection:", choices = c("All", subsections), selected = "All")
  })
  
  observeEvent(input$applyFilters, {
    selectedFilters$category <- input$selectedCategory
    selectedFilters$subsection <- input$selectedSubsection
    selectedFilters$startDate <- input$dateRange[1]
    selectedFilters$endDate <- input$dateRange[2]
  })
  
  observeEvent(input$clearFilters, {
    selectedFilters$category <- "All"
    selectedFilters$subsection <- "All"
    selectedFilters$startDate <- as.Date("2026-01-01")
    selectedFilters$endDate <- as.Date("2026-12-31")
    
    updateSelectInput(session, "selectedCategory", selected = "All")
    updateSelectInput(session, "selectedSubsection", selected = "All")
    updateDateRangeInput(session, "dateRange", start = as.Date("2026-01-01"), end = as.Date("2026-12-31"))
  })
  
  observe({
    invalidateLater(500, session)  
    
    js_code <- "
    $(document).on('click', function(e) {
      if (!$(e.target).closest('#taskTable').length) {
        Shiny.setInputValue('outside_click', Math.random());
      }
    });
  "
    runjs(js_code)  
  })
  
  output$ganttChart <- renderPlotly({
    df <- filteredData()
    
    df$Task <- trimws(df$Task)
    df$Task <- gsub("[\u00A0]+", " ", df$Task)
    df$Task <- iconv(df$Task, from = "", to = "UTF-8")
    
    if (nrow(df) == 0) {
      return(NULL)
    }
    
    df$Start_Date <- as.Date(df$Start_Date)
    df$Deadline   <- as.Date(df$Deadline)
    
    today <- Sys.Date()
    
    selected_category <- selectedFilters$category
    selected_subsection <- selectedFilters$subsection
    
    if (selected_category == "All" && selected_subsection == "All" ) {
      avg_progress_df <- averageProgress()
      
      df <- df %>%
        left_join(avg_progress_df, by = "Task")
      
      df$Progress <- df$Average_Progress
      df$BarLength <- as.numeric(df$Deadline - df$Start_Date) + 1
      df <- df %>% distinct(Task, .keep_all = TRUE)
      
      df$Progress_End <- df$Start_Date + (df$BarLength * (df$Progress / 100))
      df$Total_End    <- df$Start_Date + df$BarLength
      df$Mid_Point    <- df$Start_Date + (df$BarLength * 0.5)
      
      if (selected_category == "Responsible") {
        color_var <- df$Responsible
        legend_title <- "Owner"
      } else {
        color_var <- df$Task
        legend_title <- "Task"
      }
      
      p <- plot_ly(df, source = "A") %>%
        add_segments(
          x = ~Start_Date, 
          xend = ~Progress_End,  
          y = ~Task,
          yend = ~Task,
          line = list(width = 15),
          color = ~color_var,  
          colors = "Set2",  
          opacity = 0.7,  
          hoverinfo = 'none',
          showlegend = TRUE
        ) %>%
        add_segments(
          x = ~Progress_End, 
          xend = ~Total_End,  
          y = ~Task,
          yend = ~Task,
          line = list(width = 15),
          color = ~color_var,
          colors = "rgba(150, 150, 150, 0.5)",
          opacity = 0.3,  
          hoverinfo = 'none',
          showlegend = FALSE
        ) %>%
        add_text(
          x = ~Mid_Point, 
          y = ~Task,
          text = ~paste("<b>", round(Progress, 1), "%</b>"),  
          textposition = "middle center",
          textfont = list(size = 14),
          hoverinfo = 'none',
          showlegend = FALSE
        ) %>% 
        event_register("plotly_click") %>%
        layout(
          xaxis = list(
            title = "Date", 
            type = "date", 
            tickformat = "%Y-%m-%d",
            tickangle = 45
          ),
          yaxis = list(title = "", categoryorder = "array"),
          legend = list(
            title = list(text = legend_title), 
            x = 1,  
            y = 1
          ),  
          shapes = list(        
            list(
              type = "line",
              x0 = today, 
              x1 = today, 
              y0 = 0, 
              y1 = 1, 
              xref = "x", 
              yref = "paper", 
              line = list(color = "rgba(150, 150, 150, 0.4)", width = 8)  
            )
          )
        )
      return(p)
    } else {
      if (selected_category == "Responsible") {
        color_var <- df$Responsible
        legend_title <- "Owner"
      } else {
        color_var <- df$Task
        legend_title <- "Task"
      }
      
      df$Task_Duration <- as.numeric(df$Deadline - df$Start_Date)
      df$Sub_Progress_End <- df$Start_Date + (df$Task_Duration * (df$Progress / 100))
      df$Sub_Mid_Point    <- df$Start_Date + (df$Task_Duration * 0.5)
      
      p <- plot_ly(df, source = "A") %>%
        add_segments(
          x = ~Start_Date, 
          xend = ~Deadline, 
          y = ~Subtask,
          yend = ~Subtask,
          line = list(width = 15),  
          color = ~color_var,
          colors = "Set2",
          opacity = 0.3,  
          hoverinfo = "none",
          showlegend = FALSE  
        ) %>%
        add_segments(
          x = ~Start_Date, 
          xend = ~Sub_Progress_End,  
          y = ~Subtask, 
          yend = ~Subtask,
          line = list(width = 15),  
          color = ~color_var,
          colors = "Set2",
          hoverinfo = "none",
          showlegend = TRUE
        ) %>%
        add_text(
          x = ~Sub_Mid_Point,
          y = ~Subtask,
          text = ~paste("<b>", Progress, "%</b>"),
          textposition = "middle center",
          textfont = list(size = 14),
          hoverinfo = 'none',
          showlegend = FALSE
        ) %>%
        event_register("plotly_click") %>%
        layout(
          xaxis = list(
            title = "Date", 
            type = "date", 
            tickformat = "%Y-%m-%d",
            tickangle = 45
          ),
          yaxis = list(title = "", categoryorder = "array"),
          legend = list(
            title = list(text = legend_title), 
            x = 1,  
            y = 1
          ),
          shapes = list(
            list(
              type = "line",
              x0 = today, 
              x1 = today, 
              y0 = 0, 
              y1 = 1, 
              xref = "x", 
              yref = "paper", 
              line = list(color = "rgba(150, 150, 150, 0.4)", width = 8)  
            )
          )
        )
      return(p)
    }
  })
  
  output$clickInfo <- renderPrint({
    df <- taskData()
    d <- event_data("plotly_click")
    
    all_filters <- selectedFilters$category == "All" &&
      selectedFilters$subsection == "All"
    
    if (all_filters && !is.null(d)) {
      task_name <- d$y
      if (!is.null(task_name)) {
        sub_df <- df[df$Task == task_name, ]
        
        min_start    <- min(sub_df$Start_Date, na.rm = TRUE)
        max_deadline <- max(sub_df$Deadline,  na.rm = TRUE)
        
        clicked_list <- list(
          paste0("Task        : ", task_name),
          paste0("Responsible : ", sub_df$Responsible[1]),
          paste0("Start Date  : ", format(min_start, "%d %b. %Y")),
          paste0("Deadline    : ", format(max_deadline, "%d %b. %Y")),
          paste0("DAYS LEFT   : ", as.integer(max_deadline - Sys.Date()))
        )
        
        extra_text <- paste(clicked_list, collapse = "\n")
        cat(extra_text)
        
      } else {
        cat("No valid task/subtask found.")
      }
      
    } else if (!is.null(d)) {
      task_name <- d$y
      if (!is.null(task_name) && task_name %in% unique(df$Subtask)) {
        clicked_list <- list(
          paste0("SUBTASK     : ", task_name),
          paste0("Task        : ", df[df$Subtask == task_name, c("Task")]),
          paste0("Responsible : ", df[df$Subtask == task_name, c("Responsible")]),
          paste0("Start Date  : ", format(as.Date(as.numeric(df[df$Subtask == task_name, c("Start_Date")])), "%d %b. %Y")),
          paste0("Deadline    : ", format(as.Date(as.numeric(df[df$Subtask == task_name, c("Deadline")])), "%d %b. %Y")),
          paste0("Progress    : ", df[df$Subtask == task_name, c("Progress")]),
          paste0("DAYS LEFT   : ", df[df$Subtask == task_name, c("DaysRemaining")]),
          paste0("EXTRA INFO  : ", df[df$Subtask == task_name, c("Information")])
        )
        extra_text <- paste(clicked_list, collapse = "\n")
        cat(extra_text)
      } else {
        cat("Task name not found.")
      }
    } else {
      cat("Click to see more info.")
    }
  })
  
  onStop(function() {
    dbDisconnect(db)
  })
}

shinyApp(ui, server)