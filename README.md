# Historic Hansard Search, MkII

## Overview

An attempt at making a search for the flat-file Historic Hansard based on the salvaged search index and data culled from the original database. Although it's evolved from the initial attempt, it owes more to [the original code for the Historic Hansard project](https://github.com/millbanksystems/hansard) written by [Louise Crow](https://github.com/crowbot), [Rob McKinnon](https://github.com/robmckinnon) and [Robert Brook](https://github.com/robertbrook) (with occasional interference from me) back in 2007, from which it borrows heavily. Attribution for cross-project reuse has been stated inline wherever possible as I haven't been able to work out how to automagically get Git to do this for me.

## MkII?

Yeah, the first one didn't go so well - the idea was sound (well, I thought so) but creating a whole new index was more time-consuming than I'd thought possible so my thoughts have turned to recycling.

## Features

* Full text search
* Highlighting
* Timeline/histogram view
* Faceting on:
  * speaker name
  * sitting type (e.g. "Commons Sitting", "Lords Sitting", "Written Answers")
  * date
* Sorting

### Data searched:
* contribution text (solr index)
* sitting dates (database)
* Hansard references (database)
* member names (database)

## Notes

* Start and stop solr using the rake tasks (if stuck, kill the process and start again)
* Hacked to work with Ruby 1.9.x and ActiveRecord 3.2.x