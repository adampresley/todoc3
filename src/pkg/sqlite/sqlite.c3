module pkg::sqlite;

/*
struct User {
   String name;
   int age;
}

String query = "SELECT name, age FROM users";

QueryResult{User}? qr = db.query(MyStructType, query, 10, "testing"); 

qr.mapper = fn User? (QueryRow row) {
   User u;

   u.name = row.getText(0);
   u.age = row.getInt(1);

   return u;
};

defer qr.free();

while (qr.nextRow()) {
   User? u = qr.row();

   // do stuff
}
*/

import std::io;
import std::core::string;
import std::core::cinterop;
import std::core::mem::alloc;

faultdef OPEN_FAILED;
faultdef EXEC_FAILED;
faultdef BIND_FAILED;
faultdef UNSUPPORTED_BIND_TYPE;
faultdef PREPARE_FAILED;

alias Sqlite3 = void;
alias Sqlite3Stmt = void;

const int SQLITE_OK = 0;
const int SQLITE_ERROR = 1;
const int SQLITE_ROW = 100;
const void* SQLITE_TRANSIENT = (void*)(uptr)ulong::max;

extern fn CInt sqlite3_open(ZString filename, Sqlite3** db);
extern fn CInt sqlite3_close(Sqlite3* db);
extern fn ZString sqlite3_errmsg(Sqlite3* db);
extern fn void sqlite3_free(void* ptr);

extern fn CInt sqlite3_exec(Sqlite3* db, ZString sql, void* callback, void* arg, ZString* errmsg);

extern fn CInt sqlite3_prepare_v2(Sqlite3* db, ZString sql, CInt nbyte, Sqlite3Stmt** stmt, char** tail);
extern fn CInt sqlite3_step(Sqlite3Stmt* stmt);
extern fn CInt sqlite3_finalize(Sqlite3Stmt* stmt);

extern fn CInt sqlite3_bind_int(Sqlite3Stmt* stmt, CInt index, CInt value);
extern fn CInt sqlite3_bind_text(Sqlite3Stmt* stmt, CInt index, ZString value, CInt bytes, void* destructor);

extern fn CInt sqlite3_column_int(Sqlite3Stmt* stmt, CInt column);
extern fn ZString sqlite3_column_text(Sqlite3Stmt* stmt, CInt column);

struct Sqlite {
   Sqlite3* db;
}

alias QueryResultMapperFn<Type> = fn Type? (Allocator allocator, QueryRow row);

struct QueryResult<Type> {
   String query;
   Sqlite3Stmt* stmt;
   Allocator allocator;
   QueryResultMapperFn{Type} mapper;
}

struct QueryRow {
   Sqlite3Stmt* stmt;
}

fn void? Sqlite.open(&self, String filename) {
   Sqlite3* db = null;
   ZString zFilename = filename.zstr_tcopy();

   if (sqlite3_open(zFilename, &db) != SQLITE_OK) {
      io::printfn("sqlite open '%s' failed: %s", filename, sqlite3_errmsg(db));
      return OPEN_FAILED~;
   }

   self.db = db;
}

fn void Sqlite.close(&self) {
   sqlite3_close(self.db);
}

fn void? Sqlite.exec(&self, String query, args...) {
   ZString zQuery = query.zstr_tcopy();
   ZString msg = null;
   Sqlite3Stmt* stmt = null;

   if (sqlite3_prepare_v2(self.db, zQuery, -1, &stmt, null) != SQLITE_OK) {
      io::printfn("exec prepare failed: %s", sqlite3_errmsg(self.db));
      return PREPARE_FAILED~;
   }

   if (catch err = bindParams(self.db, stmt, args)) {
      sqlite3_finalize(stmt);
      return err~;
   }

   if (sqlite3_step(stmt) == SQLITE_ERROR) {
      io::printfn("exec failed: %s", sqlite3_errmsg(self.db));
      return EXEC_FAILED~;
   }

   sqlite3_finalize(stmt);
}

fn void? bindParam(Sqlite3* db, Sqlite3Stmt* stmt, CInt index, any arg) {
   switch (arg.type) {
      case int:
         if (sqlite3_bind_int(stmt, index, (CInt)arg.as(int)) != SQLITE_OK) {
            io::printfn("bind int failed on column %d: %s", index, sqlite3_errmsg(db));
            return BIND_FAILED~;
         }

      case String: 
         String value = arg.as(String);
         ZString zValue = value.zstr_tcopy();

         if (sqlite3_bind_text(stmt, index, zValue, -1, SQLITE_TRANSIENT) != SQLITE_OK) {
            io::printfn("bind String failed on column %d: %s", index, sqlite3_errmsg(db));
            return BIND_FAILED~;
         }

      default: 
         io::printfn("unsupported query parameter binding type on column %d: %s", index, arg.type);
         return UNSUPPORTED_BIND_TYPE~;
   }
}

fn void? bindParams(Sqlite3* db, Sqlite3Stmt* stmt, any[] args) {
   foreach (i, arg : args) {
      bindParam(db, stmt, (CInt)(i + 1), arg)!;
   }
}

macro Sqlite.query(&self, $Type, Allocator allocator, String query, args...) {
   Sqlite3Stmt* stmt = null;
   ZString zQuery = query.zstr_tcopy();

   if (sqlite3_prepare_v2(self.db, zQuery, -1, &stmt, null) != SQLITE_OK) {
      io::printfn("prepare failed: %s", sqlite3_errmsg(self.db));
      return PREPARE_FAILED~;
   }

   if (catch err = bindParams(self.db, stmt, args)) {
      sqlite3_finalize(stmt);
      return err~;
   }

   QueryResult{$Type} result;
   result.query = query;
   result.stmt = stmt;
   result.allocator = allocator;
   return result;
}

fn void QueryResult.free(&self) {
   sqlite3_finalize(self.stmt);
}

fn bool QueryResult.nextRow(&self) {
   return sqlite3_step(self.stmt) == SQLITE_ROW;
}

fn Type? QueryResult.row(&self) {
   QueryRow row;
   row.stmt = self.stmt;

   return self.mapper(self.allocator, row);
}

fn String QueryRow.getTextCopy(&self, Allocator allocator, int column) {
   ZString result = sqlite3_column_text(self.stmt, column);
   return result.copy(allocator);
}

fn int QueryRow.getInt(&self, int column) {
   CInt result = sqlite3_column_int(self.stmt, column);
   return (int)result;
}
