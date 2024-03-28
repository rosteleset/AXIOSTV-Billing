#!/bin/perl

package Sorm;

=head1 NAME

  Accounts manage functions

=cut

use strict;
use parent qw 'dbcore';
use Data::Dumper;
use Encode;
use POSIX qw(strftime);
use Net::CIDR;
use Net::CIDR::Lite;
use Net::IP;
use File::Copy;

use parent 'main';
use Nas;
#my $MODULE = 'Sorm';
#my ($admin, $CONF);

#my $region_id = $self->{conf}->{SORM_ISP_ID} || q{};
#my $country = $self->{conf}->{SORM_COUNTRY} || q{};
#my $region = $self->{conf}->{SORM_REGION} || q{};
#my $zone = $self->{conf}->{SORM_ZONE} || q{};

my $count = 0;

#FTP Login: sorm3, Passord: 7QmiUGwB0ZU4B2iL

my $date_ended = '2030-12-31 23:59:59';
my $debug = '0';

my $location_file = "$main::var_dir/sorm/Fenix/";
my $file = strftime "%Y%m%d_%H%M", localtime;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

##########SQL Functions for WEB############

#******************************************
#
#
#******************************************
sub _list {

my $self = shift;
my ($table, $null) = @_;

  $self->query("SELECT * FROM $table WHERE actual = 1",
    undef,
    { COLS_NAME => 1 }
  );

        return [ ] if ($self->{errno});
my $list = $self->{list};

return $list;
}

#******************************************
#
#
#******************************************
sub _info {

my $self = shift;
my ($table, $id) = @_;

  $self->query("SELECT * FROM $table WHERE id = $id AND actual = 1",
    undef,
    { COLS_NAME => 1 }
  );

        return [ ] if ($self->{errno});
my $list = $self->{list}->[0];

return $list;
}

#******************************************
#
#
#******************************************
sub _add {

  my $self = shift;
  my ($table, $attr) = @_;

  $self->query_add($table, $attr, {REPLACE => 1});

die if ($self->{errno});
#print Dumper $attr;
return 1;
}

#******************************************
#
#
#******************************************
sub _change {

  my $self = shift;
  my ($table, $attr, $conf_params) = @_;

#    foreach my $conf_param (@$conf_params) {

        $self->query("UPDATE $table SET actual = '0', END_TIME = CURRENT_TIMESTAMP() WHERE id = '$attr->{id}'",
                'do',
                {}
        );

        $self->query("INSERT INTO $table (DESCRIPTION, IPV4_START, IPV4_END, BEGIN_TIME, END_TIME) 
		VALUES ('$attr->{DESCRIPTION}', '$attr->{IPV4_START}', '$attr->{IPV4_END}', CURRENT_TIMESTAMP(), '$attr->{END_TIME}')",
               'do',
                {}
        );
#    }

die if ($self->{errno});
return 1;
}

#******************************************
#
#
#******************************************
sub _del {

  my $self = shift;
  my ($table, $attr) = @_;

      if ($attr->{del} > '0') {
        $self->query("UPDATE $table SET actual = '0', END_TIME = CURRENT_TIMESTAMP() WHERE id = '$attr->{del}'",
                'do',
                {}
        );
      }
die if ($self->{errno});
return 1;
}

#******************************************
#
#
#******************************************
sub _export {

  my $self = shift;
  my ($table) = @_;

        $self->query("UPDATE $table SET reported = '0'",
                'do',
                {}
        );
die if ($self->{errno});
return 1;
}

