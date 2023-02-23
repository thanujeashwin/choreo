import ballerina/graphql;
import ballerina/io;
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerina/regex;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

// import ballerinax/mysql;

// Don't change the port number

configurable string password = "wso2!234"; //jdbc:mysql://localhost:3306/testdb
configurable string host = "sahackathon.mysql.database.azure.com";
configurable int port = 3306;
configurable string db = "ashwin_db";
configurable string username = "choreo";

type Item record {
    string ID;
    string Title;
    string Description;
    string Includes;
    string IntendedFor;
    string Color;
    string Material;
    float Price;
};

type InsertExecutionResult record {
    int affectedRowCount;
    int lastInsertId;
};

public distinct service class ItemData {
    private final readonly & Item entryRecord;

    function init(Item entryRecord) {
        self.entryRecord = entryRecord.cloneReadOnly();
    }

    resource function get title() returns string {
        return self.entryRecord.Title;
    }

    resource function get Description() returns string {
        return self.entryRecord.Description;
    }

    resource function get Includes() returns string {
        return self.entryRecord.Includes;
    }

    resource function get intendedFor() returns string {
        return self.entryRecord.IntendedFor;
    }

    resource function get color() returns string {
        return self.entryRecord.Color;
    }

    resource function get material() returns string {
        return self.entryRecord.Material;
    }

    resource function get price() returns float {
        return self.entryRecord.Price;
    }

}

service /graphql on new graphql:Listener(9090) {

    // Write your answer here. You must change the input and
    // the output of the below signature along with the logic.
    private final mysql:Client dbClient;

    function init() returns error? {
        // Initiate the mysql client at the start of the service. This will be used
        // throughout the lifetime of the service.
        mysql:Options mysqlOptions = {
            ssl: {
                mode: mysql:SSL_PREFERRED
            },
            connectTimeout: 10
        };
        self.dbClient = check new (host = host, user = username, password = password, database = db, port = port, connectionPool = {maxOpenConnections: 3});
    }

    remote function editAddItem(string itemInfo) returns string {
        io:println(itemInfo);
        string[] itemDescriptions = regex:split(itemInfo, ",");
        string title = "";
        string description = "";
        string includes = "";
        string intentedFor = "";
        string color = "";
        string material = "";
        float|error price = -1;
        int|error id = -1;
        foreach string itemDescription in itemDescriptions {
            string[] itemDescriptionParts = regex:split(itemDescription, ":");
            io:println(itemDescriptionParts);

            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("Title")) {
                title = itemDescriptionParts[1];
            }
            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("Description")) {
                description = itemDescriptionParts[1];
            }
            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("Includes")) {
                includes = itemDescriptionParts[1];
            }
            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("IntendedFor")) {
                intentedFor = itemDescriptionParts[1];
            }
            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("Color")) {
                color = itemDescriptionParts[1];
            }
            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("Material")) {
                material = itemDescriptionParts[1];
            }
            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("Price")) {
                price = float:fromString(itemDescriptionParts[1]);
            }
            if (itemDescriptionParts[0].equalsIgnoreCaseAscii("ID")) {
                id = int:fromString(itemDescriptionParts[1]);
            }
        }
        // jdbc:Client|sql:Error dbClient = new (hostPortDB, username, password, poolOptions: {maximumPoolSize: 5});
        io:println("DB Client initiated");
        if (self.dbClient is jdbc:Client) {
            io:println("DB Client created successfully");
            io:println(`INSERT INTO itemtable (title, description, includes, intendedFor, color, material, price) VALUES ${title}, ${description}, ${includes}, ${intentedFor}, ${color}, ${material}, ${price})`);
            if (self.dbClient is jdbc:Client) {
                do {
                    if (id == -1 && price is float) {
                        sql:ParameterizedQuery query = `INSERT INTO itemtable (title, description, includes, intendedFor, color, material, price) 
                                VALUES (${title}, ${description}, ${includes}, ${intentedFor}, ${color}, ${material}, ${price})`;
                        sql:ExecutionResult result = check self.dbClient->execute(query);
                        io:println("Item inserted: ", result);
                        int? count = result.affectedRowCount;
                        //The integer or string generated by the database in response to a query execution.
                        string|int? generatedKey = result.lastInsertId;
                        // json jsonResultObject = <json>result;
                        // InsertExecutionResult|error insertExecutionResult = jsonResultObject.fromJsonWithType();
                        if (generatedKey is string) {
                            return generatedKey;
                        } else {
                            return generatedKey.toString();
                        }

                    } else if (id is int && price is float) {
                        sql:ParameterizedQuery query = `UPDATE itemtable SET title = ${title}, description = ${description}, 
                                includes = ${includes}, intentedFor = ${intentedFor}, color = ${color}, material = ${material}, price = ${price}
                                 WHERE ID = ${id};`;
                        sql:ExecutionResult result = check self.dbClient->execute(query);
                        io:println("Item updated: ", result);
                        int? count = result.affectedRowCount;
                        //The integer or string generated by the database in response to a query execution.
                        string|int? generatedKey = result.lastInsertId;
                        // json jsonResultObject = <json>result;
                        // InsertExecutionResult|error insertExecutionResult = jsonResultObject.fromJsonWithType();
                        if (generatedKey is string) {
                            return generatedKey;
                        } else {
                            return generatedKey.toString();
                        }
                    }

                } on fail var e {
                    io:println("Exception occurred when inserting. ", e);
                    return "Exception occurred when inserting or updating";
                }
            }
        }

        // Item item = {Title: "entry.Title", Description: "entry.Description", Includes: "entry.Includes", IntendedFor: "entry.IntendedFor", Color: "entry.Color", Material: "entry.Material", Price: 12.23};
        // return new ItemData(item);
        return "Execption ocurred";
    }

    resource function get items() returns Item[] {
        Item[] items = [];
        do {
            // mysql:Client mysqlClients = check new ("sahackathon.mysql.database.azure.com", "choreo", "wso2!234", "db_name", 3306, connectionPool={maxOpenConnections: 3});
            if (self.dbClient is jdbc:Client) {
                do {
                    // sql:ExecutionResult createTableResult = check self.dbClient->execute(`SELECT * FROM itemtable`);
                    // io:println("DBClient OK: ", createTableResult);
                    sql:ParameterizedQuery query = `SELECT * from itemtable`;
                    stream<Item, sql:Error?> resultStream = self.dbClient->query(query);
                    io:println("DBClient executed select: ", resultStream);
                    check from Item item in resultStream
                        do {
                            items.push(item);
                            io:println(item);
                        };

                } on fail var e {
                    io:println("Exception occurred when inserting. ", e);
                }
            }
            return items;
        }
    }
}

