#! /bin/perl

use WordPress::XMLRPC;
use Time::Local;
use Getopt::Std;
#$opt{t} = 1;
getopts('htp:', \%opt);

if ($opt{h}) {
  print "post_next_month.pl [-t] [-p password]\n";
  exit;
}
if ($opt{t}) {
    $dcblog = 'http://dcimporttest.wordpress.com/xmlrpc.php';
    $dwblog = 'http://dcimporttest.wordpress.com/xmlrpc.php';
} else {
    $dcblog = 'http://dailyconfession.wordpress.com/xmlrpc.php';
    $dwblog = 'http://dailywestminster.wordpress.com/xmlrpc.php';
}

if ($opt{p}) {
  $passwd = $opt{p};
} else {
  print "Password: ";
  $passwd = <STDIN>;
  chomp $passwd;
}

($cmo, $yr) = (localtime)[4,5];
$year = $yr+1900;
$nmo = $cmo; # + 1;
@monames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

$month = $monames[$nmo];
printf "Current month is %s %d\n", $monames[$cmo], $year;
printf "Next    month is %s %d\n", $month, $year;

die "Use rotate.pl to generate $year.txt" unless -r "$year.txt";
open ROT, "$year.txt";
while (<ROT>) {
  next unless /$month/;
  s!00:00:01!08:00:01!;
  s!01:00:01!08:00:01!;
  push @dclines, $_;
}
for (1..4) { shift @dclines }

sub confirm {
  print "OK? [Y/n]: ";
  my $ans = <STDIN>;
  if ($ans =~ /^\s*(y|yes|)\s*$/is) {
    return;
  } #else
  print "Buh-bye\n";
  exit;
}

print "Daily Confession posts for $month $year:\n", @dclines;
confirm;

$mmm = lc $month;
@dwfiles = glob "w/$mmm*_esv.html";
for (@dwfiles) {
  if (/$mmm(\d\d)_esv/) {
    $day = ($1);
    push @dwlines, "dow $month $day 08:00:01 $year $_\n";
  } else {
    die "what is this? $_\n";
  }
}
for (1..4) { shift @dwlines }

print "Daily Westminster posts for $month $year:\n", @dwlines;
confirm;

open DWTIT, "w/titles.txt" or die "Can't read w/titles.txt\n";
while (<DWTIT>) {
  chomp;
  if (s!^(\d\d)-(\d\d)\s+!!) {
    $monum = $1;
    $day = $2; # two digits!
    $title  = $_;
    $monum--;  # for 0-index of @monames
    $monam = lc($monames[$monum]);
    $key = "w/${monam}${day}_esv.html";
    $dwtit{$key} = $title;
  }
}

sub get_title {
  my $f = shift;
  $f =~ m!(\w+)/(\w+).html!;
  my $dir = $1;
  my $fil = $2;
  if ($dir eq 'w') {
    return qq("$dwtit{$f}");
  } else {
    my $art = {cc=>"Children's Catechism, week",
	       sc=>"Shorter Catechism, week",
	       bcf=>"Belgic Confession, week",
	       lc=>"Larger Catechism, week",
	       sod=>"Canons of Dordt, week",
	       wcf=>"Westminster Confession, week",
	       hc=>"Heidelberg Catechism, Lord's day"}->{$dir};
    $fil =~ /(\d+)/;
    my $week = $1;
    return qq("$art $week");
  }
}

sub post {
  my $blog = shift;
  my $pass = shift;

  for (@_) {
    my ($y, $m, $d, $t, $f) = (split)[4,1,2,3,5];
    my %monums = (Jan=>1,Feb=>2,Mar=>3,Apr=>4,May=>5,Jun=>6,
		  Jul=>7,Aug=>8,Sep=>9,Oct=>10,Nov=>11,Dec=>12);
    my $date = sprintf "%4d-%02d-%02d $t", $year, $monums{$m}, $d;
    my $titl = get_title($f);
    die "Need a title!" unless $titl;
    my $cmd = qq(wordpress-upload-post -d $f -t $titl -D "$date" -u RubeRad -p $pass -x $blog\n);
    print $cmd;
    system $cmd;
  }
}

post $dcblog, $passwd, @dclines;
post $dwblog, $passwd, @dwlines;


