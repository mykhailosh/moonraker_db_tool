#!/usr/bin/perl

=head2 DESCRIPTION

This script is for export, import, or merge history data in moonraker database

=cut

use warnings;
use strict;

use local::lib;
use Getopt::Long;
use LMDB_File;
use JSON qw(decode_json encode_json);

use constant MOONRAKER_DB => 'moonraker';
use constant DEFAULT_EXPORT_FILE => '/tmp/moonraker_database_export_' . time() . '.json';

my ( $source_database, $action, $import_filename );

GetOptions(
	"database=s"	=> \$source_database,
	"action=s"	=> \$action,
	"data=s"	=> \$import_filename,
);

validate_options();

my $db_data = read_data( $source_database, 'history' );

export_json( $db_data ) if $action eq 'export';
import_json( $db_data, $import_filename ) if $action eq 'import';
merge_json( $db_data, $import_filename ) if $action eq 'merge';


sub help {
	printf qq{Usage: %s --database [PATH] --action [merge|import|export] --data [exported_data.json]\n}, $0;
	exit 0;
}

sub validate_options {
	help() unless defined $source_database && defined $action ;
	help() unless $action =~ m/merge|(ex|im)port/;
	unless( -d $source_database && -f $source_database . "/data.mdb" ) {
		print "Cannot find input database $source_database\n";
		exit 1;
	}
	if ( $action =~ m/import|merge/ and not defined $import_filename ) {
		print "--import or --merge requires --data option\n";
		exit 1;
	} 
	
	return;
}

sub read_data {
	my ( $db, $table ) = @_;
	my $txn = LMDB::Txn->new( get_env( $db ), 0 );
	my $dbi = $txn->open( MOONRAKER_DB );
	my $data;
	$txn->get( $dbi, $table, $data );
	$txn->commit;
	return decode_json $data;
}


sub get_env {
	my ( $db ) = @_;
	return LMDB::Env->new( $db, {
		mapsize	=> 100 * 1024 * 1024 * 1024,
		maxdbs	=> 20,
		mode	=> 0600,
	});
}

sub export_json {
	my ( $data, $output_file) = @_;
	$output_file //= DEFAULT_EXPORT_FILE;
	open my $fh, '>', $output_file or die "Can't open file: $!";
	print $fh encode_json $data;
	close $fh;
	print "Data written to $output_file\n";
	return;
}

sub import_json {
	my ( $src_data, $input_json_file ) = @_;
	write_database_data( $source_database, 'history', parse_import_file( $input_json_file ) );
	return;
}

sub merge_json {
	my ( $src_data, $input_json_file ) = @_;
	merge_data( $src_data->{job_totals}, parse_import_file( $input_json_file ) );
	write_database_data( $source_database, 'history', $src_data );
	return;
}

sub merge_data {
	my ( $src_data, $data ) = @_;
	$src_data->{longest_print} = $data->{job_totals}->{longest_print} if $data->{job_totals}->{longest_print} > $src_data->{longest_print};
	$src_data->{longest_job}   = $data->{job_totals}->{longest_job}   if $data->{job_totals}->{longest_job}   > $src_data->{longest_job};
	$src_data->{total_filament_used} += $data->{job_totals}->{total_filament_used};
	$src_data->{total_print_time}    += $data->{job_totals}->{total_print_time};
	$src_data->{total_time}          += $data->{job_totals}->{total_time};
	$src_data->{total_jobs}          += $data->{job_totals}->{total_jobs};
	return;
}

sub parse_import_file {
	my ( $file ) = @_;
	my $json;
	open my $fh, '<', $file or die "Cannot open $file : $!";
	while ( my $line = <$fh> ) {
	    $json .= $line;
	}
	close $fh;
	die "Empty json data" unless $json;
	return decode_json $json;
}

sub write_database_data {
	my ( $db, $table, $data ) = @_;
	my $txn = LMDB::Txn->new( get_env( $db ), 0 );
	my $dbi = $txn->open( MOONRAKER_DB );
        $txn->put( $dbi, $table, encode_json $data );
        $txn->commit;
	return;
}