#******************************************
#Синхронизация с ippools
#
#******************************************
sub pool_sync {

  my $self = shift;
    $self->query2("UPDATE SORM_IP_PLAN SET actual = '0', END_TIME = CURRENT_TIMESTAMP()");
    $self->query2("INSERT INTO SORM_IP_PLAN (DESCRIPTION, IPV4_START, IPV4_END)
                SELECT name, INET_NTOA(ip), INET_NTOA(ip+counts-1) FROM ippools GROUP BY ip");
  die if ($self->{errno});
return 1;
}

#******************************************
#Синхронизация с ippools
#
#******************************************
#sub gateway_sync {
#
#  my $self = shift;
#    $self->query2("TRUNCATE SORM_GATEWAY");
#    $self->query2("INSERT INTO SORM_GATEWAY (GATE_ID, DISABLE, BEGIN_TIME, DESCRIPTION, IPV4, IP_PORT, ZIP, CITY, STREET, BUILDING, APARTMENT) 
#		SELECT id, disable AS DISABLE, DATE_ADD(changed, INTERVAL $time_offset HOUR) AS BEGIN_TIME, INET_NTOA(ip) AS IPV4, 
#		mng_host_port AS IP_PORT, name AS DESCRIPTION, address_street AS STREET, address_build AS BUILDING, address_flat AS APARTMENT, 
#		zip AS ZIP, city AS CITY FROM nas WHERE nas_type != 'other' ORDER BY id ASC");
#  die if ($self->{errno});
#return 1;
#}

#**********************************************************
=head2  sub abonentGetNewData

=cut
#**********************************************************
sub abonentGetNewData
{
	my $self = shift;
	my @db_array;
        my %axbills_array;
        my @changed_entries;
        my $count_updates = 0;
        my @new_entries;
	my @old_entries;
	my $need_update_db = 0;
	my $need_new_file = 0;
	my $entry;
	my $begin_time;
	my $abonent_created = 0;
	my $abonent_addr_created = 0;
	my $abonent_srv_created = 0;
	my $abonent_ident_created = 0;
	my $clean_hex_ip_new;
	my $clean_hex_ip_old;

	my $region_id = $self->{conf}->{SORM_ISP_ID} || q{};
	my $country = $self->{conf}->{SORM_COUNTRY} || q{};
	my $region = $self->{conf}->{SORM_REGION} || q{};
	my $zone = $self->{conf}->{SORM_ZONE} || q{};
	my $time_offset = $self->{conf}->{SORM_TIME_OFFSET} || '-3'; #Moscow

	my DBI $dbh = $self->{db}->{db};

	my $sth = $dbh->prepare(qq{SELECT users.uid AS ABONENT_ID,
users.company_id AS COMPANY_ID,
if((users.company_id > 0 && companies.contract_date > 0), companies.contract_date, users_pi.contract_date) AS CONTRACT_DATE,
if((users.company_id > 0 && companies.contract_id > 0), companies.contract_id, users_pi.contract_id) AS CONTRACT_ID,
if((users.company_id > 0 && companies.contract_id > 0), companies.contract_id, users_pi.contract_id) AS ACCOUNT,
if((users.company_id > 0), 43, 42) AS ABONENT_TYPE,
if((users.company_id > 0), companies.name, '') AS FULL_NAME,
if((users.company_id > 0), companies.tax_number, '') AS INN,
if((users.company_id > 0 && representative != ''), representative, if ((fio2 != '' && fio3 != ''), CONCAT(fio, ' ', fio2, ' ', fio3), fio)) AS CONTACT,
if((users.company_id > 0), companies.phone, '') AS PHONE_FAX,
if((users.company_id > 0), companies.bank_name, '') AS BANK,
if((users.company_id > 0), companies.bank_account, '') AS BANK_ACCOUNT,
if((users.company_id = 0), if ((fio2 != '' && fio3 != ''), CONCAT(fio, ' ', fio2, ' ', fio3), fio), '') AS UNSTRUCT_NAME,
if((users.company_id = 0), if((users_pi.birth_date = '0000-00-00'), '', users_pi.birth_date), '') AS BIRTH_DATE,
if((users.company_id = 0 && users_pi.pasport_num != ''), CONCAT(users_pi.pasport_num, ' '), '') AS IDENT_CARD_SERIAL,
if((users.company_id = 0 && users_pi.pasport_grant != '' && users_pi.pasport_date != '0000-00-00'), concat(users_pi.pasport_grant, ' ', users_pi.pasport_date), '') AS IDENT_CARD_DESCRIPTION,
CASE
    WHEN internet_main.disable > 0 
        THEN '1'
    WHEN users.disable = 1 
        THEN '1'
    WHEN companies.disable = 1
        THEN '1'
    ELSE '0'
END AS STATUS,
#Abonent_addr
if((d.zip > 0), d.zip, '') AS ZIP,
#if((users.company_id > 0), companies._city, users_pi.city) AS CITY,
#if((users.company_id > 0), companies._street, users_pi.address_street) AS STREET,
#if((users.company_id > 0), companies._building, users_pi.address_build) AS BUILDING,
#if((users.company_id > 0), companies._apartment, users_pi.address_flat) AS APARTMENT,
#users_pi.address_flat AS APARTMENT,
d.city AS CITY,
s.name AS STREET,
b.number AS BUILDING,
if((users.company_id > 0 && companies.location_id > 0), companies.address_flat, users_pi.address_flat) AS APARTMENT,
#Abonent_srv
tarif_plans.name AS PARAMETER,
internet_main.tp_id AS TP_ID,
#Abonent_ident
users.id AS LOGIN,
if((users.company_id > 0 && representative != '' && companies.phone != ''), companies.phone, (SELECT value from users_contacts WHERE type_id=2 AND users_contacts.uid=users.uid LIMIT 1)) AS PHONE,
(SELECT value from users_contacts WHERE type_id=9 AND users_contacts.uid=users.uid LIMIT 1) AS E_MAIL,
internet_main.ip AS IPV4,
INET_NTOA(internet_main.ip) AS IPV4_NTOA,
internet_main.netmask AS IPV4_MASK,
DATE_ADD(users.last_update, INTERVAL $time_offset HOUR) AS users_updated,
DATE_ADD(users_pi.last_update, INTERVAL $time_offset HOUR) AS users_pi_updated,
DATE_ADD(internet_main.last_update, INTERVAL $time_offset HOUR) AS internet_main_updated,
if ((users.company_id > 0), DATE_ADD(companies.last_update, INTERVAL $time_offset HOUR), '0000-00-00 00:00:00') AS companies_updated
from users_pi
INNER JOIN users ON users_pi.uid = users.uid
INNER JOIN internet_main ON internet_main.uid = users.uid
INNER JOIN tarif_plans ON internet_main.tp_id = tarif_plans.tp_id
LEFT JOIN companies ON companies.id = users.company_id
LEFT JOIN builds b ON b.id=if((users.company_id > 0 && companies.location_id > 0 && representative != ''), companies.location_id, users_pi.location_id)
LEFT JOIN streets s ON s.id=b.street_id
LEFT JOIN districts d ON d.id=s.district_id
ORDER BY users.uid ASC
});
$sth->execute or die DBI->errstr;

	while(my $new_data = $sth->fetchrow_hashref())
	{
		$axbills_array{$new_data->{ABONENT_ID}} = $new_data;
	}

#Соберем в массив данные из базы скрипта
	$sth = $dbh->prepare(qq{SELECT ABONENT_ID,
		CONTRACT_DATE,
		CONTRACT,
		ACCOUNT,
		ABONENT_TYPE,
		FULL_NAME,
		INN,
		CONTACT,
		PHONE_FAX,
		BANK,
		BANK_ACCOUNT,
		UNSTRUCT_NAME,
		BIRTH_DATE,
		IDENT_CARD_SERIAL,
		IDENT_CARD_DESCRIPTION,
		STATUS,
		ATTACH,
		DETACH,
		ACTUAL_FROM,
		ACTUAL_TO,
		COMPANY_ID,
		#Abonent_addr
		ZIP,
		COUNTRY,
		REGION,
		ZONE,
		CITY,
		STREET,
		BUILDING,
		APARTMENT,
		ABONENT_ADDR_BEGIN_TIME,
		ABONENT_ADDR_END_TIME,
		#Abonent_srv
		PARAMETER,
		TP_ID,
		ABONENT_SRV_BEGIN_TIME,
		ABONENT_SRV_END_TIME,
		DATE_ADD(CURRENT_TIMESTAMP, INTERVAL $time_offset HOUR) AS CURRENT_TIMESTAMP_3,
		
		#Abonent_ident
		LOGIN,
		E_MAIL,
		PHONE,
		IPV4 AS IPV4,
		INET_NTOA(IPV4) AS IPV4_NTOA,
		IPV4_MASK AS IPV4_MASK,
                ABONENT_IDENT_BEGIN_TIME,
                ABONENT_IDENT_END_TIME,
		users_updated,
		users_pi_updated,
		internet_main_updated,
		companies_updated
		from SORM_ABONENT
		ORDER BY ABONENT_ID ASC});
#if((COMPANY_ID > 0),companies_updated, '0000-00-00 00:00:00') AS companies_updated
        $sth->execute or die DBI->errstr;

        while(my $old_data = $sth->fetchrow_hashref())
        {
		push(@db_array, {id => $old_data->{ABONENT_ID},  value => $old_data });
	}

#Поиск изменений между массивами биллинга и скрипта
#Без платежей
#Ищем совпадения, выпиливаем их
        foreach my $entry (@db_array)
        {
		$need_update_db = 0;

                if($entry->{id} && exists $axbills_array{$entry->{id}})
                {
			 if ($axbills_array{$entry->{id}}->{ABONENT_ID} eq $entry->{value}->{ABONENT_ID})
				{
				$begin_time = $entry->{value}->{CURRENT_TIMESTAMP_3};
				if ($axbills_array{$entry->{id}}->{internet_main_updated} ne $entry->{value}->{internet_main_updated})
				{
					$begin_time = $axbills_array{$entry->{id}}->{internet_main_updated}; 
				} 
					elsif ($axbills_array{$entry->{id}}->{users_updated} ne $entry->{value}->{users_updated})
					{
						$begin_time = $axbills_array{$entry->{id}}->{users_updated};
					}
						elsif ($axbills_array{$entry->{id}}->{users_pi_updated} ne $entry->{value}->{users_pi_updated})
						{
						$begin_time = $axbills_array{$entry->{id}}->{users_pi_updated};
						}
						elsif (($axbills_array{$entry->{id}}->{ABONENT_TYPE}) == '43' && $axbills_array{$entry->{id}}->{companies_updated} ne $entry->{value}->{companies_updated})
                                                	{
                                                	$begin_time = $axbills_array{$entry->{id}}->{companies_updated};
                                                	}

				$begin_time = $entry->{value}->{CURRENT_TIMESTAMP_3} if ($begin_time =~ '0000-00-00 00:00:00');

                                $axbills_array{$entry->{id}}->{UNSTRUCT_NAME} //= q{};$axbills_array{$entry->{id}}->{UNSTRUCT_NAME} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{BANK} //= q{};$axbills_array{$entry->{id}}->{BANK} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{CONTRACT_DATE} //= q{};$axbills_array{$entry->{id}}->{CONTRACT_DATE} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{BANK_ACCOUNT} //= q{};$axbills_array{$entry->{id}}->{BANK_ACCOUNT} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{IDENT_CARD_DESCRIPTION} //= q{};$axbills_array{$entry->{id}}->{IDENT_CARD_DESCRIPTION} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{IDENT_CARD_SERIAL} //= q{};$axbills_array{$entry->{id}}->{IDENT_CARD_SERIAL} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{BIRTH_DATE} //= q{};$axbills_array{$entry->{id}}->{BIRTH_DATE} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{INN} //= q{};$axbills_array{$entry->{id}}->{INN} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{ACCOUNT} //= q{};$axbills_array{$entry->{id}}->{ACCOUNT} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{CONTACT} //= q{};$axbills_array{$entry->{id}}->{CONTACT} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{FULL_NAME} //= q{};$axbills_array{$entry->{id}}->{FULL_NAME} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{CONTRACT_ID} //= q{};$axbills_array{$entry->{id}}->{CONTRACT_ID} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{PHONE_FAX} //= q{};$axbills_array{$entry->{id}}->{PHONE_FAX} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{ZIP} //= q{};$axbills_array{$entry->{id}}->{ZIP} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{CITY} //= q{};$axbills_array{$entry->{id}}->{CITY} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{STREET} //= q{};$axbills_array{$entry->{id}}->{STREET} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{BUILDING} //= q{};$axbills_array{$entry->{id}}->{BUILDING} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{APARTMENT} //= q{};$axbills_array{$entry->{id}}->{APARTMENT} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{PARAMETER} //= q{};$axbills_array{$entry->{id}}->{PARAMETER} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{PHONE} //= q{};$axbills_array{$entry->{id}}->{PHONE} =~ s/[;)(]/ /g;
                                $axbills_array{$entry->{id}}->{E_MAIL} //= q{};$axbills_array{$entry->{id}}->{E_MAIL} =~ s/[;)(]/ /g;

				if (defined($axbills_array{$entry->{id}}->{BANK}) && defined($entry->{value}->{BANK}) && $axbills_array{$entry->{id}}->{BANK} ne $entry->{value}->{BANK} ||
				defined($axbills_array{$entry->{id}}->{UNSTRUCT_NAME}) && defined($entry->{value}->{UNSTRUCT_NAME}) && $axbills_array{$entry->{id}}->{UNSTRUCT_NAME} ne $entry->{value}->{UNSTRUCT_NAME} ||
				defined($axbills_array{$entry->{id}}->{CONTRACT_DATE}) && defined($entry->{value}->{CONTRACT_DATE}) && $axbills_array{$entry->{id}}->{CONTRACT_DATE} ne $entry->{value}->{CONTRACT_DATE} ||
				defined($axbills_array{$entry->{id}}->{BANK_ACCOUNT}) && defined($entry->{value}->{BANK_ACCOUNT}) && $axbills_array{$entry->{id}}->{BANK_ACCOUNT} ne $entry->{value}->{BANK_ACCOUNT} ||
				defined($axbills_array{$entry->{id}}->{IDENT_CARD_DESCRIPTION}) && defined($entry->{value}->{IDENT_CARD_DESCRIPTION}) && $axbills_array{$entry->{id}}->{IDENT_CARD_DESCRIPTION} ne $entry->{value}->{IDENT_CARD_DESCRIPTION} ||
				defined($axbills_array{$entry->{id}}->{STATUS}) && defined($entry->{value}->{STATUS}) && $axbills_array{$entry->{id}}->{STATUS} ne $entry->{value}->{STATUS} ||
				defined($axbills_array{$entry->{id}}->{IDENT_CARD_SERIAL}) && defined($entry->{value}->{IDENT_CARD_SERIAL}) && $axbills_array{$entry->{id}}->{IDENT_CARD_SERIAL} ne $entry->{value}->{IDENT_CARD_SERIAL} ||
				defined($axbills_array{$entry->{id}}->{BIRTH_DATE}) && defined($entry->{value}->{BIRTH_DATE}) && $axbills_array{$entry->{id}}->{BIRTH_DATE} ne $entry->{value}->{BIRTH_DATE} ||
				defined($axbills_array{$entry->{id}}->{INN}) && defined($entry->{value}->{INN}) && $axbills_array{$entry->{id}}->{INN} ne $entry->{value}->{INN} ||
				defined($axbills_array{$entry->{id}}->{ACCOUNT}) && defined($entry->{value}->{ACCOUNT}) && $axbills_array{$entry->{id}}->{ACCOUNT} ne $entry->{value}->{ACCOUNT} ||
				defined($axbills_array{$entry->{id}}->{CONTACT}) && defined($entry->{value}->{CONTACT}) && $axbills_array{$entry->{id}}->{CONTACT} ne $entry->{value}->{CONTACT} ||
                                defined($axbills_array{$entry->{id}}->{COMPANY_ID}) && defined($entry->{value}->{COMPANY_ID}) && $axbills_array{$entry->{id}}->{COMPANY_ID} ne $entry->{value}->{COMPANY_ID} ||
				defined($axbills_array{$entry->{id}}->{FULL_NAME}) && defined($entry->{value}->{FULL_NAME}) && $axbills_array{$entry->{id}}->{FULL_NAME} ne $entry->{value}->{FULL_NAME} ||
				defined($axbills_array{$entry->{id}}->{ABONENT_TYPE}) && defined($entry->{value}->{ABONENT_TYPE}) && $axbills_array{$entry->{id}}->{ABONENT_TYPE} ne $entry->{value}->{ABONENT_TYPE} ||
				defined($axbills_array{$entry->{id}}->{CONTRACT_ID}) && defined($entry->{value}->{CONTRACT}) && $axbills_array{$entry->{id}}->{CONTRACT_ID} ne $entry->{value}->{CONTRACT} ||
				defined($axbills_array{$entry->{id}}->{PHONE_FAX}) && defined($entry->{value}->{PHONE_FAX}) && $axbills_array{$entry->{id}}->{PHONE_FAX} ne $entry->{value}->{PHONE_FAX})
				{
					$need_update_db = 1;

					if ($abonent_created == 0)
					{
						open(Abonent, ">$location_file/ABONENT_$file.txt") || die;
						print Abonent "ID;REGION_ID;CONTRACT_DATE;CONTRACT;ACCOUNT;ACTUAL_FROM;ACTUAL_TO;ABONENT_TYPE;NAME_INFO_TYPE;FAMILY_NAME;GIVEN_NAME;INITIAL_NAME;UNSTRUCT_NAME;BIRTH_DATE;IDENT_CARD_TYPE_ID;IDENT_CARD_TYPE;IDENT_CARD_SERIAL;IDENT_CARD_NUMBER;IDENT_CARD_DESCRIPTION;IDENT_CARD_UNSTRUCT;BANK;BANK_ACCOUNT;FULL_NAME;INN;CONTACT;PHONE_FAX;STATUS;ATTACH;DETACH;NETWORK_TYPE;RECORD_ACTION;INTERNAL_ID1\n";
						$abonent_created = 1;
					}

				#Удаление строки.Как старая, но с RECORD_ACTON=2.
                                print Abonent "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{CONTRACT_DATE};$entry->{value}->{CONTRACT};$entry->{value}->{ACCOUNT};$entry->{value}->{ACTUAL_FROM};$entry->{value}->{ACTUAL_TO};$entry->{value}->{ABONENT_TYPE};1;;;;$entry->{value}->{UNSTRUCT_NAME};$entry->{value}->{BIRTH_DATE};0;1;;;;$entry->{value}->{IDENT_CARD_SERIAL}$entry->{value}->{IDENT_CARD_DESCRIPTION};$entry->{value}->{BANK};$entry->{value}->{BANK_ACCOUNT};$entry->{value}->{FULL_NAME};$entry->{value}->{INN};$entry->{value}->{CONTACT};$entry->{value}->{PHONE_FAX};$entry->{value}->{STATUS};$entry->{value}->{ATTACH};$entry->{value}->{DETACH};4;2;\n";
				
				#Запись копии старой строки, но с RECORD_ACTION=1 и ACTUAL_TO, DETACH=$begin_time.
				print Abonent "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{CONTRACT_DATE};$entry->{value}->{CONTRACT};$entry->{value}->{ACCOUNT};$entry->{value}->{ACTUAL_FROM};$begin_time;$entry->{value}->{ABONENT_TYPE};1;;;;$entry->{value}->{UNSTRUCT_NAME};$entry->{value}->{BIRTH_DATE};0;1;;;;$entry->{value}->{IDENT_CARD_SERIAL}$entry->{value}->{IDENT_CARD_DESCRIPTION};$entry->{value}->{BANK};$entry->{value}->{BANK_ACCOUNT};$entry->{value}->{FULL_NAME};$entry->{value}->{INN};$entry->{value}->{CONTACT};$entry->{value}->{PHONE_FAX};$entry->{value}->{STATUS};$entry->{value}->{ATTACH};$begin_time;4;1;\n";

				#Запись новой строки, с RECORD_ACTION=1 и ACTUAL_FROM, ATTACH=$begin_time, ACTUAL_TO, DETACH=$date_ended
                                print Abonent "$entry->{value}->{ABONENT_ID};$region_id;$axbills_array{$entry->{id}}->{CONTRACT_DATE};$axbills_array{$entry->{id}}->{CONTRACT_ID};$axbills_array{$entry->{id}}->{ACCOUNT};$begin_time;$date_ended;$axbills_array{$entry->{id}}->{ABONENT_TYPE};1;;;;$axbills_array{$entry->{id}}->{UNSTRUCT_NAME};$axbills_array{$entry->{id}}->{BIRTH_DATE};0;1;;;;$axbills_array{$entry->{id}}->{IDENT_CARD_SERIAL}$axbills_array{$entry->{id}}->{IDENT_CARD_DESCRIPTION};$axbills_array{$entry->{id}}->{BANK};$axbills_array{$entry->{id}}->{BANK_ACCOUNT};$axbills_array{$entry->{id}}->{FULL_NAME};$axbills_array{$entry->{id}}->{INN};$axbills_array{$entry->{id}}->{CONTACT};$axbills_array{$entry->{id}}->{PHONE_FAX};$axbills_array{$entry->{id}}->{STATUS};$begin_time;$date_ended;4;1;\n";

                                        my $sth = $dbh->prepare(qq{
                                                UPDATE SORM_ABONENT SET
                                                        CONTRACT_DATE = '$axbills_array{$entry->{id}}->{CONTRACT_DATE}',
							BANK = '$axbills_array{$entry->{id}}->{BANK}',
							BANK_ACCOUNT = '$axbills_array{$entry->{id}}->{BANK_ACCOUNT}',
							PHONE_FAX = '$axbills_array{$entry->{id}}->{PHONE_FAX}',
							INN = '$axbills_array{$entry->{id}}->{INN}',
                                                        CONTRACT = '$axbills_array{$entry->{id}}->{CONTRACT_ID}',
                                                        ACCOUNT = '$axbills_array{$entry->{id}}->{ACCOUNT}',
                                                        ABONENT_TYPE = '$axbills_array{$entry->{id}}->{ABONENT_TYPE}',
                                                        UNSTRUCT_NAME = '$axbills_array{$entry->{id}}->{UNSTRUCT_NAME}',
							FULL_NAME = '$axbills_array{$entry->{id}}->{FULL_NAME}',
                                                        BIRTH_DATE = '$axbills_array{$entry->{id}}->{BIRTH_DATE}',
                                                        IDENT_CARD_SERIAL = '$axbills_array{$entry->{id}}->{IDENT_CARD_SERIAL}',
                                                        IDENT_CARD_DESCRIPTION = '$axbills_array{$entry->{id}}->{IDENT_CARD_DESCRIPTION}',
							CONTACT = '$axbills_array{$entry->{id}}->{CONTACT}',
							COMPANY_ID = '$axbills_array{$entry->{id}}->{COMPANY_ID}',
                                                        STATUS = '$axbills_array{$entry->{id}}->{STATUS}',
							ATTACH = '$begin_time',
							DETACH = '$date_ended',
							ACTUAL_FROM = '$begin_time', 
							ACTUAL_TO = '$date_ended'
                                                        WHERE ABONENT_ID = '$axbills_array{$entry->{id}}->{ABONENT_ID}'});
					$sth->execute or die DBI->errstr if ($debug == '0');
				}


				#Abonent_addr
				if (defined($axbills_array{$entry->{id}}->{ZIP}) && defined($entry->{value}->{ZIP}) && $axbills_array{$entry->{id}}->{ZIP} ne $entry->{value}->{ZIP} ||
				defined($axbills_array{$entry->{id}}->{CITY}) && defined($entry->{value}->{CITY}) && $axbills_array{$entry->{id}}->{CITY} ne $entry->{value}->{CITY} ||
				defined($axbills_array{$entry->{id}}->{STREET}) && defined($entry->{value}->{STREET}) && $axbills_array{$entry->{id}}->{STREET} ne $entry->{value}->{STREET} ||
				defined($axbills_array{$entry->{id}}->{BUILDING}) && defined($entry->{value}->{BUILDING}) && $axbills_array{$entry->{id}}->{BUILDING} ne $entry->{value}->{BUILDING} ||
				defined($axbills_array{$entry->{id}}->{APARTMENT}) && defined($entry->{value}->{APARTMENT}) && $axbills_array{$entry->{id}}->{APARTMENT} ne $entry->{value}->{APARTMENT})
				{
					$need_update_db = 1;

					if ($abonent_addr_created == 0)
					{
					open(Abonent_addr, ">$location_file/ABONENT_ADDR_$file.txt") || die;
					print Abonent_addr "ABONENT_ID;REGION_ID;ADDRESS_TYPE_ID;ADDRESS_TYPE;ZIP;COUNTRY;REGION;ZONE;CITY;STREET;BUILDING;BUILD_SECT;APARTMENT;UNSTRUCT_INFO;BEGIN_TIME;END_TIME;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                                        $abonent_addr_created = 1;
					}

				#Удаление строки.Как старая, но с RECORD_ACTON=2.
				print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;0;0;$entry->{value}->{ZIP};$entry->{value}->{COUNTRY};$entry->{value}->{REGION};$entry->{value}->{ZONE};$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$entry->{value}->{ABONENT_ADDR_BEGIN_TIME};$entry->{value}->{ABONENT_ADDR_END_TIME};2;;\n";
				print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;3;0;$entry->{value}->{ZIP};$entry->{value}->{COUNTRY};$entry->{value}->{REGION};$entry->{value}->{ZONE};$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$entry->{value}->{ABONENT_ADDR_BEGIN_TIME};$entry->{value}->{ABONENT_ADDR_END_TIME};2;;\n";

				#Запись копии старой строки, но с RECORD_ACTION=1 и END_TIME=$begin_time.
				print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;0;0;$entry->{value}->{ZIP};$entry->{value}->{COUNTRY};$entry->{value}->{REGION};$entry->{value}->{ZONE};$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$entry->{value}->{ABONENT_ADDR_BEGIN_TIME};$begin_time;1;;\n";
				print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;3;0;$entry->{value}->{ZIP};$entry->{value}->{COUNTRY};$entry->{value}->{REGION};$entry->{value}->{ZONE};$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$entry->{value}->{ABONENT_ADDR_BEGIN_TIME};$begin_time;1;;\n";

				#Запись новой строки, с RECORD_ACTION=1 и BEGIN_TIME=$begin_time, END_TIME=$date_ended
				print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;0;0;$axbills_array{$entry->{id}}->{ZIP};$entry->{value}->{COUNTRY};$entry->{value}->{REGION};$entry->{value}->{ZONE};$axbills_array{$entry->{id}}->{CITY};$axbills_array{$entry->{id}}->{STREET};$axbills_array{$entry->{id}}->{BUILDING};;$axbills_array{$entry->{id}}->{APARTMENT};;$begin_time;$date_ended;1;;\n";
				print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;3;0;$axbills_array{$entry->{id}}->{ZIP};$entry->{value}->{COUNTRY};$entry->{value}->{REGION};$entry->{value}->{ZONE};$axbills_array{$entry->{id}}->{CITY};$axbills_array{$entry->{id}}->{STREET};$axbills_array{$entry->{id}}->{BUILDING};;$axbills_array{$entry->{id}}->{APARTMENT};;$begin_time;$date_ended;1;;\n";

                                        my $sth = $dbh->prepare(qq{
                                                UPDATE SORM_ABONENT SET
                                                        ZIP = '$axbills_array{$entry->{id}}->{ZIP}',
                                                        CITY = '$axbills_array{$entry->{id}}->{CITY}',
                                                        STREET = '$axbills_array{$entry->{id}}->{STREET}',
                                                        BUILDING = '$axbills_array{$entry->{id}}->{BUILDING}',
                                                        APARTMENT = '$axbills_array{$entry->{id}}->{APARTMENT}',
							ABONENT_ADDR_BEGIN_TIME = '$begin_time',
							ABONENT_ADDR_END_TIME = '$date_ended'
                                                        WHERE ABONENT_ID = '$axbills_array{$entry->{id}}->{ABONENT_ID}'});
					$sth->execute or die DBI->errstr if ($debug == '0');
				}

				#Abonent_srv
				if (defined($axbills_array{$entry->{id}}->{TP_ID}) && defined($entry->{value}->{TP_ID}) && $axbills_array{$entry->{id}}->{TP_ID} ne $entry->{value}->{TP_ID} || 
				defined($axbills_array{$entry->{id}}->{CONTRACT_ID}) && defined($entry->{value}->{CONTRACT}) && $axbills_array{$entry->{id}}->{CONTRACT_ID} ne $entry->{value}->{CONTRACT})
				{
					$need_update_db = 1;

					if ($abonent_srv_created == 0)
					{
					open(Abonent_srv, ">$location_file/ABONENT_SRV_$file.txt") || die;
					print Abonent_srv "ABONENT_ID;REGION_ID;ID;BEGIN_TIME;END_TIME;PARAMETER;SRV_CONTRACT;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                                        $abonent_srv_created = 1;
					}

				#Удаление строки.Как старая, но с RECORD_ACTON=2.
				print Abonent_srv "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{TP_ID};$entry->{value}->{ABONENT_SRV_BEGIN_TIME};$entry->{value}->{ABONENT_ADDR_END_TIME};$entry->{value}->{PARAMETER};$entry->{value}->{CONTRACT};2;;\n";

				#Запись копии старой строки, но с RECORD_ACTION=1 и END_TIME=internet_main_updated.
				print Abonent_srv "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{TP_ID};$entry->{value}->{ABONENT_SRV_BEGIN_TIME};$axbills_array{$entry->{id}}->{internet_main_updated};$entry->{value}->{PARAMETER};$entry->{value}->{CONTRACT};1;;\n";

				#Запись новой строки, с RECORD_ACTION=1 и BEGIN_TIME=internet_main_updated, END_TIME=$date_ended
				print Abonent_srv "$entry->{value}->{ABONENT_ID};$region_id;$axbills_array{$entry->{id}}->{TP_ID};$axbills_array{$entry->{id}}->{internet_main_updated};$date_ended;$axbills_array{$entry->{id}}->{PARAMETER};$axbills_array{$entry->{id}}->{CONTRACT_ID};1;;\n";

					my $sth = $dbh->prepare(qq{
						UPDATE SORM_ABONENT SET 
							TP_ID = '$axbills_array{$entry->{id}}->{TP_ID}',
							PARAMETER = '$axbills_array{$entry->{id}}->{PARAMETER}',
							ABONENT_SRV_BEGIN_TIME = '$axbills_array{$entry->{id}}->{internet_main_updated}',
							ABONENT_SRV_END_TIME = '$date_ended' 
							WHERE ABONENT_ID = '$axbills_array{$entry->{id}}->{ABONENT_ID}'});
					$sth->execute or die DBI->errstr if ($debug == '0');
				}

				#Abonent_ident
				if (defined($axbills_array{$entry->{id}}->{PHONE}) && defined($entry->{value}->{PHONE}) && $axbills_array{$entry->{id}}->{PHONE} ne $entry->{value}->{PHONE} ||
				defined($axbills_array{$entry->{id}}->{IPV4_MASK}) && defined($entry->{value}->{IPV4_MASK}) && $axbills_array{$entry->{id}}->{IPV4_MASK} ne $entry->{value}->{IPV4_MASK} ||
				defined($axbills_array{$entry->{id}}->{E_MAIL}) && defined($entry->{value}->{E_MAIL}) && $axbills_array{$entry->{id}}->{E_MAIL} ne $entry->{value}->{E_MAIL} ||
				defined($axbills_array{$entry->{id}}->{IPV4}) && defined($entry->{value}->{IPV4}) && $axbills_array{$entry->{id}}->{IPV4} ne $entry->{value}->{IPV4})
                                {
                                        $need_update_db = 1;

                                        if ($abonent_ident_created == 0)
                                        {
					open(Abonent_ident, ">$location_file/ABONENT_IDENT_$file.txt") || die;
                                        print Abonent_ident "ABONENT_ID;REGION_ID;IDENT_TYPE;PHONE;INTERNAL_NUMBER;IMSI;IMEI;ICC;MIN;ESN;EQUIPMENT_TYPE;MAC;VPI;VCI;LOGIN;E_MAIL;PIN;USER_DOMAIN;RESERVED;ORIGINATOR_NAME;IP_TYPE;IPV4;IPV6;IPV4_MASK;IPV6_MASK;BEGIN_TIME;END_TIME;LINE_OBJECT;LINE_CROSS;LINE_BLOCK;LINE_PAIR;LINE_RESERVED;LOC_TYPE;LOC_LAC;LOC_CELL;LOC_TA;LOC_CELL_WIRELESS;LOC_MAC;LOC_LATITUDE;LOC_LONGITUDE;LOC_PROJECTION_TYPE;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                                        $abonent_ident_created = 1;
                                        }
				if ($entry->{value}->{IPV4_NTOA} ne '0.0.0.0')
				{
                                my $to_hex_old = new Net::IP ($entry->{value}->{IPV4_NTOA});
                                my @hexip_old = split(/x/, $to_hex_old->hexip());
                                $clean_hex_ip_old = uc($hexip_old[1]);

                		#Добьем нулями до 8 байт
                		for (;;)
                		{
                        		if ((length($clean_hex_ip_old) < 8) && length($clean_hex_ip_old) > 4)
                        		{
                                		$clean_hex_ip_old = "0$clean_hex_ip_old";
                        		} else {last};
                		}

				} else {
                                $clean_hex_ip_old = '';
				}

				if ($axbills_array{$entry->{id}}->{IPV4_NTOA} ne '0.0.0.0')
				{
				my $to_hex = new Net::IP ($axbills_array{$entry->{id}}->{IPV4_NTOA});
                                my @hexip = split(/x/, $to_hex->hexip());
                                $clean_hex_ip_new = uc($hexip[1]);

                                #Добьем нулями до 8 байт
                                for (;;)
                                {
                                        if ((length($clean_hex_ip_new) < 8) && length($clean_hex_ip_new) > 4)
                                        {
                                                $clean_hex_ip_new = "0$clean_hex_ip_new";
                                        } else {last};
                                }
				} else {
				$clean_hex_ip_new = '';
				}


		#			print "IDENT Changed ON $entry->{id}";
				#Удаление строки.Как старая, но с RECORD_ACTON=2.
				print Abonent_ident "$entry->{value}->{ABONENT_ID};$region_id;5;$entry->{value}->{PHONE};;;;;;;0;;;;$entry->{value}->{LOGIN};$entry->{value}->{E_MAIL};;;;;0;$clean_hex_ip_old;;FFFFFFFF;;$entry->{value}->{ABONENT_IDENT_BEGIN_TIME};$entry->{value}->{ABONENT_IDENT_END_TIME};;;;;;;;;;;;;;;2;;\n";

				#Запись копии старой строки, но с RECORD_ACTION=1 и END_TIME=$begin_time.
				print Abonent_ident "$entry->{value}->{ABONENT_ID};$region_id;5;$entry->{value}->{PHONE};;;;;;;0;;;;$entry->{value}->{LOGIN};$entry->{value}->{E_MAIL};;;;;0;$clean_hex_ip_old;;FFFFFFFF;;$entry->{value}->{ABONENT_IDENT_BEGIN_TIME};$begin_time;;;;;;;;;;;;;;;1;;\n";

				#Запись новой строки, с RECORD_ACTION=1 и BEGIN_TIME=$begin_time, END_TIME=$date_ended
				print Abonent_ident "$entry->{value}->{ABONENT_ID};$region_id;5;$axbills_array{$entry->{id}}->{PHONE};;;;;;;0;;;;$axbills_array{$entry->{id}}->{LOGIN};$axbills_array{$entry->{id}}->{E_MAIL};;;;;0;$clean_hex_ip_new;;FFFFFFFF;;$begin_time;$date_ended;;;;;;;;;;;;;;;1;;\n";

					$sth = $dbh->prepare(qq{
						UPDATE SORM_ABONENT SET
							PHONE = '$axbills_array{$entry->{id}}->{PHONE}',
							LOGIN = '$axbills_array{$entry->{id}}->{LOGIN}',
							ABONENT_IDENT_BEGIN_TIME = '$begin_time',
                                                        ABONENT_IDENT_END_TIME = '$date_ended',
							E_MAIL = '$axbills_array{$entry->{id}}->{E_MAIL}',
							IPV4 = '$axbills_array{$entry->{id}}->{IPV4}',
							IPV4_MASK = '$axbills_array{$entry->{id}}->{IPV4_MASK}'
							WHERE ABONENT_ID = '$axbills_array{$entry->{id}}->{ABONENT_ID}'});
					$sth->execute or die DBI->errstr if ($debug == '0');
				}

				#Есть изменения
				if ($need_update_db == 1) 
				{
					$count_updates++;

#print Dumper $axbills_array{$entry->{id}};
					$sth = $dbh->prepare(qq{
                                                UPDATE SORM_ABONENT SET
                                                        users_updated = '$axbills_array{$entry->{id}}->{users_updated}',
                                                        users_pi_updated = '$axbills_array{$entry->{id}}->{users_pi_updated}',
                                                        internet_main_updated = '$axbills_array{$entry->{id}}->{internet_main_updated}',
							companies_updated = '$axbills_array{$entry->{id}}->{companies_updated}'
                                                        WHERE ABONENT_ID = '$axbills_array{$entry->{id}}->{ABONENT_ID}'});
                                        $sth->execute or die DBI->errstr if ($debug == '0');
				}

				delete $axbills_array{$entry->{id}};
			}
#Удаляем несуществующих абонентов
		} elsif (($entry->{id} && !exists $axbills_array{$entry->{id}}) && $entry->{id} > '0')
			{

			if ($abonent_created == 0)
			{
			open(Abonent, ">$location_file/ABONENT_$file.txt") || die;
			print Abonent "ID;REGION_ID;CONTRACT_DATE;CONTRACT;ACCOUNT;ACTUAL_FROM;ACTUAL_TO;ABONENT_TYPE;NAME_INFO_TYPE;FAMILY_NAME;GIVEN_NAME;INITIAL_NAME;UNSTRUCT_NAME;BIRTH_DATE;IDENT_CARD_TYPE_ID;IDENT_CARD_TYPE;IDENT_CARD_SERIAL;IDENT_CARD_NUMBER;IDENT_CARD_DESCRIPTION;IDENT_CARD_UNSTRUCT;BANK;BANK_ACCOUNT;FULL_NAME;INN;CONTACT;PHONE_FAX;STATUS;ATTACH;DETACH;NETWORK_TYPE;RECORD_ACTION;INTERNAL_ID1\n";
                        $abonent_created = 1;
			}

                        if ($abonent_addr_created == 0)
                        {
			open(Abonent_addr, ">$location_file/ABONENT_ADDR_$file.txt") || die;
                        print Abonent_addr "ABONENT_ID;REGION_ID;ADDRESS_TYPE_ID;ADDRESS_TYPE;ZIP;COUNTRY;REGION;ZONE;CITY;STREET;BUILDING;BUILD_SECT;APARTMENT;UNSTRUCT_INFO;BEGIN_TIME;END_TIME;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                        $abonent_addr_created = 1;
                        }
                         
  	                if ($abonent_srv_created == 0)
                        {
		        open(Abonent_srv, ">$location_file/ABONENT_SRV_$file.txt") || die;
                        print Abonent_srv "ABONENT_ID;REGION_ID;ID;BEGIN_TIME;END_TIME;PARAMETER;SRV_CONTRACT;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                        $abonent_srv_created = 1;
                        }

                        if ($abonent_ident_created == 0)
                        {
		        open(Abonent_ident, ">$location_file/ABONENT_IDENT_$file.txt") || die;
                        print Abonent_ident "ABONENT_ID;REGION_ID;IDENT_TYPE;PHONE;INTERNAL_NUMBER;IMSI;IMEI;ICC;MIN;ESN;EQUIPMENT_TYPE;MAC;VPI;VCI;LOGIN;E_MAIL;PIN;USER_DOMAIN;RESERVED;ORIGINATOR_NAME;IP_TYPE;IPV4;IPV6;IPV4_MASK;IPV6_MASK;BEGIN_TIME;END_TIME;LINE_OBJECT;LINE_CROSS;LINE_BLOCK;LINE_PAIR;LINE_RESERVED;LOC_TYPE;LOC_LAC;LOC_CELL;LOC_TA;LOC_CELL_WIRELESS;LOC_MAC;LOC_LATITUDE;LOC_LONGITUDE;LOC_PROJECTION_TYPE;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                        $abonent_ident_created = 1;
                        }

			if ($entry->{value}->{IPV4_NTOA} ne '0.0.0.0')
                        	{
                                my $to_hex_old = new Net::IP ($entry->{value}->{IPV4_NTOA});
                                my @hexip_old = split(/x/, $to_hex_old->hexip());
                                $clean_hex_ip_old = uc($hexip_old[1]);

                                #Добьем нулями до 8 байт
                                for (;;)
                                {
                                        if ((length($clean_hex_ip_old) < 8) && length($clean_hex_ip_old) > 4)
                                        {
                                                $clean_hex_ip_old = "0$clean_hex_ip_old";
                                        } else {last};
                                }
                                } else {
                                $clean_hex_ip_old = '';
                                }

                        print Abonent "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{CONTRACT_DATE};$entry->{value}->{CONTRACT_ID};$entry->{value}->{ACCOUNT};$begin_time;$date_ended;$entry->{value}->{ABONENT_TYPE};1;;;;$entry->{value}->{UNSTRUCT_NAME};$entry->{value}->{BIRTH_DATE};0;1;;;;$entry->{value}->{IDENT_CARD_SERIAL}$entry->{value}->{IDENT_CARD_DESCRIPTION};$entry->{value}->{BANK};$entry->{value}->{BANK_ACCOUNT};$entry->{value}->{FULL_NAME};$entry->{value}->{INN};$entry->{value}->{CONTACT};$entry->{value}->{PHONE_FAX};$entry->{value}->{STATUS};$begin_time;$date_ended;4;2;\n";
			print Abonent "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{CONTRACT_DATE};$entry->{value}->{CONTRACT_ID};$entry->{value}->{ACCOUNT};$begin_time;$entry->{value}->{CURRENT_TIMESTAMP_3};$entry->{value}->{ABONENT_TYPE};1;;;;$entry->{value}->{UNSTRUCT_NAME};$entry->{value}->{BIRTH_DATE};0;1;;;;$entry->{value}->{IDENT_CARD_SERIAL}$entry->{value}->{IDENT_CARD_DESCRIPTION};$entry->{value}->{BANK};$entry->{value}->{BANK_ACCOUNT};$entry->{value}->{FULL_NAME};$entry->{value}->{INN};$entry->{value}->{CONTACT};$entry->{value}->{PHONE_FAX};$entry->{value}->{STATUS};$begin_time;$entry->{value}->{CURRENT_TIMESTAMP_3};4;1;\n";

                        print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;0;0;$entry->{value}->{ZIP};$country;$region;$zone;$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$begin_time;$date_ended;2;;\n";
                        print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;0;0;$entry->{value}->{ZIP};$country;$region;$zone;$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$begin_time;$entry->{value}->{CURRENT_TIMESTAMP_3};1;;\n";
                        print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;3;0;$entry->{value}->{ZIP};$country;$region;$zone;$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$begin_time;$date_ended;2;;\n";
                        print Abonent_addr "$entry->{value}->{ABONENT_ID};$region_id;3;0;$entry->{value}->{ZIP};$country;$region;$zone;$entry->{value}->{CITY};$entry->{value}->{STREET};$entry->{value}->{BUILDING};;$entry->{value}->{APARTMENT};;$begin_time;$entry->{value}->{CURRENT_TIMESTAMP_3};1;;\n";

                        print Abonent_srv "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{TP_ID};$begin_time;$date_ended;$entry->{value}->{PARAMETER};$entry->{value}->{CONTRACT_ID};2;;\n";
                        print Abonent_srv "$entry->{value}->{ABONENT_ID};$region_id;$entry->{value}->{TP_ID};$begin_time;$entry->{value}->{CURRENT_TIMESTAMP_3};$entry->{value}->{PARAMETER};$entry->{value}->{CONTRACT_ID};1;;\n";

                        print Abonent_ident "$entry->{value}->{ABONENT_ID};$region_id;5;$entry->{value}->{PHONE};;;;;;;0;;;;$entry->{value}->{LOGIN};$entry->{value}->{E_MAIL};;;;;0;$clean_hex_ip_old;;FFFFFFFF;;$begin_time;$date_ended;;;;;;;;;;;;;;;2;;\n";
                        print Abonent_ident "$entry->{value}->{ABONENT_ID};$region_id;5;$entry->{value}->{PHONE};;;;;;;0;;;;$entry->{value}->{LOGIN};$entry->{value}->{E_MAIL};;;;;0;$clean_hex_ip_old;;FFFFFFFF;;$begin_time;$entry->{value}->{CURRENT_TIMESTAMP_3};;;;;;;;;;;;;;;1;;\n";

                        my $sth = $dbh->prepare(qq{DELETE FROM SORM_ABONENT WHERE ABONENT_ID = '$entry->{id}';
                        });
                        $sth->execute() if ($debug == '0');
			}
	}
	@new_entries = values %axbills_array;

	printf "=============UPDATE Abonent Data=========\n" if ($debug == '1');
	print Dumper \@changed_entries if ($debug == '1');
	printf "UPDATED $count_updates rows\n";

	printf "=============NEW Abonent Data=========\n" if ($debug == '1');
#Новый абонент
        foreach my $new_entry (@new_entries)
        {
		if ($new_entry)
		{
                                $new_entry->{UNSTRUCT_NAME} //= q{};$new_entry->{UNSTRUCT_NAME} =~ s/[;)(]/ /g;
                                $new_entry->{BANK} //= q{};$new_entry->{BANK} =~ s/[;)(]/ /g;
                                $new_entry->{CONTRACT_DATE} //= q{};$new_entry->{CONTRACT_DATE} =~ s/[;)(]/ /g;
                                $new_entry->{BANK_ACCOUNT} //= q{};$new_entry->{BANK_ACCOUNT} =~ s/[;)(]/ /g;
                                $new_entry->{IDENT_CARD_DESCRIPTION} //= q{};$new_entry->{IDENT_CARD_DESCRIPTION} =~ s/[;)(]/ /g;
                                $new_entry->{IDENT_CARD_SERIAL} //= q{};$new_entry->{IDENT_CARD_SERIAL} =~ s/[;)(]/ /g;
                                $new_entry->{BIRTH_DATE} //= q{};$new_entry->{BIRTH_DATE} =~ s/[;)(]/ /g;
                                $new_entry->{INN} //= q{};$new_entry->{INN} =~ s/[;)(]/ /g;
                                $new_entry->{ACCOUNT} //= q{};$new_entry->{ACCOUNT} =~ s/[;)(]/ /g;
                                $new_entry->{CONTACT} //= q{};$new_entry->{CONTACT} =~ s/[;)(]/ /g;
                                $new_entry->{FULL_NAME} //= q{};$new_entry->{FULL_NAME} =~ s/[;)(]/ /g;
                                $new_entry->{CONTRACT_ID} //= q{};$new_entry->{CONTRACT_ID} =~ s/[;)(]/ /g;
                                $new_entry->{PHONE_FAX} //= q{};$new_entry->{PHONE_FAX} =~ s/[;)(]/ /g;
                                $new_entry->{ZIP} //= q{};$new_entry->{ZIP} =~ s/[;)(]/ /g;
                                $new_entry->{CITY} //= q{};$new_entry->{CITY} =~ s/[;)(]/ /g;
                                $new_entry->{STREET} //= q{};$new_entry->{STREET} =~ s/[;)(]/ /g;
                                $new_entry->{BUILDING} //= q{};$new_entry->{BUILDING} =~ s/[;)(]/ /g;
                                $new_entry->{APARTMENT} //= q{};$new_entry->{APARTMENT} =~ s/[;)(]/ /g;
                                $new_entry->{PARAMETER} //= q{};$new_entry->{PARAMETER} =~ s/[;)(]/ /g;
                                $new_entry->{PHONE} //= q{};$new_entry->{PHONE} =~ s/[;)(]/ /g;
                                $new_entry->{E_MAIL} //= q{};$new_entry->{E_MAIL} =~ s/[;)(]/ /g;
                        if ($abonent_created == 0)
                        {
                        open(Abonent, ">$location_file/ABONENT_$file.txt") || die;
                        print Abonent "ID;REGION_ID;CONTRACT_DATE;CONTRACT;ACCOUNT;ACTUAL_FROM;ACTUAL_TO;ABONENT_TYPE;NAME_INFO_TYPE;FAMILY_NAME;GIVEN_NAME;INITIAL_NAME;UNSTRUCT_NAME;BIRTH_DATE;IDENT_CARD_TYPE_ID;IDENT_CARD_TYPE;IDENT_CARD_SERIAL;IDENT_CARD_NUMBER;IDENT_CARD_DESCRIPTION;IDENT_CARD_UNSTRUCT;BANK;BANK_ACCOUNT;FULL_NAME;INN;CONTACT;PHONE_FAX;STATUS;ATTACH;DETACH;NETWORK_TYPE;RECORD_ACTION;INTERNAL_ID1\n";
                        $abonent_created = 1;
                        }

                        if ($abonent_addr_created == 0)
                        {
                        open(Abonent_addr, ">$location_file/ABONENT_ADDR_$file.txt") || die;
                        print Abonent_addr "ABONENT_ID;REGION_ID;ADDRESS_TYPE_ID;ADDRESS_TYPE;ZIP;COUNTRY;REGION;ZONE;CITY;STREET;BUILDING;BUILD_SECT;APARTMENT;UNSTRUCT_INFO;BEGIN_TIME;END_TIME;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                        $abonent_addr_created = 1;
                        }

                        if ($abonent_srv_created == 0)
                        {
                        open(Abonent_srv, ">$location_file/ABONENT_SRV_$file.txt") || die;
                        print Abonent_srv "ABONENT_ID;REGION_ID;ID;BEGIN_TIME;END_TIME;PARAMETER;SRV_CONTRACT;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                        $abonent_srv_created = 1;
                        }

                        if ($abonent_ident_created == 0)
                        {
                        open(Abonent_ident, ">$location_file/ABONENT_IDENT_$file.txt") || die;
                        print Abonent_ident "ABONENT_ID;REGION_ID;IDENT_TYPE;PHONE;INTERNAL_NUMBER;IMSI;IMEI;ICC;MIN;ESN;EQUIPMENT_TYPE;MAC;VPI;VCI;LOGIN;E_MAIL;PIN;USER_DOMAIN;RESERVED;ORIGINATOR_NAME;IP_TYPE;IPV4;IPV6;IPV4_MASK;IPV6_MASK;BEGIN_TIME;END_TIME;LINE_OBJECT;LINE_CROSS;LINE_BLOCK;LINE_PAIR;LINE_RESERVED;LOC_TYPE;LOC_LAC;LOC_CELL;LOC_TA;LOC_CELL_WIRELESS;LOC_MAC;LOC_LATITUDE;LOC_LONGITUDE;LOC_PROJECTION_TYPE;RECORD_ACTION;INTERNAL_ID1;INTERNAL_ID2\n";
                        $abonent_ident_created = 1;
                        }

			print Abonent "$new_entry->{ABONENT_ID};$region_id;$new_entry->{CONTRACT_DATE};$new_entry->{CONTRACT_ID};$new_entry->{ACCOUNT};$new_entry->{CONTRACT_DATE} 00:00:00;$date_ended;$new_entry->{ABONENT_TYPE};1;;;;$new_entry->{UNSTRUCT_NAME};$new_entry->{BIRTH_DATE};0;1;;;;$new_entry->{IDENT_CARD_SERIAL}$new_entry->{IDENT_CARD_DESCRIPTION};$new_entry->{BANK};$new_entry->{BANK_ACCOUNT};$new_entry->{FULL_NAME};$new_entry->{INN};$new_entry->{CONTACT};$new_entry->{PHONE_FAX};$new_entry->{STATUS};$new_entry->{CONTRACT_DATE} 00:00:00;$date_ended;4;1;\n";
			print Abonent_addr "$new_entry->{ABONENT_ID};$region_id;0;0;$new_entry->{ZIP};$country;$region;$zone;$new_entry->{CITY};$new_entry->{STREET};$new_entry->{BUILDING};;$new_entry->{APARTMENT};;$new_entry->{CONTRACT_DATE} 00:00:00;$date_ended;1;;\n";
			print Abonent_addr "$new_entry->{ABONENT_ID};$region_id;3;0;$new_entry->{ZIP};$country;$region;$zone;$new_entry->{CITY};$new_entry->{STREET};$new_entry->{BUILDING};;$new_entry->{APARTMENT};;$new_entry->{CONTRACT_DATE} 00:00:00;$date_ended;1;;\n";
			print Abonent_srv "$new_entry->{ABONENT_ID};$region_id;$new_entry->{TP_ID};$new_entry->{CONTRACT_DATE} 00:00:00;$date_ended;$new_entry->{PARAMETER};$new_entry->{CONTRACT_ID};1;;\n";

			if ($new_entry->{IPV4_NTOA} ne '0.0.0.0')
				{
                                my $to_hex = new Net::IP ($new_entry->{IPV4_NTOA});
                                my @hexip = split(/x/, $to_hex->hexip());
                                $clean_hex_ip_new = uc($hexip[1]);
			
                                #Добьем нулями до 8 байт
                                for (;;)
                                {
                                        if ((length($clean_hex_ip_new) < 8) && length($clean_hex_ip_new) > 4)
                                        {
                                                $clean_hex_ip_new = "0$clean_hex_ip_new";
                                        } else {last};
                                }
				} else {
                                $clean_hex_ip_new = '';
				}

			print Abonent_ident "$new_entry->{ABONENT_ID};$region_id;5;$new_entry->{PHONE};;;;;;;0;;;;$new_entry->{LOGIN};$new_entry->{E_MAIL};;;;;0;$clean_hex_ip_new;;FFFFFFFF;;$new_entry->{CONTRACT_DATE} 00:00:00;$date_ended;;;;;;;;;;;;;;;1;;\n";
			#print Dumper \$new_entry;

			my $sth = $dbh->prepare(qq{INSERT INTO SORM_ABONENT (ABONENT_ID, CONTRACT_DATE, CONTRACT, ACCOUNT, ABONENT_TYPE, UNSTRUCT_NAME, BIRTH_DATE,
        	        IDENT_CARD_TYPE_ID, IDENT_CARD_SERIAL, IDENT_CARD_DESCRIPTION, BANK, BANK_ACCOUNT, FULL_NAME, INN, CONTACT, PHONE_FAX,
             		STATUS, ATTACH, DETACH, NETWORK_TYPE, ACTUAL_FROM, ACTUAL_TO, ZIP, COUNTRY, REGION, ZONE,CITY, 
			STREET, BUILDING, APARTMENT, ABONENT_ADDR_BEGIN_TIME, ABONENT_ADDR_END_TIME, TP_ID, ABONENT_SRV_BEGIN_TIME, ABONENT_SRV_END_TIME, PARAMETER, 
			PHONE, EQUIPMENT_TYPE, LOGIN, E_MAIL, IP_TYPE, IPV4, IPV4_MASK, ABONENT_IDENT_BEGIN_TIME, ABONENT_IDENT_END_TIME,
			users_pi_updated, users_updated, internet_main_updated, companies_updated)
                        VALUES
                        	('$new_entry->{ABONENT_ID}', '$new_entry->{CONTRACT_DATE}', '$new_entry->{CONTRACT_ID}', 
				'$new_entry->{ACCOUNT}', '$new_entry->{ABONENT_TYPE}', '$new_entry->{UNSTRUCT_NAME}', '$new_entry->{BIRTH_DATE}', 
				'0', '$new_entry->{IDENT_CARD_SERIAL}', '$new_entry->{IDENT_CARD_DESCRIPTION}', '$new_entry->{BANK}', 
				'$new_entry->{BANK_ACCOUNT}', 
				'$new_entry->{FULL_NAME}', '$new_entry->{INN}', '$new_entry->{CONTACT}', '$new_entry->{PHONE_FAX}', 
				'$new_entry->{STATUS}', 
				'$new_entry->{CONTRACT_DATE}', '$date_ended', '4', '$new_entry->{CONTRACT_DATE} 00:00:00', '$date_ended', 
				'$new_entry->{ZIP}', '$country', '$region', 
				'$zone', '$new_entry->{CITY}', 
				'$new_entry->{STREET}', '$new_entry->{BUILDING}', '$new_entry->{APARTMENT}', 
				'$new_entry->{CONTRACT_DATE} 00:00:00', 
				'$date_ended', '$new_entry->{TP_ID}',
                                '$new_entry->{CONTRACT_DATE} 00:00:00','$date_ended', '$new_entry->{PARAMETER}', '$new_entry->{PHONE}', '0', 
				'$new_entry->{LOGIN}', '$new_entry->{E_MAIL}', '0', '$new_entry->{IPV4}', '$new_entry->{IPV4_MASK}', 
				'$new_entry->{CONTRACT_DATE} 00:00:00', '$date_ended', '$new_entry->{users_pi_updated}', 
				'$new_entry->{users_updated}', '$new_entry->{internet_main_updated}', '$new_entry->{companies_updated}')
		        });
        		$sth->execute() if ($debug == '0');
		}
	}
}



#PAYMENTS
sub paymentsGetOldData {
#Платежи из базы скрипта

	my $self = shift;

        my @db_p_array;
	my %axbills_p_array;
	my %axbills_p_array1;
        my @changed_p_entries;
        my $count_updates = 0;
        my @new_p_entries;
	my @del_p_entries;
	my $file_created = 0;

        my $region_id = $self->{conf}->{SORM_ISP_ID} || q{};
        my $zip = $self->{conf}->{OFFICE_ZIP} || q{};
        my $country = $self->{conf}->{SORM_COUNTRY} || q{};
        my $region = $self->{conf}->{SORM_REGION} || q{};
        my $zone = $self->{conf}->{SORM_ZONE} || q{};
	my $city = $self->{conf}->{OFFICE_CITY} || q{};
	my $street = $self->{conf}->{OFFICE_STREET} || q{};
	my $build = $self->{conf}->{OFFICE_BUILD} || q{};
	my $apart = $self->{conf}->{OFFICE_APART} || q{};
	my $time_offset = $self->{conf}->{SORM_TIME_OFFSET} || '-3'; #Moscow

	my DBI $dbh = $self->{db}->{db};

	printf "======PAYMENTS SECTION=======\n";

        my $sth = $dbh->prepare(qq{SELECT PAYMENT_TYPE, PAY_TYPE_ID, PAYMENT_DATE, AMOUNT, AMOUNT_CURRENCY, ACCOUNT,
                                SORM_PAYMENT.ABONENT_ID AS ABONENT_ID, SORM_PAYMENT.COUNTRY, SORM_PAYMENT.REGION, SORM_PAYMENT.ZONE, SORM_PAYMENT.STREET, 
				SORM_PAYMENT.BUILDING, SORM_PAYMENT.APARTMENT, axbills_id, SORM_PAYMENT.PHONE
                                FROM SORM_PAYMENT
				LEFT JOIN SORM_ABONENT ON SORM_PAYMENT.ABONENT_ID = SORM_ABONENT.ABONENT_ID
                                ORDER BY SORM_PAYMENT.axbills_id ASC
				});
        $sth->execute or die DBI->errstr;

        while(my $old_p_data = $sth->fetchrow_hashref())
        {
		 push(@db_p_array, $old_p_data);
        }

#Платежи из Абиллса
        $sth = $dbh->prepare(qq{SELECT payments.method AS PAYMENT_TYPE, 
		DATE_ADD(payments.date, INTERVAL $time_offset HOUR) AS PAYMENT_DATE,
		payments.amount AS AMOUNT, 
		(SELECT value from users_contacts WHERE type_id=2 AND users_contacts.uid=payments.uid LIMIT 1) AS PHONE,
		payments.bill_id AS ACCOUNT, 
		payments.uid AS ABONENT_ID,
		payments.id AS axbills_id,
		users_pi.contract_id AS ACCOUNT,
		payments.method AS PAY_TYPE_ID,
		users_pi.zip AS ZIP
		FROM payments
		INNER JOIN users_pi ON users_pi.uid = payments.uid  
		ORDER BY payments.id ASC
		});
	$sth->execute or die DBI->errstr;
  
        while(my $new_p_data = $sth->fetchrow_hashref())
        {
		 $axbills_p_array{$new_p_data->{axbills_id}} = $new_p_data;
		 $axbills_p_array1{$new_p_data->{ABONENT_ID}} = $new_p_data;
        }

#Ищем совпадения, выпиливаем их
	foreach my $entry (@db_p_array)
	{
		if($entry->{axbills_id} && exists $axbills_p_array{$entry->{axbills_id}})
		{
			#Есть совпадение, удаляем из массива, т.к нужды добавлять в базу нет
			delete $axbills_p_array{$entry->{axbills_id}};

		} elsif ($entry->{axbills_id} && !exists $axbills_p_array{$entry->{axbills_id}} && defined ($axbills_p_array1{$entry->{ABONENT_ID}}->{ABONENT_ID}) && $axbills_p_array1{$entry->{ABONENT_ID}}->{ABONENT_ID} > 0) {

			if ($file_created == 0)
                        {
				open(Payments, ">$location_file/PAYMENT_$file.txt") || die;
                        	print Payments "REGION_ID;PAYMENT_TYPE;PAY_TYPE_ID;PAYMENT_DATE;AMOUNT;AMOUNT_CURRENCY;PHONE_NUMBER;ACCOUNT;ABONENT_ID;BANK_ACCOUNT;BANK_NAME;EXPRESS_CARD_NUMBER;TERMINAL_ID;TERMINAL_NUMBER;LATITUDE;LONGITUDE;PROJECTION_TYPE;CENTER_ID;DONATED_PHONE_NUMBER;DONATED_ACCOUNT;DONATED_INTERNAL_ID1;DONATED_INTERNAL_ID2;CARD_NUMBER;PAY_PARAMS;PERSON_RECIEVED;BANK_DIVISION_NAME;BANK_CARD_ID;ADDRESS_TYPE_ID;ADDRESS_TYPE;ZIP;COUNTRY;REGION;ZONE;CITY;STREET;BUILDING;BUILD_SECT;APARTMENT;UNSTRUCT_INFO;RECORD_ACTION\n";
                                $file_created = 1;
                        }

			#Ключ найден в базе скрипта, но не найден в Абиллсе, заносим в очередь на удаление, но только если UID существует в AXbills
        	        print Payments "$region_id;83;$entry->{PAY_TYPE_ID};$entry->{PAYMENT_DATE};$entry->{AMOUNT};;$entry->{PHONE};$entry->{ACCOUNT};$entry->{ABONENT_ID};;;;;;;;;0;;;;;;;;;;0;0;$entry->{ZIP};$entry->{COUNTRY};$entry->{REGION};$entry->{ZONE};$entry->{CITY};$entry->{STREET};$entry->{BUILDING};;$entry->{APARTMENT};;2\n";

                        my $sth = $dbh->prepare(qq{DELETE FROM SORM_PAYMENT WHERE axbills_id = '$entry->{axbills_id}'
                        });
                        $sth->execute() if ($debug == '0');

                }
	}
	@new_p_entries = values %axbills_p_array;

	printf "=========ADDING entires=============\n" if ($debug == '1');
#        print Dumper \@new_p_entries;# if ($debug == '1');

        foreach my $new_entry (@new_p_entries)
        {
                if (defined($new_entry->{axbills_id}) && $new_entry->{AMOUNT} > '0')
                {
			if ($file_created == 0)
                        {
				open(Payments, ">$location_file/PAYMENT_$file.txt") || die;
                                print Payments "REGION_ID;PAYMENT_TYPE;PAY_TYPE_ID;PAYMENT_DATE;AMOUNT;AMOUNT_CURRENCY;PHONE_NUMBER;ACCOUNT;ABONENT_ID;BANK_ACCOUNT;BANK_NAME;EXPRESS_CARD_NUMBER;TERMINAL_ID;TERMINAL_NUMBER;LATITUDE;LONGITUDE;PROJECTION_TYPE;CENTER_ID;DONATED_PHONE_NUMBER;DONATED_ACCOUNT;DONATED_INTERNAL_ID1;DONATED_INTERNAL_ID2;CARD_NUMBER;PAY_PARAMS;PERSON_RECIEVED;BANK_DIVISION_NAME;BANK_CARD_ID;ADDRESS_TYPE_ID;ADDRESS_TYPE;ZIP;COUNTRY;REGION;ZONE;CITY;STREET;BUILDING;BUILD_SECT;APARTMENT;UNSTRUCT_INFO;RECORD_ACTION\n";
                                $file_created = 1;
                        }

			print Payments "$region_id;83;$new_entry->{PAY_TYPE_ID};$new_entry->{PAYMENT_DATE};$new_entry->{AMOUNT};;$new_entry->{PHONE};$new_entry->{ACCOUNT};$new_entry->{ABONENT_ID};;;;;;;;;0;;;;;;;;;;0;0;$new_entry->{ZIP};$country;$region;$zone;$city;$street;$build;;$apart;;1\n";

                        my $sth = $dbh->prepare(qq{INSERT INTO SORM_PAYMENT (PAYMENT_TYPE, PAY_TYPE_ID, PAYMENT_DATE, AMOUNT, ABONENT_ID, axbills_id, COUNTRY, REGION,
				ZONE, CITY, STREET, BUILDING, APARTMENT, PHONE, ZIP) 
					VALUES ('83', '$new_entry->{PAY_TYPE_ID}', '$new_entry->{PAYMENT_DATE}', 
						'$new_entry->{AMOUNT}', '$new_entry->{ABONENT_ID}',
						'$new_entry->{axbills_id}', '$country', '$region', '$zone', '$city', '$street', '$build', '$apart', 
						'$new_entry->{PHONE}', '$zip');
			});
                        $sth->execute() if ($debug == '0');

		}
	}
	return;
}

#**********************************************************
=head2 IP_PLAN_report()

=cut
#**********************************************************
sub ipplan_report {

	 my $self = shift;
	 my $region_id = $self->{conf}->{SORM_ISP_ID} || q{};
	 my $time_offset = $self->{conf}->{SORM_TIME_OFFSET} || '-3'; #Moscow

	 my DBI $dbh = $self->{db}->{db};
#Export to Files
	 my @cidr_list;

         my $sth = $dbh->prepare(qq{SELECT id, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL $time_offset HOUR) AS CURRENT, DESCRIPTION, BEGIN_TIME, END_TIME, IPV4_START, IPV4_END, IP_TYPE 
					FROM SORM_IP_PLAN WHERE reported = '0' ORDER BY id ASC});
         $sth->execute or die DBI->errstr;

	 if (($sth->rows) > 0) {
		 open(Ip_plan, ">$location_file/IP_PLAN_$file.txt") || die;
		 print Ip_plan "DESCRIPTION;IP_TYPE;IPV4;IPV6;IPV4_MASK;IPV6_MASK;BEGIN_TIME;END_TIME;REGION_ID\n";
	 } else { return; }

         while(my $data = $sth->fetchrow_hashref())
         {
		@cidr_list = Net::CIDR::range2cidr("$data->{IPV4_START} - $data->{IPV4_END}");

			foreach my $ip (@cidr_list)
			{
                               my $to_hex = new Net::IP ($ip);
                               my @hexip = split(/x/, $to_hex->hexip());
                               my $clean_hex_ip = uc($hexip[1]);

			       #Добьем нулями до 8 байт
			       for (;;) 
			       {
					if ((length($clean_hex_ip) < 8) && length($clean_hex_ip) > 4) 
					{
						$clean_hex_ip = "0$clean_hex_ip";
					} else {last};
			       }
                               my @hexmask = split(/x/, $to_hex->hexmask());
                               my $clean_hex_mask = uc($hexmask[1]);

                               print Ip_plan "$data->{DESCRIPTION};0;$clean_hex_ip;;$clean_hex_mask;;$data->{BEGIN_TIME};$data->{END_TIME};$region_id\n";
                               }
         }

	 $sth = $dbh->prepare(qq{UPDATE SORM_IP_PLAN SET reported = '1'});
         $sth->execute or die DBI->errstr;

        return;
}

