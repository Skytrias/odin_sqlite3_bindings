# SQLite3 Bindings
SQLite3 bindings for Odin. Made agianst the SQLITE3 3.53.2 amalgamation.

## API differances
Endpoints that take either a sized string or a null terminated string, i.e. `result_text` & `bind_text`. Have been split into one that takes `cstring/16` & another `[^]u8/u16`, named like `bind_text_str` & `bind_text_buf`. Then put into a proc group of the orginal name, i.e. `bind_text`. (Both will still link to `sqlite3_bind_text`).  To help make using with them nicer.

Proc groups have also been provided for `result_*` & `bind_*`.  

Result Codes & Extended Result Codes have been combind into a single `Result` enum.  