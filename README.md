
# Interactive Project Tracker & Gantt Dashboard

An interactive, enterprise-grade R Shiny web application designed for dynamic project management, task monitoring, and execution logging. Built with asynchronous filtering, dynamic Plotly Gantt visualizations, customizable DT data tables, and an embedded SQLite database with transactional persistence.

![R Shiny](https://img.shields.io/badge/R-Shiny-blue.svg)
![Database](https://img.shields.io/badge/Database-SQLite-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

---

## Key Features

* **Interactive Gantt Chart Visualizations:** Built using `plotly` with interactive click listeners, automated timeline mid-point progress display, and dynamically generated legend categories (by Task or Responsible Person).
* **Editable Data Tables:** Embedded `DT` (DataTables) grid with custom JavaScript handlers (`initComplete`) for inline dropdown selection, reactive cell edits, and real-time confirmation modals.
* **Persistent SQLite Database:** Powered by `RSQLite` and `DBI` featuring auto-initialization, parameterized queries, and safe ACID transaction management (`dbBegin`, `dbCommit`, `dbRollback`).
* **Audit & Execution Logging:** Automatically tracks completed tasks and generates timestamped activity logs.
* **Responsive UI/UX:** Styled with the Bootswatch `flatly` theme, standard CSS customizations, and dynamic JavaScript execution via `shinyjs`.

---

## Technical Architecture & Stack

### Frontend & UI
* **Shiny & shinythemes:** Dynamic layout structure with the modern `flatly` Bootstrap theme.
* **shinyjs:** Execution of client-side JavaScript for active DOM updates (e.g., custom progress bars).
* **Plotly:** Interactive timeline visualization and event listeners (`event_data("plotly_click")`).
* **DT (DataTables):** Custom JavaScript injections for real-time table cell edits.

### Backend & Database
* **RSQLite & DBI:** Lightweight local persistence layer with structured SQL schema definitions.
* **dplyr & lubridate:** High-performance data manipulation, reactive filtering, and date calculations.
* **glue:** Clean string interpolation for embedded SQL and JavaScript snippets.

---

## Database Schema

The database consists of two core tables initialized on application startup:

### 1. `project_summary`
Tracks active and historical project deliverables, progress metrics, and task deadlines.

| Field | Type | Description |
| :--- | :--- | :--- |
| `Task` | TEXT | Parent project category |
| `Subtask` | TEXT | Specific task item |
| `Start` | TEXT | Start date (`YYYY-MM-DD`) |
| `Deadline` | TEXT | Target completion date (`YYYY-MM-DD`) |
| `Responsible` | TEXT | Assigned project owner |
| `Progress` | INTEGER | Completion percentage (0–100%) |
| `DaysRemaining`| INTEGER | Days remaining until target deadline |
| `Information` | TEXT | Additional notes and task context |

### 2. `log_table`
Stores an audit trail of completion actions.

| Field | Type | Description |
| :--- | :--- | :--- |
| `Subtask` | TEXT | Completed subtask item |
| `Progress` | INTEGER | Final progress value (100) |
| `timestamp` | TEXT | Execution timestamp (Europe/Athens timezone) |

---

## Getting Started

### Prerequisites

Ensure you have R (>= 4.0.0) installed on your system.

### Dependencies

Install the required R packages by running the following command in your R console:

```r
install.packages(c(
  "shiny",
  "plotly",
  "lubridate",
  "dplyr",
  "readxl",
  "shinythemes",
  "shinyjs",
  "DT",
  "RSQLite",
  "DBI",
  "glue"
))
=======
# project-tracker
Interactive project tracker and Gantt dashboard built in R Shiny.
>>>>>>> 1a0f2c2dc7bfb5bea292fb36ba85b4252e360fd2
