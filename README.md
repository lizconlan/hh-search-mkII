# Historic Hansard Search, MkII

## Overview

An attempt at making a search for Historic Hansard based on the salvaged search index and data culled from the original database.

## MkII?

Yeah, the first one didn't go so well - the idea was sound (well, I think so) but creating a whole new index was more time-consuming than I'd thought possible so my thoughts have turned to recycling.

## Apologies

Lots of code being recycled from the original Hansard project, will try to make credit where it's due clearer once I've finished cherrypicking the most useful bits.

Very much a work in progress - currently somewhere between a train wreck and a cargo cult, approach with caution and don't expect the tests to pass (yet).

I've been asked to get something working ASAP so this is being rushed (excuse, sticking to it).

## Features

* Full text search
* Highlighting
* Faceting on:
  * speaker name
  * sitting type (e.g. "Commons Sitting", "Lords Sitting", "Written Answers")
  * date (not surfaceable yet - nothing to click on)
* Sorting

Data searched:
* contribution text
* dates
* Hansard references
* member names


## Notes

* Start and stop solr using the rake tasks (if stuck, kill the process and start again)
* Works best with Ruby 1.9.x and Active Record 2.3.x (I know, go with it)
* Limited to Active Record 2.3.x series because of acts_as_solr