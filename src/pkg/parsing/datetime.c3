module pkg::parsing;

import std::io;
import std::time;
import std::core::mem::alloc;
import std::time::datetime;

faultdef INVALID_DATE_FORMAT;

/*
Turns YYYY-MM-DD into a unix seconds epoc in UTC
*/
fn long? unixEpocSecondsFromString(String date) {
   String[] dateSplit = date.tsplit("-");

   if (dateSplit.len != 3) {
      return INVALID_DATE_FORMAT~;
   }

   int? year = dateSplit[0].to_int();
   int? monthInt = dateSplit[1].to_int();
   int? day = dateSplit[2].to_int();

   if (catch year) return INVALID_DATE_FORMAT~;
   if (catch monthInt) return INVALID_DATE_FORMAT~;
   if (catch day) return INVALID_DATE_FORMAT~;

   Month month = Month::from_ordinal(monthInt - 1);
   DateTime dt = datetime::at(year, month, day, 0, 0, 0, 0);

   return (long)dt.to_time().to_seconds();
}

fn long now() {
   return (long)datetime::now().to_time().to_seconds();
}

fn DateTime dateTimeFromSeconds(long epochSeconds)
{
	return datetime::from_time((Time)(epochSeconds * (long)time::SEC));
}

fn String formatDate(Allocator allocator, DateTime dt) {
   String s = dt.format(allocator, DateTimeFormat.DATEONLY);
   return s;
}
