#!/usr/bin/env perl

use Catmandu::Sane;
use Catmandu -load;
use Catmandu::Importer::EuropePMC;
use YAML;

Catmandu->load;

my $bag      = Catmandu->store('search')->bag('publicationItem');
my $importer = Catmandu->importer;
my $exporter = Catmandu->exporter;

$importer->each(
    sub {
        my $rec = $_;

        my $importer =
          Catmandu::Importer::EuropePMC->new( query => $rec->{pmid} );
        my $data = $importer->first;

        if ( $data->{hitCount} == 1
            && lc $data->{resultList}->{result}->{inEPMC} eq 'n' )
        {
            $exporter->add( { pmid => $rec->{pmid}, id => $rec->{id} } );
        }
        elsif ( $data->{hitCount} > 1 ) {
            foreach my $item ( @{ $data->{resultList}->{result} } ) {
                if ( lc $item->{source} eq 'med' && lc $item->{inEPMC} eq 'n' )
                {
                    $exporter->add(
                        { pmid => $rec->{pmid}, id => $rec->{id} } );
                }
            }
        }

    }
);

$exporter->commit;
