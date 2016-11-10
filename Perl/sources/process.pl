use strict;
use warnings;

use XML::LibXML;																#Use XML module in order to search in XML document without intensive use of regular expression
use Text::CSV;																	#Use CSV module in order to be more robust in the csv search (otherwise split)
use DBI;																		#Use DBI module in order to communicate with mySQL database


main();

##
## main()
##
## Arguments: 
## 		$ARGV[0]: 	string  	location of the input document
## 		$ARGV[1]: 	string  	mySQL username
## 		$ARGV[2]: 	string  	mySQL password
##
## Returns: None 
##
## Main subroutine
## Get all argument from command line
## Call the appropriated subroutine depending on input format
##	

sub main{
	my $sqlF = './Files/create_table_forecasts.sql';							#SQL script provided by Weatherzone could easily be passed as argument
	my $outF = './output.txt';													#Output text file location

	my $file = $ARGV[0];														#get the input file location												
	my $username = $ARGV[1];
	my $password = $ARGV[2];

	system("mysql -u$username -p$password < $sqlF");							#Run the input sql script from the shell



	my $dbh = DBI->connect(          
		"dbi:mysql:dbname=test", 
		$username,                          
		$password,                          
		{ RaiseError => 1 },         
	) or die $DBI::errstr;														#Connect to the mySql database

	if ($file =~ m/.csv$/){
		extractCSV($file, $dbh);
		}elsif ($file =~ m/.xml$/){
			extractXML($file, $dbh);
		}else {die "the input file needs to be either CSV or XML format\n";}	#if file is a .csv call extractCSV, if it is xml call extractXML, else nothing implemented yet


	generateSortedOutputTextFile($outF, $dbh);									#Get information from the database and export to a text file
	$dbh->disconnect();															#Disconnect to the mySql database
}

##
## extractCSV()
##
## Arguments:
##    $filename: 	string  	location of the input csv document
##    $dbh: 		handler 	database handler
##
## Returns: None 
##
## extract all requested information from the CSV document.
## Create a hash table with same syntaxt as the Database table. 
## Call insertRowSQL with this hash table.
##	
	
sub extractCSV{

	my $filename = $_[0];
	my $dbh = $_[1];
	my $csv = Text::CSV->new({ sep_char => ',' });
	my %row = (
				loc_type => 'NA',
				loc_code => 'NA',                            
				loc_name => 'NA',                            
				state  => 'NA',                             
				forecast_date => '1000-01-01',                       
				weather_icon  => 'NA',                       
				temp_min   => 'NA',                          
				temp_max    => 'NA',                         
				create_time    => '0000-00-00',                      
				create_system    => 'process.pl',                    
				create_version   => 'V0.01',                    
				create_source   => 'twc_fcast_4day_capcity.csv',                     
				last_update    => '1970-01-01 00:00:01',                      
				update_system   => 'process.pl',                     
				update_version   => 'V0.01',                    
				update_source	 => 'twc_fcast_4day_capcity.csv'
				);																													#Hash row contains the same key as database table
	
	open(my $data, '<', $filename) or die "Could not open '$filename' $!\n";
	my $l = <$data>;																												#Get the csv header
	if ($l !~ m/LocCode,State,Name,Date,Icon,MinTemp,MaxTemp/) {warn "CSV format is different, analysis might not be accurate";}	#Write a warning if header if not in the right format
	while (my $line = <$data>) {
						
		if ($csv->parse($line)) {																									#for each line if it can be parsed
			my @fields = $csv->fields();
				@row{('loc_code','state','loc_name','forecast_date','weather_icon','temp_min','temp_max')} = @fields;				#overwrite value in row for appropriate keys
				insertRowSQL(\%row, $dbh);																							#Call insertRowSQL in order to add this row in the DB
				print "$line has succesfully been extracted and added to the database\n";											#Standard ouput line read and added
		} else {
			warn "Data couldn't be extracted from: $line\n";
		}
	}
}


##
## extractXML()
##
## Arguments:
##    $filename: 	string  	location of the input xml document
##    $dbh: 		handler 	database handler
##
## Returns: None 
##
## extract all requested information from the XML document.
## Create a hash table with same syntaxt as the Database table. 
## Call insertRowSQL with this hash table.
##

sub extractXML{
	my $filename = $_[0];
	my $dbh = $_[1];
	my %row = (
			loc_type => 'NA',
			loc_code => 'NA',                            
			loc_name => 'NA',                            
			state  => 'NA',                             
			forecast_date => '1000-01-01',                       
			weather_icon  => 'NA',                       
			temp_min   => 'NA',                          
			temp_max    => 'NA',                         
			create_time    => '0000-00-00',                      
			create_system    => 'process.pl',                    
			create_version   => 'V0.01',                    
			create_source   => 'twc_fcast_4day_capcity.xml',                     
			last_update    => '1970-01-01 00:00:01',                      
			update_system   => 'process.pl',                     
			update_version   => 'V0.01',                    
			update_source	 => 'twc_fcast_4day_capcity.xml'
			);																										#Hash row contains the same key as database table
	my $dom = XML::LibXML->load_xml(location => $filename);


	foreach my $location ($dom->findnodes('/data/weather/countries/country/location')) {							#Get to the location node level
		@row{('loc_type','loc_code','loc_name','state')} = ($location->findvalue('./@type'),
															$location->findvalue('./@code'),
															$location->findvalue('./@name'), 
															$location->findvalue('./@state'));						#Extract foreach location every attributes
											  
		foreach my $forecast ($location->findnodes('./forecasts/forecast')) {										#Get to the forecast node level
			@row{('forecast_date','temp_min','temp_max','weather_icon')} = ($forecast->findvalue('./date'),
																			$forecast->findvalue('./temp_min_c'),
																			$forecast->findvalue('./temp_max_c'), 
																			$forecast->findvalue('./icon'));		#Extract foreach forecats all attributes														
			insertRowSQL(\%row, $dbh);																				#Add the row to the DB using insertRowSQL
			print(join(",", values %row), "has succesfully been added to the database\n");							#Standard ouput line read and added
		}

	}
}

##
## insertRowSQL()
##
## Arguments:
##    $rowRef: 	reference  	reference to the Hash row
##    $dbh: 	handler 	database handler
##
## Returns: None 
##
## Insert one row to the mySQL database.
## 
##

sub insertRowSQL{
	
	my ($rowRef, $dbh) = @_;
	my %row = %{$rowRef};
	my $keys = join(",",keys %row);
	my @values = values %row;
	$dbh->do("INSERT INTO forecasts($keys) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef,@values) or die "DBI::errstr";

}

##
## generateSortedOutputTextFile()
##
## Arguments:
##    $filename: 	string  	location of the output text file
##    $dbh: 		handler 	database handler
##
## Returns: None 
##
## Load all information required and sorted from data base.
## Write a pipe output text file as requested.
##

sub generateSortedOutputTextFile{

	my $filename = $_[0];
	my $dbh = $_[1];
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
	print $fh "Text Output ordered by location then by date\n";									#Header of the output file

	my $sth = $dbh->prepare("SELECT loc_code, 
							loc_name, 
							forecast_date, 
							weather_icon,
							temp_min,
							temp_max
							FROM forecasts
							ORDER by loc_code, forecast_date") or die "DBI::errstr";;			#Extract data from DB, sort them per code and then by date
							
	$sth->execute() or die $DBI::errstr;
	
	while (my @row = $sth->fetchrow_array()) {
	   print $fh join("|", @row), "\n";															#Write in the ouput file the row with pipe separators
	}
	close $fh;
	$sth->finish();

}
