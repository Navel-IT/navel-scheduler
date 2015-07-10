navel-scheduler
===============

navel-scheduler's purpose is to get back datas from connectors at scheduled (Quartz expressions) time then encode and push it through RabbbitMQ to navel-router.

It must work on all Linux platforms but, **at this time, it is only supported on RHEL/CentOS 6.6**.

Build and install
-----------------

Assuming you have all the necessary commands installed ...

- CPAN

```
git clone http://github.com/Navel-IT/navel-scheduler.git

cd navel-scheduler/

./build_cpan_archive.sh <version>

cpanm <cpan-archive> -n

cp -R RPM/SOURCES/* /

chkconfig navel-scheduler on
```

- RPM

```
git clone http://github.com/Navel-IT/navel-scheduler.git

cd navel-scheduler/

./build_rpm_archive.sh <version> <release>

yum localinstall <rpm-archive>
```

Prepare configuration
---------------------

*general.json* is the entrypoint for the configuration of navel-scheduler. Most of this properties cannot be modified at runtime. It must look like this :

```javascript
{
    "definitions_path" : {
        "connectors" : "/etc/navel-scheduler/connectors.json",
        "connectors_exec_directory" : "/etc/navel-scheduler/connectors", // this directory contains the connectors (scripts)
        "rabbitmq" : "/etc/navel-scheduler/rabbitmq.json",
        "webservices" : "/etc/navel-scheduler/webservices.json"
    },
    "webservices" : { // properties shared by all the web services
        "login" : "admin", // can be modified at runtime
        "password" : "password", // can be modified at runtime
        "mojo_server" : { // Mojo::Server::Prefork properties
        }
    },
    "rabbitmq" : { // properties shared by all the rabbitmq clients
        "auto_connect" : 1 // 0 or 1. Automatically connect navel-scheduler to rabbitmq servers when a rabbitmq definition is added or when navel-scheduler start
    }
}
```

*webservices.json* contains the definitions of navel-scheduler's web services and cannot be modified at runtime. It must look like this :

```javascript
[
    {
        "name" : "webservice-1", // web service (unique name)
        "interface_mask" : "*", // this web service will be listening on this mask
        "port" : 3000, // this web service will be listening on this port
        "tls" : 0 // 0 or 1. Enable TLS
    },
    {
        "name" : "webservice-2",
        "interface_mask" : "*",
        "port" : 3000,
        "tls" : 0
    }
]
```

Others parts of the configuration must be done via the REST API.

Service
-------

`service navel-scheduler <action>`

If you want to change the service options, edit */etc/sysconfig/navel-scheduler*.

REST API
--------

The following endpoints are currently availables for informations and runtime modifications.

**Note** : JSON below URI are exemples of what HTTP message body you should get (**GET**, **DEL**) or send (**POST**, **PUT**).

- **GET** - read
  - /scheduler/api
```json
{
    "version" : 0.1
}
```
  - /scheduler/api/general
```json
{
    "definitions_path" : {
        "connectors" : "/etc/navel-scheduler/connectors.json",
        "connectors_exec_directory" : "/etc/navel-scheduler/connectors",
        "rabbitmq" : "/etc/navel-scheduler/rabbitmq.json",
        "webservices" : "/etc/navel-scheduler/webservices.json"
    },
    "webservices" : {
        "login" : "admin",
        "password" : "password",
        "mojo_server" : {
        }
    },
    "rabbitmq" : {
        "auto_connect" : 1
    }
}
```
  - /scheduler/api/general?action=write_configuration
```json
{
    "ok" : [
        "Runtime configuration saved"
    ],
    "ko" : []
}
```
  - /scheduler/api/cron/jobs
```json
{
    "jobs_registered" : {
        "loggers" : 1,
        "publishers" : 2,
        "connectors" : 2
    }
}
```
  - /scheduler/api/connectors
```json
[
    "glpi-1",
    "collectd-1"
]
```
  - /scheduler/api/connectors/(:connector)
