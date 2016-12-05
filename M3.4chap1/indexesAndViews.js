// to start mongod: /Users/shuyu/Mongodb3.4/bin/mongod --dbpath mongo3.4data/3.4db
// to run .js: /Users/shuyu/mongodb3.4/bin/mongo < mongodb3.4/M3.4chap1/indexesAndViews.js

//conn = new Mongo();
//db = connect("localhost:27017/test");

function printCursor(curs) { 
    while (curs.hasNext()) { printjson(curs.next())}
};

db = db.getSiblingDB("personnel");  // analogous to 'use personnel'
    
var sevenEmployees = [
    { name: "Will Cross", team: "Curriculum", likes: ["physics", "lunch", "mongodb" ] },
    { name: "Zach Davis", team: "Curriculum", likes: ["video games", "windows", "lunch", "mongodb"] },
    { name: "Kirby Kohlmorgen", team: "Curriculum", likes: ["mongodb", "New York", "lunch"] },
    { name: "Graham Lowe", team: "University Platform", likes: ["mongodb", "Tim Horton's", "leadership"] },
    { name: "John Yu", team: "University Platform", likes: ["video games", "lunch", "mongodb", "rubik's cube"] },
    { name: "David Percy", team: "University Platform", likes: ["mongodb", "lunch", "video games", "puzzles"] },
    { name: "Jason Flax", team: "University Platform", likes: ["mongodb", "lunch", "current events", "design"] } ];

Norberto = { name: "Norberto Leite", team: "Curriculum", likes: ["languages", "lunch", "mongodb", "leadership"] };

var eightEmployees = sevenEmployees.concat(Norberto);
print("First, we'll initialize our data.");
db.employees.drop();
db.employees.insertMany(eightEmployees);
db.createView( "whatCurriculumLikes", "employees", [
        { $match : { team : "Curriculum" } },
        { $unwind : "$likes" }, 
        { 
            $group : 
            { 
                _id : { topic : "$likes" },
                popularity : { $sum : 1 } 
            } 
        }, {
            $sort : { popularity: -1 }
        } ] );

print("OK, initial setup is done. Here's what our view looks like when we query it:");
printCursor(db.whatCurriculumLikes.find());

print("Great, now let's explain it.");
printCursor(db.whatCurriculumLikes.explain().find());

print("OK, let's make that more efficient. We'll start by creating an index.");
db.employees.createIndex( { team : 1 } );

print("Now let's explain the original query again.");
printCursor(db.whatCurriculumLikes.explain().find());

print("Finally, let's create a view that uses another view as its source.");
db.createView("popularCurriculumTopics", "whatCurriculumLikes", [
        { $match : { popularity : { $gte : 2 } } },
        { $group : { _id : null, popularTopics : { $push : "$_id.topic" } } } ] );

print("Now, let's see our views.");
printCursor(db.system.views.find());

print("... and the new view.");
printCursor(db.popularCurriculumTopics.find());

print("... and explain it:");
printCursor(db.popularCurriculumTopics.explain().find());