#**********************************************************
=head2 GATEWAY former()

=cut
#**********************************************************
sub gateway_report {

	 my $self = shift;
#Из базы скрипта
	 my $begin_time;
         my @db_array;
         my %axbills_array;
         my @changed_entries;
         my $count_updates = 0;
         my @new_entries;
         my @del_entries;
         my $need_update_files = 0;
	 my $region_id = $self->{conf}->{SORM_ISP_ID} || q{};
	 my $time_offset = $self->{conf}->{SORM_TIME_OFFSET} || '-3'; #Moscow

	 my DBI $dbh = $self->{db}->{db};

         printf "======GATEWAY & GATEWAY_IP SECTION=======\n";

         my $sth = $dbh->prepare(qq{SELECT record_id, DISABLE, GATE_ID AS id, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL $time_offset HOUR) AS CURRENT, BEGIN_TIME, END_TIME, 
					DESCRIPTION, IPV4, IP_PORT, STREET, BUILDING, APARTMENT, ZIP, CITY 
					FROM SORM_GATEWAY WHERE ended = '0' ORDER BY record_id DESC});

         $sth->execute or die DBI->errstr;

         while(my $old_data = $sth->fetchrow_hashref())
         {
                 push(@db_array, $old_data);
         }

#AXbills

        $sth = $dbh->prepare(qq{SELECT nas.id, disable AS DISABLE, DATE_ADD(changed, INTERVAL $time_offset HOUR) AS BEGIN_TIME, INET_NTOA(ip) AS IPV4, mng_host_port AS IP_PORT, 
				nas.name AS DESCRIPTION, d.zip AS ZIP, d.city AS CITY, s.name AS STREET, b.number AS BUILDING, nas.address_flat AS APARTMENT 
				FROM nas
				LEFT JOIN builds b ON b.id=nas.location_id
				LEFT JOIN streets s ON s.id=b.street_id
				LEFT JOIN districts d ON d.id=s.district_id 
				ORDER BY id ASC});

        $sth->execute or die DBI->errstr;

        while(my $new_data = $sth->fetchrow_hashref())
        {
                 $axbills_array{$new_data->{id}} = $new_data;
        }

