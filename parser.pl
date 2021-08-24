#!/usr/bin/perl -w

use DBI;


open my $file, '<', 'out' or die "Невозможно открыть файл: $!\n";

my $db = myconnect();
while(<$file>){
    #print $_;
    parse_row($_, $db);
}
$db->disconnect();


sub parse_row{
    my @arr_str = split(' ',$_[0]);
    my $dbh = $_[1];

    if(scalar(@arr_str) < 3){
        return 0;
    }

    my $sql = '';
    my $flag = '';
    my $mail = '';
    my $id = '';

    my %flags = ("<=" => 1,"=>" => 1,"->" => 1,"**" => 1,"==" => 1);
    
    my $date = shift(@arr_str);
    my $time = shift(@arr_str);
    my $int_id = @arr_str[0];
    if($flags{@arr_str[1]}){
        $flag = @arr_str[1];
        $mail = (@arr_str[2] eq ':blackhole:') ? @arr_str[3] : @arr_str[2];
    }
    print($mail . "\n\n");
    my $text = join ' ', @arr_str;

    if($text =~ /\sid=([^\s]+)\s?/){
        $id = $1;
    }

    my $sth;
    if($flag eq '<=' && $id){
        $sql = 'insert into message (created, id, int_id, str) values (?, ?, ?, ?)';
        $sth = $dbh->prepare($sql);
        $sth->execute($date . ' ' . $time, $id, $int_id, $text);
    }else{
        $sql = 'insert into log (created, int_id, str, address) values (?, ?, ?, ?)';
        $sth = $dbh->prepare($sql);
        $sth->execute($date . ' ' . $time, $int_id, $text, $mail);   
    }
    $sth->finish();

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
