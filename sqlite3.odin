package sqlite3 

import "core:c"

// Use dynamicly linked locally built binaries.
SQLITE_SHARED  :: #config(SQLITE_SHARED, false)
// Use System binaries on non-Windows targets.
USE_SYSTEM_LIB :: #config(SQLITE_USE_SYSTEM_LIB, false)
// Assumes locally built static binaries. Will not use System binaries.
SQLITE_DEBUG   :: #config(SQLITE_DEBUG, ODIN_DEBUG)

when ODIN_OS == .Windows {
	@(extra_linker_flags="/DEFAULTLIB:libcmt")
	foreign import lib {(
		"./lib/sqlite3_debug.lib" when SQLITE_DEBUG else 
		"./lib/sqlite3_dll.lib"   when SQLITE_SHARED else 
		"./lib/sqlite3_lib.lib"
	)}

} else {
	when USE_SYSTEM_LIB && !SQLITE_DEBUG {
		LIB_PATH :: "system:libsqlite3"
		// LIB_PATH :: "system:sqlite3"

	} else when ODIN_OS == .Darwin {
		when ODIN_ARCH == .arm64 {
			LIB_PATH :: (
				"./lib/sqlite3_debug_darwin_arm64.a" when SQLITE_DEBUG else 
				"./lib/sqlite3_darwin_arm64.dylib"   when SQLITE_SHARED else 
				"./lib/sqlite3_darwin_arm64.a"
			)
		} else {
			LIB_PATH :: (
				"./lib/sqlite3_debug_darwin_amd64.a" when SQLITE_DEBUG else 
				"./lib/sqlite3_darwin_amd64.dylib"   when SQLITE_SHARED else 
				"./lib/sqlite3_darwin_amd64.a"
			)
		}
	
	} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
		LIB_PATH :: (
			"./lib/sqlite3_wasam_debug.a" when SQLITE_DEBUG else
			"./lib/sqlite3_wasm.so"       when SQLITE_SHARED else 
			"./lib/sqlite3_wasm.a"
		)

	} else {
		LIB_PATH :: (
			"./lib/sqlite3_debug.a" when SQLITE_DEBUG else
			"./lib/sqlite3.so"      when SQLITE_SHARED else 
			"./lib/sqlite3.a"
		)
	}

	when !USE_SYSTEM_LIB || SQLITE_DEBUG {
		#assert(#exists(LIB_PATH))
	}
	foreign import lib { LIB_PATH }
}


VERSION        :: "3.53.2"
VERSION_NUMBER :: 3053002
SOURCE_ID      :: "2026-06-03 19:12:13 d6e03d8c777cfa2d35e3b60d8ec3e0187f3e9f99d8e2ee9cac695fd6fcdf1a24"
SCM_BRANCH     :: "branch-3.53"
SCM_TAGS       :: "release version-3.53.2"
SCM_DATETIME   :: "2026-06-03T19:12:13.350Z"


/******** Begin of SQLITE3_H *********/

OMIT_COMPILEOPTION_DIAGS :: #config(OMIT_COMPILEOPTION_DIAGS, false)
ENABLE_PREUPDATE_HOOK    :: #config(ENABLE_PREUPDATE_HOOK, false)
OMIT_FLOATING_POINT      :: #config(OMIT_FLOATING_POINT, false)
OMIT_SHARED_CACHE        :: #config(OMIT_SHARED_CACHE, false)
ENABLE_NORMALIZE         :: #config(ENABLE_NORMALIZE, false)
OMIT_DEPRECATED          :: #config(OMIT_DEPRECATED, false)
ENABLE_CEROD             :: #config(ENABLE_CEROD, false)

SHM_NLOCK :: 8


int64    :: i64
uint64   :: u64
double   :: int64 when OMIT_FLOATING_POINT else f64
filename :: distinct cstring


callback    :: #type proc "c" (rawptr, c.int, ^cstring, ^cstring) -> Result
syscall_ptr :: #type proc "c" ()

destructor_type  :: #type proc "c" (rawptr)
SQLITE_STATIC    := transmute(destructor_type)(uintptr(0))
SQLITE_TRANSIENT := transmute(destructor_type)(~uintptr(0))

sqlite3 :: struct {}
mutex   :: struct {}
stmt    :: struct {}
value   :: struct {}
blob    :: struct {}
str     :: struct {}
pcache  :: struct {}
backup  :: struct {}