#Ищем совпадения, выпиливаем их
        foreach my $entry (@db_array)
        {
                if ($entry->{id} && !exists $axbills_array{$entry->{id}} && $entry->{END_TIME} eq $date_ended)
		{
			$need_update_files = 1;
                        #Deleting
			my $sth = $dbh->prepare(qq{UPDATE SORM_GATEWAY SET END_TIME = '$entry->{CURRENT}', ended = '1' 
                                                        WHERE SORM_GATEWAY.record_id = $entry->{record_id}});
                        $sth->execute() if ($debug == '0');
                }

                if($entry->{id} && exists $axbills_array{$entry->{id}})
                {
                         if ($axbills_array{$entry->{id}}->{id} eq $entry->{id})
                                {
                                        if (($axbills_array{$entry->{id}}->{BEGIN_TIME} ne $entry->{BEGIN_TIME}))# && $entry->{END_TIME} eq $date_ended)
                                        {
						$axbills_array{$entry->{id}}->{STREET} //= q{};$axbills_array{$entry->{id}}->{STREET} =~ s/[;)(]/ /g;
						$axbills_array{$entry->{id}}->{BUILDING} //= q{};$axbills_array{$entry->{id}}->{BUILDING} =~ s/[;)(]/ /g;
						$axbills_array{$entry->{id}}->{APARTMENT} //= q{};$axbills_array{$entry->{id}}->{APARTMENT} =~ s/[;)(]/ /g;
						$axbills_array{$entry->{id}}->{ZIP} //= q{};$axbills_array{$entry->{id}}->{ZIP} =~ s/[;)(]/ /g;
						$axbills_array{$entry->{id}}->{CITY} //= q{};$axbills_array{$entry->{id}}->{CITY} =~ s/[;)(]/ /g;
						$axbills_array{$entry->{id}}->{DESCRIPTION} //= q{};$axbills_array{$entry->{id}}->{DESCRIPTION} =~ s/[;)(]/ /g;
						$axbills_array{$entry->{id}}->{IPV4} //= q{};$axbills_array{$entry->{id}}->{IPV4} =~ s/[;)(]/ /g;
						$axbills_array{$entry->{id}}->{IP_PORT} //= q{};$axbills_array{$entry->{id}}->{IP_PORT} =~ s/[;)(]/ /g;
						
                                                if ($axbills_array{$entry->{id}}->{STREET} ne $entry->{STREET} ||
						$axbills_array{$entry->{id}}->{BUILDING} ne $entry->{BUILDING} ||
						$axbills_array{$entry->{id}}->{APARTMENT} ne $entry->{APARTMENT} ||
						$axbills_array{$entry->{id}}->{ZIP} ne $entry->{ZIP} ||
						$axbills_array{$entry->{id}}->{CITY} ne $entry->{CITY} ||
                                                $axbills_array{$entry->{id}}->{DESCRIPTION} ne $entry->{DESCRIPTION} ||
						$axbills_array{$entry->{id}}->{IPV4} ne $entry->{IPV4} ||
						$axbills_array{$entry->{id}}->{DISABLE} ne $entry->{DISABLE} ||
						$axbills_array{$entry->{id}}->{IP_PORT} ne $entry->{IP_PORT})
                                                {
							$need_update_files = 1;
							$date_ended = $entry->{CURRENT} if ($axbills_array{$entry->{id}}->{DISABLE} == 1);

							my $sth = $dbh->prepare(qq{UPDATE SORM_GATEWAY SET END_TIME = '$axbills_array{$entry->{id}}->{BEGIN_TIME}', ended = '1' 
											WHERE SORM_GATEWAY.record_id = $entry->{record_id}});
			 				$sth->execute() if ($debug == '0');

                         				$sth = $dbh->prepare(qq{INSERT INTO SORM_GATEWAY (GATE_ID, DISABLE, BEGIN_TIME, END_TIME, DESCRIPTION, IPV4, IP_PORT, ZIP, CITY, STREET, BUILDING, APARTMENT)
                                        					VALUES ('$entry->{id}', '$axbills_array{$entry->{id}}->{DISABLE}', '$axbills_array{$entry->{id}}->{BEGIN_TIME}', '$date_ended', '$axbills_array{$entry->{id}}->{DESCRIPTION}',
                                                					'$axbills_array{$entry->{id}}->{IPV4}', '$axbills_array{$entry->{id}}->{IP_PORT}', 
											'$axbills_array{$entry->{id}}->{ZIP}', '$axbills_array{$entry->{id}}->{CITY}', 
											'$axbills_array{$entry->{id}}->{STREET}', '$axbills_array{$entry->{id}}->{BUILDING}', '$axbills_array{$entry->{id}}->{APARTMENT}')
                         				});
                         				$sth->execute() if ($debug == '0');
			 				delete $axbills_array{$entry->{id}};
                                                }
                                        } else { delete $axbills_array{$entry->{id}} }
                                }

                }
}
        @new_entries = values %axbills_array;

        printf "=========ADDING entires=============\n" if ($debug == '1');
