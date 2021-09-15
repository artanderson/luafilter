---
id: java-modeling_using_maps
title: Modeling Using Maps
---

# Modeling Using Maps

*Last updated: August 6, 2021*

This notebook shares how Aerospike facilitates working with map data,
covering the following topics:

1.  Ordering
2.  Index & Rank
3.  Nested Structures (subcontexts)

The above Aerospike Map capabilities provide significant utility through
providing easy and precise control and access to map data. This notebook
shares how to incorporate these strengths and best practices, and use
Maps as a powerful modeling tool.

This [Jupyter
Notebook](https://jupyter-notebook.readthedocs.io/en/stable/notebook.html)
requires the Aerospike Database running locally with Java kernel and
Aerospike Java Client. To create a Docker container that satisfies the
requirements and holds a copy of these notebooks, visit the [Aerospike
Notebooks
Repo](https://github.com/aerospike-examples/interactive-notebooks).

## Notebook Setup

### Import Jupyter Java Integration

``` java
import io.github.spencerpark.ijava.IJava;
import io.github.spencerpark.jupyter.kernel.magic.common.Shell;

IJava.getKernelInstance().getMagics().registerMagics(Shell.class);
```

### Start Aerospike

``` java
%sh asd
```

### Download the Aerospike Java Client

``` java
%%loadFromPOM
<dependencies>
  <dependency>
    <groupId>com.aerospike</groupId>
    <artifactId>aerospike-client</artifactId>
    <version>5.0.0</version>
  </dependency>
</dependencies>
```

### Start the Aerospike Java Client and Connect

The default cluster location for the Docker container is *localhost*
port *3000*. If your cluster is not running on your local machine,
modify *localhost* and *3000* to the values for your Aerospike cluster.

``` java
import com.aerospike.client.AerospikeClient;

AerospikeClient client = new AerospikeClient("localhost", 3000);
System.out.println("Initialized the client and connected to the cluster.");
```

> Initialized the client and connected to the cluster.

# Prerequisites

-   [Reading and Updating Maps](./java-working_with_maps.ipynb)
-   [Advanced Collection Data
    Types](./java-advanced_collection_data_types.ipynb)
-   [Introduction to Data Modeling](./java-intro_to_data_modeling.ipynb)
-   [Modeling Using Lists](./java-modeling_using_lists.ipynb)

# Aerospike Provides Powerful Resources for Working with Document-Oriented Data

Aerospike is a real-time data platform architected to store
Document-Oriented Data efficiently at scale. Rather than a traditional
KVS approach of blindly storing blobs in the database and sorting the
data in the application, Aerospike provides rich Map and List
(Collection Data Type) APIs for operating on Aerospike Records. The
result is that rather than spending an outsized time packing, unpacking,
and transporting data to and from the database, significant performance
efficiencies are gained by working with Document-Oriented Data on the
server-side.

# Apply Key-Order or Key/Value-Order to Maps

The default order for Aerospike Maps is unordered. The best practice is
to use an ordered map, either Key-ordered (K-ordered) or
Key/Value-ordered (KV-ordered):

-   If the application reads data only by-key, use K-ordered.
-   If the application reads data frequently by either by-value or
    by-rank operations, use KV-ordered.

Worst case [Map Operation
Performance](https://docs.aerospike.com/docs/guide/cdt-map-performance.html)
highlight that the benefits of operating on a pre-sorted list are
significant.

## Ordering Example

Add map keys `(b=0, z=2, c=9, a=1, yy=1)` to Bins containing unordered,
K-ordered, and KV-ordered maps.

``` java
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import com.aerospike.client.Key;
import com.aerospike.client.Bin;
import com.aerospike.client.Record;
import com.aerospike.client.Operation;
import com.aerospike.client.Value;
import com.aerospike.client.cdt.MapOperation;
import com.aerospike.client.cdt.MapOrder;
import com.aerospike.client.cdt.MapPolicy;
import com.aerospike.client.cdt.MapWriteFlags;


String mapModelSetName = "mapmodelset1";
String mapModelNamespaceName = "test";

String mapOrderKeyName = "mapOrder";
Key mapOrderKey = new Key(mapModelNamespaceName, mapModelSetName, mapOrderKeyName);

String unorderedMapBinName = "uoBin";
String kOrderedMapBinName = "koBin";
String kvOrderedMapBinName = "kvoBin";

Bin bin1 = new Bin(unorderedMapBinName, mapOrderKeyName);
Bin bin2 = new Bin(kOrderedMapBinName, mapOrderKeyName);
Bin bin3 = new Bin(kvOrderedMapBinName, mapOrderKeyName);

MapPolicy unorderedBinPolicy = new MapPolicy();
MapPolicy kOrderedBinPolicy = new MapPolicy(MapOrder.KEY_ORDERED, MapWriteFlags.DEFAULT);
MapPolicy kvOrderedBinPolicy = new MapPolicy(MapOrder.KEY_VALUE_ORDERED, MapWriteFlags.DEFAULT);


String stringKey0 = "b";
Integer intValue0 = 0;
String stringKey1 = "z";
Integer intValue1 = 2;
String stringKey2 = "c";
Integer intValue2 = 9;
String stringKey3 = "a";
Integer intValue3 = 1;
String stringKey4 = "yy";
Integer intValue4 = 1;


Record addMapKeys = client.operate(null, mapOrderKey,
    MapOperation.put(unorderedBinPolicy, unorderedMapBinName, Value.get(stringKey0), Value.get(intValue0)), 
    MapOperation.put(kOrderedBinPolicy, kOrderedMapBinName, Value.get(stringKey0), Value.get(intValue0)), 
    MapOperation.put(kvOrderedBinPolicy, kvOrderedMapBinName, Value.get(stringKey0), Value.get(intValue0)), 
    MapOperation.put(unorderedBinPolicy, unorderedMapBinName, Value.get(stringKey1), Value.get(intValue1)), 
    MapOperation.put(kOrderedBinPolicy, kOrderedMapBinName, Value.get(stringKey1), Value.get(intValue1)), 
    MapOperation.put(kvOrderedBinPolicy, kvOrderedMapBinName, Value.get(stringKey1), Value.get(intValue1)), 
    MapOperation.put(unorderedBinPolicy, unorderedMapBinName, Value.get(stringKey2), Value.get(intValue2)), 
    MapOperation.put(kOrderedBinPolicy, kOrderedMapBinName, Value.get(stringKey2), Value.get(intValue2)), 
    MapOperation.put(kvOrderedBinPolicy, kvOrderedMapBinName, Value.get(stringKey2), Value.get(intValue2)), 
    MapOperation.put(unorderedBinPolicy, unorderedMapBinName, Value.get(stringKey3), Value.get(intValue3)), 
    MapOperation.put(kOrderedBinPolicy, kOrderedMapBinName, Value.get(stringKey3), Value.get(intValue3)), 
    MapOperation.put(kvOrderedBinPolicy, kvOrderedMapBinName, Value.get(stringKey3), Value.get(intValue3)), 
    MapOperation.put(unorderedBinPolicy, unorderedMapBinName, Value.get(stringKey4), Value.get(intValue4)), 
    MapOperation.put(kOrderedBinPolicy, kOrderedMapBinName, Value.get(stringKey4), Value.get(intValue4)), 
    MapOperation.put(kvOrderedBinPolicy, kvOrderedMapBinName, Value.get(stringKey4), Value.get(intValue4)) 
    );
Record outMaps = client.get(null, mapOrderKey);


System.out.println("The unordered map is: " + outMaps.getValue(unorderedMapBinName));
System.out.println("The k-ordered map is: " + outMaps.getValue(kOrderedMapBinName));
System.out.println("The kv-unordered map is also: " + outMaps.getValue(kvOrderedMapBinName));
```

> The unordered map is: {yy=1, a=1, b=0, z=2, c=9}  
> The k-ordered map is: {a=1, b=0, c=9, yy=1, z=2}  
> The kv-unordered map is also: {a=1, b=0, c=9, yy=1, z=2}

**Note:** As demonstrated above, using unordered Maps in Aerospike will
not preserve insertion order. If insertion order is relevant to the
application, consider the following options:

-   Appending Maps to an Unordered List
-   Storing insertion order or a timestamp-like field in your Map

# Map Index and Rank

In Aerospike, **Map Index** operations provide data in the key order.

**Map Rank** operations provides data in order of the value. Aerospike
provides a methodical order for maps, the following are factors that
impact rank:

1.  Higher number of elements in the Map means higher rank.
2.  For maps with the same number of elements, compare the KV-sorted
    list.
    -   Higher key results in higher rank.
    -   Same key and higher value results in higher rank.

**Note:** Aerospike's range operations for Index, Rank, and Value are
powerful, though not used here. See [Modeling Using
Lists](./java-modeling_using_lists.ipynb) or [Reading and Updating
Maps](./java-working_with_maps.ipynb) for examples.

## Index and Rank Examples

The following example shows index and rank operations using a list of
maps.

### Create List of Maps Example Data

`[    {z=26}    {a=1, b=2}    {e=5, a=1, b=2, c=3}    {c=3, b=2}    {b=2, c=3}    {a=1} ]`

``` java
import com.aerospike.client.cdt.ListOperation;
import com.aerospike.client.cdt.ListOrder;
import com.aerospike.client.cdt.ListPolicy;
import com.aerospike.client.cdt.ListWriteFlags;
import com.aerospike.client.cdt.ListReturnType;
import com.aerospike.client.cdt.MapReturnType;
import com.aerospike.client.cdt.CTX;


String stringKey0 = "z";
Integer intValue0 = 26;
String stringKey1 = "a";
Integer intValue1 = 1;
String stringKey2 = "b";
Integer intValue2 = 2;
String stringKey3 = "c";
Integer intValue3 = 3;
String stringKey4 = "e";
Integer intValue4 = 5;


String mapIndexAndRankKeyName = "mapIndexAndRank";
Key mapIndexAndRankKey = new Key(mapModelNamespaceName, mapModelSetName, mapIndexAndRankKeyName);

String unorderedListBinName = "uoListBin";

Bin bin1 = new Bin(unorderedListBinName, mapIndexAndRankKeyName);

Record addMapKeys = client.operate(null, mapIndexAndRankKey,
    ListOperation.clear(unorderedListBinName),
    ListOperation.create(unorderedListBinName, ListOrder.UNORDERED, false),
    MapOperation.create(unorderedListBinName, MapOrder.UNORDERED, CTX.listIndexCreate(0, ListOrder.UNORDERED, false)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey0), Value.get(intValue0), CTX.listIndex(0)),
    MapOperation.create(unorderedListBinName, MapOrder.UNORDERED, CTX.listIndexCreate(1, ListOrder.UNORDERED, false)),    
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey1), Value.get(intValue1), CTX.listIndex(1)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey2), Value.get(intValue2), CTX.listIndex(1)),
    MapOperation.create(unorderedListBinName, MapOrder.UNORDERED, CTX.listIndexCreate(2, ListOrder.UNORDERED, false)),    
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey4), Value.get(intValue4), CTX.listIndex(2)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey1), Value.get(intValue1), CTX.listIndex(2)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey2), Value.get(intValue2), CTX.listIndex(2)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey3), Value.get(intValue3), CTX.listIndex(2)),
    MapOperation.create(unorderedListBinName, MapOrder.UNORDERED, CTX.listIndexCreate(3, ListOrder.UNORDERED, false)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey3), Value.get(intValue3), CTX.listIndex(3)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey2), Value.get(intValue2), CTX.listIndex(3)),
    MapOperation.create(unorderedListBinName, MapOrder.UNORDERED, CTX.listIndexCreate(4, ListOrder.UNORDERED, false)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey2), Value.get(intValue2), CTX.listIndex(4)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey3), Value.get(intValue3), CTX.listIndex(4)),
    MapOperation.create(unorderedListBinName, MapOrder.UNORDERED, CTX.listIndexCreate(5, ListOrder.UNORDERED, false)),
    MapOperation.put(unorderedBinPolicy, unorderedListBinName, Value.get(stringKey1), Value.get(intValue1), CTX.listIndex(5))
    );
Record listOfMaps = client.get(null, mapIndexAndRankKey);

System.out.println("The data is: " + listOfMaps.getValue(unorderedListBinName));
```

> The data is: \[{z=26}, {a=1, b=2}, {a=1, b=2, c=3, e=5}, {b=2, c=3}, {b=2, c=3}, {a=1}\]

**Note:** This was explicitly written longform to not hide any important
knowledge in Java code complexity. Most developers would create a Java
TreeMap and use putItems to put the map in Aerospike.

### Use Index and Rank

``` java
Record getIndexAndRank = client.operate(null, mapIndexAndRankKey,
    MapOperation.getByIndex(unorderedListBinName, 0, MapReturnType.KEY_VALUE, CTX.listIndex(2)),
    ListOperation.getByRankRange(unorderedListBinName, 0, 6, ListReturnType.VALUE)
    );

List<?> indexAndRankResults = getIndexAndRank.getList(unorderedListBinName);
System.out.println("The first element by index in the 3rd map in the list is:" + indexAndRankResults.get(0));
System.out.println("The maps in order from highest to lowest rank is: " + indexAndRankResults.get(1));
```

> The first element by index in the 3rd map in the list is:\[a=1\]  
> The maps in order from highest to lowest rank is: \[{a=1, b=2, c=3, e=5}, {b=2, c=3}, {b=2, c=3}, {a=1, b=2}, {z=26}, {a=1}\]

# Distinguishing Maps from Bins

It is important to highlight how an Aerospike Map (in a Bin) differs
from a Bin.

## Unique Properties of Aerospike Bins

Bins were architected with the following design constraints:

-   A Namespace can contain a maximum of 32k-1 unique Bin names. This
    was increased to 64k-1 in Aerospike Database 5.0+.
-   A Record can contain up to 32k-1 Bins.
-   Bins names are limited to 15 characters and are stored unencoded.
-   Bins have higher metadata overhead than Maps.

## Unique Properties of Maps

Maps were architected for the flexibility needed from the data type.

### Storage Efficiency

By comparison, Aerospike Maps use [MessagePack
Serialization](https://msgpack.org/index.html), to compress and index a
map's keys and values. This makes storing and working with large maps
quite efficient.

### Setting Context to Operations

Aerospike Database supports arbitrarily deep nesting within Container
Data Types (CDTs), Lists and Maps. As an application adds data to a Map
in Aerospike, the application also creates indexes and subindexes, which
allow operations to supply an operation with the precise context of the
data to be operated on. By understanding the nested structure of a Map,
an application can efficiently apply operations to the appropriate
context within a Map and send only the relevant parts of a Map across
the wire back to the client.

## Bins or Maps: Best Practice for Modeling

Based on the above constraints, the best practices for longterm
Aerospike use are:

1.  When storing data in Bins, use *and reuse* fewer, shorter,
    consistent Bin names.
2.  Use Maps with arbitrary nesting widely.

## Map Index, Rank, and Context Example

A credit card user can have multiple credit cards. This is modeled as:

-   A User: Bin containing a K-ordered map
    -   Cards: Mapkey whose value is an Unordered list
        -   A Card: KV-ordered map

### Create Credit Card Model Data

`user:    {     "cards" =        [          {              "last_six" = 51111             "expires" = 202201             "cvv" = 111             "zip" = 95008             "default" = 1          }       ]    }`

``` java
import java.util.List;
import java.util.Map;

String cardsMapKey = "cards";    
List<String> emptyCardsList = Collections.<String>emptyList();

String cardMapKeyLast6 = "last_six";
String cardMapKeyExp = "expires";
String cardMapKeyCVV = "cvv";
String cardMapKeyZip = "zip";
String cardMapKeyDefault = "default";


Integer cardValue1Last6 = 511111;
Integer cardValue1Exp = 202201;
Integer cardValue1CVV = 111;
Integer cardValue1Zip = 95008;
Integer cardValueDefault = 1;


String mapCreditCardKeyName = "mapCreditCard";
Key mapCreditCardKey = new Key(mapModelNamespaceName, mapModelSetName, mapCreditCardKeyName);

Bin bin1 = new Bin(kOrderedMapBinName, mapCreditCardKeyName);

Record createUserAndAddCC1 = client.operate(null, mapCreditCardKey,
    MapOperation.clear(kOrderedMapBinName),
    MapOperation.put(kOrderedBinPolicy, kOrderedMapBinName, Value.get(cardsMapKey), Value.get(emptyCardsList)),
    MapOperation.create(kOrderedMapBinName, MapOrder.KEY_VALUE_ORDERED, CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndexCreate(0, ListOrder.UNORDERED, false)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyLast6), Value.get(cardValue1Last6), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(0)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyExp), Value.get(cardValue1Exp), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(0)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyCVV), Value.get(cardValue1CVV), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(0)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyZip), Value.get(cardValue1Zip), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(0)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyDefault), Value.get(cardValueDefault), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(0))
    );
    
Record getCardMap = client.get(null, mapCreditCardKey);
System.out.println("The Credit Card data is: " + getCardMap.getValue(kOrderedMapBinName));
```

> The Credit Card data is: {cards=\[{cvv=111, default=1, expires=202201, last_six=511111, zip=95008}\]}

**Note:** This was explicitly written longform to not hide any knowledge
in Java code complexity. Most developers would create a Java TreeMap and
use putItems to put the map in Aerospike.

### Use Index, Rank, and Contexts

``` java
Integer cardValue2Last6 = 522222;
Integer cardValue2Exp = 202202;
Integer cardValue2CVV = 222;
Integer cardValue2Zip = 95008;

Record getDefaultCard1 = client.operate(null, mapCreditCardKey,
    ListOperation.getByRank(kOrderedMapBinName, -1, ListReturnType.VALUE, CTX.mapKey(Value.get(cardsMapKey)))
    );
System.out.println("The default card is: " + getDefaultCard1.getValue(kOrderedMapBinName));

Record addCC2 = client.operate(null, mapCreditCardKey,
    MapOperation.create(kOrderedMapBinName, MapOrder.KEY_VALUE_ORDERED, CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndexCreate(1, ListOrder.UNORDERED, false)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyLast6), Value.get(cardValue2Last6), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(1)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyExp), Value.get(cardValue2Exp), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(1)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyCVV), Value.get(cardValue2CVV), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(1)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyZip), Value.get(cardValue2Zip), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(1))
    );

Record getCard2 = client.operate(null, mapCreditCardKey,
    ListOperation.getByIndex(kOrderedMapBinName, 1, ListReturnType.VALUE, CTX.mapKey(Value.get(cardsMapKey)))
    );

Record getDefaultCard2 = client.operate(null, mapCreditCardKey,
    ListOperation.getByRank(kOrderedMapBinName, -1, ListReturnType.VALUE, CTX.mapKey(Value.get(cardsMapKey)))
    );

Record makeCard2TheDefault = client.operate(null, mapCreditCardKey,
    MapOperation.removeByKey(kOrderedMapBinName, Value.get(cardMapKeyDefault), MapReturnType.NONE, CTX.mapKey(Value.get(cardsMapKey)), CTX.listRank(0)),
    MapOperation.put(kvOrderedBinPolicy, kOrderedMapBinName, Value.get(cardMapKeyDefault), Value.get(cardValueDefault), CTX.mapKey(Value.get(cardsMapKey)), CTX.listIndex(1))
    );

Record getDefaultCard3 = client.operate(null, mapCreditCardKey,
    ListOperation.getByRank(kOrderedMapBinName, -1, ListReturnType.VALUE, CTX.mapKey(Value.get(cardsMapKey)))
    );

System.out.println("Added new card: " + getCard2.getValue(kOrderedMapBinName));
System.out.println("The default card is still: " + getDefaultCard2.getValue(kOrderedMapBinName));
System.out.println("Changed the default card, the new default is: " + getDefaultCard3.getValue(kOrderedMapBinName));
```

> The default card is: {cvv=111, default=1, expires=202201, last_six=511111, zip=95008}  
> Added new card: {cvv=222, expires=202202, last_six=522222, zip=95008}  
> The default card is still: {cvv=111, default=1, expires=202201, last_six=511111, zip=95008}  
> Changed the default card, the new default is: {cvv=222, default=1, expires=202202, last_six=522222, zip=95008}

# Notebook Cleanup

## Truncate the Set

Truncate the set from the Aerospike Database.

``` java
import com.aerospike.client.policy.InfoPolicy;
InfoPolicy infoPolicy = new InfoPolicy();

client.truncate(infoPolicy, mapModelNamespaceName, mapModelSetName, null);
System.out.println("Set Truncated.");
```

> Set Truncated.

## Close the Connection to Aerospike

``` java
client.close();
System.out.println("Server connection closed.");
```

> Server connection closed.

# Takeaways – Maps are Flexible and Powerful

Aerospike's Index and Rank methods make Maps powerful. Make sure to K or
KV-order the Maps, and take advantage of nesting and contexts.

## What's Next?

### Next Steps

Have questions? Don't hesitate to post about modeling using maps on
[Aerospike's Discussion
Forums](https://discuss.aerospike.com/c/how-developers-are-using-aerospike/data-modeling/143).

Want to check out other Java notebooks?

1.  [Hello, World](./hello_world.ipynb)
2.  [Aerospike Query and UDF](./query_udf.ipynb)
3.  [Simple Put Get Example](./SimplePutGetExample.ipynb)
4.  [Expressions](./expressions.ipynb)
5.  [Advanced Collection Data
    Types](./java-advanced_collection_data_types.ipynb)

Are you running this from Binder? [Download the Aerospike Notebook
Repo](https://github.com/aerospike-examples/interactive-notebooks) and
work with Aerospike Database and Jupyter locally using a Docker
container.

## Additional Resources

-   Want to get started with Java?
    [Download](https://www.aerospike.com/download/client/) or
    [install](https://github.com/aerospike/aerospike-client-java) the
    Aerospike Java Client.
-   What other ways can we work with Lists? Take a look at [Aerospike's
    List
    Operations](https://www.aerospike.com/apidocs/java/com/aerospike/client/cdt/ListOperation.html).
-   What are Namespaces, Sets, and Bins? Check out the [Aerospike Data
    Model](https://www.aerospike.com/docs/architecture/data-model.html).
-   How robust is the Aerospike Database? Browse the [Aerospike Database
    Architecture](https://www.aerospike.com/docs/architecture/index.html).
