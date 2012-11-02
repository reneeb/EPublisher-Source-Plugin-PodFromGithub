package EPublisher::Source::Plugin::PodFromGithub;

=encoding utf-8

=cut

# ABSTRACT: Get POD from files hosted on github.com

use strict;
use warnings;

use Data::Dumper;
use Encode;
use File::Basename;
use Pithub;

use EPublisher::Source::Base;

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.2;

# implementing the interface to EPublisher::Source::Base
sub load_source{
    my ($self) = @_;

    $self->publisher->debug( '100: start ' . __PACKAGE__ );

    my $options = $self->_config;
    
    return '' unless $options->{repo} and $options->{user};

    my $branch = $options->{branch} || 'master';
    my $repo   = $options->{repo};
    my $user   = $options->{user};
    my $files  = $options->{files} || [];

    my $file = join ', ', @{$files};

    # fetching the requested tutorial from metacpan
    $self->publisher->debug( "103: fetch $file from $user/$repo (branch $branch)" );

    # try to get data for the given repo to get the sha
    my $sha = ;

    return unless $sha;

    my @files = @{$files};

    if ( !@files ) {
        @files = _get_repo_files(
            user => $user,
            repo => $repo,
            sha  => $sha,
        );
    }

    FILE:
    for my $file ( @files ) {

        # get pod from content

        if ( !$pod ) { 
            $self->publisher->debug(
                "103: No pod for $file found",
            );

            next FILE;
        }

        # try to decode it otherwise the target plugins may produce garbage
        eval{ $pod = decode( 'utf-8', $pod ); };

        if ( $options->{preprocessor} and ref $options->{preprocessor} eq 'ARRAY' ) {

            PREPROCESSOR:
            for my $preprocessor ( @{$options->{preprocessor}} ) {
                next PREPROCESSOR if $preprocessor !~ m{
                    \A
                        [A-Za-z][A-Za-z0-9_]*
                        (?: :: [A-Za-z][A-Za-z0-9_]* )*
                    \z
                }xms;

                require $preprocessor;

                next if !$preprocessor->can( 'run' );

                $pod = $preprocessor->run( $pod );
            }
        }

        my $title = $name;
        my $info  = { pod => $pod, filename => $name, title => $title };
        push @pod, $info;

        $self->publisher->debug(
            "103: passed info: "
                . "filename => $name, "
                . "title => $title, "
                . "pod => $pod"
        );
    }

    return @pod;
}

sub _get_repo_files {
    my (%param) = @_;

    # get the tree (recursively)
    my $tree = Pithub::GitData::Trees->new;
    my $tree_data = $tree->get(
        user => $user,
        repo => $repo,
        sha  => $sha,
    );

    # get "interesting files" (.pm, .pod, .pl)

    return @files;
}

1;

=head1 SYNOPSIS

  my $source_options = { type => 'PodFromGithub', name => 'Moose' };
  my $url_source     = EPublisher::Source->new( $source_options );
  my $pod            = $url_source->load_source;

=head1 METHODS

=head2 load_source

  $url_source->load_source;

reads the URL 

=cut
