# SQLite3 Bindings
SQLite3 bindings for Odin. Made agianst the SQLITE3 3.53.2 amalgamation.

## Binaries
No binaries are provided. Instead it'll use the ones on your system. <br>
You can alternatively, you the build scripts in `./lib` to build them localy

## Definables
- `SQLITE_SHARED`: Use dynamicly linked locally built binaries. Defaut `false`;
- `SQLITE_SYSTEM_LIB`: Use System binaries. Default `true`;
- `SQLITE_DEBUG`: Use locally built static debug binaries. Default `ODIN_DEBUG`;
- `SQLITE_SEE`: Include the SQLite Encryption Extension enpoints. Default `false`.

## Bindings API differances
Endpoints that take either a sized string or a null terminated string, i.e. `result_text` & `bind_text`. Have been split into one that takes `cstring/16` & another `[^]u8/u16`, named like `bind_text_str` & `bind_text_buf`. Then put into a proc group of the orginal name, i.e. `bind_text`. (Both will still link to `sqlite3_bind_text`).  This is to help make using with them a bit nicer.   

Proc groups have been provided for `result_*` & `bind_*`.  

Result Codes & Extended Result Codes have been combind into a single `Result` enum.  

# WARNINGS
Foreign imports are, for now atleast untested, on Non-Windows platforms.   
