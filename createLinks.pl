#!/usr/bin/env perl

use Catmandu::Sane;
use Catmandu -load;
use Catmandu::Importer::EuropePMC;
use Net::FTP;
use Getopt::Std;

getopts('t');
our $opt_t;

Catmandu->load;
my $conf = Catmandu->config;

my $importer = Catmandu->importer;
my $exporter = Catmandu->exporter;

#generate provider.xml
my $provider = Catmandu->exporter('provider');
$provider->add({conf => $conf});
$provider->commit;

$importer->each(
    sub {
        my $rec = $_[0];

        my $importer =
          Catmandu::Importer::EuropePMC->new( query => $rec->{pmid} );
        my $data = $importer->first;

        if ( $data->{hitCount} == 1
            && lc $data->{resultList}->{result}->{inEPMC} eq 'n' )
        {
            $exporter->add( { conf => $conf, pmid => $rec->{pmid}, id => $rec->{id} } );
        }
        elsif ( $data->{hitCount} > 1 ) {
            foreach my $item ( @{ $data->{resultList}->{result} } ) {
                if ( lc $item->{source} eq 'med' && lc $item->{inEPMC} eq 'n' )
                {
                    $exporter->add(
                        { conf => $conf, pmid => $rec->{pmid}, id => $rec->{id} } );
                }
            }
        }

    }
);

$exporter->commit;

if ($opt_t) {
    my $ftp = Net::FTP->new($conf->{ftp}->{host}) || die "Cannot connect: $@";
    $ftp->login($conf->{ftp}->{login}, $conf->{ftp}->{pwd}) || die "Cannot login", $ftp->message;
    $ftp->cwd($conf->{ftp}->{cwd}) || die "Cannot change directory", $ftp->message;
    $ftp->put($conf->{exporter}->{default}->{options}->{file}) || die "Cannot put file to server", $ftp->message;;
    $ftp->quit;
    say "FTP upload successful.";
}

=head1 USAGE
    
    # creates file 'pushLinks.xml'
    $ perl createLinks.pl

    # additionally transfers the file 'pushLinks.xml' to the ftp server
    $ perl createLinks.pl -t

=cut
