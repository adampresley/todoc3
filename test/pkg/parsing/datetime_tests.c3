module pkg::parsing_tests;

import std::io;
import std::core::test;

import pkg::parsing;

fn void unixEpocSecondsFromString_success() @test {
   String input = "2026-06-30";
   long want = 1782777600;

   // I suspect this is wrong, but I don't care THAT much right now. 
   // This is a learning exercise after all...
   long got = parsing::unixEpocSecondsFromString(input)!!;
   test::eq(want, got);
}
