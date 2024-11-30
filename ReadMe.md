# sql.nvim

## Overview
This package is a Neovim implementation of a very small portion of what SSMS does. It provides the following functionality:

1. Connect to multiple types of database. Currently it supports SQL Server and PostgreSQL, but more can be added.
1. Display a catalog window showing objects defined in the database.
1. Assign a selected database to the current SQL script file.
1. Run an entire SQL script.
1. Run a paragraph within a SQL script.
1. Run a visual selection of text within a SQL script.
1. Craft SQL statements from the catalog window into the unnamed register. One such example is to generate a SELECT statement from a table or view, which can be pasted into the SQL buffer.

## Filetypes

### sql
Buffers of this type are where queries are written. The `:SQL` command will either set the filetype of the current empty buffer, or create a new buffer in a new tab of this filetype.

#### Keys
* <kbd>F5</kbd> - Submit the whole file or the visual selection to the database.
* <kbd>Shift+F5</kbd> - Submit the current paragraph to the database.
* <kbd>F8</kbd> - Open a buffer showing the current database's catalog in a floating window.

### sqlcatalog
The buffer of this filetype shows the platforms, servers, databases, and objects that are available.

#### Keys
* <kbd>l</kbd> - Expand the outline, if collaped.
* <kbd>l</kbd> - Open a popup menu of actions that can be done on the object
* <kbd>h</kbd> - Collapse the outline
* <kbd>Enter</kbd> - Make this database the one to use in the SQL buffer when running its queries.
* <kbd>q</kbd> or <kbd>Esc</kbd> - Close the SQL Catalog window.

### sqlout
This buffer is where the query results go.

#### Keys
* <kbd>F5</kbd> - Re-run the query that was last run.

## Installation
This plugin is installed the same way any other plugin would be.

## Settings File
All the information about the servers and the platforms they're running is stored a JSON file that you can edit with this command: `:SQLUserConfig`. If the file is not found, the plugin will create it with the following sample contents (minus these comments):

```json
{   /* An object of supported platforms */
    "sqlserver": {  /* An object of sqlserver properties */
        "alignThreshold": 5.0,  /* Skip alignment when over 5 seconds */
        "servers": {    /* An object of servers. */
            "server1": {    /* User/Password given on command line */
                "-U": "user",
                "-P": "password"
            },
            "server2": {}  /* No additional arguments */
        }
    },
    "postgres": {   /* An object of postgres properties */
        "alignThreshold": 0.0,    /* Always skip alignment */
        "servers": {
            "server3": {    /* Port needs to be specified */
                "-p": 5432
            }
        }
    }
}
```
* The `<platform>.servers[<server>]` object is used to specify additional command-line arguments as needed: user ID, password, port, etc. The base command lines, with `<server>`, `<database>` and `<file>` placeholders, are:
    * **sqlserver**: `sqlcmd -S <server> -d <database> -i <file> -s \";\" -W -I -f 65001`
    * **postgres**: `psql -h <server> -d <database> -f <file> -F\";\"`

* Alignment of query results is done with the EasyAlign plugin, if it's installed. The `<platform>.alignThreshold` setting controls when alignment is allowed to proceed. If the estimated time (based on the number of rows and columns) exceeds this threshold, alignment is skipped. The default is `5` for **sqlserver**. A value of `0` turns alignment off, and is the default for **postgres**.

## Dependencies
- For running **sqlserver** queries, `sqlcmd.exe` must be installed and in the path.
- for running **postgres** queries, `psql.exe` must be installed and in the path.

If the following optional plugins are installed, they will be used to improve the look of the results.
- [EasyAlign](https://github.com/junegunn/vim-easy-align) aligns the text into columns, if the output isn't too large.
- [csv.vim](https://github.com/chrisbra/csv.vim) highlights the columns in alternating colors.