@(default_calling_convention="c", link_prefix="sqlite3_")
foreign lib {
	// version: cstring
	temp_directory: [^]u8
	data_directory: [^]u8


	libversion        :: proc() -> cstring ---
	sourceid          :: proc() -> cstring ---
	libversion_number :: proc() -> c.int ---
	threadsafe        :: proc() -> b32 ---

	close             :: proc(db: Maybe(^sqlite3)) -> Result ---
	close_v2          :: proc(db: Maybe(^sqlite3)) -> Result ---

	exec :: proc(
		db:       ^sqlite3,              /* An open database */
		sql:      cstring,               /* SQL to be evaluated */
		callback: Maybe(callback) = nil, /* Callback function */
		cb_arg:   rawptr = nil,          /* 1st argument to callback */
		errmsg:   Maybe(^cstring) = nil, /* Error msg written here */
	) -> Result ---

	initialize :: proc() -> Result ---
	shutdown   :: proc() -> Result ---
	os_init    :: proc() -> Result ---
	os_end     :: proc() -> Result ---
	config     :: proc(Config, #c_vararg ..any) -> Result ---
	db_config  :: proc(db: ^sqlite3, op: DB_Config, #c_vararg args: ..any) -> Result ---

	extended_result_codes :: proc(db: ^sqlite3, onoff: b32) -> Result ---
	last_insert_rowid     :: proc(db: ^sqlite3) -> int64 ---
	set_last_insert_rowid :: proc(db: ^sqlite3, rowID: int64) ---
	
	changes         :: proc(db: ^sqlite3) -> c.int ---
	changes64       :: proc(db: ^sqlite3) -> int64 ---
	total_changes   :: proc(db: ^sqlite3) -> c.int ---
	total_changes64 :: proc(db: ^sqlite3) -> int64 ---
	interrupt       :: proc(db: ^sqlite3) ---
	is_interrupted  :: proc(db: ^sqlite3) -> b32 ---
	complete        :: proc(sql: cstring) -> b32 ---
	complete16      :: proc(sql: cstring16) -> b32 ---
	busy_handler    :: proc(db: ^sqlite3, cb: proc "c" (rawptr, c.int) -> Result, pUserData: rawptr) -> Result ---
	busy_timeout    :: proc(db: ^sqlite3, ms: c.int) -> Result ---
	setlk_timeout   :: proc(db: ^sqlite3, ms: c.int, flags: SETLK_Flags) -> Result ---

	get_table :: proc(
		db: ^sqlite3,             /* An open database */
		zSql: cstring,            /* SQL to be evaluated */
		pazResult: ^[^]cstring,   /* Results of the query */
		pnRow: ^c.int,            /* Number of result rows written here */
		pnColumn: ^c.int,         /* Number of result columns written here */
		pzErrmsg: Maybe(^cstring) = nil, /* Error msg written here */
	) -> Result ---
	free_table :: proc(result: [^]cstring) ---

	mprintf   :: proc(zFormat: cstring, #c_vararg ap: ..any) -> [^]u8 ---
	vmprintf  :: proc(zFormat: cstring, ap: c.va_list) -> [^]u8 ---
	snprintf  :: proc(n: c.int, zBuf: [^]u8, zFormat: cstring, #c_vararg ap: ..any) -> [^]u8 ---
	vsnprintf :: proc(n: c.int, zBuf: [^]u8, zFormat: cstring, ap: c.va_list) -> [^]u8 ---

	malloc    :: proc(n: c.int) -> rawptr ---
	malloc64  :: proc(n: uint64) -> rawptr ---
	realloc   :: proc(pOld: rawptr, n: c.int) -> rawptr ---
	realloc64 :: proc(pOld: rawptr, n: uint64) -> rawptr ---
	free      :: proc(p: rawptr) ---
	msize     :: proc(p: rawptr) -> uint64 ---

	memory_used      :: proc() -> int64 ---
	memory_highwater :: proc(resetFlag: b32) -> int64 ---

	randomness :: proc(N: c.int, P: [^]byte) ---

	set_authorizer :: proc(
		db: ^sqlite3,
		xAuth: proc "c" (rawptr, Action_Code, cstring, cstring, cstring, cstring) -> Auth_Res,
		pUserData: rawptr,
	) -> Auth_Res ---

	@(deprecated="Use sqlite3.trace_v2() instead")
	trace :: proc(db: ^sqlite3, xTrace: proc "c" (rawptr, cstring), pUserData: rawptr) -> rawptr ---
	@(deprecated="Use sqlite3.trace_v2() instead")
	profile :: proc(db: ^sqlite3, xProfile: proc "c" (rawptr, cstring, uint64), pUserData: rawptr) -> rawptr ---

   trace_v2 :: proc(
		db: ^sqlite3,
		uMask: Trace_Codes,
		xCallback: proc "c" (Trace_Code, rawptr, rawptr, rawptr) -> b32,
		pCtx: rawptr,
	) -> Result ---

	progress_handler :: proc(db: ^sqlite3, n: c.int, cb: proc "c" (pUserData: rawptr) -> b32, pUserData: rawptr) ---

	open :: proc(
		filename: cstring, /* Database filename (UTF-8) */
		ppDb: ^^sqlite3,   /* OUT: SQLite db handle */
	) -> Result ---

	open16 :: proc(
		filename: cstring16, /* Database filename (UTF-16) */
		ppDb: ^^sqlite3,     /* OUT: SQLite db handle */
	) -> Result ---

	open_v2 :: proc(
		filename: cstring, /* Database filename (UTF-8) */
		ppDb: ^^sqlite3,   /* OUT: SQLite db handle */
		flags: Open_Flags, /* Flags */
		zVfs: cstring,     /* Name of VFS module to use */
	) -> Result ---

	uri_parameter :: proc(z: filename, zParam:  cstring) -> cstring ---
	uri_boolean   :: proc(z: filename, czParam: cstring, bDefault: b32) -> b32 ---
	uri_int64     :: proc(z: filename, czParam: cstring, zParam: int64) -> int64 ---
	uri_key       :: proc(z: filename, N: c.int) -> cstring ---

	filename_database :: proc(zFilename: filename) -> cstring ---
	filename_journal  :: proc(zFilename: filename) -> cstring ---
	filename_wal      :: proc(zFilename: filename) -> cstring ---

	database_file_object :: proc(zName: cstring) -> ^file ---

	create_filename :: proc(
		zDatabase: cstring,
		zJournal:  cstring,
		zWal:      cstring,
		nParam:    c.int,
		azParam:   [^]cstring,
	) -> filename ---
	free_filename :: proc(filename) ---

	errcode          :: proc(db: ^sqlite3) -> Result ---
	extended_errcode :: proc(db: ^sqlite3) -> Result ---
	errmsg           :: proc(db: ^sqlite3) -> cstring ---
	errmsg16         :: proc(db: ^sqlite3) -> cstring16 ---
	errstr           :: proc(Result) -> cstring ---
	error_offset     :: proc(db: ^sqlite3) -> c.int ---
	set_errmsg       :: proc(db: ^sqlite3, errcode: Result, zErrMsg: cstring) -> Result ---

	limit :: proc(db: ^sqlite3, id: Limit_Category, newVal: c.int) -> c.int ---


	@(link_name="sqlite3_prepare") prepare_str :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    cstring,       /* SQL statement, UTF-8 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u8) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare_v2") prepare_v2_str :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    cstring,       /* SQL statement, UTF-8 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u8) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare_v3") prepare_v3_str :: proc(
		db:        ^sqlite3,      /* Database handle */
		zSql:      cstring,       /* SQL statement, UTF-8 encoded */
		nByte:     c.int,         /* Maximum length of zSql in bytes. */
		prepFlags: Prepare_Flags, /* Zero or more SQLITE_PREPARE_ flags */
		ppStmt:    ^^stmt,        /* OUT: Statement handle */
		pzTail:    Maybe(^[^]u8) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---

	@(link_name="sqlite3_prepare") prepare_buf :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    [^]u8,         /* SQL statement, UTF-8 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u8) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare_v2") prepare_v2_buf :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    [^]u8,         /* SQL statement, UTF-8 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u8) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare_v3") prepare_v3_buf :: proc(
		db:        ^sqlite3,      /* Database handle */
		zSql:      [^]u8,         /* SQL statement, UTF-8 encoded */
		nByte:     c.int,         /* Maximum length of zSql in bytes. */
		prepFlags: Prepare_Flags, /* Zero or more SQLITE_PREPARE_ flags */
		ppStmt:    ^^stmt,        /* OUT: Statement handle */
		pzTail:    Maybe(^[^]u8) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	
	@(link_name="sqlite3_prepare16") prepare16_str :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    cstring16,     /* SQL statement, UTF-16 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u16) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare16_v2") prepare16_v2_str :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    cstring16,     /* SQL statement, UTF-16 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u16) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare16_v3") prepare16_v3_str :: proc(
		db:        ^sqlite3,      /* Database handle */
		zSql:      cstring16,     /* SQL statement, UTF-16 encoded */
		nByte:     c.int,         /* Maximum length of zSql in bytes. */
		prepFlags: Prepare_Flags, /* Zero or more SQLITE_PREPARE_ flags */
		ppStmt:    ^^stmt,        /* OUT: Statement handle */
		pzTail:    Maybe(^[^]u16) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---


	@(link_name="sqlite3_prepare16") prepare16_buf :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    [^]u16,        /* SQL statement, UTF-16 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u16) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare16_v2") prepare16_v2_buf :: proc(
		db:      ^sqlite3,      /* Database handle */
		zSql:    [^]u16,        /* SQL statement, UTF-16 encoded */
		nByte:   c.int,         /* Maximum length of zSql in bytes. */
		ppStmt:  ^^stmt,        /* OUT: Statement handle */
		pzTail:  Maybe(^[^]u16) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---
	@(link_name="sqlite3_prepare16_3") prepare16_v3_buf :: proc(
		db:        ^sqlite3,      /* Database handle */
		zSql:      [^]u16,        /* SQL statement, UTF-16 encoded */
		nByte:     c.int,         /* Maximum length of zSql in bytes. */
		prepFlags: Prepare_Flags, /* Zero or more SQLITE_PREPARE_ flags */
		ppStmt:    ^^stmt,        /* OUT: Statement handle */
		pzTail:    Maybe(^[^]u16) = nil, /* OUT: Pointer to unused portion of zSql */
	) -> Result ---


	sql          :: proc(pStmt: ^stmt) -> cstring ---
	expanded_sql :: proc(pStmt: ^stmt) -> cstring ---

	stmt_readonly  :: proc(pStmt: ^stmt) -> b32 ---
	stmt_isexplain :: proc(pStmt: ^stmt) -> b32 ---
	stmt_explain   :: proc(pStmt: ^stmt, eMode: c.int) -> Result ---
	stmt_busy      :: proc(pStmt: ^stmt) -> b32 ---

	bind_blob    :: proc(pStmt: ^stmt, idx: c.int, data: rawptr, n: c.int,  d: proc "c" (rawptr) = SQLITE_STATIC) -> Result ---
	bind_blob64  :: proc(pStmt: ^stmt, idx: c.int, data: rawptr, n: uint64, d: proc "c" (rawptr) = SQLITE_STATIC) -> Result ---
	bind_double  :: proc(pStmt: ^stmt, idx: c.int, data: double) -> Result ---
	bind_int     :: proc(pStmt: ^stmt, idx: c.int, data: c.int) -> Result ---
	bind_int64   :: proc(pStmt: ^stmt, idx: c.int, data: int64) -> Result ---
	bind_null    :: proc(pStmt: ^stmt, idx: c.int) -> Result ---
	bind_value   :: proc(pStmt: ^stmt, idx: c.int, data: ^value) -> Result ---
	bind_pointer :: proc(pStmt: ^stmt, idx: c.int, data: rawptr, t: cstring, d: proc "c" (rawptr) = SQLITE_STATIC) -> Result ---

	@(link_name="sqlite3_bind_text")
	bind_text_str   :: proc(pStmt: ^stmt, idx: c.int, data: cstring,   n: c.int,  d: proc "c" (rawptr) = SQLITE_STATIC) -> Result ---
	@(link_name="sqlite3_bind_text16")
	bind_text16_str :: proc(pStmt: ^stmt, idx: c.int, data: cstring16, n: c.int,  d: proc "c" (rawptr) = SQLITE_STATIC) -> Result ---
	
	@(link_name="sqlite3_bind_text")
	bind_text_buf   :: proc(pStmt: ^stmt, idx: c.int, data: [^]u8,  n: c.int, d: proc "c" (rawptr) = SQLITE_STATIC) -> Result ---
	@(link_name="sqlite3_bind_text16")
	bind_text16_buf :: proc(pStmt: ^stmt, idx: c.int, data: [^]u16, n: c.int, d: proc "c" (rawptr) = SQLITE_STATIC) -> Result ---

	bind_text64  :: proc(pStmt: ^stmt, idx: c.int, data: rawptr, n: uint64, d: proc "c" (rawptr), encoding: Text_Encoding_U8) -> Result ---
	
	

	bind_zeroblob   :: proc(pStmt: ^stmt, idx: c.int, n: c.int)  -> Result ---
	bind_zeroblob64 :: proc(pStmt: ^stmt, idx: c.int, n: uint64) -> Result ---

	bind_parameter_count :: proc(pStmt: ^stmt) -> c.int ---
	bind_parameter_name  :: proc(pStmt: ^stmt, N: int) -> cstring ---
	bind_parameter_index :: proc(pStmt: ^stmt, zName: cstring) -> c.int ---

	clear_bindings :: proc(pStmt: ^stmt) -> Result ---

	column_count :: proc(pStmt: ^stmt) -> c.int ---

	column_name            :: proc(pStmt: ^stmt, N: c.int) -> cstring ---
	column_name16          :: proc(pStmt: ^stmt, N: c.int) -> cstring16 ---
	column_database_name   :: proc(pStmt: ^stmt, N: c.int) -> cstring ---
	column_database_name16 :: proc(pStmt: ^stmt, N: c.int) -> cstring16 ---
	column_table_name      :: proc(pStmt: ^stmt, N: c.int) -> cstring ---
	column_table_name16    :: proc(pStmt: ^stmt, N: c.int) -> cstring16 ---
	column_origin_name     :: proc(pStmt: ^stmt, N: c.int) -> cstring ---
	column_origin_name16   :: proc(pStmt: ^stmt, N: c.int) -> cstring16 ---
	column_decltype        :: proc(pStmt: ^stmt, N: c.int) -> cstring ---
	column_decltype16      :: proc(pStmt: ^stmt, N: c.int) -> cstring16 ---

	step :: proc(pStmt: ^stmt) -> Result ---

	data_count :: proc(pStmt: ^stmt) -> c.int ---

	column_blob    :: proc(pStmt: ^stmt, iCol: c.int) -> [^]byte ---
	column_double  :: proc(pStmt: ^stmt, iCol: c.int) -> double ---
	column_int     :: proc(pStmt: ^stmt, iCol: c.int) -> c.int ---
	column_int64   :: proc(pStmt: ^stmt, iCol: c.int) -> int64 ---
	column_text    :: proc(pStmt: ^stmt, iCol: c.int) -> cstring ---
	column_text16  :: proc(pStmt: ^stmt, iCol: c.int) -> cstring16 ---
	column_value   :: proc(pStmt: ^stmt, iCol: c.int) -> ^value ---
	column_bytes   :: proc(pStmt: ^stmt, iCol: c.int) -> c.int ---
	column_bytes16 :: proc(pStmt: ^stmt, iCol: c.int) -> c.int ---
	column_type    :: proc(pStmt: ^stmt, iCol: c.int) -> c.int ---

	finalize :: proc(pStmt: ^stmt) -> Result ---

	reset :: proc(pStmt: ^stmt) -> Result ---

	create_function :: proc(
		db: ^sqlite3,
		zFunctionName: cstring,
		nArg: c.int,
		eTextRep: Text_Encoding,
		pApp: rawptr,
		xFunc:  proc "c" (^sqlite3_context, c.int, ^^value),
		xStep:  proc "c" (^sqlite3_context, c.int, ^^value),
		xFinal: proc "c" (^sqlite3_context),
	) -> Result ---
	create_function16 :: proc(
		db: ^sqlite3,
		zFunctionName: cstring16,
		nArg: c.int,
		eTextRep: Text_Encoding,
		pApp: rawptr,
		xFunc:  proc "c" (^sqlite3_context, c.int, ^^value),
		xStep:  proc "c" (^sqlite3_context, c.int, ^^value),
		xFinal: proc "c" (^sqlite3_context),
	) -> Result ---
	create_function_v2 :: proc(
		db: ^sqlite3,
		zFunctionName: cstring,
		nArg: c.int,
		eTextRep: Text_Encoding,
		pApp: rawptr,
		xFunc:    proc "c" (^sqlite3_context, c.int, ^^value),
		xStep:    proc "c" (^sqlite3_context, c.int, ^^value),
		xFinal:   proc "c" (^sqlite3_context),
		xDestroy: proc "c" (rawptr),
	) -> Result ---
	create_window_function :: proc(
		db: ^sqlite3,
		zFunctionName: cstring,
		nArg: c.int,
		eTextRep: Text_Encoding,
		pApp: rawptr,
		xStep:    proc "c" (^sqlite3_context, c.int, ^^value),
		xFinal:   proc "c" (^sqlite3_context),
		xValue:   proc "c" (^sqlite3_context),
		xInverse: proc "c" (^sqlite3_context, c.int, ^^value),
		xDestroy: proc "c" (rawptr),
	) -> Result ---

	value_blob         :: proc(pVal: ^value) -> [^]byte ---
	value_double       :: proc(pVal: ^value) -> double ---
	value_int          :: proc(pVal: ^value) -> c.int ---
	value_int64        :: proc(pVal: ^value) -> int64 ---
	value_pointer      :: proc(pVal: ^value, zPType: cstring) -> rawptr ---
	value_text         :: proc(pVal: ^value) -> cstring ---
	value_text16       :: proc(pVal: ^value) -> cstring16 ---
	value_text16le     :: proc(pVal: ^value) -> [^]u16le ---
	value_text16be     :: proc(pVal: ^value) -> [^]u16be ---
	value_bytes        :: proc(pVal: ^value) -> c.int ---
	value_bytes16      :: proc(pVal: ^value) -> c.int ---
	value_type         :: proc(pVal: ^value) -> Datatype ---
	value_numeric_type :: proc(pVal: ^value) -> Datatype ---
	value_nochange     :: proc(pVal: ^value) -> b32 ---
	value_frombind     :: proc(pVal: ^value) -> b32 ---
	value_encoding     :: proc(pVal: ^value) -> Text_Encoding ---
	value_subtype      :: proc(pVal: ^value) -> c.uint ---

	value_dup          :: proc(pVal: ^value) -> ^value ---
	value_free         :: proc(pVal: ^value) ---

	aggregate_context :: proc(pCtx: ^sqlite3_context, nBytes: c.int) -> rawptr ---

	user_data :: proc(pCtx: ^sqlite3_context) -> rawptr ---

	context_db_handle :: proc(pCtx: ^sqlite3_context) -> ^sqlite3 ---

	get_auxdata :: proc(pCtx: ^sqlite3_context, N: c.int) -> rawptr ---
	set_auxdata :: proc(pCtx: ^sqlite3_context, N: c.int, p: rawptr, d: proc "c" (rawptr) = SQLITE_STATIC) ---

	get_clientdata :: proc(db: ^sqlite3, zName: cstring) -> rawptr ---
	set_clientdata :: proc(db: ^sqlite3, zName: cstring, pData: rawptr, xDestructor: proc "c" (rawptr)) -> Result ---

	result_blob         :: proc(pCtx: ^sqlite3_context, z: rawptr, n: c.int,  xDel: proc "c" (rawptr) = SQLITE_STATIC) ---
	result_blob64       :: proc(pCtx: ^sqlite3_context, z: rawptr, n: uint64, xDel: proc "c" (rawptr) = SQLITE_STATIC) ---
	result_double       :: proc(pCtx: ^sqlite3_context, rVal: double) ---
	result_error_toobig :: proc(pCtx: ^sqlite3_context) ---
	result_error_nomem  :: proc(pCtx: ^sqlite3_context) ---
	result_error_code   :: proc(pCtx: ^sqlite3_context, data: Result) ---
	result_int          :: proc(pCtx: ^sqlite3_context, data: c.int) ---
	result_int64        :: proc(pCtx: ^sqlite3_context, data: int64) ---
	result_null         :: proc(pCtx: ^sqlite3_context) ---
	result_text16le     :: proc(pCtx: ^sqlite3_context, data: [^]u16le,  n: c.int,  xDel: proc "c" (rawptr) = SQLITE_STATIC) ---
	result_text16be     :: proc(pCtx: ^sqlite3_context, data: [^]u16be,  n: c.int,  xDel: proc "c" (rawptr) = SQLITE_STATIC) ---
	result_value        :: proc(pCtx: ^sqlite3_context, data: ^value) ---
	result_pointer      :: proc(pCtx: ^sqlite3_context, data: rawptr, t: cstring, xDel: proc "c" (rawptr) = SQLITE_STATIC) ---

	@(link_name="sqlite3_result_error")
	result_error_str        :: proc(pCtx: ^sqlite3_context, data: cstring,   n: c.int) ---
	@(link_name="sqlite3_result_error16")
	result_error16_str      :: proc(pCtx: ^sqlite3_context, data: cstring16, n: c.int) ---
	@(link_name="sqlite3_result_error")
	result_error_buf        :: proc(pCtx: ^sqlite3_context, data: [^]u8,   n: c.int) ---
	@(link_name="sqlite3_result_error16")
	result_error16_buf      :: proc(pCtx: ^sqlite3_context, data: [^]u16, n: c.int) ---

	@(link_name="sqlite3_result_text")
	result_text_str   :: proc(pCtx: ^sqlite3_context, data: cstring,   n: c.int,  d: proc "c" (rawptr) = SQLITE_STATIC) ---
	@(link_name="sqlite3_result_text")
	result_text_buf   :: proc(pCtx: ^sqlite3_context, data: [^]u8,     n: c.int,  d: proc "c" (rawptr) = SQLITE_STATIC) ---
	@(link_name="sqlite3_result16_text")
	result_text16_str :: proc(pCtx: ^sqlite3_context, data: cstring16, n: c.int,  d: proc "c" (rawptr) = SQLITE_STATIC) ---
	@(link_name="sqlite3_result16_text")
	result_text16_buf :: proc(pCtx: ^sqlite3_context, data: [^]u16,    n: c.int,  d: proc "c" (rawptr) = SQLITE_STATIC) ---

	result_text64     :: proc(pCtx: ^sqlite3_context, data: rawptr,    n: uint64, d: proc "c" (rawptr) = SQLITE_STATIC, encoding: Text_Encoding_U8) ---
	
	result_zeroblob     :: proc(pCtx: ^sqlite3_context, n: c.int) ---
	result_zeroblob64   :: proc(pCtx: ^sqlite3_context, n: uint64) -> Result ---

	result_subtype      :: proc(pCtx: ^sqlite3_context, eSubtype: c.uint) ---

	create_collation :: proc(
		db: ^sqlite3,
		zName: cstring,
		eTextRep: Text_Encoding,
		pArg: rawptr,
		xCompare: proc "c" (rawptr, c.int, rawptr, c.int, cstring) -> c.int,
	) -> Result ---
	create_collation_v2 :: proc(
		db: ^sqlite3,
		zName: cstring,
		eTextRep: Text_Encoding,
		pArg: rawptr,
		xCompare: proc "c" (rawptr, c.int, rawptr, c.int, cstring) -> c.int,
		xDestroy: proc "c" (rawptr),
	) -> Result ---
	create_collation16 :: proc(
		db: ^sqlite3,
		zName: cstring16,
		eTextRep: Text_Encoding,
		pArg: rawptr,
		xCompare: proc "c" (rawptr, c.int, rawptr, c.int, cstring) -> c.int,
	) -> Result ---

	collation_needed :: proc(
		db: ^sqlite3,
		pCollNeededArg: rawptr,
		xCollNeeded: proc "c" (rawptr, ^sqlite3, Text_Encoding, cstring),
	) -> Result ---
	collation_needed16 :: proc(
		db: ^sqlite3,
		pCollNeededArg: rawptr,
		xCollNeeded: proc "c" (rawptr, ^sqlite3, Text_Encoding, cstring16),
	) -> Result ---

	sleep :: proc(ms: c.int) -> c.int ---

	win32_set_directory :: proc(
		type: WIN32_Dir_Type, /* Identifier for directory being set or reset */
		zValue: rawptr,       /* New value for directory being set or reset */
	) -> Result ---
	win32_set_directory8  :: proc(type: WIN32_Dir_Type, zValue: cstring) -> Result ---
	win32_set_directory16 :: proc(type: WIN32_Dir_Type, zValue: cstring16) -> Result ---

	get_autocommit :: proc(db: ^sqlite3) -> Result ---

	db_handle   :: proc(pStmt: ^stmt) -> ^sqlite3 ---
	db_name     :: proc(db: ^sqlite3, N: c.int) -> cstring ---
	db_filename :: proc(db: ^sqlite3, zDbName: cstring) -> filename ---
	db_readonly :: proc(db: ^sqlite3, zDbName: cstring) -> c.int ---

	txn_state :: proc(db: ^sqlite3, zSchema: cstring) -> TXN_State ---

	next_stmt :: proc(pDb: ^sqlite3, pStmt: ^stmt) -> ^stmt ---

	commit_hook   :: proc(^sqlite3, proc "c" (rawptr) -> b32, rawptr) -> rawptr ---
	rollback_hook :: proc(^sqlite3, proc "c" (rawptr), rawptr) -> rawptr ---

	autovacuum_pages :: proc(
		db: ^sqlite3,
		cb: proc "c" (rawptr, cstring, c.uint, c.uint, c.uint) -> c.uint,
		p: rawptr,
		d: proc "c" (rawptr) = SQLITE_STATIC,
	) -> Result ---

	update_hook :: proc(
		db: ^sqlite3,
		xCallback: proc "c" (rawptr, c.int, cstring, cstring, int64),
		pArg: rawptr,
	) -> rawptr ---

	release_memory    :: proc(c.int) -> c.int ---
	db_release_memory :: proc(db: ^sqlite3) -> c.int ---

	soft_heap_limit64 :: proc(N: int64) -> int64 ---
	hard_heap_limit64 :: proc(N: int64) -> int64 ---

	@(deprecated="Use sqlite3.soft_heap_limit64() instead")
	soft_heap_limit :: proc(N: c.int) ---

	table_column_metadata :: proc(
		db:          ^sqlite3, /* Connection handle */
		zDbName:     cstring,  /* Database name or NULL */
		zTableName:  cstring,  /* Table name */
		zColumnName: cstring,  /* Column name */
		pzDataType:  ^cstring, /* OUTPUT: Declared data type */
		pzCollSeq:   ^cstring, /* OUTPUT: Collation sequence name */
		pNotNull:    ^c.int,   /* OUTPUT: True if NOT NULL constraint exists */
		pPrimaryKey: ^c.int,   /* OUTPUT: True if column part of PK */
		pAutoinc:    ^c.int,   /* OUTPUT: True if column is auto-increment */
	) -> Result ---

	load_extension :: proc(
		db:       ^sqlite3,        /* Load the extension into this database connection */
		zFile:    cstring,         /* Name of the shared library containing extension */
		zProc:    cstring,         /* Entry point.  Derived from zFile if 0 */
		pzErrMsg: Maybe(^cstring), /* Put error message here if not 0 */
	) -> Result ---
	enable_load_extension :: proc(db: ^sqlite3, onoff: b32) -> Result ---

	auto_extension        :: proc(xEntryPoint: proc "c" ()) -> Result ---
	cancel_auto_extension :: proc(xEntryPoint: proc "c" ()) -> Result ---
	reset_auto_extension : : proc() ---

	create_module :: proc(
		db:          ^sqlite3, /* SQLite connection to register module with */
		zName:       cstring,  /* Name of the module */
		p:           ^module,  /* Methods for the module */
		pClientData: rawptr,   /* Client data for xCreate/xConnect */
	) -> Result ---
	create_module_v2 :: proc(
		db:          ^sqlite3, /* SQLite connection to register module with */
		zName:       cstring,  /* Name of the module */
		p:           ^module,  /* Methods for the module */
		pClientData: rawptr,   /* Client data for xCreate/xConnect */
		xDestroy:    proc "c" (rawptr), /* Module destructor function */
	) -> Result ---

	drop_modules :: proc(
		db:     ^sqlite3,          /* Remove modules from this connection */
		azKeep: Maybe([^]cstring), /* Except, do not remove the ones named here */
	) -> Result ---

	declare_vtab :: proc(db: ^sqlite3, zSQL: cstring) -> Result ---

	overload_function :: proc(db: ^sqlite3, zFuncName: cstring, nArg: c.int) -> Result ---

	blob_open :: proc(
		db:      ^sqlite3,
		zDb:     cstring,
		zTable:  cstring,
		zColumn: cstring,
		iRow:    int64,
		flags:   Open_Flags,
		ppBlob:  ^^blob,
	) -> Result ---
	blob_reopen :: proc(pBlob: ^blob, iRow: int64) -> Result ---
	blob_close  :: proc(pBlob: ^blob) -> Result ---
	blob_bytes  :: proc(pBlob: ^blob) -> c.int ---
	blob_read   :: proc(pBlob: ^blob, Z: [^]byte, N: c.int, iOffset: c.int) -> Result ---
	blob_write  :: proc(pBlob: ^blob, Z: [^]byte, N: c.int, iOffset: c.int) -> Result ---

	vfs_find       :: proc(zVfsName: cstring) -> ^vfs ---
	vfs_register   :: proc(pVfs: ^vfs, makeDflt: ^int) -> Result ---
	vfs_unregister :: proc(pVfs: ^vfs) -> Result ---

	mutex_alloc :: proc(id: c.int) -> ^mutex ---
	mutex_free  :: proc(p: ^mutex) ---
	mutex_enter :: proc(p: ^mutex) ---
	mutex_try   :: proc(p: ^mutex) -> Result --- 
	mutex_leave :: proc(p: ^mutex) ---

	db_mutex :: proc(db: ^sqlite3) -> ^mutex ---

	file_control :: proc(db: ^sqlite3, zDbName: cstring, op: FCNTL_Opcodes, p: rawptr) -> Result ---

	test_control :: proc(op: Test_Ctrl_Op, #c_vararg ops: ..any) -> Result ---

	keyword_count :: proc() -> c.int ---
	keyword_name  :: proc(i: c.int, pzName: ^cstring, pnName: ^c.int) -> Result ---

	@(link_name="keyword_check")
	keyword_check_str :: proc(zName: cstring, nName: c.int) -> b32 ---
	@(link_name="keyword_check")
	keyword_check_buf :: proc(zName: [^]u8, nName: c.int) -> b32 ---

	str_new        :: proc(db: ^sqlite3) -> ^str ---
	str_finish     :: proc(p: ^str) -> cstring ---
	str_free       :: proc(p: ^str) ---
	str_appendf    :: proc(p: ^str, zFormat: cstring, #c_vararg args: ..any) ---
	str_vappendf   :: proc(p: ^str, zFormat: cstring, list: c.va_list) ---
	str_append     :: proc(p: ^str, zIn: [^]u8, N: c.int) ---
	str_appendall  :: proc(p: ^str, zIn: cstring) ---
	str_appendchar :: proc(p: ^str, N: c.int, C: c.char) ---
	str_reset      :: proc(p: ^str) ---
	str_truncate   :: proc(p: ^str, N: c.int) ---
	str_errcode    :: proc(p: ^str) -> Result ---
	str_length     :: proc(p: ^str) -> c.int ---
	str_value      :: proc(p: ^str) -> [^]u8 ---

	status   :: proc(op: Status, pCurrent: ^c.int, pHighwater: ^c.int, resetFlag: b32) -> Result ---
	status64 :: proc(op: Status, pCurrent: ^int64, pHighwater: ^int64, resetFlag: b32) -> Result ---

	db_status   :: proc(db: ^sqlite3, op: DB_Status, pCur: ^c.int, pHiwtr: ^c.int, resetFlag: b32) -> Result ---
	db_status64 :: proc(db: ^sqlite3, op: DB_Status, pCur: ^int64, pHiwtr: ^int64, resetFlag: b32) -> Result ---

	stmt_status :: proc(p: ^stmt, op: STMT_Status, resetFlag: b32) -> c.int ---

	backup_init :: proc(
		pDest:       ^sqlite3, /* Destination database handle */
		zDestName:   cstring,  /* Destination database name */
		pSource:     ^sqlite3, /* Source database handle */
		zSourceName: cstring,  /* Source database name */
	) -> ^backup ---
	backup_step      :: proc(p: ^backup, nPage: c.int) -> Result ---
	backup_finish    :: proc(p: ^backup) -> Result ---
	backup_remaining :: proc(p: ^backup) -> Result ---
	backup_pagecount :: proc(p: ^backup) -> Result ---

	unlock_notify :: proc(
		pBlocked:   ^sqlite3, /* Waiting connection */
		xNotify:    proc "c" (apArg: [^]rawptr, nArg: c.int), /* Callback function to invoke */
		pNotifyArg: rawptr,   /* Argument to pass to xNotify */
	) -> Result ---

	stricmp  :: proc(zLeft: cstring, zRight: cstring) -> c.int ---
	@(link_name="sqlite3_strnicmp")
	strnicmp_str :: proc(zLeft: cstring, zRight: cstring, N: c.int) -> c.int ---
	@(link_name="sqlite3_strnicmp")
	strnicmp_buf :: proc(zLeft: [^]u8, zRight: [^]u8, N: c.int) -> c.int ---

	strglob :: proc(zGlob: cstring, zStr: cstring) -> Match_Res ---
	strlike :: proc(zGlob: cstring, zStr: cstring, cEsc: c.uint) -> Match_Res ---

	log :: proc(iErrCode: Result, zFormat: cstring, #c_vararg args: ..any) ---

	wal_hook :: proc(db: ^sqlite3, pxCallback: proc "c" (rawptr, ^sqlite3, cstring, c.int), pArg: rawptr) -> rawptr ---
	wal_autocheckpoint :: proc(db: ^sqlite3, N: c.int) -> Result ---
	wal_checkpoint     :: proc(db: ^sqlite3, zDb: cstring) -> Result ---
	wal_checkpoint_v2  :: proc(
		db:     ^sqlite3,        /* Database handle */
		zDb:    cstring,         /* Name of attached database (or NULL) */
		eMode:  Checkpoint_Mode, /* SQLITE_CHECKPOINT_* value */
		pnLog:  ^c.int,          /* OUT: Size of WAL log in frames */
		pnCkpt: ^c.int,          /* OUT: Total number of frames checkpointed */
	) -> Result ---

	vtab_config      :: proc(db: ^sqlite3, op: VTab_Config, #c_vararg args: ..any) -> Result ---
	vtab_on_conflict :: proc(db: ^sqlite3) -> Conflict_Resolution ---
	vtab_nochange    :: proc(ppCtx: ^sqlite3_context) -> b32 ---
	vtab_collation   :: proc(pIdxInfo: ^index_info, iCons: c.int) -> cstring ---
	vtab_distinct    :: proc(pIdxInfo: ^index_info) -> b32 ---
	vtab_in          :: proc(pIdxInfo: ^index_info, iCons: c.int, bHandle: b32) -> b32 ---
	vtab_in_first    :: proc(pVal: ^value, ppOut: ^^value) -> Result ---
	vtab_in_next     :: proc(pVal: ^value, ppOut: ^^value) -> Result ---
	vtab_rhs_value   :: proc(pIdxInfo: ^index_info, n: c.int, ppVal: ^^value) -> Result ---

	stmt_scanstatus :: proc(
		pStmt:         ^stmt,        /* Prepared statement for which info desired */
		idx:           c.int,        /* Index of loop to report on */
		iScanStatusOp: Scan_Stat_Op, /* Information desired.  SQLITE_SCANSTAT_* */
		pOut:          rawptr,       /* Result written here */
	) -> b32 ---
	stmt_scanstatus_v2 :: proc(
		pStmt:         ^stmt,           /* Prepared statement for which info desired */
		idx:           c.int,           /* Index of loop to report on */
		iScanStatusOp: Scan_Stat_Op,    /* Information desired.  SQLITE_SCANSTAT_* */
		flags:         Scan_Stat_Flags, /* Mask of flags defined below */
		pOut:          rawptr,          /* Result written here */
	) -> b32 ---
	stmt_scanstatus_reset :: proc(pStmt: ^stmt) ---

	db_cacheflush :: proc(db: ^sqlite3) -> Result ---

	system_errno :: proc(db: ^sqlite3) -> c.int ---

	snapshot_get     :: proc(db: ^sqlite3, zSchema: cstring, ppSnapshot: ^^snapshot) -> Result ---
	snapshot_open    :: proc(db: ^sqlite3, zSchema: cstring, ppSnapshot: ^^snapshot) -> Result ---
	snapshot_free    :: proc(pSnapshot: ^snapshot) ---
	snapshot_cmp     :: proc(p1: ^snapshot, p2: ^snapshot) -> c.int ---
	snapshot_recover :: proc(db: ^sqlite3, zDb: cstring) -> Result ---

	serialize :: proc(
		db:      ^sqlite3,        /* The database connection */
		zSchema: cstring,         /* Which DB to serialize. ex: "main", "temp", ... */
		piSize:  ^int64,          /* Write size of the DB here, if not NULL */
		mFlags:  Serialize_Flags, /* Zero or more SQLITE_SERIALIZE_* flags */
	) -> cstring ---

	deserialize :: proc(
		db:      ^sqlite3,          /* The database connection */
		zSchema: cstring,           /* Which DB to reopen with the deserialization */
		pData:   [^]byte,           /* The serialized database content */
		szDb:    int64,             /* Number of bytes in the deserialization */
		szBuf:   int64,             /* Total size of buffer pData[] */
		mFlags:  Deserialize_Flags, /* Zero or more SQLITE_SERIALIZE_* flags */
	) -> Result ---

	carray_bind_v2 :: proc(
		pStmt:  ^stmt,             /* Statement to be bound */
		i:      c.int,             /* Parameter index */
		aData:  rawptr,            /* Pointer to array data */
		nData:  c.int,             /* Number of data elements */
		mFlags: Carray_Flag,       /* CARRAY flags */
		xDel:   proc "c" (rawptr), /* Destructor for aData */
		pDel:   rawptr,            /* Optional argument to xDel() */
	) -> Result ---
	carray_bind :: proc(
		pStmt:  ^stmt,             /* Statement to be bound */
		i:      c.int,             /* Parameter index */
		aData:  rawptr,            /* Pointer to array data */
		nData:  c.int,             /* Number of data elements */
		mFlags: Carray_Flag,       /* CARRAY flags */
		xDel:   proc "c" (rawptr), /* Destructor for aData */
	) -> Result ---
}


when !OMIT_COMPILEOPTION_DIAGS {
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		compileoption_used :: proc (zOptName: cstring) -> b32 ---
		compileoption_get  :: proc (N: c.int) -> cstring ---
	}
} else {
	compileoption_used :: proc "c" (zOptName: cstring) -> b32 { return false }
	compileoption_get  :: proc "c" (N: c.int) -> cstring { return "" }
}


when ENABLE_NORMALIZE {
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		normalized_sql :: proc(pStmt: ^stmt) -> cstring ---
	}   
}


when !OMIT_DEPRECATED {
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		aggregate_count   :: proc(p: ^sqlite3_context) -> c.int ---
		expired           :: proc(pStmt: ^stmt) -> bool ---
		transfer_bindings :: proc(pFromStmt: ^stmt, pToStmt: ^stmt) -> Result ---
		global_recover    :: proc() -> Result ---
		thread_cleanup    :: proc() ---
		memory_alarm      :: proc(
			xCallback: proc "c" (rawptr, int64, c.int), 
			pArg: rawptr, 
			iThreshold: int64,
		) -> Result ---
	}   
}


when ENABLE_CEROD {
	/*
	** Specify the activation key for a CEROD database.  Unless
	** activated, none of the CEROD routines will work.
	*/
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		activate_cerod :: proc(
			zPassPhrase: cstring, /* Activation phrase */
		) ---
	}
}


when !OMIT_SHARED_CACHE {
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		enable_shared_cache :: proc(enable: b32) -> Result ---
	}
}


when !SQLITE_DEBUG {
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		mutex_held    :: proc(p: ^mutex) -> Result ---
		mutex_notheld :: proc(p: ^mutex) -> Result ---
	}
}


when ENABLE_PREUPDATE_HOOK {
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		preupdate_hook :: proc(
			db: ^sqlite3,
			xPreUpdate: proc"c" (
				pCtx:  rawptr,    /* Copy of third arg to preupdate_hook() */
				db:    ^sqlite3,    /* Database handle */
				op:    Action_Code, /* SQLITE_UPDATE, DELETE or INSERT */
				zDb:   cstring,    /* Database name */
				zName: cstring,  /* Table name */
				iKey1: int64,    /* Rowid of row about to be deleted/updated */
				iKey2: int64,    /* New rowid value (for a rowid UPDATE) */
			),
			pCtx: rawptr,
		) -> rawptr ---
		preupdate_old       :: proc(db: ^sqlite3, iIdx: c.int, ppValue: ^^value) -> Result ---
		preupdate_count     :: proc(db: ^sqlite3) -> c.int ---
		preupdate_depth     :: proc(db: ^sqlite3) -> c.int ---
		preupdate_new       :: proc(db: ^sqlite3, iIdx: c.int, ppValue: ^^value) -> Result ---
		preupdate_blobwrite :: proc(db: ^sqlite3) -> c.int ---
	}
}


result :: proc {
	result_blob,   result_blob64, 
	result_double, result_int, 
	result_int64, result_error_code, 
	result_error_str, result_error16_str,
	result_text64, 
	result_text_str, result_error_buf,
	result_text16_str, result_error16_buf,
	result_text16le, result_text16be,
	result_value,  result_pointer, result_null,
}

result_error   :: proc { result_error_str,   result_error_buf }
result_error16 :: proc { result_error16_str, result_error16_buf }
result_text    :: proc { result_text_str,    result_text_buf }
result_text16  :: proc { result_text16_str,  result_text16_buf }

result_zero :: proc { result_zeroblob, result_zeroblob64 }

bind :: proc {
	bind_blob,     bind_blob64,
	bind_double,   bind_int,        bind_int64, 
	bind_value,    bind_pointer,    bind_null,
	bind_text64,   bind_text_str,   bind_text16_str,
	bind_text_buf, bind_text16_buf,
}

bind_text   :: proc { bind_text_str,   bind_text_buf }
bind_text16 :: proc { bind_text16_str, bind_text16_buf }

bind_zero :: proc { bind_zeroblob, bind_zeroblob64 }

format :: mprintf
printf :: format

prepare      :: proc { prepare_str,      prepare_buf      }
prepare_v2   :: proc { prepare_v2_str,   prepare_v2_buf   }
prepare_v3   :: proc { prepare_v3_str,   prepare_v3_buf   }
prepare16    :: proc { prepare16_str,    prepare16_buf    }
prepare16_v2 :: proc { prepare16_v2_str, prepare16_v2_buf }
prepare16_v3 :: proc { prepare16_v2_str, prepare16_v3_buf }

keyword_check :: proc { keyword_check_str, keyword_check_buf }

strnicmp :: proc { strnicmp_str, strnicmp_buf }



api_routines    :: struct {}
sqlite3_context :: struct {}

file :: struct {
	pMethods: ^io_methods,  /* Methods for an open file */
}

pcache_page :: struct {
	pBuf:   rawptr, /* The content of the page */
	pExtra: rawptr, /* Extra information associated with the page */
}

index_constraint :: struct {
	iColumn:     c.int, /* Column constrained.  -1 for ROWID */
	op:          VT_Constraint_Op, /* Constraint operator */
	usable:      b8,    /* True if this constraint is usable */
	iTermOffset: c.int, /* Used internally - xBestIndex should ignore */
}

index_orderby :: struct {
	iColumn: c.int, /* Column number */
	desc:    b8,    /* True for DESC.  False for ASC. */
}

index_constraint_usage :: struct {
	argvIndex: c.int,            /* if >0, constraint is part of argv to xFilter */
	omit:      VT_Constraint_Op, /* Do not code a test for this constraint */
}

index_info :: struct {
	/* Inputs */
	nConstraint:      c.int,               /* Number of entries in aConstraint */
	aConstraint:      [^]index_constraint, /* Table of WHERE clause constraints */
	nOrderBy:         c.int,               /* Number of terms in the ORDER BY clause */
	aOrderBy:         [^]index_orderby,    /* The ORDER BY clause */
	/* Outputs */
	aConstraintUsage: [^]index_constraint_usage,
	idxNum:           c.int,               /* Number used to identify the index */
	idxStr:           cstring,             /* String, possibly obtained from sqlite3_malloc */
	needToFreeIdxStr: b32,                 /* Free idxStr using sqlite3_free() if true */
	orderByConsumed:  b32,                 /* True if output is already ordered */
	estimatedCost:    double,              /* Estimated cost of using this index */
	/* Fields below are only available in SQLite 3.8.2 and later */
	estimatedRows:    int64,               /* Estimated number of rows returned */
	/* Fields below are only available in SQLite 3.9.0 and later */
	idxFlags:         VT_Scan_Flags,       /* Mask of SQLITE_INDEX_SCAN_* flags */
	/* Fields below are only available in SQLite 3.10.0 and later */
	colUsed:          uint64,              /* Input: Mask of columns used by statement */
}

vtab :: struct {
	pModule: ^module, /* The module for this virtual table */
	nRef:    c.int,   /* Number of open cursors */
	zErrMsg: [^]u8,   /* Error message from sqlite3_mprintf() */
	/* Virtual table implementations will typically add additional fields */
}

vtab_cursor :: struct {
	pVtab: ^vtab, /* Virtual table of this cursor */
	/* Virtual table implementations will typically add additional fields */
}

snapshot :: struct {
	hidden: [48]u8,
}


io_methods :: struct {
	iVersion: c.int,
	
	xClose:                 proc "c" (fd: ^file) -> Result,
	xRead:                  proc "c" (fd: ^file, buf: rawptr, iAmt: c.int, iOfst: int64) -> Result,
	xWrite:                 proc "c" (fd: ^file, buf: rawptr, iAmt: c.int, iOfst: int64) -> Result,
	xTruncate:              proc "c" (fd: ^file, size: int64) -> Result,
	xSync:                  proc "c" (fd: ^file, flags: Sync_Flag) -> Result,
	xFileSize:              proc "c" (fd: ^file, pSize: ^int64) -> Result,
	xLock:                  proc "c" (fd: ^file, level: Lock_Level) -> Result,
	xUnlock:                proc "c" (fd: ^file, level: Lock_Level) -> Result,
	xCheckReservedLock:     proc "c" (fd: ^file, pResOut: ^c.int) -> Result,
	xFileControl:           proc "c" (fd: ^file, op: c.int, pArg: rawptr) -> Result,
	xSectorSize:            proc "c" (fd: ^file) -> c.int,
	xDeviceCharacteristics: proc "c" (fd: ^file) -> IOCAP_Flags,
	/* Methods above are valid for version 1 */
	
	xShmMap:     proc "c" (fd: ^file, iRegion: c.int, szRegion: c.int, bExtend: b32, pp: ^rawptr) -> Result,
	xShmLock:    proc "c" (fd: ^file, offset: c.int, n: c.int, flags: SHM_Lock_Flags) -> Result,
	xShmBarrier: proc "c" (fd: ^file),
	xShmUnmap:   proc "c" (fd: ^file, deleteFlag: c.int) -> Result,
	/* Methods above are valid for version 2 */
	
	xFetch:   proc "c" (fd: ^file, iOfst: int64, iAmt: c.int, pp: ^rawptr) -> Result,
	xUnfetch: proc "c" (fd: ^file, iOfst: int64, p: rawptr) -> Result,
	/* Methods above are valid for version 3 */
	/* Additional methods may be added in future releases */
}

vfs :: struct {
	iVersion:   c.int,   /* Structure version number (currently 3) */
	szOsFile:   c.int,   /* Size of subclassed sqlite3_file */
	mxPathname: c.int,   /* Maximum file pathname length */
	pNext:      ^vfs,    /* Next registered VFS */
	zName:      cstring, /* Name of this virtual file system */
	pAppData:   rawptr,  /* Pointer to application-specific data */
	
	xOpen:         proc "c" (vfs: ^vfs, zName: filename, file: ^file, flags: Open_Flags, pOutFlags: ^Open_Flags) -> Result,
	xDelete:       proc "c" (vfs: ^vfs, zName: cstring, syncDir: c.int) -> Result,
	xAccess:       proc "c" (vfs: ^vfs, zName: cstring, flags: Access_Flags, pResOut: ^b32) -> Result,
	xFullPathname: proc "c" (vfs: ^vfs, zName: cstring, nOut: c.int, zOut: [^]u8) -> Result,
	xDlOpen:       proc "c" (vfs: ^vfs, zFilename: cstring) -> rawptr,
	xDlError:      proc "c" (vfs: ^vfs, nByte: c.int, zErrMsg: [^]u8),
	xDlSym:        proc "c" (proc "c" (vfs: ^vfs, _: rawptr, zSymbol: cstring)),
	xDlClose:      proc "c" (vfs: ^vfs, _: rawptr),
	xRandomness:   proc "c" (vfs: ^vfs, nByte: c.int, zOut: [^]u8) -> c.int,
	xSleep:        proc "c" (vfs: ^vfs, microseconds: c.int) -> c.int,
	xCurrentTime:  proc "c" (vfs: ^vfs, tOut: ^double) -> c.int,
	xGetLastError: proc "c" (vfs: ^vfs, nOut: c.int, zOut: [^]u8) -> Result,
	/*
	** The methods above are in version 1 of the sqlite_vfs object
	** definition.  Those that follow are added in version 2 or later
	*/
	xCurrentTimeInt64: proc "c" (vfs: ^vfs, _: ^int64) -> c.int,
	/*
	** The methods above are in versions 1 and 2 of the sqlite_vfs object.
	** Those below are for version 3 and greater.
	*/
	xSetSystemCall:  proc "c" (vfs: ^vfs, zName: cstring, _: syscall_ptr) -> Result,
	xGetSystemCall:  proc "c" (vfs: ^vfs, zName: cstring) -> syscall_ptr,
	xNextSystemCall: proc "c" (vfs: ^vfs, zName: cstring) -> cstring,
	/*
	** The methods above are in versions 1 through 3 of the sqlite_vfs object.
	** New fields may be appended in future versions.  The iVersion
	** value will increment whenever this happens.
	*/
}

mem_methods :: struct {
	xMalloc:   proc "c" (c.int) -> rawptr,         /* Memory allocation function */
	xFree:     proc "c" (rawptr),                  /* Free a prior allocation */
	xRealloc:  proc "c" (rawptr, c.int) -> rawptr, /* Resize an allocation */
	xSize:     proc "c" (rawptr) -> c.int,         /* Return the size of an allocation */
	xRoundup:  proc "c" (c.int) -> c.int,          /* Round up request size to allocation size */
	xInit:     proc "c" (rawptr) -> Result,        /* Initialize the memory allocator */
	xShutdown: proc "c" (rawptr),                  /* Deinitialize the memory allocator */
	pAppData:  rawptr,                             /* Argument to xInit() and xShutdown() */
}

module :: struct {
	iVersion: c.int,
	
	xCreate:       proc "c" (db: ^sqlite3, pAux: rawptr, argc: c.int, argv: [^]cstring, ppVTab: ^^vtab, _: ^[^]byte) -> Result,
	xConnect:      proc "c" (db: ^sqlite3, pAux: rawptr, argc: c.int, argv: [^]cstring, ppVTab: ^^vtab, _: ^[^]byte) -> Result,
	xBestIndex:    proc "c" (pVTab: ^vtab, pII: ^index_info) -> Result,
	xDisconnect:   proc "c" (pVTab: ^vtab) -> b32,
	xDestroy:      proc "c" (pVTab: ^vtab) -> Result,
	xOpen:         proc "c" (pVTab: ^vtab, ppCursor: ^^vtab_cursor) -> Result,
	xClose:        proc "c" (^vtab_cursor) -> Result,
	xFilter:       proc "c" (pVTabCur: ^vtab_cursor, idxNum: c.int, idxStr: cstring, argc: c.int, argv: [^]^value) -> c.int,
	xNext:         proc "c" (^vtab_cursor) -> Result,
	xEof:          proc "c" (^vtab_cursor) -> Result,
	xColumn:       proc "c" (^vtab_cursor, ^sqlite3_context, c.int) -> Result,
	xRowid:        proc "c" (pVTabCur: ^vtab_cursor, pRowid: ^int64) -> Result,
	xUpdate:       proc "c" (^vtab, c.int, ^^value, ^int64) -> Result,
	xBegin:        proc "c" (pVTab: ^vtab) -> Result,
	xSync:         proc "c" (pVTab: ^vtab) -> Result,
	xCommit:       proc "c" (pVTab: ^vtab) -> Result,
	xRollback:     proc "c" (pVTab: ^vtab) -> Result,
	xFindFunction: proc "c" (pVtab: ^vtab, nArg: c.int, zName: cstring, pxFunc: ^(proc "c" (^sqlite3_context, c.int, ^^value)), ppArg: ^rawptr) -> Result,
	xRename:       proc "c" (pVtab: ^vtab, zNew: cstring) -> Result,
	/* The methods above are in version 1 of the sqlite_module object. Those
	** below are for version 2 and greater. */
	xSavepoint:    proc "c" (^vtab, c.int) -> Result,
	xRelease:      proc "c" (^vtab, c.int) -> Result,
	xRollbackTo:   proc "c" (^vtab, c.int) -> Result,
	/* The methods above are in versions 1 and 2 of the sqlite_module object.
	** Those below are for version 3 and greater. */
	xShadowName:   proc "c" (cstring) -> Result,
	/* The methods above are in versions 1 through 3 of the sqlite_module object.
	** Those below are for version 4 and greater. */
	xIntegrity:    proc "c" (pVTab: ^vtab, zSchema: cstring, zTabName: cstring, mFlags: c.int /*TODO*/, pzErr: ^[^]u8) -> Result,
}

mutex_methods :: struct {
	xMutexInit:    proc "c" () -> Result,
	xMutexEnd:     proc "c" () -> Result,
	xMutexAlloc:   proc "c" (c.int) -> ^mutex,
	xMutexFree:    proc "c" (^mutex),
	xMutexEnter:   proc "c" (^mutex),
	xMutexTry:     proc "c" (^mutex) -> Result,
	xMutexLeave:   proc "c" (^mutex),
	xMutexHeld:    proc "c" (^mutex) -> b32,
	xMutexNotheld: proc "c" (^mutex) -> b32,
}

pcache_methods2 :: struct {
	iVersion: c.int,
	pArg: rawptr,

	xInit:      proc "c" (rawptr) -> Result,
	xShutdown:  proc "c" (rawptr),
	xCreate:    proc "c" (szPage: c.int, szExtra: c.int, bPurgeable: b32) -> ^pcache,
	xCachesize: proc "c" (pPCache: ^pcache, nCachesize: c.int),
	xPagecount: proc "c" (^pcache) -> c.int,
	xFetch:     proc "c" (pPCache: ^pcache, key: c.uint, createFlag: c.int /*TODO*/) -> ^pcache_page,
	xUnpin:     proc "c" (pPCache: ^pcache, pPage: ^pcache_page, discard: c.int),
	xRekey:     proc "c" (pPCache: ^pcache, pPage: ^pcache_page, oldKey: c.uint, newKey: c.uint),
	xTruncate:  proc "c" (pPCache: ^pcache, iLimit: c.uint),
	xDestroy:   proc "c" (^pcache),
	xShrink:    proc "c" (^pcache),
}

@(deprecated="Obsolete, use pcache_methods2")
pcache_methods :: struct {
	pArg: rawptr,

	xInit:      proc "c" (rawptr) -> Result,
	xShutdown:  proc "c" (rawptr),
	xCreate:    proc "c" (szPage: c.int, bPurgeable: b32) -> ^pcache,
	xCachesize: proc "c" (pPCache: ^pcache, nCachesize: c.int),
	xPagecount: proc "c" (^pcache) -> c.int,
	xFetch:     proc "c" (pPCache: ^pcache, key: c.uint, createFlag: b32) -> rawptr,
	xUnpin:     proc "c" (pPCache: ^pcache, pPage: rawptr, discard: b32),
	xRekey:     proc "c" (pPCache: ^pcache, pPage: rawptr, oldKey: c.uint, newKey: c.uint),
	xTruncate:  proc "c" (pPCache: ^pcache, iLimit: c.uint),
	xDestroy:   proc "c" (^pcache),
}


Result :: enum c.int {
	OK         =  0,   /* Successful result */
	/* beginning-of-error-codes */
	ERROR      =  1,   /* Generic error */
	INTERNAL   =  2,   /* Internal logic error in SQLite */
	PERM       =  3,   /* Access permission denied */
	ABORT      =  4,   /* Callback routine requested an abort */
	BUSY       =  5,   /* The database file is locked */
	LOCKED     =  6,   /* A table in the database is locked */
	NOMEM      =  7,   /* A malloc() failed */
	READONLY   =  8,   /* Attempt to write a readonly database */
	INTERRUPT  =  9,   /* Operation terminated by sqlite3_interrupt()*/
	IOERR      = 10,   /* Some kind of disk I/O error occurred */
	CORRUPT    = 11,   /* The database disk image is malformed */
	NOTFOUND   = 12,   /* Unknown opcode in sqlite3_file_control() */
	FULL       = 13,   /* Insertion failed because database is full */
	CANTOPEN   = 14,   /* Unable to open the database file */
	PROTOCOL   = 15,   /* Database lock protocol error */
	EMPTY      = 16,   /* Internal use only */
	SCHEMA     = 17,   /* The database schema changed */
	TOOBIG     = 18,   /* String or BLOB exceeds size limit */
	CONSTRAINT = 19,   /* Abort due to constraint violation */
	MISMATCH   = 20,   /* Data type mismatch */
	MISUSE     = 21,   /* Library used incorrectly */
	NOLFS      = 22,   /* Uses OS features not supported on host */
	AUTH       = 23,   /* Authorization denied */
	FORMAT     = 24,   /* Not used */
	RANGE      = 25,   /* 2nd parameter to sqlite3_bind out of range */
	NOTADB     = 26,   /* File opened that is not a database file */
	NOTICE     = 27,   /* Notifications from sqlite3_log() */
	WARNING    = 28,   /* Warnings from sqlite3_log() */
	ROW        = 100,  /* sqlite3_step() has another row ready */
	DONE       = 101,  /* sqlite3_step() has finished executing */
	/* end-of-error-codes */

	/*  Extended Result Codes */

	ERROR_MISSING_COLLSEQ   = (ERROR | (1<<8)),
	ERROR_RETRY             = (ERROR | (2<<8)),
	ERROR_SNAPSHOT          = (ERROR | (3<<8)),
	ERROR_RESERVESIZE       = (ERROR | (4<<8)),
	ERROR_KEY               = (ERROR | (5<<8)),
	ERROR_UNABLE            = (ERROR | (6<<8)),
	
	IOERR_READ              = (IOERR | (1<<8)),
	IOERR_SHORT_READ        = (IOERR | (2<<8)),
	IOERR_WRITE             = (IOERR | (3<<8)),
	IOERR_FSYNC             = (IOERR | (4<<8)),
	IOERR_DIR_FSYNC         = (IOERR | (5<<8)),
	IOERR_TRUNCATE          = (IOERR | (6<<8)),
	IOERR_FSTAT             = (IOERR | (7<<8)),
	IOERR_UNLOCK            = (IOERR | (8<<8)),
	IOERR_RDLOCK            = (IOERR | (9<<8)),
	IOERR_DELETE            = (IOERR | (10<<8)),
	IOERR_BLOCKED           = (IOERR | (11<<8)),
	IOERR_NOMEM             = (IOERR | (12<<8)),
	IOERR_ACCESS            = (IOERR | (13<<8)),
	IOERR_CHECKRESERVEDLOCK = (IOERR | (14<<8)),
	IOERR_LOCK              = (IOERR | (15<<8)),
	IOERR_CLOSE             = (IOERR | (16<<8)),
	IOERR_DIR_CLOSE         = (IOERR | (17<<8)),
	IOERR_SHMOPEN           = (IOERR | (18<<8)),
	IOERR_SHMSIZE           = (IOERR | (19<<8)),
	IOERR_SHMLOCK           = (IOERR | (20<<8)),
	IOERR_SHMMAP            = (IOERR | (21<<8)),
	IOERR_SEEK              = (IOERR | (22<<8)),
	IOERR_DELETE_NOENT      = (IOERR | (23<<8)),
	IOERR_MMAP              = (IOERR | (24<<8)),
	IOERR_GETTEMPPATH       = (IOERR | (25<<8)),
	IOERR_CONVPATH          = (IOERR | (26<<8)),
	IOERR_VNODE             = (IOERR | (27<<8)),
	IOERR_AUTH              = (IOERR | (28<<8)),
	IOERR_BEGIN_ATOMIC      = (IOERR | (29<<8)),
	IOERR_COMMIT_ATOMIC     = (IOERR | (30<<8)),
	IOERR_ROLLBACK_ATOMIC   = (IOERR | (31<<8)),
	IOERR_DATA              = (IOERR | (32<<8)),
	IOERR_CORRUPTFS         = (IOERR | (33<<8)),
	IOERR_IN_PAGE           = (IOERR | (34<<8)),
	IOERR_BADKEY            = (IOERR | (35<<8)),
	IOERR_CODEC             = (IOERR | (36<<8)),
	
	LOCKED_SHAREDCACHE      = (LOCKED | (1<<8)),
	LOCKED_VTAB             = (LOCKED | (2<<8)),
	
	BUSY_RECOVERY           = (BUSY | (1<<8)),
	BUSY_SNAPSHOT           = (BUSY | (2<<8)),
	BUSY_TIMEOUT            = (BUSY | (3<<8)),
	
	CANTOPEN_NOTEMPDIR      = (CANTOPEN | (1<<8)),
	CANTOPEN_ISDIR          = (CANTOPEN | (2<<8)),
	CANTOPEN_FULLPATH       = (CANTOPEN | (3<<8)),
	CANTOPEN_CONVPATH       = (CANTOPEN | (4<<8)),
	CANTOPEN_DIRTYWAL       = (CANTOPEN | (5<<8)), /* Not Used */
	CANTOPEN_SYMLINK        = (CANTOPEN | (6<<8)),
	
	CORRUPT_VTAB            = (CORRUPT | (1<<8)),
	CORRUPT_SEQUENCE        = (CORRUPT | (2<<8)),
	CORRUPT_INDEX           = (CORRUPT | (3<<8)),
	
	READONLY_RECOVERY       = (READONLY | (1<<8)),
	READONLY_CANTLOCK       = (READONLY | (2<<8)),
	READONLY_ROLLBACK       = (READONLY | (3<<8)),
	READONLY_DBMOVED        = (READONLY | (4<<8)),
	READONLY_CANTINIT       = (READONLY | (5<<8)),
	READONLY_DIRECTORY      = (READONLY | (6<<8)),
	
	ABORT_ROLLBACK          = (ABORT | (2<<8)),
	
	CONSTRAINT_CHECK        = (CONSTRAINT | (1<<8)),
	CONSTRAINT_COMMITHOOK   = (CONSTRAINT | (2<<8)),
	CONSTRAINT_FOREIGNKEY   = (CONSTRAINT | (3<<8)),
	CONSTRAINT_FUNCTION     = (CONSTRAINT | (4<<8)),
	CONSTRAINT_NOTNULL      = (CONSTRAINT | (5<<8)),
	CONSTRAINT_PRIMARYKEY   = (CONSTRAINT | (6<<8)),
	CONSTRAINT_TRIGGER      = (CONSTRAINT | (7<<8)),
	CONSTRAINT_UNIQUE       = (CONSTRAINT | (8<<8)),
	CONSTRAINT_VTAB         = (CONSTRAINT | (9<<8)),
	CONSTRAINT_ROWID        = (CONSTRAINT |(10<<8)),
	CONSTRAINT_PINNED       = (CONSTRAINT |(11<<8)),
	CONSTRAINT_DATATYPE     = (CONSTRAINT |(12<<8)),
	
	NOTICE_RECOVER_WAL      = (NOTICE | (1<<8)),
	NOTICE_RECOVER_ROLLBACK = (NOTICE | (2<<8)),
	NOTICE_RBU              = (NOTICE | (3<<8)),
	
	WARNING_AUTOINDEX       = (WARNING | (1<<8)),
	
	AUTH_USER               = (AUTH | (1<<8)),
	
	OK_LOAD_PERMANENTLY     = (OK | (1<<8)),
	OK_SYMLINK              = (OK | (2<<8)), /* internal only */
}

Open_Flags :: bit_set[Open_Flag; c.int]
Open_Flag  :: enum c.int {
	READONLY      =  0,  /* Ok for sqlite3_open_v2() */
	READWRITE     =  1,  /* Ok for sqlite3_open_v2() */
	CREATE        =  2,  /* Ok for sqlite3_open_v2() */
	DELETEONCLOSE =  3,  /* VFS only */
	EXCLUSIVE     =  4,  /* VFS only */
	AUTOPROXY     =  5,  /* VFS only */
	URI           =  6,  /* Ok for sqlite3_open_v2() */
	MEMORY        =  7,  /* Ok for sqlite3_open_v2() */
	MAIN_DB       =  8,  /* VFS only */
	TEMP_DB       =  9,  /* VFS only */
	TRANSIENT_DB  = 10,  /* VFS only */
	MAIN_JOURNAL  = 11,  /* VFS only */
	TEMP_JOURNAL  = 12,  /* VFS only */
	SUBJOURNAL    = 13,  /* VFS only */
	SUPER_JOURNAL = 14,  /* VFS only */
	NOMUTEX       = 15,  /* Ok for sqlite3_open_v2() */
	FULLMUTEX     = 16,  /* Ok for sqlite3_open_v2() */
	SHAREDCACHE   = 17,  /* Ok for sqlite3_open_v2() */
	PRIVATECACHE  = 18,  /* Ok for sqlite3_open_v2() */
	NOFOLLOW      = 24,  /* Ok for sqlite3_open_v2() */
	WAL           = 19,  /* VFS only */
	EXRESCODE     = 25,  /* Extended result codes */

	/* Reserved:                         0x00F00000 */
	/* Legacy compatibility: */
	MASTER_JOURNAL = 14,  /* VFS only */
}

IOCAP_Flags :: bit_set[IOCAP_Flag; c.int]
IOCAP_Flag :: enum c.int {
	ATOMIC                =  0,
	ATOMIC512             =  1,
	ATOMIC1K              =  2,
	ATOMIC2K              =  3,
	ATOMIC4K              =  4,
	ATOMIC8K              =  5,
	ATOMIC16K             =  6,
	ATOMIC32K             =  7,
	ATOMIC64K             =  8,
	SAFE_APPEND           =  9,
	SEQUENTIAL            = 10,
	UNDELETABLE_WHEN_OPEN = 11,
	POWERSAFE_OVERWRITE   = 12,
	IMMUTABLE             = 13,
	BATCH_ATOMIC          = 14,
	SUBPAGE_READ          = 15,
}

Lock_Level :: enum c.int {
	NONE      = 0,       /* xUnlock() only */
	SHARED    = 1,       /* xLock() or xUnlock() */
	RESERVED  = 2,       /* xLock() only */
	PENDING   = 3,       /* xLock() only */
	EXCLUSIVE = 4,       /* xLock() only */
}

Sync_Flags :: bit_set[Sync_Flag; c.int]
Sync_Flag :: enum c.int {
	NORMAL   = 1,
	FULL     = 2,
	DATAONLY = 3,
}

FCNTL_Opcodes :: enum c.int {
	LOCKSTATE             =  1,
	GET_LOCKPROXYFILE     =  2,
	SET_LOCKPROXYFILE     =  3,
	LAST_ERRNO            =  4,
	SIZE_HINT             =  5,
	CHUNK_SIZE            =  6,
	FILE_POINTER          =  7,
	SYNC_OMITTED          =  8,
	WIN32_AV_RETRY        =  9,
	PERSIST_WAL           = 10,
	OVERWRITE             = 11,
	VFSNAME               = 12,
	POWERSAFE_OVERWRITE   = 13,
	PRAGMA                = 14,
	BUSYHANDLER           = 15,
	TEMPFILENAME          = 16,
	MMAP_SIZE             = 18,
	TRACE                 = 19,
	HAS_MOVED             = 20,
	SYNC                  = 21,
	COMMIT_PHASETWO       = 22,
	WIN32_SET_HANDLE      = 23,
	WAL_BLOCK             = 24,
	ZIPVFS                = 25,
	RBU                   = 26,
	VFS_POINTER           = 27,
	JOURNAL_POINTER       = 28,
	WIN32_GET_HANDLE      = 29,
	PDB                   = 30,
	BEGIN_ATOMIC_WRITE    = 31,
	COMMIT_ATOMIC_WRITE   = 32,
	ROLLBACK_ATOMIC_WRITE = 33,
	LOCK_TIMEOUT          = 34,
	DATA_VERSION          = 35,
	SIZE_LIMIT            = 36,
	CKPT_DONE             = 37,
	RESERVE_BYTES         = 38,
	CKPT_START            = 39,
	EXTERNAL_READER       = 40,
	CKSM_FILE             = 41,
	RESET_CACHE           = 42,
	NULL_IO               = 43,
	BLOCK_ON_CONNECT      = 44,
	FILESTAT              = 45,
}


Access_Flags :: bit_set[Access_Flag; c.int]
Access_Flag :: enum c.int {
	EXISTS    = 0,
	READWRITE = 1,   /* Used by PRAGMA temp_store_directory */
	READ      = 2,   /* Unused */
}


SHM_Lock_Flags :: bit_set[SHM_Lock_Flag; c.int]
SHM_Lock_Flag :: enum c.int {
	UNLOCK    = 0,
	LOCK      = 1,
	SHARED    = 2,
	EXCLUSIVE = 3,
}


SETLK_Flags :: bit_set[SETLK_Flag; c.int]
SETLK_Flag :: enum c.int {
	BLOCK_ON_CONNECT = 0,
}

Config :: enum c.int {
	SINGLETHREAD        =  1,  /* nil */
	MULTITHREAD         =  2,  /* nil */
	SERIALIZED          =  3,  /* nil */
	MALLOC              =  4,  /* sqlite3_mem_methods* */
	GETMALLOC           =  5,  /* sqlite3_mem_methods* */
	SCRATCH             =  6,  /* No longer used */
	PAGECACHE           =  7,  /* void*, int sz, int N */
	HEAP                =  8,  /* void*, int nByte, int min */
	MEMSTATUS           =  9,  /* boolean */
	MUTEX               = 10,  /* sqlite3_mutex_methods* */
	GETMUTEX            = 11,  /* sqlite3_mutex_methods* */
	/* previously SQLITE_CONFIG_CHUNKALLOC    12 which is now unused. */
	LOOKASIDE           = 13,  /* int int */
	PCACHE              = 14,  /* no-op */
	GETPCACHE           = 15,  /* no-op */
	LOG                 = 16,  /* xFunc, void* */
	URI                 = 17,  /* int */
	PCACHE2             = 18,  /* sqlite3_pcache_methods2* */
	GETPCACHE2          = 19,  /* sqlite3_pcache_methods2* */
	COVERING_INDEX_SCAN = 20,  /* int */
	SQLLOG              = 21,  /* xSqllog, void* */
	MMAP_SIZE           = 22,  /* int64, int64 */
	WIN32_HEAPSIZE      = 23,  /* int nByte */
	PCACHE_HDRSZ        = 24,  /* int *psz */
	PMASZ               = 25,  /* unsigned int szPma */
	STMTJRNL_SPILL      = 26,  /* int nByte */
	SMALL_MALLOC        = 27,  /* boolean */
	SORTERREF_SIZE      = 28,  /* int nByte */
	MEMDB_MAXSIZE       = 29,  /* int64 */
	ROWID_IN_VIEW       = 30,  /* int* */
}

DB_Config :: enum c.int {
	MAINDBNAME            = 1000, /* const char* */
	LOOKASIDE             = 1001, /* void* int int */
	ENABLE_FKEY           = 1002, /* int int* */
	ENABLE_TRIGGER        = 1003, /* int int* */
	ENABLE_FTS3_TOKENIZER = 1004, /* int int* */
	ENABLE_LOAD_EXTENSION = 1005, /* int int* */
	NO_CKPT_ON_CLOSE      = 1006, /* int int* */
	ENABLE_QPSG           = 1007, /* int int* */
	TRIGGER_EQP           = 1008, /* int int* */
	RESET_DATABASE        = 1009, /* int int* */
	DEFENSIVE             = 1010, /* int int* */
	WRITABLE_SCHEMA       = 1011, /* int int* */
	LEGACY_ALTER_TABLE    = 1012, /* int int* */
	DQS_DML               = 1013, /* int int* */
	DQS_DDL               = 1014, /* int int* */
	ENABLE_VIEW           = 1015, /* int int* */
	LEGACY_FILE_FORMAT    = 1016, /* int int* */
	TRUSTED_SCHEMA        = 1017, /* int int* */
	STMT_SCANSTATUS       = 1018, /* int int* */
	REVERSE_SCANORDER     = 1019, /* int int* */
	ENABLE_ATTACH_CREATE  = 1020, /* int int* */
	ENABLE_ATTACH_WRITE   = 1021, /* int int* */
	ENABLE_COMMENTS       = 1022, /* int int* */
	FP_DIGITS             = 1023, /* int int* */
	MAX                   = 1023, /* Largest DBCONFIG */
}

Auth_Res :: enum c.int {
	OK     = 0,
	DENY   = 1, /* Abort the SQL statement with an error */
	IGNORE = 2, /* Don't allow access, but don't generate an error */
}

Action_Code :: enum c.int {
	CREATE_INDEX        =  1,   /* Index Name      Table Name      */
	CREATE_TABLE        =  2,   /* Table Name      NULL            */
	CREATE_TEMP_INDEX   =  3,   /* Index Name      Table Name      */
	CREATE_TEMP_TABLE   =  4,   /* Table Name      NULL            */
	CREATE_TEMP_TRIGGER =  5,   /* Trigger Name    Table Name      */
	CREATE_TEMP_VIEW    =  6,   /* View Name       NULL            */
	CREATE_TRIGGER      =  7,   /* Trigger Name    Table Name      */
	CREATE_VIEW         =  8,   /* View Name       NULL            */
	DELETE              =  9,   /* Table Name      NULL            */
	DROP_INDEX          = 10,   /* Index Name      Table Name      */
	DROP_TABLE          = 11,   /* Table Name      NULL            */
	DROP_TEMP_INDEX     = 12,   /* Index Name      Table Name      */
	DROP_TEMP_TABLE     = 13,   /* Table Name      NULL            */
	DROP_TEMP_TRIGGER   = 14,   /* Trigger Name    Table Name      */
	DROP_TEMP_VIEW      = 15,   /* View Name       NULL            */
	DROP_TRIGGER        = 16,   /* Trigger Name    Table Name      */
	DROP_VIEW           = 17,   /* View Name       NULL            */
	INSERT              = 18,   /* Table Name      NULL            */
	PRAGMA              = 19,   /* Pragma Name     1st arg or NULL */
	READ                = 20,   /* Table Name      Column Name     */
	SELECT              = 21,   /* NULL            NULL            */
	TRANSACTION         = 22,   /* Operation       NULL            */
	UPDATE              = 23,   /* Table Name      Column Name     */
	ATTACH              = 24,   /* Filename        NULL            */
	DETACH              = 25,   /* Database Name   NULL            */
	ALTER_TABLE         = 26,   /* Database Name   Table Name      */
	REINDEX             = 27,   /* Index Name      NULL            */
	ANALYZE             = 28,   /* Table Name      NULL            */
	CREATE_VTABLE       = 29,   /* Table Name      Module Name     */
	DROP_VTABLE         = 30,   /* Table Name      Module Name     */
	FUNCTION            = 31,   /* NULL            Function Name   */
	SAVEPOINT           = 32,   /* Operation       Savepoint Name  */
	COPY                =  0,   /* No longer used */
	RECURSIVE           = 33,   /* NULL            NULL            */
}

Trace_Codes :: bit_set[Trace_Code; c.uint]
Trace_Code :: enum c.uint {
	STMT    = 0,
	PROFILE = 1,
	ROW     = 2,
	CLOSE   = 3,
}

Limit_Category :: enum c.int {
	LENGTH              =  0,
	SQL_LENGTH          =  1,
	COLUMN              =  2,
	EXPR_DEPTH          =  3,
	COMPOUND_SELECT     =  4,
	VDBE_OP             =  5,
	FUNCTION_ARG        =  6,
	ATTACHED            =  7,
	LIKE_PATTERN_LENGTH =  8,
	VARIABLE_NUMBER     =  9,
	TRIGGER_DEPTH       = 10,
	WORKER_THREADS      = 11,
	PARSER_DEPTH        = 12,
}

Prepare_Flags :: bit_set[Prepare_Flag; c.uint]
Prepare_Flag :: enum c.uint {
	PERSISTENT = 0,
	NORMALIZE  = 1,
	NO_VTAB    = 2,
	DONT_LOG   = 4,
	FROM_DDL   = 5,
}

Datatype :: enum c.int {
	INTEGER = 1,
	FLOAT   = 2,
	BLOB    = 4,
	NULL    = 5,
	TEXT    = 3,
}

Text_Encoding :: enum c.int {
	UTF8          =  1, /* IMP: R-37514-35566 */
	UTF16LE       =  2, /* IMP: R-03371-37637 */
	UTF16BE       =  3, /* IMP: R-51971-34154 */
	UTF16         =  4, /* Use native byte order */
	ANY           =  5, /* Deprecated */
	UTF16_ALIGNED =  8, /* sqlite3_create_collation only */
	UTF8_ZT       = 16, /* Zero-terminated UTF8 */
}
Text_Encoding_U8 :: enum u8 {
	UTF8          = u8(Text_Encoding.UTF8),          /* IMP: R-37514-35566 */
	UTF16LE       = u8(Text_Encoding.UTF16LE),       /* IMP: R-03371-37637 */
	UTF16BE       = u8(Text_Encoding.UTF16BE),       /* IMP: R-51971-34154 */
	UTF16         = u8(Text_Encoding.UTF16),         /* Use native byte order */
	ANY           = u8(Text_Encoding.ANY),           /* Deprecated */
	UTF16_ALIGNED = u8(Text_Encoding.UTF16_ALIGNED), /* sqlite3_create_collation only */
	UTF8_ZT       = u8(Text_Encoding.UTF8_ZT),       /* Zero-terminated UTF8 */
}
#assert(len(Text_Encoding) == len(Text_Encoding_U8))

Function_Flags :: bit_set[Function_Flag; c.int]
Function_Flag :: enum c.int {
	DETERMINISTIC  = 11,
	DIRECTONLY     = 19,
	SUBTYPE        = 20,
	INNOCUOUS      = 21,
	RESULT_SUBTYPE = 24,
	SELFORDER1     = 25,
}

WIN32_Dir_Type :: enum c.ulong {
	DATA = 1,
	TEMP = 2,
}

TXN_State :: enum c.int {
	INVALID = -1,
	NONE    = 0,
	READ    = 1,
	WRITE   = 2,
}

VT_Scan_Flags :: bit_set[VT_Scan_Flag; c.int]
VT_Scan_Flag :: enum c.int {
	UNIQUE = 0, /* Scan visits at most 1 row */
	HEX    = 1, /* Display idxNum as hex in EXPLAIN QUERY PLAN */
}

VT_Constraint_Op :: enum u8 {
	EQ        =   2,
	GT        =   4,
	LE        =   8,
	LT        =  16,
	GE        =  32,
	MATCH     =  64,
	LIKE      =  65,
	GLOB      =  66,
	REGEXP    =  67,
	NE        =  68,
	ISNOT     =  69,
	ISNOTNULL =  70,
	ISNULL    =  71,
	IS        =  72,
	LIMIT     =  73,
	OFFSET    =  74,
	FUNCTION  = 150,
}

Mutex_Type :: enum c.int {
	FAST          =  0,
	RECURSIVE     =  1,
	STATIC_MAIN   =  2,
	STATIC_MEM    =  3,  /* sqlite3_malloc() */
	STATIC_MEM2   =  4,  /* NOT USED */
	STATIC_OPEN   =  4,  /* sqlite3BtreeOpen() */
	STATIC_PRNG   =  5,  /* sqlite3_randomness() */
	STATIC_LRU    =  6,  /* lru page list */
	STATIC_LRU2   =  7,  /* NOT USED */
	STATIC_PMEM   =  7,  /* sqlite3PageMalloc() */
	STATIC_APP1   =  8,  /* For use by application */
	STATIC_APP2   =  9,  /* For use by application */
	STATIC_APP3   = 10,  /* For use by application */
	STATIC_VFS1   = 11,  /* For use by built-in VFS */
	STATIC_VFS2   = 12,  /* For use by extension VFS */
	STATIC_VFS3   = 13,  /* For use by application VFS */

	/* Legacy compatibility: */
	STATIC_MASTER =  2,
} 

Test_Ctrl_Op :: enum c.int {
	FIRST                =  5,
	PRNG_SAVE            =  5,
	PRNG_RESTORE         =  6,
	PRNG_RESET           =  7,  /* NOT USED */
	FK_NO_ACTION         =  7,
	BITVEC_TEST          =  8,
	FAULT_INSTALL        =  9,
	BENIGN_MALLOC_HOOKS  = 10,
	PENDING_BYTE         = 11,
	ASSERT               = 12,
	ALWAYS               = 13,
	RESERVE              = 14,  /* NOT USED */
	JSON_SELFCHECK       = 14,
	OPTIMIZATIONS        = 15,
	ISKEYWORD            = 16,  /* NOT USED */
	GETOPT               = 16,
	SCRATCHMALLOC        = 17,  /* NOT USED */
	INTERNAL_FUNCTIONS   = 17,
	LOCALTIME_FAULT      = 18,
	EXPLAIN_STMT         = 19,  /* NOT USED */
	ONCE_RESET_THRESHOLD = 19,
	NEVER_CORRUPT        = 20,
	VDBE_COVERAGE        = 21,
	BYTEORDER            = 22,
	ISINIT               = 23,
	SORTER_MMAP          = 24,
	IMPOSTER             = 25,
	PARSER_COVERAGE      = 26,
	RESULT_INTREAL       = 27,
	PRNG_SEED            = 28,
	EXTRA_SCHEMA_CHECKS  = 29,
	SEEK_COUNT           = 30,
	TRACEFLAGS           = 31,
	TUNE                 = 32,
	LOGEST               = 33,
	USELONGDOUBLE        = 34,  /* NOT USED */
	ATOF                 = 34,
	LAST                 = 34,  /* Largest TESTCTRL */
}

Status :: enum c.int {
	MEMORY_USED        = 0,
	PAGECACHE_USED     = 1,
	PAGECACHE_OVERFLOW = 2,
	SCRATCH_USED       = 3,  /* NOT USED */
	SCRATCH_OVERFLOW   = 4,  /* NOT USED */
	MALLOC_SIZE        = 5,
	PARSER_STACK       = 6,
	PAGECACHE_SIZE     = 7,
	SCRATCH_SIZE       = 8,  /* NOT USED */
	MALLOC_COUNT       = 9,
}

DB_Status :: enum c.int {
	LOOKASIDE_USED      =  0,
	CACHE_USED          =  1,
	SCHEMA_USED         =  2,
	STMT_USED           =  3,
	LOOKASIDE_HIT       =  4,
	LOOKASIDE_MISS_SIZE =  5,
	LOOKASIDE_MISS_FULL =  6,
	CACHE_HIT           =  7,
	CACHE_MISS          =  8,
	CACHE_WRITE         =  9,
	DEFERRED_FKS        = 10,
	CACHE_USED_SHARED   = 11,
	CACHE_SPILL         = 12,
	TEMPBUF_SPILL       = 13,
	MAX                 = 13,   /* Largest defined DBSTATUS */
}

STMT_Status :: enum c.int {
	FULLSCAN_STEP =  1,
	SORT          =  2,
	AUTOINDEX     =  3,
	VM_STEP       =  4,
	REPREPARE     =  5,
	RUN           =  6,
	FILTER_MISS   =  7,
	FILTER_HIT    =  8,
	MEMUSED       = 99,
}

Checkpoint_Mode :: enum c.int {
	NOOP     =-1,  /* Do no work at all */
	PASSIVE  = 0,  /* Do as much as possible w/o blocking */
	FULL     = 1,  /* Wait for writers, then checkpoint */
	RESTART  = 2,  /* Like FULL but wait for readers */
	TRUNCATE = 3,  /* Like RESTART but also truncate WAL */
}

VTab_Config :: enum c.int {
	CONSTRAINT_SUPPORT = 1,
	INNOCUOUS          = 2,
	DIRECTONLY         = 3,
	USES_ALL_SCHEMAS   = 4,
}

Conflict_Resolution :: enum c.int {
	ROLLBACK = 1,
	/* IGNORE = 2, // Also used by sqlite3_authorizer() callback */
	FAIL     = 3,
	/* ABORT = 4,  // Also an error code */
	REPLACE  = 5,
}

Scan_Stat_Op :: enum c.int {
	NLOOP    = 0,
	NVISIT   = 1,
	EST      = 2,
	NAME     = 3,
	EXPLAIN  = 4,
	SELECTID = 5,
	PARENTID = 6,
	NCYCLE   = 7,
}

Scan_Stat_Flags :: bit_set[Scan_Stat_Flag; c.int]
Scan_Stat_Flag :: enum c.int {
	COMPLEX = 0,
}

Serialize_Flags :: bit_set[Serialize_Flag; c.uint]
Serialize_Flag :: enum c.uint {
	NOCOPY = 0, /* Do no memory allocations */
}

Deserialize_Flags :: bit_set[Deserialize_Flag; c.uint]
Deserialize_Flag :: enum c.uint {
	FREEONCLOSE = 0, /* Call sqlite3_free() on close */
	RESIZEABLE  = 1, /* Resize using sqlite3_realloc64() */
	READONLY    = 2, /* Database is read-only */
}

Carray_Flag :: enum c.int {
	INT32  = 0, /* Data is 32-bit signed integers */
	INT64  = 1, /* Data is 64-bit signed integers */
	DOUBLE = 2, /* Data is doubles */
	TEXT   = 3, /* Data is char* */
	BLOB   = 4, /* Data is struct iovec */
}

Match_Res :: enum c.int {
	MATCH           = 0,
	NOMATCH         = 1,
	NOWILDCARDMATCH = 2,
}




/******** Begin file sqlite3rtree.h *********/
SQLITE_RTREE_INT_ONLY :: false

rtree_dbl :: int64 when SQLITE_RTREE_INT_ONLY else f64

rtree_geometry :: struct {
	pContext: rawptr,            /* Copy of pContext passed to s_r_g_c() */
	nParam:   c.int,             /* Size of array aParam[] */
	aParam:   ^rtree_dbl,        /* Parameters passed to SQL geom function */
	pUser:    rawptr,            /* Callback implementation user data */
	xDelUser: proc "c" (rawptr), /* Called by SQLite to clean up pUser */
}

rtree_query_info :: struct {
	pContext:      rawptr,            /* pContext from when function registered */
	nParam:        c.int,             /* Number of function parameters */
	aParam:        ^rtree_dbl,        /* value of function parameters */
	pUser:         rawptr,            /* callback can use this, if desired */
	xDelUser:      proc "c" (rawptr), /* function to free pUser */
	aCoord:        ^rtree_dbl,        /* Coordinates of node or entry to check */
	anQueue:       ^c.uint,           /* Number of pending entries in the queue */
	nCoord:        c.int,             /* Number of coordinates */
	iLevel:        c.int,             /* Level of current node or entry */
	mxLevel:       c.int,             /* The largest iLevel value in the tree */
	iRowid:        int64,             /* Rowid for current entry */
	rParentScore:  rtree_dbl,         /* Score of parent node */
	eParentWithin: RTree_Visibility,  /* Visibility of parent node */
	eWithin:       RTree_Visibility,  /* OUT: Visibility */
	rScore:        rtree_dbl,         /* OUT: Write the score here */
	/* The following fields are only available in 3.8.11 and later */
	apSqlParam:    ^^value,           /* Original SQL values of parameters */
}

RTree_Visibility :: enum c.int {
	NOT_WITHIN    = 0,   /* Object completely outside of query region */
	PARTLY_WITHIN = 1,   /* Object partially overlaps query region */
	FULLY_WITHIN  = 2,   /* Object fully contained within query region */
}


@(default_calling_convention="c", link_prefix="sqlite3_")
foreign lib {
	rtree_geometry_callback :: proc(
		db:       ^sqlite3,
		zGeom:    cstring,
		xGeom:    proc"c" (^rtree_geometry, c.int, ^rtree_dbl, ^int) -> Result,
		pContext: rawptr,
	) -> Result ---

	rtree_query_callback :: proc(
		db:          ^sqlite3,
		zQueryFunc:  cstring,
		xQueryFunc:  proc"c" (^rtree_query_info) -> Result,
		pContext:    rawptr,
		xDestructor: proc "c" (rawptr),
	) -> Result ---
}

/******** End of sqlite3rtree.h *********/


/******** Begin file sqlite3session.h *********/


SQLITE_ENABLE_SESSION :: true

session        :: struct {}
changeset_iter :: struct {}
changegroup    :: struct {}
rebaser        :: struct {}

Session_OBJ_Config :: enum c.int {
	SIZE  = 1,
	ROWID = 2,
}

Changeset_Start_Flags :: bit_set[Changeset_Start_Flag; c.int] 
Changeset_Start_Flag :: enum c.int {
	INVERT = 1,
}

Changeset_Apply_Flags :: bit_set[Changeset_Apply_Flag; c.int]
Changeset_Apply_Flag :: enum c.int {
	NOSAVEPOINT  = 0,
	INVERT       = 1,
	IGNORENOOP   = 2,
	FKNOACTION   = 3,
	NOUPDATELOOP = 4,
}

Changeset_Conflict_Flag :: enum c.int {
	DATA        = 1,
	NOTFOUND    = 2,
	CONFLICT    = 3,
	CONSTRAINT  = 4,
	FOREIGN_KEY = 5,
}

Changeset_Conflict_Res :: enum c.int {
	OMIT    = 0,
	REPLACE = 1,
	ABORT   = 2,
}

Session_Config_Op :: enum c.int {
	STRMSIZE = 1,
}

Changegroup_Config_Op :: enum c.int {
	PATCHSET = 1,
}


when SQLITE_ENABLE_SESSION {
	@(default_calling_convention="c", link_prefix="sqlite3_")
	foreign lib {
		session_create :: proc(
			db:        ^sqlite3,  /* Database handle */
			zDb:       cstring,   /* Name of db (e.g. "main") */
			ppSession: ^^session, /* OUT: New session object */
		) -> Result ---

		session_delete        :: proc(pSession: ^session) ---
		session_object_config :: proc(pSession: ^session, op: Session_OBJ_Config, pArg: rawptr) -> Result ---
		session_enable        :: proc(pSession: ^session, bEnable: c.int) -> b32 ---
		session_indirect      :: proc(pSession: ^session, bIndirect: c.int) -> b32 ---

		session_attach :: proc(
			pSession: ^session, /* Session object */
			zTab:     cstring,  /* Table name */
		) -> Result ---

		session_table_filter :: proc(
			pSession: ^session, /* Session object */
			xFilter:  proc "c" (
				pCtx: rawptr,  /* Copy of third arg to _filter_table() */
				zTab: cstring, /* Table name */
			) -> b32,
			pCtx:     rawptr,  /* First argument passed to xFilter */
		) ---

		session_changeset :: proc(
			pSession:    ^session, /* Session object */
			pnChangeset: ^int,     /* OUT: Size of buffer at *ppChangeset */
			ppChangeset: ^[^]byte, /* OUT: Buffer containing changeset */
		) -> Result ---

		session_changeset_size :: proc(pSession: ^session) -> int64 ---

		session_diff :: proc(
			pSession: ^session,
			zFromDb:  cstring,
			Tbl:      cstring,
			pzErrMsg: ^[^]byte,
		) -> Result ---

		session_patchset :: proc(
			pSession:   ^session, /* Session object */
			pnPatchset: ^c.int,   /* OUT: Size of buffer at *ppPatchset */
			ppPatchset: ^[^]byte, /* OUT: Buffer containing patchset */
		) -> Result ---

		session_isempty     :: proc(pSession: ^session) -> b32 ---
		session_memory_used :: proc(pSession: ^session) -> int64 ---

		changeset_start :: proc(
			pp:         ^^changeset_iter, /* OUT: New changeset iterator handle */
			nChangeset: c.int,            /* Size of changeset blob in bytes */
			pChangeset: rawptr,           /* Pointer to blob containing changeset */
		) -> Result ---
		changeset_start_v2 :: proc(
			pp:         ^^changeset_iter,      /* OUT: New changeset iterator handle */
			nChangeset: c.int,                 /* Size of changeset blob in bytes */
			pChangeset: rawptr,                /* Pointer to blob containing changeset */
			flags:      Changeset_Start_Flags, /* SESSION_CHANGESETSTART_* flags */
		) -> Result ---


		changeset_next :: proc(pIter: ^changeset_iter) -> Result ---

		changeset_op :: proc(
			pIter:      ^changeset_iter, /* Iterator object */
			pzTab:      ^cstring,        /* OUT: Pointer to table name */
			pnCol:      ^c.int,          /* OUT: Number of columns in table */
			pOp:        ^Action_Code,    /* OUT: SQLITE_INSERT, DELETE or UPDATE */
			pbIndirect: ^b32,            /* OUT: True for an 'indirect' change */
		) -> Result ---

		changeset_pk :: proc(
			pIter: ^changeset_iter, /* Iterator object */
			pabPK: ^[^]b8,          /* OUT: Array of boolean - true for PK cols */
			pnCol: ^c.int,          /* OUT: Number of entries in output array */
		) -> Result ---

		changeset_old :: proc(
			pIter:   ^changeset_iter, /* Changeset iterator */
			iVal:    c.int,           /* Column number */
			ppValue: ^value,          /* OUT: Old value (or NULL pointer) */
		) -> Result ---

		changeset_new :: proc(
			pIter:   ^changeset_iter, /* Changeset iterator */
			iVal:    c.int,           /* Column number */
			ppValue: ^^value,         /* OUT: New value (or NULL pointer) */
		) -> Result ---

		changeset_conflict :: proc(
			pIter:   ^changeset_iter, /* Changeset iterator */
			iVal:    c.int,           /* Column number */
			ppValue: ^^value,         /* OUT: Value from conflicting row */
		) -> Result ---

		changeset_fk_conflicts :: proc(
			pIter: ^changeset_iter, /* Changeset iterator */
			pnOut: ^c.int,          /* OUT: Number of FK violations */
		) -> Result ---

		changeset_finalize :: proc(pIter: ^changeset_iter) -> Result ---

		changeset_invert :: proc(
			nIn:   c.int,  pIn:   rawptr,  /* Input changeset */
			pnOut: ^c.int, ppOut: ^rawptr, /* OUT: Inverse of input */
		) -> Result ---

		changeset_concat :: proc(
			nA:    c.int,   /* Number of bytes in buffer pA */
			pA:    rawptr,  /* Pointer to buffer containing changeset A */
			nB:    c.int,   /* Number of bytes in buffer pB */
			pB:    rawptr,  /* Pointer to buffer containing changeset B */
			pnOut: ^c.int,  /* OUT: Number of bytes in output changeset */
			ppOut: ^rawptr, /* OUT: Buffer containing output changeset */
		) -> Result ---

		changegroup_new        :: proc(pp: ^^changegroup) -> Result ---
		changegroup_schema     :: proc(p: ^changegroup, db: ^sqlite3, zDb: cstring) -> Result ---
		changegroup_add        :: proc(p: ^changegroup, nData: c.int, pData: rawptr) -> Result ---
		changegroup_add_change :: proc(p: ^changegroup, pI: ^changeset_iter) -> Result ---

		changegroup_output :: proc(
			p:      ^changegroup,
			pnData: ^c.int,  /* OUT: Size of output buffer in bytes */
			ppData: ^rawptr, /* OUT: Pointer to output buffer */
		) -> Result ---

		changegroup_delete :: proc(p: ^changegroup) ---

		changeset_apply :: proc(
			db: ^sqlite3,         /* Apply change to "main" db of this handle */
			nChangeset: c.int,    /* Size of changeset in bytes */
			pChangeset: rawptr,   /* Changeset blob */
			xFilter: proc "c" (
				pCtx: rawptr,     /* Copy of sixth arg to _apply() */
				zTab: cstring,    /* Table name */
			) -> b32,
			xConflict: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				eConflict: Changeset_Conflict_Flag, /* DATA, MISSING, CONFLICT, CONSTRAINT */
				p: ^changeset_iter, /* Handle describing change and conflict */
			) -> Changeset_Conflict_Res,
			pCtx: rawptr,           /* First argument passed to xConflict */
		) -> Result ---

		changeset_apply_v2 :: proc(
			db: ^sqlite3,           /* Apply change to "main" db of this handle */
			nChangeset: c.int,      /* Size of changeset in bytes */
			pChangeset: rawptr,     /* Changeset blob */
			xFilter: proc "c" (
				pCtx: rawptr,       /* Copy of sixth arg to _apply() */
				zTab: cstring,      /* Table name */
			) -> b32,
			xConflict: proc "c" (
				pCtx: rawptr,       /* Copy of sixth arg to _apply() */
				eConflict: Changeset_Conflict_Flag, /* DATA, MISSING, CONFLICT, CONSTRAINT */
				p: ^changeset_iter,  /* Handle describing change and conflict */
			) -> Changeset_Conflict_Res,
			pCtx: rawptr,           /* First argument passed to xConflict */
			ppRebase: ^rawptr,      /* OUT: Rebase data */
			pnRebase: ^c.int,       /* OUT: Rebase data */
			flags: Changeset_Apply_Flags, /* SESSION_CHANGESETAPPLY_* flags */
		) -> Result ---

		changeset_apply_v3 :: proc(
			db: ^sqlite3,          /* Apply change to "main" db of this handle */
			nChangeset: c.int,     /* Size of changeset in bytes */
			pChangeset: rawptr,    /* Changeset blob */
			xFilter: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				p: ^changeset_iter, /* Handle describing change */
			) -> b32,
			xConflict: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				eConflict: Changeset_Conflict_Flag, /* DATA, MISSING, CONFLICT, CONSTRAINT */
				p: ^changeset_iter, /* Handle describing change and conflict */
			) -> Changeset_Conflict_Res,
			pCtx: rawptr,          /* First argument passed to xConflict */
			ppRebase: ^rawptr,     /* OUT: Rebase data */
			pnRebase: ^c.int,      /* OUT: Rebase data */
			flags: Changeset_Apply_Flags, /* SESSION_CHANGESETAPPLY_* flags */
		) -> Result ---

		rebaser_create    :: proc(ppNew: ^^rebaser) -> Result ---
		rebaser_configure :: proc(p: ^rebaser, nRebase: c.int, pRebase: rawptr) -> Result ---
		rebaser_rebase    :: proc(p: ^rebaser, nIn: c.int, pIn: rawptr, pnOut: ^c.int, ppOut: ^rawptr) -> Result ---
		rebaser_delete    :: proc(p: ^rebaser) ---

		changeset_apply_strm :: proc(
			db: ^sqlite3,          /* Apply change to "main" db of this handle */
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result, /* Input function */
			pIn: rawptr,           /* First arg for xInput */
			xFilter: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				zTab: cstring,      /* Table name */
			) -> b32,
			xConflict: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				eConflict: Changeset_Conflict_Flag, /* DATA, MISSING, CONFLICT, CONSTRAINT */
				p: ^changeset_iter, /* Handle describing change and conflict */
			) -> Changeset_Conflict_Res,
			pCtx: rawptr,           /* First argument passed to xConflict */
		) -> Result ---

		changeset_apply_v2_strm :: proc(
			db: ^sqlite3,          /* Apply change to "main" db of this handle */
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result, /* Input function */
			pIn: rawptr,           /* First arg for xInput */
			xFilter: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				zTab: cstring,      /* Table name */
			) -> b32,
			xConflict: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				eConflict: Changeset_Conflict_Flag,                /* DATA, MISSING, CONFLICT, CONSTRAINT */
				p: ^changeset_iter, /* Handle describing change and conflict */
			) -> Changeset_Conflict_Res,
			pCtx: rawptr,          /* First argument passed to xConflict */
			ppRebase: ^rawptr, 
			pnRebase: ^c.int,
			flags: Changeset_Apply_Flags,
		) -> Result ---

		changeset_apply_v3_strm :: proc(
			db: ^sqlite3,          /* Apply change to "main" db of this handle */
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result, /* Input function */
			pIn: rawptr,           /* First arg for xInput */
			xFilter: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				p: ^changeset_iter,
			) -> b32,
			xConflict: proc "c" (
				pCtx: rawptr,      /* Copy of sixth arg to _apply() */
				eConflict: Changeset_Conflict_Flag,                /* DATA, MISSING, CONFLICT, CONSTRAINT */
				p: ^changeset_iter, /* Handle describing change and conflict */
			) -> Changeset_Conflict_Res,
			pCtx: rawptr,          /* First argument passed to xConflict */
			ppRebase: ^rawptr, 
			pnRebase: ^c.int,
			flags: Changeset_Apply_Flags,
		) -> Result ---

		changeset_concat_strm :: proc(
			xInputA: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result,
			pInA: rawptr,
			xInputB: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result,
			pInB: rawptr,
			xOutput: proc "c" (pOut: rawptr, pData: rawptr, nData: c.int) -> Result,
			pOut: rawptr,
		) -> Result ---

		changeset_invert_strm :: proc(
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result,
			pIn: rawptr,
			xOutput: proc "c" (pOut: rawptr, pData: rawptr, nData: c.int) -> Result,
			pOut: rawptr,
		) -> Result ---
		changeset_start_strm :: proc(
			pp: ^^changeset_iter,
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result,
			pIn: rawptr,
		) -> Result ---
		changeset_start_v2_strm :: proc(
			pp: ^^changeset_iter,
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result,
			pIn: rawptr,
			flags: Changeset_Apply_Flags,
		) -> Result ---
		session_changeset_strm :: proc(
			pSession: ^session,
			xOutput: proc "c" (pOut: rawptr, pData: rawptr, nData: c.int) -> Result,
			pOut: rawptr,
		) -> Result ---
		session_patchset_strm :: proc(
			pSession: ^session,
			xOutput: proc "c" (pOut: rawptr, pData: rawptr, nData: c.int) -> Result,
			pOut: rawptr,
		) -> Result ---
		changegroup_add_strm :: proc(
			p: ^changegroup,
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result,
			pIn: rawptr,
		) -> Result ---
		changegroup_output_strm :: proc(
			p: ^changegroup,
			xOutput: proc "c" (pOut: rawptr, pData: rawptr, nData: c.int) -> Result,
			pOut: rawptr,
		) -> Result ---
		rebaser_rebase_strm :: proc(
			pRebaser: ^rebaser,
			xInput: proc "c" (pIn: rawptr, pData: rawptr, pnData: ^c.int) -> Result,
			pIn: rawptr,
			xOutput: proc "c" (pOut: rawptr, pData: rawptr, nData: c.int) -> Result,
			pOut: rawptr,
		) -> Result ---

		session_config :: proc(op: Session_Config_Op, pArg: rawptr) -> Result ---

		changegroup_config :: proc (p: ^changegroup, op: Changegroup_Config_Op, pArg: rawptr) -> Result ---

		changegroup_change_begin :: proc(
			p: ^changegroup,
			eOp: Action_Code,
			zTab: cstring,
			bIndirect: c.int,
			pzErr: ^[^]byte,
		) -> Result ---

		changegroup_change_int64  :: proc(p: ^changegroup, bNew: b32, iCol: c.int, iVal: int64) -> Result ---
		changegroup_change_null   :: proc(p: ^changegroup, bNew: b32, iCol: c.int) -> Result ---
		changegroup_change_double :: proc(p: ^changegroup, bNew: b32, iCol: c.int, dVal: double) -> Result ---
		changegroup_change_blob   :: proc(p: ^changegroup, bNew: b32, iCol: c.int, pVal: rawptr,  nVal: c.int) -> Result ---

		@(link_name="sqlite3_changegroup_change_text")
		changegroup_change_text_str :: proc(p: ^changegroup, bNew: b32, iCol: c.int, pVal: cstring, nVal: c.int) -> Result ---
		@(link_name="sqlite3_changegroup_change_text")
		changegroup_change_text_buf :: proc(p: ^changegroup, bNew: b32, iCol: c.int, pVal: [^]u8, nVal: c.int) -> Result ---

		changegroup_change_finish :: proc(
			p: ^changegroup, 
			bDiscard: b32, 
			pzErr: ^[^]u8,
		) -> Result ---
	}
}