// service /graphql on new graphql:Listener(9090) {

//     // Write your answer here. You must change the input and
//     // the output of the below signature along with the logic.

//     resource function get sleepSummary(string ID, TimeUnit timeunit) returns SleepSummary[] {
//         SleepSummary[] sleepSummaries = [];
//         int multiplier = 1;
//         if (timeunit == SECONDS) {
//             multiplier = 60;
//         }
//         do {
//             http:Client sleepSummaryEP = check new ("http://localhost:9091");
//             map<json>|http:ClientError sleepSummaryResponse = sleepSummaryEP->get("/activities/summary/sleep/user/" + ID);
//             if (sleepSummaryResponse is map<json>) {
//                 io:println(sleepSummaryResponse["sleep"]);
//                 json[] sleepItems = <json[]>sleepSummaryResponse["sleep"];

//                 foreach int x in 0 ..< sleepItems.length() {
//                     map<json> sleepObject = <map<json>>sleepItems[x];
//                     map<json> levels = <map<json>>sleepObject["levels"];
//                     map<json> summary = <map<json>>levels["summary"];
//                     string[] keys = summary.keys();

//                     int deep = 0;
//                     int wake = 0;
//                     int light = 0;
//                     foreach string key in keys {
//                         map<json> levelValue = <map<json>>summary[key];
//                         io:println(levelValue);
//                         io:println(levelValue["minutes"]);
//                         match key {
//                             "wake" => {
//                                 wake = <int>levelValue["minutes"] * multiplier;
//                             }
//                             "deep" => {
//                                 deep = <int>levelValue["minutes"] * multiplier;
//                             }
//                             "light" => {
//                                 light = <int>levelValue["minutes"] * multiplier;
//                             }
//                         }
//                     }
//                     Levels level = {deep: deep, wake: wake, light: light};
//                     SleepSummary sleepSUmmary = {date: <string>sleepObject["date"], duration: <int>sleepObject["duration"]*multiplier, levels: level};
//                     sleepSummaries.push(sleepSUmmary);
//                 }                
//             }
//         }
//         on fail var e {
//             io:println("Error ocurred !!", e);
//         }
//         return sleepSummaries;
//     }
// }

// enum TimeUnit {
//     SECONDS,
//     MINUTES
// }

// public type SleepSummary record {|
//     string date;
//     int duration;
//     Levels levels;
// |};

// public type Levels record {|
//     int deep;
//     int wake;
//     int light;
// |};