#        print Dumper \@new_entries;# if ($debug == '1');

	#ADD Entries
        foreach my $new_entry (@new_entries)
        {
		next if (defined($new_entry->{record_id}));
			 $need_update_files = 1;
                         my $sth = $dbh->prepare(qq{INSERT INTO SORM_GATEWAY (GATE_ID, DISABLE, BEGIN_TIME, DESCRIPTION, IPV4, IP_PORT, ZIP, CITY, STREET, BUILDING, APARTMENT)
                                        VALUES ('$new_entry->{id}', '$new_entry->{DISABLE}', '$new_entry->{BEGIN_TIME}', '$new_entry->{DESCRIPTION}',
                                                '$new_entry->{IPV4}', '$new_entry->{IP_PORT}', '$new_entry->{ZIP}', '$new_entry->{CITY}', '$new_entry->{STREET}', 
						'$new_entry->{BUILDING}', '$new_entry->{APARTMENT}')
                         });
                         $sth->execute() if ($debug == '0');
        }

gateway_export($self) if ($need_update_files == 1);
}

#**********************************************************
=head2 GATEWAY_export()

=cut
#**********************************************************
sub gateway_export{

	 my $self = shift;
	 my $region_id = $self->{conf}->{SORM_ISP_ID} || q{};
         my $country = $self->{conf}->{SORM_COUNTRY} || q{};
         my $region = $self->{conf}->{SORM_REGION} || q{};
         my $zone = $self->{conf}->{SORM_ZONE} || q{};
	 my $time_offset = $self->{conf}->{SORM_TIME_OFFSET} || '-3'; #Moscow
	 #my $zone = '';

	 my DBI $dbh = $self->{db}->{db};
#Export to Files
         my $sth = $dbh->prepare(qq{SELECT record_id AS id, BEGIN_TIME, END_TIME, DESCRIPTION, IPV4, IP_PORT, STREET, BUILDING, APARTMENT, ZIP, CITY 
					FROM SORM_GATEWAY ORDER BY record_id ASC});
         $sth->execute or die DBI->errstr;

	 open(Gateway, ">$location_file/GATEWAY_$file.txt") || die;
	 open(Gateway_ip, ">$location_file/IP_GATEWAY_$file.txt") || die;
	 print Gateway "GATE_ID;BEGIN_TIME;END_TIME;DESCRIPTION;GATE_TYPE;ADDRESS_TYPE_ID;ADDRESS_TYPE;ZIP;COUNTRY;REGION;ZONE;CITY;STREET;BUILDING;BUILD_SECT;APARTMENT;UNSTRUCT_INFO;REGION_ID\n";
	 print Gateway_ip "GATE_ID;IP_TYPE;IPV4;IPV6;IP_PORT;REGION_ID\n";
         while(my $data = $sth->fetchrow_hashref())
         {
                #print Dumper $data;
		my $to_hex = new Net::IP ($data->{IPV4});
                my @hexip = split(/x/, $to_hex->hexip());
                my $clean_hex_ip = uc($hexip[1]);

                #Добьем нулями до 8 байт
                for (;;)
                {
	                if ((length($clean_hex_ip) < 8) && length($clean_hex_ip) > 4)
                        {
        	                $clean_hex_ip = "0$clean_hex_ip";
                        } else {last};
                }

		my @port_to_hex = split(':', $data->{IP_PORT});
		my $hexport = uc(sprintf("%x", $port_to_hex[1] || '161'));

                #Добьем нулями до 4 байт
                for (;;)
                {
                        if ((length($hexport) < 4) && length($hexport) > 1)
                        {
                                $hexport = "0$hexport";
                        } else {last};
                }

		print Gateway "$data->{id};$data->{BEGIN_TIME};$data->{END_TIME};$data->{DESCRIPTION};7;0;0;$data->{ZIP};$country;$region;$zone;$data->{CITY};$data->{STREET};$data->{BUILDING};;$data->{APARTMENT};;$region_id\n";
		print Gateway_ip "$data->{id};0;$clean_hex_ip;;$hexport;$region_id\n";
         }
        return;
}

