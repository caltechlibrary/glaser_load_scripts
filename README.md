# Scripts and usage notes for Islandora load of Glaser collection

## Overview

This repository contains tools for loading folder-level archival data into Islandora using the "book" multipage content model and the `book_batch` command line load process.  Material requiring other content models, such as single images, audio, video, etc, cannot be loaded with these tools and are better handles singly through the Islandora web interface.

Process (all from the Linux command line):

- Create MODS metadata records (.xml) for each folder in a directory on the Islandora server.
- Move folders containing scanned pages/items to the server if they are not already there.
- Use the bookbatch.sh script to gather MODS records and corresponding pages from folders into packages suitable for loading from the command line.
- Use drush to run the islandora preprocess command to move folders into the Islandora loading queue.
- Use drush to ingest the folders in the queue.

Note that this process assumes a numbering scheme for folders in the form of

   `<string>_<series#>_<box#>_<folder#>`

e.g, `DAG_1_5_2`.  The process will work with other numbering schemes but will require some modification in the scripts and the way scripts are invoked.

## Creating MODS records

The script `excel_ead2mods.pl` is a perl script that takes .tsv spreadsheet data as input and produces an .xml output file for each line of the input, so that there is one MODS record per folder. The input spreadsheet is expected to be the one produced by Archives when the collection was processed for creation of an EAD through the old SCREAD process.

See the documentation in the code for a description of the expected input spreadsheet format and the mapping from spreadsheet to MODS.

Currently, no parameters are required for invocation since the input and output files are hardcoded in the script.

Usage:
   
   `perl excel_ead2mods.pl`

Note that in future, we will probably need to generate mods directly from the EAD XML, so this script will not be useful. 

## Preparing packages for bookbatch loading

The script `bookbatch.sh` expects to find folders full of scanned pages in the current directory, as well as corresponding MODS records in a directory specified as a parameter.  It matches folders with MODS records by matching the file names which are expected to be in the series-box-folder format described above.  See the Islandora book batch documentation for details of the output package format: https://wiki.duraspace.org/display/ISLANDORA/Islandora+Book+Batch.

the script `bookbatch_zip.sh` is a variant form that zips up the output packages.  This can be useful if the packages are to be uploaded or moved from one server to another, but is not generally needed when the whole process is carried out on the Islandora server.

See file `bookbatch_command.txt` for examples for invoking this script.  Basic format (assuming you are in the folder directory) is:

  `/home/bcoles/glaser/bin/bookbatch.sh Folder1 DAG_3_1_1`

Note that the MODS directory is hardcoded in the script.  If you need it in a different place, either modify the script or upgrade the script to specify the MODS dir in a parameter.

## Loading the bookbatch packages

The actual ingest process uses drush.  To invoke the drush commands, you need to be inside the drupal environment, so you will begin with

  `cd /var/www/html/drupal`  (for example, on the current coda6 server)

Packages must first be __preprocessed__ to add them to the Islandora load queue.  For examples of this, see the file `proprocess_command.txt`.  Basic format is

  `drush -v -d --user=bcoles --uri=http://glaser.library.caltech.edu islandora_book_batch_preprocess --content_models=islandora:bookCModel --namespace=dag --parent=islandora:dag --do_not_generate_ocr --type=directory --target=/load/DAG_1_1_1_batch`

See the Islandora bookbatch module documentation cited above for usage details.

Preprocessing add the packages to the Islandora load queue, which may be viewed through the Islandora admin interface at /admin/reports/Islandora batch sets.  You can preprocess several packages and then ingest them all with one ingest command (see below); it is generally much more efficient to do these in fairly large batches, such as all the folders in one box at a time.

The Islandora batch sets created in the preprocess step must then be __ingested__ with the ingest command.  See the file `ingest_command.txt` for examples.  The basic format is

  `drush -v -d --user=bcoles --uri=http://glaser.library.caltech.edu islandora_batch_ingest`

This will ingest all queued sets, creating islandora records and generating derivatives.  It will also mark the batch sets as ingested.

## Quality Assurance

Following ingest, it is wise to search or browse to each of the ingested records to ensure that all is well and that all images are viewable.
