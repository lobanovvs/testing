#!/usr/bin/perl -w

use lib '/home/c/cv45412/perl5/lib/perl5/'; # CGI не установлен на выбранном мною хостинге по умолчанию, пришлось подключать как библиотеку
use CGI;
use DBI;

main();

sub main{
    my $q = new CGI;
    my $address = $q->param('address') || '';
    my $table = '';
    my $warning = '';
    my $cnt = 0;
    my @res = [];

    if($address){
        @res = get_res($address);
        $len = scalar(@res);
        if($len > 1){
            $table = '<table><tr><td>Date</td><td>String log</td></tr>';
            foreach my $item (@res){
                $table .= '<tr><td>' . $item->[1] . '</td><td>' . $item->[2] . '</td></tr>';
                $cnt++;
                if($cnt == 99){
                    last;
                }
            }
            $table .= '</table>';
            if($len > 100){
                $warning = '<strong>Warning! Over 100 lines</strong>';
            }
        }
    }

    print $q->header;
    print qq(
        <!DOCTYPE html>
        <html lang="ru">
        <head>
            <meta charset="UTF-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Document</title>

        </head>
        <body>
            <div class="container">
                <form action="" method="get">
                    <input type="text" name="address" value="$address">
                    <button type="submit">Search</button>
                </form>
                $warning
                <br>
                $table
            </div>    
        </body>
        </html>
    );
}

sub myconnect{
    my $dsn = "DBI:mysql:cv45412_maillog";
    my $username = "cv45412_maillog";
    my $password = 'Passw0rd2021';

    my %attr = ( 
        PrintError=>0,
        RaiseError=>1
    );
    my $dbh = DBI->connect($dsn,$username,$password,\%attr);
    return($dbh);
}

sub get_res{
    my ($address) = @_;
    my @result = [];
    my %temp_hash = ();

    my $db = myconnect();
    my $sql = "SELECT int_id, created, str FROM log where address like ? order by int_id, created limit 101";
    my $sth = $db->prepare($sql);
    $sth->execute($address);

    while(my @row = $sth->fetchrow_array()){
        push @result, [$row[0],$row[1],$row[2]];
        unless($temp_hash{$row[0]}){
            $temp_hash{$row[0]} = 1;
        }
    }
    $sth->finish();

    if(%temp_hash){
        my $str_id = join(',', map{'"' . $_ . '"'} keys %temp_hash) || '';

        $sql = "SELECT int_id, created, str FROM message where int_id in (". $str_id .") order by int_id, created limit 101";

        $sth = $db->prepare($sql);
        $sth->execute();

        while(my @row = $sth->fetchrow_array()){
            push @result, [$row[0],$row[1],$row[2]];
        }
        $sth->finish();
    }

    $db->disconnect();

    @result = sort{$a[0] cmp $b[0] || $a[1] cmp $b[1]} @result;

    return @result;
}