#**********************************************************
=head2 SUPPLEMENTARY_SERVICE former()

=cut
#**********************************************************
sub supplementary_service {

	 my $self = shift;

#Из базы скрипта
         my $begin_time;
         my @db_array;
         my %axbills_array;
         my @changed_entries;
         my $count_updates = 0;
         my @new_entries;
         my @del_entries;
         my $need_update_files = 0;
	 my $time_offset = $self->{conf}->{SORM_TIME_OFFSET} || '-3'; #Moscow

	 my DBI $dbh = $self->{db}->{db};

         printf "======SUPPLEMENTARY SERVICE SECTION=======\n";

         my $sth = $dbh->prepare(qq{SELECT record_id, ID AS id, BEGIN_TIME, END_TIME, DESCRIPTION, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL $time_offset HOUR) AS CURRENT 
					FROM SORM_SUPPLEMENTARY_SERVICE ORDER BY record_id DESC});

         $sth->execute or die DBI->errstr;

         while(my $old_data = $sth->fetchrow_hashref())
         {
                 push(@db_array, $old_data);
         }

#AXbills

        $sth = $dbh->prepare(qq{SELECT id, DATE_ADD(last_update, INTERVAL $time_offset HOUR) AS BEGIN_TIME, name AS DESCRIPTION 
                                FROM tarif_plans ORDER BY id ASC});

        $sth->execute or die DBI->errstr;

        while(my $new_data = $sth->fetchrow_hashref())
        {
                 $axbills_array{$new_data->{id}} = $new_data;
        }

