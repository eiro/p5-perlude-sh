package Perlude::Sh;
use Modern::Perl;
use Perlude;
use parent 'Exporter';
our @EXPORT_OK   = qw< sh ls cat zcat csv >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
# ABSTRACT: just forget about sed/awk based shell scripts. 

=head1 SYNOPSIS

Perlude::Sh

just forget about sed/awk based shell scripts. 

=head1 FUNCTIONS

sh, ls, cat, zcat, csv to be documented. but a simple example


    # count the occurrences of the first column in every csv

    my %seen; 
    now { $seen{  $_[0] }++ }
	concatM { csv $_ }
	ls "data/*.csv"
    ;

=head1 TODO

    * moar documentation
    * load modules on demand ? is it possible ? 

=cut


sub sh { lines "@_|" }

sub ls {
    my $pattern = shift;
    sub {
        while (my $file = glob $pattern) { return $file }
        ()
    }
}

sub cat {
    concatC
        apply { lines $_ }
        filter { -f $_ }
        ls shift;
}

sub zcat {
    require PerlIO::gzip;
    cat {qw/io :gzip/}, @_
}

sub csv {
    use Text::CSV;
    my ( $source, $csv_config ) = @_;
    my $input = do {
	if ( ref $source ) { $source }
	else {
	    open my $fh,$source or die "$! with $source";
	    $fh;
	}
    };

    my $parser = Text::CSV->new( $csv_config || {} )
	or die Text::CSV->error_diag;

    sub {
	if ( my $line = $parser->getline( $input ) ) { return $line }
	die $parser->error_diag unless $parser->eof;
	()
    }
}

1;