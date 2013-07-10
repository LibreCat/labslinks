#!/usr/bin/env perl

use Catmandu::Sane;
use Catmandu -load;
use Furl;
use XML::Simple;

Catmandu->load;
Catmandu->config;

my $furl = Furl->new(
  agent => 'Mozilla/5.0',
  timeout => 10
);
my $BASE_URL = 'http://www.ebi.ac.uk/europepmc/webservices/rest/query=';
my $bag = Catmandu->store('search')->bag('publicationItem');

# get all fulltext records with medline IDs (depends on your cql mapping)
my $hits = $bag->search(cql_query => "externalIdentifier=medline* AND fulltext=1");
my $opts = {
  xml => 'true',
  template => 'labs.tt',
  template_before => 'labs_before.tt',
  template_after => 'labs_after.tt',
  fix => 'fix.txt',
  file => 'pushLabsLinks.xml',
  };

my $exporter = Catmandu::Exporter::Template->new($opts);

$hits->each( sub {
  my $pub = $_[0];
	my $url = $BASE_URL . $pub->{medline}; # pmid
  my $res = $furl->get($url);
  die $res->status_line unless $res->is_success;
  my $xml = XMLin($res);
  
  # if no OA fulltext in Europe PMC, then create xml snippet
  if (lc $xml->{responseWrapper}->{resultList}->{result}->{inEPMC} eq 'n') {
    $exporter->add($pub);
  }
});

$exporter->commit;
