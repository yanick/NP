package NP;
# ABSTRACT: provide access for previous and next lines for -p/-n oneliners

=head1 SYNOPSIS

    # remember the previous line
    $ perl -E'say $_ for "a".."z"' | perl -MNP=1 -nE'print if $p[0] =~ /m/'
    n

    # remember 3 previous lines
    $ perl -E'say $_ for "a".."z"' | perl -MNP=3 -nE'print if $p[2] =~ /m/'
    p

    # can look in the future too!
    $ perl -E'say $_ for "a".."z"' | perl -MNP=3,1 -nE'print if $n[0] =~ /m/'
    l

=head1 DESCRIPTION

This module is meant to be used in one-liners using C<-n> or C<-p> types of
loops.  It 
injects the arrays C<@p> and C<@n> (standing for I<previous>
and I<next> values) into the main namespace. Assuming the 
module has been loaded via C<-MNP=x,y>, the two arrays will contain 
up to the I<x> previous and I<y> next values read from C<ARGV>. If one of the
limits is not given, it's assumed to be zero.

=head1 CAVEATS

If C<-l> is being used, the lines won't be C<chomp>ed in C<@p> and C<@n>.

=cut

use strict;
use warnings;

sub import {
    ( undef, $NP::previous, $NP::next ) = @_;
    $NP::previous ||= 0;
    $NP::next     ||= 0;
}

tie *ARGV, 'Fake::ARGV';

{
    package Fake::ARGV;

    sub TIEHANDLE {
        # TODO fake the whole <ARGV> behavior
        # TODO handle the use of -l and -0
        my @files = @ARGV ? @ARGV : '-';

        open my $handle, shift @files;

        my $self = { ended => 0, handle => $handle, files => \@files };
        return bless $self, __PACKAGE__;
    }

    sub next_file {
        my $self = shift;
        return unless @{ $self->{files} };
        open my $handle, shift @{ $self->{files} } or return;
        return $self->{handle} = $handle;
    }

    sub READLINE {
        my $self = shift;

        while( ! $self->{ended} and @::next <= $NP::next ) {
            my $line = readline $self->{handle};
            if ( not defined $line ) {
                redo if $self->next_file;
                $self->{ended} = 1;
                last;
            }
            push @::n, $line;
        }

        pop @::p if @::p >= $NP::previous;
        unshift @::p, $NP::current_line if defined $NP::current_line;

        return $NP::current_line = shift @::n;
    }

}

1;
