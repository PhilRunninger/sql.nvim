# SQL

## Overview
This package is a Neovim equivalent of a very small portion of what SSMS does. It provides the following functionality:

1. Connect to multiple types of database (SQL Server, PostgreSQL, etc.)
1. Run an entire SQL script.
1. Run a paragraph within a SQL script.
1. Run a visual selection of text within a SQL script.
1. Display a catalog window showing objects defined in the database.
1. Craft SQL statements into the SQL buffer from the catalog window.

## Filetypes

### SQL
This buffer type is where queries are written.

#### Keys
* <Leader>F5 - Connect to a database.
* F5 - Submit the whole file or the visual selection to the database.
* Shift+F5 - Submit the current paragraph to the database.
* F8 - Open a buffer showing the current database's catalog in a floating window.

### SQLCatalog
This buffer shows the objects in the current database. It has the following outline structure:
* Tables
    * <table_1...n>
        * <column_1...n>
* Views
    * <view_1...n>
        * <column_1...n>
* Stored Procedures
    * <sproc_1...n>
* Functions
    * <function_1...n>

#### Keys
* l - Expand the outline, if collaped.
* l - open a popup menu of actions that can be done on the object
* h - collapse the outline

### SQLOut
This buffer is where the query results go. No other functionality (for now).
