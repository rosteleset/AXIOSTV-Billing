#!/usr/bin/gawk -f
BEGIN {
    is_data=0; is_struct=0; is_header=1; is_footer=0; i=0; tname="UNKNOWN_TABLE";
}

/^($|-- |\/\*\!)/ && !/^-- Table struct/ {
  # accumulate header lines
    if (is_header && !is_struct) { header[i]= $0; i++; } 
}

/^-- Table structure for table/ {
    is_struct=1; is_header=0; i=0; is_data=0;
    tname=substr($6,2,length($6)-2);
    tables[tname]=1;
    print "--" > tname".schema.sql"
    for (i in header) print header[i] >> tname".schema.sql";
    ###print "STRUCT:", tname;
}

/^-- Dumping data for table/ {
    is_data=1; is_header=0; is_struct=0;
    tname=substr($6,2,length($6)-2);
    print "--" > tname".data.sql"
    for (i in header) print header[i] >> tname".data.sql";
    ###print "DATA_START for table ",tname;
    i=0
}

{ if (is_struct) { print $0 >> tname".schema.sql"} }
{ if (is_data) { print $0 >> tname".data.sql" } }

/^UNLOCK TABLES/ {
    is_data=0; is_struct=0;
    ###print "DATA_END for table ",$tname;
}

/^(--|\/\*.40[0-9]{3} SET .+\*\/;$)/ {
    if (!(is_header || is_struct || is_data)) {
        # accumulate footer lines
        is_footer=1;
        footer[$0]=1;
    }
}

END { 
    # append footer to files
    for (t in tables) {
        for (f in footer) {
            print f >> t".schema.sql";
            print f >> t".data.sql";
        }
    }
}