changegroup_change :: proc {
	changegroup_change_int64,  changegroup_change_null,
	changegroup_change_double, changegroup_change_text_str,
	changegroup_change_blob,   changegroup_change_text_buf,
}
changegroup_change_text :: proc { changegroup_change_text_str, changegroup_change_text_buf }

/******** End of sqlite3session.h  *********/


/******** Begin file fts5.h *********/


Fts5Context :: struct {}

fts5_extension_function :: #type proc "c" (
	pApi: ^Fts5ExtensionApi, /* API offered by current FTS version */
	pFts: ^Fts5Context,      /* First arg to pass to pApi functions */
	ppCtx: ^sqlite3_context, /* Context for returning result/error */
	nVal: c.int,             /* Number of values in apVal[] array */
	apVal: [^]^value,        /* Array of trailing arguments */
)

Fts5PhraseIter :: struct {
	a: cstring,
	b: cstring,
}

Fts5ExtensionApi :: struct {
	iVersion:           c.int, /* Currently always set to 4 */

	xUserData:          proc "c" (p: ^Fts5Context) -> rawptr,
	xColumnCount:       proc "c" (p: ^Fts5Context) -> c.int,
	xRowCount:          proc "c" (p: ^Fts5Context, pnRow: ^int64) -> c.int,
	xColumnTotalSize:   proc "c" (p: ^Fts5Context, iCol: c.int, pnToken: ^int64) -> c.int,
	xTokenize: proc "c" (
		p: ^Fts5Context,
		pText: cstring, nText: c.int, /* Text to tokenize */
		pCtx: rawptr,                 /* Context passed to xToken() */
		xToken: proc "c" (rawptr, c.int, cstring, c.int, c.int, c.int) -> Result, /* Callback */
	) -> Result,
	xPhraseCount:       proc "c" (p: ^Fts5Context) -> c.int,
	xPhraseSize:        proc "c" (p: ^Fts5Context, iPhrase: c.int) -> c.int,
	xInstCount:         proc "c" (p: ^Fts5Context, pnInst: ^c.int) -> c.int,
	xInst:              proc "c" (p: ^Fts5Context, iIdx: c.int, piPhrase: ^c.int, piCol: ^c.int, piOff: ^c.int) -> Result,
	xRowid:             proc "c" (p: ^Fts5Context) -> int64,
	xColumnText:        proc "c" (p: ^Fts5Context, iCol: c.int, pz: ^cstring16, pn: ^c.int) -> Result,
	xColumnSize:        proc "c" (p: ^Fts5Context, iCol: c.int, pnToken: ^c.int) -> Result,
	xQueryPhrase: proc "c" (
		p:         ^Fts5Context, 
		iPhrase:   c.int, 
		pUserData: rawptr, 
		cb:        proc "c" (^Fts5ExtensionApi, ^Fts5Context, rawptr) -> Result,
	) -> Result,
	xSetAuxdata:        proc "c" (p: ^Fts5Context, pAux: rawptr, xDelete: proc "c" (rawptr)) -> Result,
	xGetAuxdata:        proc "c" (p: ^Fts5Context, bClear: b32) -> rawptr,
	xPhraseFirst:       proc "c" (p: ^Fts5Context, iPhrase: c.int, pIter: ^Fts5PhraseIter, p1: ^c.int, p2: ^int) -> Result,
	xPhraseNext:        proc "c" (p: ^Fts5Context, pIter: ^Fts5PhraseIter, piCol: ^c.int, piOff: ^c.int),
	xPhraseFirstColumn: proc "c" (p: ^Fts5Context, iPhrase: c.int, pIter: ^Fts5PhraseIter, p1: ^int) -> Result,
	xPhraseNextColumn:  proc "c" (p: ^Fts5Context, pIter: ^Fts5PhraseIter, piCol: ^c.int),

	/* Below this point are iVersion>=3 only */
	xQueryToken: proc "c" (
		p: ^Fts5Context,
		iPhrase: c.int,
		iToken:  c.int,
		ppToken: ^cstring, 
		pnToken: ^c.int,
	) -> Result,
	xInstToken: proc "c" (p: ^Fts5Context, iIdx: c.int, iToken: c.int, p1: ^cstring, p2: ^c.int) -> Result,

	/* Below this point are iVersion>=4 only */
	xColumnLocale:      proc "c" (p: ^Fts5Context, iCol: c.int, pz: ^cstring, pn: ^c.int) -> Result,
	xTokenize_v2: proc "c" (
		p: ^Fts5Context,
		pText:   cstring, nText:   c.int,  /* Text to tokenize */
		pLocale: cstring, nLocale: c.int,  /* Locale to pass to tokenizer */
		pCtx:    rawptr,                   /* Context passed to xToken() */
		xToken:  proc "c" (rawptr, c.int, cstring, c.int, c.int, c.int) -> Result,  /* Callback */
	) -> Result,
}


