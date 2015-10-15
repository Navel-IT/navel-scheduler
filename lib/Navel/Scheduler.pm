# Copyright 2015 Navel-IT
# navel-scheduler is developed by Yoann Le Garff, Nicolas Boquet and Yann Le Bras under GNU GPL v3

#-> BEGIN

#-> initialization

package Navel::Scheduler;

use strict;
use warnings;

use parent 'Navel::Base';

use Exporter::Easy (
    OK => [qw/
        $VERSION
        :all
    /],
    TAGS => [
        all => [qw/
            $VERSION
        /]
    ]
);

use Carp 'croak';

use Navel::Scheduler::Parser;
use Navel::Scheduler::Core;
use Navel::Definition::Connector::Parser;
use Navel::Definition::RabbitMQ::Parser;

our $VERSION = 0.1;

#-> methods

sub new {
    my ($class, %options) = @_;

    croak('general configuration file path is missing') unless defined $options{general_configuration_path};

    bless {
        core => undef,
        configuration => Navel::Scheduler::Parser->new()->read(
            file_path => $options{general_configuration_path}
        )->make()
    }, ref $class || $class;
}

sub run {
    my ($self, %options) = @_;

    $self->{core} = Navel::Scheduler::Core->new(
        configuration => $self->{configuration},
        connectors => Navel::Definition::Connector::Parser->new(
            maximum => $self->{configuration}->{definition}->{connectors}->{maximum}
        )->read(
            file_path => $self->{configuration}->{definition}->{connectors}->{definitions_from_file}
        )->make(),
        rabbitmq => Navel::Definition::RabbitMQ::Parser->new(
            maximum => $self->{configuration}->{definition}->{rabbitmq}->{maximum}
        )->read(
            file_path => $self->{configuration}->{definition}->{rabbitmq}->{definitions_from_file}
        )->make(),
        logger => $options{logger}
    );

    my $run = $self->{core}->register_the_logger()->register_connectors()->init_publishers();

    for (@{$self->{core}->{publishers}}) {
        $self->{core}->connect_publisher_by_name($_->{definition}->{name}) if $_->{definition}->{auto_connect};
    }

    $run->register_publishers()->start();

    $self;
}

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=head1 NAME

Navel::Scheduler

=head1 AUTHOR

Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

GNU GPL v3

=cut