#Ищем совпадения, выпиливаем их
        foreach my $entry (@db_array)
        {
                if ($entry->{id} && !exists $axbills_array{$entry->{id}} && $entry->{END_TIME} eq $date_ended)
                {
                        $need_update_files = 1;
                        #Deleting
                        my $sth = $dbh->prepare(qq{UPDATE SORM_SUPPLEMENTARY_SERVICE SET END_TIME = $entry->{CURRENT}
                                                        WHERE SORM_SUPPLEMENTARY_SERVICE.record_id = $entry->{record_id}});
                        $sth->execute() if ($debug == '0');
                }

                if($entry->{id} && exists $axbills_array{$entry->{id}})
                {
                         if ($axbills_array{$entry->{id}}->{id} eq $entry->{id})
                                {
                                        if (($axbills_array{$entry->{id}}->{BEGIN_TIME} ne $entry->{BEGIN_TIME}))# && $entry->{END_TIME} eq $date_ended)
                                        {
                                                if ($axbills_array{$entry->{id}}->{DESCRIPTION} ne $entry->{DESCRIPTION})
                                                {
                                                        $need_update_files = 1;
							$axbills_array{$entry->{id}}->{DESCRIPTION} //= q{};$axbills_array{$entry->{id}}->{DESCRIPTION} =~ s/[;]/ /g;

                                                        my $sth = $dbh->prepare(qq{UPDATE SORM_SUPPLEMENTARY_SERVICE SET END_TIME = '$axbills_array{$entry->{id}}->{BEGIN_TIME}'
                                                                                        WHERE SORM_SUPPLEMENTARY_SERVICE.record_id = $entry->{record_id}});
                                                        $sth->execute() if ($debug == '0');

                                                        $sth = $dbh->prepare(qq{INSERT INTO SORM_SUPPLEMENTARY_SERVICE (ID, BEGIN_TIME, END_TIME, DESCRIPTION)
                                                                                VALUES ('$entry->{id}', '$axbills_array{$entry->{id}}->{BEGIN_TIME}', '$date_ended',
											'$axbills_array{$entry->{id}}->{DESCRIPTION}')
                                                        });
                                                        $sth->execute() if ($debug == '0');
                                                        delete $axbills_array{$entry->{id}};
                                                } else { delete $axbills_array{$entry->{id}} }
                                        } else { delete $axbills_array{$entry->{id}} }
                                }

                }
}
        @new_entries = values %axbills_array;

        printf "=========ADDING entires=============\n" if ($debug == '1');