Fts5Tokenizer :: struct {}

fts5_tokenizer_v2 :: struct {
	iVersion:  c.int, /* Currently always 2 */

	xCreate:   proc "c" (p: rawptr, azArg: [^]cstring, nArg: c.int, ppOut: ^^Fts5Tokenizer) -> Result,
	xDelete:   proc "c" (^Fts5Tokenizer),
	xTokenize: proc "c" (
		p:       ^Fts5Tokenizer,
		pCtx:    rawptr,
		flags:   FT5_Tokenize_Flags, /* Mask of FTS5_TOKENIZE_* flags */
		pText:   cstring, 
		nText:   c.int,
		pLocale: cstring, 
		nLocale: c.int,
		xToken: proc "c" (
			pCtx:   rawptr,          /* Copy of 2nd argument to xTokenize() */
			tflags: FT5_Token_Flags, /* Mask of FTS5_TOKEN_* flags */
			pToken: cstring,         /* Pointer to buffer containing token */
			nToken: c.int,           /* Size of token in bytes */
			iStart: c.int,           /* Byte offset of token within input text */
			iEnd:   c.int,           /* Byte offset of end of token within input text */
		) -> Result,
	) -> Result,
}


fts5_tokenizer :: struct {
	xCreate: proc "c" (p: rawptr, azArg: [^]cstring, nArg: c.int, ppOut: ^^Fts5Tokenizer) -> Result,
	xDelete: proc "c" (^Fts5Tokenizer),
	xTokenize: proc "c" (
		p:     ^Fts5Tokenizer,
		pCtx:  rawptr,
		flags: FT5_Tokenize_Flags, /* Mask of FTS5_TOKENIZE_* flags */
		pText: cstring, 
		nText: c.int,
		xToken: proc "c" (
			pCtx:   rawptr,          /* Copy of 2nd argument to xTokenize() */
			tflags: FT5_Token_Flags, /* Mask of FTS5_TOKEN_* flags */
			pToken: ^cstring,        /* Pointer to buffer containing token */
			nToken: c.int,           /* Size of token in bytes */
			iStart: c.int,           /* Byte offset of token within input text */
			iEnd:   c.int,           /* Byte offset of end of token within input text */
		) -> Result,
	) -> Result,
}


