module pkg::todo;

import std::io;
import std::collections::list;
import std::collections::maybe;
import std::time::datetime;
import std::core::mem::alloc;

import pkg::parsing;
import pkg::sqlite;

struct TodoItem {
   int id;
   String title;
   Maybe{DateTime} completeDate;
}

fn TodoItem? todoItemMapperFn(Allocator allocator, QueryRow row) {
   TodoItem item;

   int complete = row.getInt(2);
   int completeDate = row.getInt(3);

   item.id = row.getInt(0);
   item.title = row.getTextCopy(allocator, 1);
   item.completeDate = completeDate > 0
      ? maybe::value{DateTime}(parsing::dateTimeFromSeconds((long)completeDate))
      : maybe::EMPTY{DateTime};

   return item;
}
