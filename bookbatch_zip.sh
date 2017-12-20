#!/bin/bash
# script for preparing the folder structure necessary to
# feed the islandora batch import module (https://github.com/Islandora/islandora_book_batch)
# It expects a folder of tif files that are in sequence like pages of a book:
# (e.g MYBOOK_001.tif, .. ,MYBOOK_345.tif) and it will output the structure as required by the module

if [ -z "$1" ]
  then
    echo "Specify the folder of the tif images"
    echo "e.g. ./script.sh ./tif_folder book_name"
    exit
fi

if [ -z "$2" ]
  then
    echo "Specify the book name"
    echo "e.g. ./script.sh ./tif_folder book_name"
    exit
fi

# directory of tif files
DIR="$1"

# book name
BOOK_NAME="$2"

#create new book = folder
mkdir -p "$DIR/$BOOK_NAME"

# Index for creating folders 1..n
index=0;

cd "$DIR"

# Remove "Thumbs.db" and all .jpg files that may be present
rm -f Thumbs.db
rm -f *.jpg
 
# set up the source files for the DC.xml to be generated
DCBEGIN_NAME="/home/bcoles/maccready/DC/DCBEGIN"
DCEND_NAME="/home/bcoles/maccready/DC/DCEND"

# Find all files and folders in the current directory, sort them and iterate through them
find *.tif -maxdepth 1 -type f | sort | while IFS= read -r file; do

	#flag to check if file has been moved
	moved=0;

	# increment index
	((index++))

	#create new folder
	TARGET="./$BOOK_NAME/$index"
    mkdir -p "$TARGET"	

	# The moved will be 0 until the file is moved
    while [ $moved -eq 0 ]; do
    	
    	# If the directory has no files
		if find "$TARGET" -maxdepth 0 -empty | read; 
		then 
		  # Copy the current file to $target and increment the moved.
		  cp -v "$file" "$TARGET/OBJ.tif" && moved=1; 
		  
		  # create the corresponding DC.xml file and add to folder
		  xfile=${file%.*}
		  echo $xfile > /tmp/XFILE_TEXT
		  cat "$DCBEGIN_NAME" "/tmp/XFILE_TEXT" "$DCEND_NAME" > "$TARGET/DC.xml"
		else
		  # Uncomment the line below for debugging 
		  # echo "Directory not empty: $(find "$target" -mindepth 1)"

		  # Wait for one second. This avoids spamming 
		  # the system with multiple requests.
		  sleep 1; 
		fi;
    done;
done

# Add the MODS file from the MODS directory
cp -v "/home/bcoles/maccready/MODS/$BOOK_NAME.xml" "./$BOOK_NAME/MODS.xml"

echo -e "\nFolder structure completed..\n"
zip -r $BOOK_NAME.zip $BOOK_NAME
echo -e "Archive completed..\n"
echo -e "Done.\n"
exit 0

