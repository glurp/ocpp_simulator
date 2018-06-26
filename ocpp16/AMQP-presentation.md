

# Présentation AMQP

[https://www.rabbitmq.com/tutorials/amqp-concepts.html]{.underline}

##  Base

**Virtual-host**

Un serveur AMQP peut supporte plusieurs 'virtual-host' : cela permet de de patronner les domaines gérés par un serveur AMQP. (saia-ve : typiquement un virtual-host par contrat)

**Connexion**

Un micro service se connecte une fois, il peut préciser le 'virtual-host' sur lequel il doit travailler

**Channel**

Lien TCP entre un client et le serveur AMQP.

Une connexion peut supporter plusieurs channel, cela permet de définir des niveaux d'urgence . \>Par exemple :

-   Un channel pour le fond de messages (gros debit, peut critique),

-   Un channel pour les messages urgents (faible debit, latence critique).

##  Publish/Subscribe

Le modèle est un peu complexe :

-   **Exchange** : défini un topic, soit un sujet de pubsub : nom, structure de message, QOS..(durabilité et auto-delete)

<!-- -->

-   **Message **: un message (texte/binaire), auquel on associe des meta-data. Un message est émis vers un Exchange. Un méta-data de base est le « routing-key » : String sur lequel des rules peuvent appliquer du pattern-matching.\
    Les 4 métadonnées suivantes sont les plus courantes :

  delivery\_mode    Marks a message as persistent (with a value of 2) or transient (any other value).
----------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------
  content\_type     Used to describe the mime-type of the encoding. For example for the often used JSON encoding it is a good practice to set this property to application/json
  reply\_to         Commonly used to name a callback queue.
  correlation\_id   Useful to correlate RPC responses with requests.

-   **Queue** : pile de messages, typiquement une pile par consommateur.\
    Peut être utilisé pour le partage de charge : une pile, plusieurs thread/process consommateurs, dans ce cas un message représente une demande de travail, qui ne sera pris en compte que par un seul consommateur.

-   **Rule** : **binding** permettant de relie un **Exchange** à une **Queue**. Pour chaque message émis sur un Exchange, la/les rules permettent de décider si le message doit être cloné/empiler dans sa Queue associée.La décision utilise les meta-data du message (conditions logique et pattern matching)\
    Une Rule ne concerne qu'un exchange et une Queue, Plusieurs Rules peuvent relier un Exchange et une Queue (permet le OU de Rule),\
    Une queue peut être 'binder' avec plusieurs exchange : cela permettra à un consommateur de n'avoir qu'un point d'entrée pour tous les messages (topics) en input.

Donc, le design des méta-data des **messages** détermine les **rules** utilisables, qui déterminent les **Exchange** à configurer. Cela effectué, chaque consommateur créera sa/ses queue(s) avec les rules associés.

### Topologies typiques

Pour de petites applications, on peut ne pas déclarer d'Exchange : un Exchange par défaut préexiste systématiquement (exchange de nom ''), les rules peuvent mentionner cet exchange.

**Direct Exchange Routing** :

La routing-key porte le nom de la queue destinatrice : l'émetteur d'un message connait exactement son destinataire, et il est unique

![https://www.rabbitmq.com/img/tutorials/python-three-overall.png](media/image20.png){width="2.681375765529309in" height="1.3051137357830271in"}

![https://www.rabbitmq.com/img/tutorials/python-four.png](media/image21.png){width="3.029950787401575in" height="1.2274617235345582in"}

**Fanout exchange**

L'Exchange envoie les messages reçus sur chaque queue qui lui est associée.

![https://www.rabbitmq.com/img/tutorials/exchanges.png](media/image22.png){width="2.3183103674540684in" height="0.7729265091863518in"}

**Topic Exchange**

Exchange de type Pub/sub.

![https://www.rabbitmq.com/img/tutorials/python-five.png](media/image23.png){width="4.383333333333334in" height="1.7729166666666667in"}

**Header Exchcange.**

Direct exchange, mais toutes les meta-data peuvent être utilisés, (integer, float, boolean...)

## Requête/Réponse

Exchange de type Question/réponse. La queue de réponse n'est pas encapsulée par l'API AMQP !

![https://www.rabbitmq.com/img/tutorials/python-six.png](media/image24.png){width="4.504892825896763in" height="1.5652416885389326in"}

Le client doit créer une queue, réserver a toutes les réponses des QR qu'il fera. A l'émission de la requête, il positionne le nom de sa queue de réponse et un identifiant (correlation\_id) permettant de recoller une réponse a une question (Un micro service peut être multi-thread, donc il peut y avoir plusieurs QR en parallèle).

La réponse peut être traitée de manière synchrone ou asynchrone.

##  Orchestration

Pour faire fonctionner une appli microservice orientée message, il faut un service permettant :

-   De lancer /arrêter le middleware, de surveiller sa bonne marche, de le tuer/relancer si besoin

-   De gérer une liste de micro service 'résident', avec leurs paramètres

-   De lancer la liste des micro service configurés

-   D'arrêter l'application : microservice et middleware

-   Supporter une IHM pour maintenir l'appli :

    -   ajout de micro-service,

    -   arrêt / relance,

    -   etat : stats par mq , etat du service , logs, ping...

    -   test ....

IL serait dommageable de développer cela pour nos besoins.

A voir si on trouve ce qu'il faut en logiciel libre ... 

##
