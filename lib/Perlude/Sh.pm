package Perlude::Sh;
use Modern::Perl;
use Perlude;
use parent 'Exporter';
our @EXPORT_OK   = qw< sh ls cat zcat csv cat_with read_file from_dir >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
our $VERSION = '0.1';

# ABSTRACT: just forget about sed/awk based shell scripts. 

=head1 WARNINGS

no test, no warranty, API can change. don't push in production

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

use Cwd;
sub from_dir {
    my $pwd  = getcwd;
    my ( $dir, $sub ) = @_;
    chdir $dir or die "cd to $dir: $!";
    # TODO: think! is &$sub a good idea ? 
    my @r = $sub->();
    chdir $pwd or die "cd back to $pwd: $!";
    @r;
}

sub read_file {
    # TODO: is it worth ? 
    # use File::Slurp ();
    # File::Slurp::read_file
    open my $fh
    , (@_ ? $_[0] : $_)
        or die;
    local $/;
    <$fh>;
}

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

sub cat_with (&$) {
    my ( $streamer, $glob ) = @_;
    concatM { $streamer->() } ls $glob
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
