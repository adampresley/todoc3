module todoc3;

import std::io;
import std::core::string;
import std::time::datetime;

import pkg::sqlite;
import pkg::todo;
import pkg::parsing;

faultdef ERR_READING_INPUT;

fn int main(String[] args)
{
   Sqlite db;
   if (catch db.open("./todo.db")) {
      return 1;
   }

   defer db.close();

   String dbSetup = 
      "CREATE TABLE IF NOT EXISTS todo ("
      "  id INTEGER PRIMARY KEY,"
      "  title TEXT NOT NULL," 
      "  complete_date INTEGER"
      ");";

   if (catch err = db.exec(dbSetup)) {
      io::printfn("failed to setup db: %s", err);
      return 1;
   }

   return mainMenu(&db);
}

fn int mainMenu(Sqlite* db) {
   bool running = true;

   while (running) {
      @pool() {
         io::printn("What would you like to do?");
         io::printn("--------------------------");
         io::printn("");
         
         io::printn("1. List incomplete to do items");
         io::printn("2. List complete to do items");
         io::printn("3. Create to do item");
         io::printn("4. Mark item complete");
         io::printn("5. Exit");
         io::printn("");

         String? choice = io::treadline();

         if (catch err = choice) {
            io::printf("  ERROR: an unexpected error occurred reading your input: %s.\n  Exiting.\n", err);
            return 1;
         }

         switch (choice.trim()) {
            case "1":
               if (catch listIncompleteTodos(db)) {
                  return 1;
               }

               io::printn("");

            case "2":
               if (catch listCompleteTodos(db)) {
                  return 1;
               }

               io::printn("");

            case "3":
               if (catch createTodo(db)) {
                  return 1;
               }

               io::printn("");

            case "4": 
               if (catch markComplete(db)) {
                  return 1;
               }

               io::printn("");

            default:
               running = false;
         }

         io::printn("");
      };
   }

   io::printn("Goodbye.");
   return 0;
}

fn void? listIncompleteTodos(Sqlite *db) {
   @pool() {
      TodoItem[]? items = todo::listIncomplete(tmem, db);

      if (catch err = items) {
         io::printn("There was an error listing incomplete items");
         return err~;
      }

      io::printn("ID      | Title");
      io::printn("---------------");

      foreach (TodoItem item : items) {
         io::printf("| %-6d|", item.id);
         io::printf(" %s", item.title);
         io::printn("");
      }
   };
}

fn void? listCompleteTodos(Sqlite *db) {
   @pool() {
      TodoItem[]? items = todo::listComplete(tmem, db);

      if (catch err = items) {
         io::printn("There was an error listing complete items");
         return err~;
      }

      io::printn("ID      | Complete Date | Title");
      io::printn("-------------------------------");

      foreach (TodoItem item : items) {
         @pool() {
            String formattedDate = parsing::formatDate(tmem, item.completeDate.value);

            io::printf("| %-6d|", item.id);
            io::printf(" %s    |", formattedDate);
            io::printf(" %s", item.title);
            io::printn("");
         };
      }
   };
}

fn void? createTodo(Sqlite* db) {
   String? title = "";

   io::print("Enter a title: ");
   title = io::treadline();

   if (catch err = title) {
      io::printfn("unexpected error reading title input: %s", err);
      return ERR_READING_INPUT~;
   }

   TodoItem todo;
   todo.title = title;

   todo::create(db, todo)!;
}

fn void? markComplete(Sqlite* db) {
   String? value = "";

   io::print("Enter ID of to do item: ");
   value = io::treadline();

   if (catch err = value) {
      io::printfn("unexpected error reading todo id: %s", err);
      return ERR_READING_INPUT~;
   }

   int? id = value.to_int();

   if (catch err = id) {
      io::printfn("unexpected error converting value into integer: %s", err);
      return ERR_READING_INPUT~;
   }

   if (catch todo::markComplete(db, id)) {
      return ERR_READING_INPUT~;
   }
}