fts5_api :: struct {
	iVersion: c.int, /* Currently always set to 3 */

	/* Create a new tokenizer */
	xCreateTokenizer: proc "c" (
		pApi:       ^fts5_api,
		zName:      cstring,
		pUserData:  rawptr,
		pTokenizer: ^fts5_tokenizer,
		xDestroy:   proc "c" (rawptr),
	) -> Result,

	/* Find an existing tokenizer */
	xFindTokenizer: proc "c" (
		pApi:       ^fts5_api,
		zName:      cstring,
		ppUserData: ^rawptr,
		pTokenizer: ^fts5_tokenizer,
	) -> Result,

	/* Create a new auxiliary function */
	xCreateFunction: proc "c" (
		pApi:      ^fts5_api,
		zName:     cstring,
		pUserData: rawptr,
		xFunction: fts5_extension_function,
		xDestroy: proc "c" (rawptr),
	) -> Result,

	/* APIs below this point are only available if iVersion>=3 */

	/* Create a new tokenizer */
	xCreateTokenizer_v2: proc "c" (
		pApi:       ^fts5_api,
		zName:      cstring,
		pUserData:  rawptr,
		pTokenizer: ^fts5_tokenizer_v2,
		xDestroy: proc "c" (rawptr),
	) -> Result,

	/* Find an existing tokenizer */
	xFindTokenizer_v2: proc "c" (
		pApi:        ^fts5_api,
		zName:       cstring,
		ppUserData:  ^rawptr,
		ppTokenizer: ^^fts5_tokenizer_v2,
	) -> Result,
}


FT5_Tokenize_Flags :: bit_set[FT5_Tokenize_Flag; c.int]
FT5_Tokenize_Flag :: enum c.int {
	QUERY    = 0,
	PREFIX   = 1,
	DOCUMENT = 2,
	AUX      = 3,
}

FT5_Token_Flags :: bit_set[FT5_Token_Flag; c.int]
FT5_Token_Flag :: enum c.int {
	COLOCATED = 0, /* Same position as prev. token */
}

/******** End of fts5.h *********/
/******** End of SQLITE3_H *********/


/******** Begin of SQLITE3EXT_H *********/
/******** End of SQLITE3EXT_H *********/
