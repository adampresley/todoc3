module pkg::todo;

import std::io;
import std::collections::list;
import std::time::datetime;
import std::core::mem::alloc;

import pkg::parsing;
import pkg::sqlite;

faultdef ERR_CREATING_TODO;
faultdef ERR_LISTING_TODO;
faultdef ERR_UPDATING_TODO;

fn void? create(Sqlite* db, TodoItem item) {
   String query = 
      "INSERT INTO todo ("
      "  title"
      ") VALUES ("
      "  ?"
      ");";

   if (catch err = db.exec(query, item.title)) {
      io::printfn("unexpected error creating todo item: %s", err);
      return ERR_CREATING_TODO~;
   }
}

/*
Returns a slice of incomplete todo items. The slice is 
owned so memory must be freed.
*/
fn TodoItem[]? listIncomplete(Allocator allocator, Sqlite* db) {
   String query = 
      "SELECT "
      "  id "
      "  , title "
      "  , IFNULL(complete_date, 0) AS complete_date "
      "FROM todo "
      "WHERE 1=1"
      "  AND complete_date IS NULL "
      "ORDER BY id";

   QueryResult{TodoItem}? qr = db.query(TodoItem, allocator, query);

   if (catch err = qr) {
      io::printfn("unexpected error listing incomplete to do items: %s", err);
      return ERR_LISTING_TODO~;
   }

   qr.mapper = &todoItemMapperFn;
   defer qr.free();

   List{TodoItem} items;
   items.init(allocator);
   defer items.free();

   while (qr.nextRow()) {
      TodoItem? item = qr.row();

      if (catch err = item) {
         io::printfn("error reading incomplete to do item: %s", err);
         return ERR_LISTING_TODO~;
      }

      items.push(item);
   }

   TodoItem[] result = items.to_array(allocator);
   return result;
}

/*
Returns a slice of complete todo items. The slice is 
owned so memory must be freed.
*/
fn TodoItem[]? listComplete(Allocator allocator, Sqlite* db) {
   String query = 
      "SELECT "
      "  id "
      "  , title "
      "  , IFNULL(complete_date, 0) AS complete_date "
      "FROM todo "
      "WHERE 1=1"
      "  AND complete_date IS NOT NULL "
      "ORDER BY id";

   QueryResult{TodoItem}? qr = db.query(TodoItem, allocator, query);

   if (catch err = qr) {
      io::printfn("unexpected error listing complete to do items: %s", err);
      return ERR_LISTING_TODO~;
   }

   qr.mapper = &todoItemMapperFn;
   defer qr.free();

   List{TodoItem} items;
   items.init(allocator);
   defer items.free();

   while (qr.nextRow()) {
      TodoItem? item = qr.row();

      if (catch err = item) {
         io::printfn("error reading complete to do item: %s", err);
         return ERR_LISTING_TODO~;
      }

      items.push(item);
   }

   TodoItem[] result = items.to_array(allocator);
   return result;
}

fn void? markComplete(Sqlite* db, int id) {
   String query = 
      "UPDATE todo SET "
      "  complete_date=? "
      "WHERE id=?;";

   if (catch err = db.exec(query, (int)parsing::now(), id)) {
      io::printfn("unexpected error completing todo item: %s", err);
      return ERR_UPDATING_TODO~;
   }
}
