#!/usr/bin/env perl

# Copyright (c) "2012, Alexandr Fonari
#                URL: https://github.com/alexandr-fonari/Main/tree/master/CRYSTAL
#                License: MIT License
# Version 1.0
#
# Program converts CRYSTAL output into CIF file.
# Output from ionic relaxation is supported (variable unit cell relaxations have not been tested),
# and will result in CIF with many structures (as many as ionic steps)
# CIF file can be opened with CSD Mercury (c).
#


use strict; 
use warnings;
use Data::Dumper;

if ( scalar( @ARGV ) < 1 )
{
    die( "\nUse: $0 <input.out>\n" );
}

open( my $outcar_fh, "<", $ARGV[0]) || die "Can't open $ARGV[0]: $!\n";
open( my $cif_fh, ">", "$ARGV[0].cif" ) || die "Can't open $ARGV[0].cif: $!\n";

my $primitive = 1;
if ( scalar( @ARGV ) == 2 and $ARGV[1] eq "crystal" )
{
    $primitive = 0;
}

my $count = 0;
my @atoms_lines;

while(my $line = <$outcar_fh>)
{
    if($line =~ /LATTICE PARAMETERS \(ANGSTROMS AND DEGREES\)/ and $primitive)
    {
        my $next = <$outcar_fh>; # volume and density
        $next = <$outcar_fh>; # A              B              C           ALPHA      BETA       GAMMA
        my ($a, $b, $c, $alpha, $beta, $gamma) = (<$outcar_fh> =~ m/([\d\.]+)/g);

        print_cif_header($cif_fh, $a, $b, $c, $alpha, $beta, $gamma);
        $next = <$outcar_fh>; # *******************************************************************************
        $next = <$outcar_fh>; # ATOMS IN THE ASYMMETRIC UNIT   23 - ATOMS IN THE UNIT CELL:   46
        $next = <$outcar_fh>; # ATOM              X/A                 Y/B                 Z/C    
        $next = <$outcar_fh>; # *******************************************************************************

        while(my $next = <$outcar_fh>)
        {
            # 1 T  16 S     1.385742829523E-01  1.780535294494E-01  2.267245222437E-01
            if($next  =~ m/^\s+(\d+)\s+(\w)\s+(\d+)\s+(\w+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/)
            {
                # print $next;
                my ($i, $au, $atom_n, $atom_s, $x, $y, $z) = ($1, $2, $3, $4, $5, $6, $7);
                print $cif_fh sprintf("%s%d %s %9.5f %9.5f %9.5f\n", $atom_s, $i, $atom_s, $x, $y, $z);
                #push(@atoms_lines, sprintf("%s %.5f %.5f %.5f", $atom_s, $x, $y, $z));
            }
            else
            {
                last;
            }
        }
    }
    elsif(!$primitive and $line =~ /CRYSTALLOGRAPHIC CELL \(VOLUME/)
    {
        my $next = <$outcar_fh>; # A              B              C           ALPHA      BETA       GAMMA
        my ($a, $b, $c, $alpha, $beta, $gamma) = (<$outcar_fh> =~ m/([\d\.]+)/g);

        print_cif_header($cif_fh, $a, $b, $c, $alpha, $beta, $gamma);
        $next = <$outcar_fh>; # 
        $next = <$outcar_fh>; #  COORDINATES IN THE CRYSTALLOGRAPHIC CELL
        $next = <$outcar_fh>; #      ATOM              X/A                 Y/B                 Z/C    
        $next = <$outcar_fh>; #  *******************************************************************************

        while(my $next = <$outcar_fh>)
        {
            # 1 T  16 S     1.385742829523E-01  1.780535294494E-01  2.267245222437E-01
            if($next  =~ m/^\s+(\d+)\s+(\w)\s+(\d+)\s+(\w+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/)
            {
                # print $next;
                my ($i, $au, $atom_n, $atom_s, $x, $y, $z) = ($1, $2, $3, $4, $5, $6, $7);
                print $cif_fh sprintf("%s%d %s %9.5f %9.5f %9.5f\n", $atom_s, $i, $atom_s, $x, $y, $z);
                #push(@atoms_lines, sprintf("%s %.5f %.5f %.5f", $atom_s, $x, $y, $z));
            }
            else
            {
                last;
            }
        }
    }
}

close($outcar_fh);
close($cif_fh);

print "\ncry2cif.pl V. 1.0.\nFile $ARGV[0].cif created.\nJob done.\n\n";

# SUBs
sub print_cif_header
{
    my ($cif_fh, $a, $b, $c, $alpha, $beta, $gamma) = @_;
    print $cif_fh "\n\ndata_a\n";
    print $cif_fh "\n";
    print $cif_fh "_cell_length_a     $a\n";
    print $cif_fh "_cell_length_b     $b\n";
    print $cif_fh "_cell_length_c     $c\n";
    print $cif_fh "_cell_angle_alpha  $alpha\n";
    print $cif_fh "_cell_angle_beta   $beta\n";
    print $cif_fh "_cell_angle_gamma  $gamma\n";
    print $cif_fh "\n";
    print $cif_fh "loop_\n";
    print $cif_fh "_space_group_symop_id\n";
    print $cif_fh "_space_group_symop_operation_xyz\n";
    print $cif_fh "1 'x, y, z'\n";
    print $cif_fh "\n";
    print $cif_fh "loop_\n";
    print $cif_fh "_atom_site_label\n";
    print $cif_fh "_atom_site_type_symbol\n";
    print $cif_fh "_atom_site_fract_x\n";
    print $cif_fh "_atom_site_fract_y\n";
    print $cif_fh "_atom_site_fract_z\n";
}
sub trim{ my $s=shift; $s =~ s/^\s+|\s+$//g; return $s;}

