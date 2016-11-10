OS: Ubuntu 14.04.5 LTS

USE: perl source.pl xmlOrCSVfile mySQLUsername mySQLPassword

example: perl ./sources/process.pl ./Files/twc_fcast_4day_capcity.xml Nicolas Password

Modules prerequired:

install XML::LibXML
	sudo apt-get install libxml-libxml-perl
	
	
install Text::CSV	
	sudo apt-get install libtext-csv-perl
	
install DBI and DBD::mysql	(interaction PERL mySQL)
	$ sudo perl -MCPAN -e shell
	cpan> install DBI
	cpan[2]> install DBD::mysql