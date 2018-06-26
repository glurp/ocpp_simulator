> 

# Présentation AMQP

Voir annexe 9.1 et : [https://www.rabbitmq.com/tutorials/amqp-concepts.html]{.underline}

##  Notions de base

**Server AMQP : Broker ou severless**

Une messagerie AMQP peut être

-   **serverless** : la messagerie fonctionne alors en peer to peer. La Connection est tout de même nécessaire pour entré dans le domaine.

-   Avec **Broker** : Process (ou sous-système) supportant toutes la messagerie : toutes les requêtes arrivent dans le broker, celui-ci distribue les messages vers les clients concernés.

**Virtual-host**

Un broker AMQP peut supporter plusieurs 'virtual-host' : cela permet de partitionner les domaines gérés par un serveur AMQP. (saia-ve : typiquement un virtual-host par contrat)

**Connexion**

Un micro service se connecte une fois, il peut préciser le 'virtual-host' sur lequel il doit travailler

**Channel**

Lien TCP entre un client et le serveur AMQP.

Une connexion peut supporter plusieurs channel, cela permet de définir des niveaux d'urgence . Par exemple :

-   Un channel pour le fond de messages (gros débit, peut critique),

-   Un channel pour les messages urgents (faible débit, latence critique).

**Transaction**

Le concept de transaction permet à un émetteur de message de s'assurer que tous les messages à émettre sont bien émis de manière intègre : tous les messages sont émis (commit) ou-bien aucun message n'est émis (rollback).

Cela ne présuppose pas que tout les messages soient bien traités par au moins un consommateur (cela peut être assuré si entités d'échanges AMQP (exchange, queue) sont crée en QOS 'persistant') \...

**Acquittement**

Le receveur d'un message doit acquitter tous messages reçus. Il peut acquitter dès réception, ou après traitement.

si le **Broker** détecte qu'un micro service est hors-service (connexion fermée ou processus tué ou socket du Channel fermé), il réémettra les messages non-acquittés sur la queue concerné.

L'ensemble transaction+Acquitement permet de fiabiliser les échanges, sans pour autans garantir le caractère ACID des transactions.

##  Model

Le modèle pour faire de la messagerie est un peu complexe. Cette complexité a pour but de permettre l'usage de pattern de communication divers et varié : Au lieu de définir un Subscriber et un Publisher, AMQP définie des entités divers : Exchange, Queue, Rule, et Message.

Les différentes combinaisons de ces éléments permettent :

-   Publish / subscribe : communication par abonnement / diffusion

-   Job sheduling : partage de charge par requête distribué

-   Broadcast / multicast : émission systématique de message à tout le monde ou quelques uns

-   Rendez-vous : synchroniser deux services sur une ressource commune

-   RPC : Question/reponse, synchrone et/ou asynchrone

On a donc :

-   **Exchange** : défini une entrée de message dans la messagerie : il est définie par un nom, une structure de message/schema (?), une QOS (durabilité et/ou auto-delete, suplante une QOS par message).\
    Un Exchange ne définie pas de queue : il s'agit d'une porte d'entrée de message.\
    Pour de petites applications, on peut ne pas déclarer d'Exchange : un Exchange par défaut préexiste systématiquement (exchange de nom ''), les rules peuvent binder cet exchange avec un ensemble de queue.

<!-- -->

-   **Message **: un message (texte/binaire,'payload'), auquel on associe des méta-data ('header', à la http). Un message est émis vers un Exchange. Un header obligatoire est le « routing-key » : String sur lequel des rules peuvent appliquer du pattern-matching pour selectionner les destinataire(s) d'un message (queue).\
    Les 4 méta-données suivantes sont les plus courantes :

  delivery\_mode    Persistent ou transcient , QOS associé individuellement à un message (peut etre suplante par le QOS de l'exchange)
----------------- --------------------------------------------------------------------------------------------------------------------
  content\_type     mime-type 'application/json'
  reply\_to         QR : Nom de la queue de réponse. (RPC, rendez-vous...)
  correlation\_id   QR : ID message de la requête, rappelé dans le message réponse .

-   **Queue** : pile de messages, typiquement une pile par consommateur.\
    Accessoirement, une queue peut être utilisé pour le partage de charge : une pile, plusieurs thread/process consommateurs, dans ce cas un message représente une demande de travail, qui ne sera pris en compte que par un seul consommateur (le premier disponible).\
    Un queue ne peut recevoir de message que via un Exchange (si une Rule le permet).

-   **Rule** : **binding** permettant de relie un **Exchange** à une **Queue**. Pour chaque message émis sur un Exchange, la/les rules permettent de décider si le message doit être cloné/empilé dans sa Queue associée. La décision utilise les meta-data du message (conditions logique et pattern matching)\
    Une Rule ne concerne qu'un exchange et une Queue, Plusieurs Rules peuvent relier un Exchange et une Queue (permet le OU de Rule),\
    Une queue peut être 'binder' avec plusieurs exchanges : cela permettra à un consommateur de n'avoir qu'un point d'entrée pour tous les messages (topics) en input.

Donc :

-   Les producteurs de message émettent des messages vers des **Exchange**, en documentant chaque message par un **header**,

-   Les consommateurs reçoivent des messages via des queues,

-   Le lien entre **Exchange** et **Queue** est déclaratif, via une ou plusieurs **Rules** (déclarées lors de la création d'une **Queue**) declarant un lien logique en les données d'un header de message et une **queue**

![](media/image20.png){width="4.346574803149606in" height="0.5402777777777777in"}

Le design des méta-data des **messages** détermine les **rules** utilisables, qui déterminent les **Exchange** à configurer. Cela effectué, chaque consommateur créera sa/ses queue(s) avec les rules associés.

### Topologies typiques

A chaque type de topogie correspond un type d'exchange.

**Direct Exchange Routing** :

La routing-key porte le nom de la queue destinatrice : l'émetteur d'un message connait exactement son destinataire, et il est unique

![https://www.rabbitmq.com/img/tutorials/python-three-overall.png](media/image21.png){width="2.681375765529309in" height="1.3051137357830271in"}

**Fanout exchange** **(one to many: broadcast)**

L'Exchange envoie les messages reçus sur chaque queue qui lui est associée.

![https://www.rabbitmq.com/img/tutorials/exchanges.png](media/image22.png){width="2.3183103674540684in" height="0.7729265091863518in"}

**Publish/Subscribe**

Exchange de type 'topic'. ON remarquera que le subscriber ne peut specifier ses besoins que par une expression reguliere sur un routing-key de message.

![https://www.rabbitmq.com/img/tutorials/python-five.png](media/image23.png){width="4.383333333333334in" height="1.7729166666666667in"}

**Header Exchange.**

Direct exchange, mais toutes les meta-data peuvent être utilisés, (integer, float, boolean...)

## Requête/Réponse

Exchange de type Question/réponse. La queue de réponse n'est pas encapsulée par l'API AMQP !

![https://www.rabbitmq.com/img/tutorials/python-six.png](media/image24.png){width="4.504892825896763in" height="1.5652416885389326in"}

Le client doit créer une queue, réserver à toutes les réponses des QR qu'il fera. A l'émission de la requête, il positionne le nom de sa queue de réponse et un identifiant (correlation\_id) permettant de recoller une réponse a une question (Un micro service peut être multi-thread, donc il peut y avoir plusieurs QR en parallèle).

Cela implique qu'en lecture de queue, un micro-service peut spécifier un message a dépiler, par une meta-donné, et peut attendre en bloquante (synchrone) ou en callback (asynchrone).

La réponse peut être traitée de manière synchrone (pull de la queue de reponse) ou asynchrone (callback sur queue).

On remarque que le message réponse ne passe pas par un Exchange  : il est empilé directement dans la queue de réponse (reply\_to) avec l'id de la requête (correlation\_id).

##  Orchestration

Pour faire fonctionner une appli micro service orientée message, il faut un service permettant :

-   De lancer /arrêter le middleware, de surveiller sa bonne marche, de le tuer/relancer si besoin

-   De gérer une liste de micro service 'résident', avec leurs paramètres

-   De lancer la liste des micro service configurés

-   D'arrêter l'application : micro service et middleware

-   Supporter une IHM pour maintenir l'appli :

    -   ajout de micro-service,

    -   arrêt / relance,

    -   etat : stats par mq , etat du service , logs, ping...

    -   test ....

IL serait dommageable de développer cela pour nos besoins.

A voir si on trouve ce qu'il faut en logiciel libre ... 

## Exemple de code API AMQP

Un producteur :

```
import pika, os, logging

logging.basicConfig()
# Parse CLODUAMQP\_URL (fallback to localhost)
url = os.environ.get(\'CLOUDAMQP\_URL\', \'amqp://guest:guest\@localhost/%2f\')
params = pika.URLParameters(url)
params.socket\_timeout = 5

connection = **pika.BlockingConnection**(params) \# Connect to CloudAMQP
channel = **connection.channel()** \# start a channel
channel.**queue\_declare(queue=\'pdfprocess\')** \# Declare a queue

# send a message

**channel.basic\_publish**(exchange=\'\', routing\_key=\'pdfprocess\', body=\'User information\')

print (\"\[x\] Message sent to consumer\")

**connection.close()**
```

Exemple d'un consommateur :

```
def pdf\_process\_function(msg):
	print(\" PDF processing\")
	print(\" Received %r\" % msg)
	time.sleep(5) \# delays for 5 seconds
	print(\" PDF processing finished\");
	return;

# Connection

url = os.environ.get(\'CLOUDAMQP\_URL\', \'amqp://guest:guest\@localhost:5672/%2f\')
params = pika.URLParameters(url)
connection = **pika.BlockingConnection(params)**
channel = **connection.channel()** \# start a channel
channel.**queue\_declare(queue=[\'pdfprocess\']{.underline})** \# Declare a queue

# create a callback for receive message

def callback(ch, method, properties, body):
. . . . .(body)

#Subscibe

channel.**basic\_consume**(**callback**,queue=[\'pdfprocess\']{.underline},no\_ack=True)

#start consuming (blocks)

**channel.start\_consuming**()
sleep
connection.close()
```



# Règles d'usages

## Objectifs

On doit déterminer des règles (essentiellement des règles de nommages d'entités AMQP) en vue de l'architecture suivante :

-   3D Cube : plusieurs micros services par instance, plusieurs instances par application, plusieurs applications

-   AMQP partageables les ressources middleware (http, HTTPS, SCP, Auth, AMQP) doivent pouvoir être partagées entre :

    -   plusieurs instances

    -   plusieurs applications

-   Support de plusieurs versions d'un micro service

-   Support de micro service transversal (commun à plusieurs instances, plusieurs applications\...)

-   Une seule orchestration

## Nommage des Exchanges

\<nom-appli\>.service.Vn\_n.fonction

Exemple :

> saiave.saia.V1\_0.bddtr
>
> cityapp.rapport.V9\_2.

##  {#section-3 .ListParagraph}

## Nommage des routing-keys

\<nom-instance\>. ????

## Nommage des Queues

\<nom-appli\>.\<nom-instance\>.\<service\>...libre

# Interface SAIA / micro-service

SAIA supporte la notion de service. Cela permet d'associer un Objet de classe Service à des fragments XML ('instruments') de la config de la BDDTR.

Pour chaque instrument, l'objet Service peut émettre des abonnements sur une ou plusieurs variables.

On se propose de répliquer cette structure en remplaçant un objet Service par un micro service. Cela nbecessite de faire supporter par SAIA deux type d'échange : QR et pub/sub

## QR

-   Salve d'écriture : liste de objet/variable/valeur/timestamp/validité

-   Lecture liste de variable, spécification par filtrage sur \<valeur de variable\>,\<nom de variable\>,objet,structure\
    Par exemple :\
    etat de toutes les bornes : str=BORNE\_\* ; nom\_variable = 'etat\_borne'\
    valeur de toutes les variable CHAGE\_BOX\_ID des PDC en charge :  str=CHARGE\_\* valeur\_variable 'etat\_charge'=1 ; nom\_variable : 'CHARGE\_BOX\_ID'\
    réponse : liste de \[structure, objet, nom-variable, valeur, timestamp, validité\]

## Topics services

En service.xml : nom de la queue du micro service

Sur switch :

-   Envoie à chaque micro service concerné : services.xml, instruments du service,

-   Envoie Top before

-   Envoie Top after

-   Envoi shutdown

Un exchange pour toutes les instances SAIA :

> nom :BDDTR

-   Routing\_clef  : app\_NOMAPP.inst\_NOMINST.saia.supervision.commande

## 

## 

## 

## Topics BDDTR

Un exchange pour toutes les instances SAIA :

> nom :BDDTR

-   Routing\_clef  : app\_NOMAPP.inst\_NOMINST.saia.supervision.sub

SAIA envoi à chaque service :

-   Le nom de fichier complet du fichier xsrv\_NONSERVICE.xml,avec préfixe SCP

-   Le contenu de l'entrée du service dans le fichier services.xml

## 

## 

-- -- -- -- -- --

-- -- -- -- -- --

## 

-- --


​     
​     
​     
​     
-- --

# 

-   -   -   -   -   -

<!-- -->

-   -   -

<!-- -->

-   -   

## 

#### 

#### 

###### 

-   -   -   -   -   -   -   -

###### 

-- -- --


​        
​        
-- -- --

##### 

##### 

-   -   -

#### 

-   -   -   -   -   -

##### 

-   -   -

##### 

##### 

### 

### 

### 

-   -   -

### 

-   -   -

## 

### 

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

-   

### 

#### 

#### 

#### 

#### 

-   -   -

#### 

-   -   -

#### 

-   -   -   -   -

#### 

-   -   -

#### 

-   -   -

#### 

#### 

-   -   -

#### 

-   -   

#### 

#### 

#### 

-   -   

#### 

#### 

#### 

#### 

-   -   -   -

#### 

#### 

-   

#### 

-   -   

#### 

#### 

-   

#### 

-   -   -

#### 

#### 

-   -   -

### 

#### 

#### 

#### 

-   

#### 

-   

#### 

#### 

#### 

### 

#### 

#### 

#### 

-   

#### 

## 

-   -   -   -

#### 

+--+------+
|  | -    |
+--+------+
|  |      |
+--+------+
|  |      |
+--+------+
|  |      |
+--+------+

#### 

+--+--------------+
|  | -            |
+--+--------------+
|  |              |
+--+--------------+
|  |              |
+--+--------------+
|  | -   -   -    |
+--+--------------+

#### 

+--+------+
|  | -    |
+--+------+
|  |      |
+--+------+
|  |      |
+--+------+

#### 

-- --


​     
-- --

### 

#### 

+--+--------------+
|  | -   -   -    |
+--+--------------+
|  |              |
+--+--------------+
|  |              |
+--+--------------+
|  |              |
+--+--------------+

#### 

+--+------+
|  | -    |
+--+------+
|  |      |
+--+------+
|  |      |
+--+------+

#### 

+--+--------------+
|  | -   -   -    |
+--+--------------+
|  |              |
+--+--------------+
|  |              |
+--+--------------+

#### 

+--+------------------+
|  | -   -   -   -    |
+--+------------------+
|  |                  |
+--+------------------+
|  |                  |
+--+------------------+

#### 

+--+----------------------+
|  | -   -   -   -   -    |
+--+----------------------+
|  |                      |
+--+----------------------+
|  |                      |
+--+----------------------+

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

#### 

-- --


​     
-- --

#### 

#### 

-- --


​     
-- --

#### 

-- --


​     
-- --

#### 

#### 

-- --


​     
-- --

#### 

-- --

-- --

# Services SAIA AMQP

## Présentation

Pour coupler SAIA à AMQP on prévoie deux modules :

-   CommandeAMQP : reçoit et traite les commandes sur Topics-service,

-   ServiceAMQP : envoi les TOP-BEFORE,TOP\_AFTER,SHUTDOWN, notifications

Le service ServiceAMQP est un service générique, dont le code sera à déclarer à la place d'un service interne, dans le fichier services.xml :

L'arrêt / relance du micro service doit être géré, ainsi que le switch de la BDDTR saia et l'arrêt de SAIA

Il serait souhaitable que l'API SAIA disponible soit répliqué/proxifié dans l'environnement micro service.

Cela permetrait un portage direct du code d'un service SAIA vers un micro-service SAIA.

# API accès SAIA par micro service

TODO

# Doc message

TODO ...

# Annexe

## Présentation AMQP

[http://rubyamqp.info/articles/amqp\_9\_1\_model\_explained/]{.underline}

### About this guide

This guide explains the AMQP 0.9.1 Model used by RabbitMQ. Understanding the AMQP Model will make a lot of other documentation, both for the Ruby amqp gem and RabbitMQ itself, easier to follow. This work is licensed under a [Creative Commons Attribution 3.0 Unported License]{.underline} (including images & stylesheets). The source is available [on Github]{.underline}.

#### What this guide covers

-   High-level overview of the AMQP 0.9.1 Model

-   Key differences between the AMQP model and some other messaging models

-   What exchanges are

-   What queues are

-   What bindings are

-   How AMQP protocol is structured and what AMQP methods are

-   AMQP 0.9.1 message attributes

-   What message acknowledgements are

-   What negative message acknowledgements are

-   and a lot of other things

### High-level overview of AMQP 0.9.1 and the AMQP Model

#### What is AMQP

AMQP (Advanced Message Queuing Protocol) is a networking protocol that enables conforming client applications to communicate with conforming messaging middleware brokers.

#### AMQP 0.9.1 Model in brief

The AMQP 0.9.1 Model has the following view of the world: messages are published by producers to *exchanges*, often compared to post offices or mailboxes. Exchanges then distribute message copies to *queues* using rules called *bindings*. Then AMQP brokers either push messages to *consumers* subscribed to queues, or consumers fetch/pull messages from queues on demand.

![http://localhost/doc/AMQP%200.9.1%20Model%20Explained\_fichiers/001\_hello\_world\_example\_routing.png](media/image29.png){width="4.173870297462817in" height="1.9572954943132108in"}

When publishing a message, producers may specify various *message attributes* (message metadata). Some of this metadata may be used by the broker, however, the rest of it is completely opaque to the broker and is only used by applications that receive the message.

Networks are unreliable and applications may fail to process messages, therefore the AMQP Model has a notion of *message acknowledgements*: when a message is pushed down to a consumer, the consumer *notifies the broker*, either automatically, or as soon as the application developer chooses to do so. When message acknowledgements are in use, a broker will only completely remove a message from a queue when it receives a notification for that message (or group of messages).

In certain situations, for example, when a message cannot be routed, messages may be *returned* to producers, dropped, or, if the broker implements an extension, placed into a so-called "dead letter queue". Producers choose how to handle situations like this by publishing messages using certain parameters.

Queues, exchanges and bindings are commonly referred to as *AMQP entities*.

#### AMQP is a Programmable Protocol

AMQP 0.9.1 is a programmable protocol in the sense that AMQP entities and routing schemes are defined by applications themselves, not a broker administrator. Accordingly, provision is made for protocol operations that declare queues and exchanges, define bindings between them, subscribe to queues and so on.

This gives application developers a lot of freedom but also requires them to be aware of potential definition conflicts. In practice, definition conflicts are rare and often indicate misconfigurations. This can be very useful as it is a good thing if misconfigurations are caught early.

Applications declare the AMQP entities that they need, define necessary routing schemes and may choose to delete AMQP entities when they are no longer used.

### AMQP Exchanges and Exchange Types

*Exchanges* are AMQP entities where messages are sent. Exchanges then take a message and route it into one or more (or no) queues. The routing algorithm used depends on *exchange type* and rules called *bindings*. AMQP 0.9.1 brokers typically provide 4 exchange types out of the box:

-   Direct exchange (typically used for for 1-to-1 communication or unicasting)

-   Fanout exchange (1-to-n communication or broadcasting)

-   Topic exchange (1-to-n or n-to-m communication, multicasting)

-   Headers exchange (message metadata-based routing)

but it is possible to extend AMQP 0.9.1 brokers with custom exchange types, for example:

-   x-random exchange (randomly chooses a queue to route incoming messages to)

-   x-recent-history (a fanout exchange that also keeps N recent messages in memory)

-   regular expressions based variations of headers exchange

and so on.

Besides the type, exchanges have a number of attributes, most important of which are:

-   Name

-   Can be durable (information about them is persisted to disk and thus survives broker restarts) or non-durable (information is only kept in RAM)

-   Can have metadata associated with them on declaration

### AMQP Queues

Queues in the AMQP Model are very similar to queues in other message and "task queueing" systems: they store messages that are consumed by applications. Like AMQP exchanges, an AMQP queue has a name and a durability property but also

-   Can be exclusive (used by only one connection)

-   Can be automatically deleted when last consumer unsubscribes

-   Can have metadata associated with them on declaration (some brokers use this to implement features like message TTL)

### AMQP Bindings

Bindings are rules that exchanges use (among other things) to route messages to queues. To instruct an exchange E to route messages to a queue Q, Q has to *be bound* to E. Bindings may have an optional *routing key* attribute used by some exchange types. The purpose of the routing key is to selectively match only specific (matching) messages published to an exchange to the bound queue. In other words, the routing key acts like a filter.

To draw an analogy:

-   Queue is like your destination in New York city

-   Exchange is like JFK airport

-   Bindings are routes from JFK to your destination. There may be no way, or more than one way, to reach it

Having this layer of indirection enables routing scenarios that are impossible or very hard to implement using publishing directly to queues and also eliminates a certain amount of duplicated work that application developers have to do.

If an AMQP message cannot be routed to any queue (for example, because there are no bindings for the exchange it was published to), it is either dropped or returned to the publisher, depending on the message attributes that the publisher has set.

### AMQP Message Consumers

Storing messages in queues is useless unless applications can *consume* them. In the AMQP 0.9.1 Model, there are two ways for applications to do this:

-   Have messages pushed to them ("push API")

-   Fetch messages as needed ("pull API")

With the "push API", applications have to indicate interest in consuming messages from a particular queue. When they do so, we say that they *register a consumer* or, simply put, *subscribe to a queue*. It is possible to have more than one consumer per queue or to register an *exclusive consumer* (excludes all other consumers from the queue while it is consuming).

Each consumer (subscription) has an identifier called a *consumer tag*. This can be used to unsubscribe from messages. Consumer tags are just strings.

### AMQP Message Attributes and Payload

Messages in the AMQP Model have *attributes*. Some attributes are so common that the AMQP 0.9.1 specification defines them and application developers do not have to think about the exact attribute name. Some examples are

-   Content type

-   Content encoding

-   Routing key

-   Delivery mode (persistent or not)

-   Message priority

-   Message publishing timestamp

-   Expiration period

-   Producer application id

Some attributes are used by AMQP brokers, but most are open to interpretation by applications that receive them. Some attributes are optional and known as *headers*. They are similar to X-Headers in HTTP. Message attributes are set when a message is published.

AMQP messages also have a *payload* (the data that they carry). Brokers treat this data as opaque (it is neither modified nor used by them). It is possible for messages to contain only attributes and no payload. It is common to use serialization formats like JSON, Thrift, Protocol Buffers and MessagePack to serialize structured data in order to publish it as an AMQP message payload.

### AMQP Message Acknowledgements

Since networks are unreliable and applications fail, it is often necessary to have some kind of "processing acknowledgement". Sometimes it is only necessary to acknowledge the fact that a message has been received. Sometimes acknowledgements mean that a message was validated and processed by a consumer, for example, verified as having mandatory data and persisted to a data store or indexed.

This situation is very common, so AMQP 0.9.1 has a built-in feature called *message acknowledgements* (sometimes referred to as *acks*) that consumers use to confirm message delivery and/or processing. If an application crashes (the AMQP broker notices this when the connection is closed), and if an acknowledgement for a message was expected but not received by the AMQP broker, the message is re-queued (and possibly immediately delivered to another consumer, if any exists).

Having acknowledgements built into the protocol helps developers to build more robust software.

### AMQP 0.9.1 Methods

AMQP 0.9.1 is structured as a number of *methods*. Methods are operations (like HTTP methods) and have nothing in common with methods in object-oriented programming languages. AMQP methods are grouped into *classes*. Classes are just logical groupings of AMQP methods. The [AMQP 0.9.1 reference]{.underline} can be found on the RabbitMQ website.

Let us take a look at the exchange.\* class, a group of methods related to operations on exchanges. It includes the following operations:

-   exchange.declare

-   exchange.declare-ok

-   exchange.delete

-   exchange.delete-ok

The operations above form logical pairs: **exchange.declare** and **exchange.declare-ok**, **exchange.delete** and **exchange.delete-ok**. These operations are "requests" and "responses" .

As an example, the client asks the broker to declare a new exchange using the **exchange.declare** method:

As shown on the diagram above, **exchange.declare** carries several\*parameters\*. They enable the client to specify exchange name, type, durability flag and so on.

If the operation succeeds, the broker responds with the **exchange.declare-ok** method:

**exchange.declare-ok** does not carry any parameters except for the channel number.

The sequence of events is very similar for another method pair, **queue.declare** and **queue.declare-ok**:

Not all AMQP methods have counterparts. Some do not have corresponding "response" methods and some others have more than one possible "response".

### AMQP Connections

AMQP connections are typically long-lived. AMQP is an application level protocol that uses TCP for reliable delivery. AMQP connections use authentication and can be protected using TLS . When an application no longer needs to be connected to an AMQP broker, it should gracefully close the AMQP connection instead of abruptly closing the underlying TCP connection.

### AMQP Channels

Some applications need multiple connections to an AMQP broker. However, it is undesirable to keep many TCP connections open at the same time because doing so consumes system resources and makes it more difficult to configure firewalls. AMQP 0.9.1 connections are multiplexed with\*channels\_ that can be thought of as "lightweight connections that share a single TCP connection".

For applications that use multiple threads/processes/etc. for processing, it is very common to open a new channel per thread (process, etc.) and **not share** channels between them.

Communication on a particular channel is completely separate from communication on another channel, therefore every AMQP method also carries a channel number that clients use to figure out which channel the method is for (and thus, which event handler needs to be invoked).

### AMQP Virtual Hosts (vhosts)

To make it possible for a single broker to host multiple isolated "environments" (groups of users, exchanges, queues and so on), AMQP includes the concept of *virtual hosts* (vhosts). They are similar to virtual hosts used by many popular Web servers and provide completely isolated environments in which AMQP entities live. AMQP clients specify the vhosts that they want to use during AMQP connection negotiation.

An AMQP 0.9.1 vhost name can be any non-blank string. Some of the most common use cases for vhosts are

-   To separate AMQP entities used by different groups of applications

-   To separate multiple installations/environments (e.g. production, staging) of one or more applications

-   To implement a multi-tenant environment

### AMQP is Extensible

AMQP 0.9.1 has several extension points:

-   Custom exchange types let developers implement routing schemes that exchange types provided out-of-the-box do not cover well, for example, geodata-based routing.

-   Declaration of exchanges and queues can include additional attributes that the broker can use. For example, per-queue message TTL in RabbitMQ is implemented this way.

-   Broker-specific extensions to the protocol. See, for example, [extensions RabbitMQ implements]{.underline}.

-   New AMQP 0.9.1 method classes can be introduced.

-   Brokers can be extended with additional plugins, for example, RabbitMQ management frontend and HTTP API are implemented as a plugin.

These features make the AMQP 0.9.1 Model even more flexible and applicable to a very broad range of problems.

### Key differences from some other messaging models

One key difference to understand about the AMQP 0.9.1 model is that **messages are not sent to queues. They are sent to exchanges that route them to queues according to rules called "bindings"**. This means that routing is primarily handled by AMQP brokers and not applications themselves.

TBD

### AMQP 0.9.1 clients ecosystem

#### Overview

There are many AMQP 0.9.1 clients for popular programming languages and platforms. Some of them follow AMQP terminology closely and only provide implementations of AMQP methods. Some others have additional features, convenience methods and abstractions. Some of the clients are asynchronous (non-blocking), some are synchronous (blocking), some support both models. Some clients support vendor-specific extensions (for example, RabbitMQ-specific extensions).

Because one of the main AMQP goals is interoperability, it is a good idea for developers to understand protocol operations and not limit themselves to the terminology of a particular client library. This way communicating with developers using different libraries will be significantly easier.

### Wrapping up

This is the end of the AMQP 0.9.1 Model tutorial. Congratulations! Armed with this knowledge, you will find it easier to follow the rest of the amqp gem documentation as well as the rabbitmq.com documentation and the [RabbitMQ mailing list]{.underline}.

To stay up to date with amqp gem development, [follow \@rubyamqp on Twitter]{.underline} and [join our mailing list]{.underline}.

### What to read next

Documentation is organized as a number of documentation guides, covering all kinds of topics from [use cases for various exchange types]{.underline} to [error handling]{.underline} and [Broker-specific AMQP 0.9.1 extensions]{.underline}.

We recommend that you read the following guides next, if possible, in this order:

-   [Connection to the broker]{.underline}. This guide explains how to connect to an AMQP broker and how to integrate the amqp gem into standalone and Web applications.

-   [Working With Queues]{.underline}. This guide focuses on features that consumer applications use heavily.

-   [Working With Exchanges]{.underline}. This guide focuses on features that producer applications use heavily.

-   [Patterns & Use Cases]{.underline}. This guide focuses implementation of [common messaging patterns]{.underline} using AMQP Model features as building blocks.

-   [Error Handling & Recovery]{.underline}. This guide explains how to handle protocol errors, network failures and other things that may go wrong in real world projects.

If you are migrating your application from earlier versions of the amqp gem (0.6.x and 0.7.x), to 0.8.x and later, there is the [amqp gem 0.8 migration guide]{.underline}.

### Tell Us What You Think!

Please take a moment to tell us what you think about this guide on Twitter or the [RabbitMQ mailing list]{.underline}

Let us know what was unclear or what has not been covered. Maybe you do not like the guide style or grammar or discover spelling mistakes. Reader feedback is key to making the documentation better.

This website was developed by the [Ruby AMQP Team]{.underline}.

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 

# 