```json
{
    "name" : "glpi-1",
    "collection" : "glpi",
    "type" : "code",
    "singleton" : 1,
    "scheduling" : "15 * * * * ?",
    "source" : "glpi",
    "input" : {
        "url" : "http://login:password@glpi.home.fr:8080"
    },
    "exec_directory_path" : "/etc/navel-scheduler/connectors"
}
```
  - /scheduler/api/rabbitmq
```json
[
    "rabbitmq-1",
    "rabbitmq-2"
]
```
  - /scheduler/api/rabbitmq/(:rabbitmq)
```json
{
    "name" : "rabbitmq-1",
    "host" : "172.16.1.1",
    "port" : 5672,
    "user" : "guest",
    "password" : "guest",
    "timeout" : 0,
    "vhost" : "/",
    "exchange" : "navel-scheduler.E.direct.events",
    "routing_key" : "navel-scheduler.collections",
    "delivery_mode" : 2,
    "scheduling" : "*/15 * * * * ?"
}
```
  - /scheduler/api/publishers
```json
[
    "rabbitmq-1",
    "rabbitmq-2"
]
```
  - /scheduler/api/publishers/(:publisher)
```json
{
    "name" : "rabbitmq-1",
    "connected" : 0,
    "messages_in_queue" : 500
}
```
  - /scheduler/api/publishers/(:publisher)?action=clear_queue
```json
{
    "name" : "rabbitmq-1",
    "connected" : 0,
    "messages_in_queue" : 0
}
```
  - /scheduler/api/publishers/(:publisher)?action=connect
```json
{
    "name" : "rabbitmq-1",
    "connected" : 1,
    "messages_in_queue" : 5
}
```
  - /scheduler/api/publishers/(:publisher)?action=disconnect
```json
{
    "name" : "rabbitmq-1",
    "connected" : 1,
    "messages_in_queue" : 0
}
```
  - /scheduler/api/webservices
```json
[
    "webservice-1",
    "webservice-2"
]
```
  - /scheduler/api/webservices/(:webservice)
```json
[
    {
        "name" : "webservice-1",
        "interface_mask" : "*",
        "port" : 80,
        "tls" : 0
    }
]
```
- **POST** - create
  - /scheduler/api/connectors
```json
{
    "name" : "glpi-2",
    "collection" : "glpi",
    "type" : "code",
    "singleton" : 1,
    "scheduling" : "15 * * * * ?",
    "source" : "glpi",
    "input" : {
        "url" : "http://login:password@glpi2.home.fr:8080"
    }
}
```
  - /scheduler/api/rabbitmq
```json
{
    "name" : "rabbitmq-3",
    "host" : "172.16.1.3",
    "port" : 5672,
    "user" : "guest",
    "password" : "guest",
    "timeout" : 0,
    "vhost" : "/",
    "exchange" : "navel-scheduler.E.direct.events",
    "routing_key" : "navel-scheduler.collections",
    "delivery_mode" : 2,
    "scheduling" : "*/15 * * * * ?"
}
```
  - /scheduler/api/publishers/(:publisher)
```json
[
    "foo",
    "bar"
]
```
- **PUT** - modify
  - /scheduler/api/general/webservices
```json
{
    "password" : "new_password"
}
```
  - /scheduler/api/connectors/(:connector)
```json
{
    "scheduling" : "*/30 * * * * ?"
}
```
  - /scheduler/api/rabbitmq/(:rabbitmq)
```json
{
    "timeout" : 5
}
```
- **DEL** - delete
  - /scheduler/api/connectors/(:connector)
```json
{
    "ok" : [
        "Connector glpi-2 unregistered and deleted"
    ],
    "ko" : []
}
```
  - /scheduler/api/rabbitmq/(:rabbitmq)
```json
{
    "ok" : [
        "Publisher rabbitmq-3 disconnected, unregistered and deleted",
        "RabbitMQ rabbitmq-3 deleted"
    ],
    "ko" : []
}
```

Connectors
----------

Connectors are plain JSON files or Perl scripts which must contain a method named `connector`.

An exemple of Perl connector :

```perl
# pragmas strict and warnings + Navel::Utils are automatically loaded

#-> connector callback

sub connector {
    my ($connector_properties, $input) = @_;

    my @datas; # or retrieve datas from databases, message brokers, web services, ...

    \@datas;
}
```