#        print Dumper \@new_entries;# if ($debug == '1');

        #ADD Entries
        foreach my $new_entry (@new_entries)
        {
                if (defined($new_entry->{id}))
                {
                         $need_update_files = 1;
                         my $sth = $dbh->prepare(qq{INSERT INTO SORM_SUPPLEMENTARY_SERVICE (ID, BEGIN_TIME, DESCRIPTION, END_TIME)
                                        VALUES ('$new_entry->{id}', '$new_entry->{BEGIN_TIME}', '$new_entry->{DESCRIPTION}',
                                                '$date_ended')
                         });
                         $sth->execute() if ($debug == '0');
                }
        }

supplementary_export($self) if ($need_update_files == 1);
}

#**********************************************************
=head2 SUPPLEMENTARY_SERVICE_export()

=cut
#**********************************************************
sub supplementary_export{

	 my $self = shift;
	 my $region_id = $self->{conf}->{SORM_ISP_ID} || q{};

	 my DBI $dbh = $self->{db}->{db};
#Export to Files
         my $sth = $dbh->prepare(qq{SELECT ID AS id, BEGIN_TIME, END_TIME, DESCRIPTION FROM SORM_SUPPLEMENTARY_SERVICE ORDER BY record_id DESC});
         $sth->execute or die DBI->errstr;

         open(Supplementary, ">$location_file/SUPPLEMENTARY_SERVICE_$file.txt") || die;
         print Supplementary "ID;MNEMONIC;BEGIN_TIME;END_TIME;DESCRIPTION;REGION_ID\n";
         while(my $data = $sth->fetchrow_hashref())
         {
                print Supplementary "$data->{id};;$data->{BEGIN_TIME};$data->{END_TIME};$data->{DESCRIPTION};$region_id\n";
         }
        return;

}

1
