import std/times
import std/md5
import std/oids

import balls

import mongo/bson

suite "BSON serializer/deserializer test suite":

  test "Creating empty document with constructor":
    let doc = newBsonDocument()
    check($doc == "{\n}")

  test "Creating empty document with `%*` operator":
    let doc = %*{}
    check($doc == "{\n}")

  test "Creating document with all available types":
    let doc = %*{
      "double": 5436.5436,
      "stringkey": "stringvalue",
      "document": {
        "double": 5436.5436,
        "key": "value"
      },
      "array": [1, 2, 3],
      "int32": 5436'i32,
      "int64": 5436,
    }
    check(doc["double"].toFloat64 == 5436.5436)
    check(doc["stringkey"].toString == "stringvalue")
    check doc["stringkey"] is Bson
    check(doc["stringkey"].toString == "stringvalue")
    check(doc["document"]["double"].toFloat64 == 5436.5436)
    check(doc["document"]["key"].toString == "value")
    check(doc["array"][0].toInt64 == 1'i64)
    check(doc["int32"].toInt32 == 5436'i32)
    check(doc["int64"].toInt64 == 5436'i64)

  test "Document modification usin `[]=` operator":
    let doc = %*{
      "int32": 1'i32,
      "array": [1, 2, 3]
    }
    check(doc["int32"].toInt32 == 1'i32)
    doc["int32"] = toBson(2'i32)
    check(doc["int32"].toInt32 == 2'i32)
    doc["array"][0] = toBson(10'i32)
    check(doc["array"][0].toInt32 == 10'i32)
    doc["newfield"] = "newvalue".toBson
    check(doc["newfield"].toString == "newvalue")


  test "Check if document has specific field with `in` operator":
    let doc = %*{
      "field1": "string",
      "field2": 1'i32
    }
    check("field1" in doc)
    check(not ("field3" in doc))

  test "Document inside array":
    let doc = %*{
      "field": "value",
      "ar": [
        {
          "field1": 5'i32,
          "field2": "gello"
        },
        {
          "field": "hello"
        }
      ]
    }
    check(doc["ar"][0]["field1"].toInt() == 5)

  test "Document's merge":
    let a = %*{
      "field1": "value1",
      "field2": [
        {"ar0": "1"},
        {"ar1": "2"},
        {"ar2": "3"}
      ]
    }
    let b = %*{
      "field3": "value2",
      "field0": 5'i32
    }

    let abm = merge(a, b)
    check(abm["field0"].toInt32 == 5'i32)
    check(abm["field2"][0]["ar0"].toString == "1")

  test "Document update":
    let a = %*{
      "field1": "value1",
      "field2": [
        {"ar0": "1"},
        {"ar1": "2"},
        {"ar2": "3"}
      ]
    }

    let b = %*{
      "field3": "value2",
      "field0": 5'i32
    }

    b.update(a)
    check(b["field0"].toInt32 == 5'i32)
    check(b["field2"][0]["ar0"].toString == "1")

  test "array length":
    var arr = newBsonArray()
    arr.add(%*{
      "field3": "value2",
      "field0": 5'i32
    })

    check(arr.len == 1)

  test "miscellaneous":
    let oid = genOid()
    let bdoc: Bson = %*{
      "image": bin("12312l3jkalksjslkvdsdas"),
      "balance":       1000.23,
      "name":          "John",
      "someId":        oid,
      "someTrue":      true,
      "surname":       "Smith",
      "someNull":      null(),
      "minkey":        minkey(),
      "maxkey":        maxkey(),
      "digest":        "".toMd5(),
      "regexp-field":  regex("pattern", "ismx"),
      "undefined":     undefined(),
      "someJS":        js("function identity(x) {return x;}"),
      "someRef":       dbref("db.col", genOid()),
      "userDefined":   binuser("some-binary-data"),
      "someTimestamp": BsonTimestamp(increment: 1, timestamp: 1),
      "utcTime":       timeUTC(getTime()),
      "subdoc": %*{
        "salary": 500
      },
      "array": [
        %*{"string": "hello"},
        %*{"string" : "world"}
      ]
    }

    checkpoint bdoc
    let bbytes = bdoc.bytes()
    let recovered = newBsonDocument(bbytes)
    checkpoint "RECOVERED: ", recovered

    var bdoc2 = newBsonArray()
    bdoc2.add(2)
    bdoc2.add(2)
    checkpoint bdoc2
